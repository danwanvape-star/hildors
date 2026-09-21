import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../localization/localization.dart';
import 'cloud_business_intake.dart';
import 'cloud_order_submission.dart';
import 'custom_store_billing.dart';
import '../community/content_preview_player.dart';
import '../community/verified_video_download.dart';
import 'custom_delivery_download.dart';

class CustomPlansPage extends StatefulWidget {
  const CustomPlansPage({super.key, this.service, this.billing});
  final CloudBusinessIntake? service;
  final CustomStoreBilling? billing;
  @override
  State<CustomPlansPage> createState() => _CustomPlansPageState();
}

class _CustomPlansPageState extends State<CustomPlansPage> {
  CloudBusinessIntake get api => widget.service ?? CloudBusinessIntake.instance;
  List<Map<String, dynamic>> plans = [], orders = [];
  bool busy = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
    CloudBusinessIntake.identityChanges.addListener(identityChanged);
  }

  @override
  void dispose() {
    CloudBusinessIntake.identityChanges.removeListener(identityChanged);
    super.dispose();
  }

  void identityChanged() {
    if (mounted) {
      setState(() {
        plans = [];
        orders = [];
      });
      load();
    }
  }

  Future<void> load() async {
    final revision = api.identityRevision;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final p = await api.contentRequest('GET', '/v1/customization-plans');
      final o = await api.orderRequest('GET', '/v1/me/customization-orders');
      if (revision != api.identityRevision) return;
      if (p.statusCode != 200) {
        throw const CloudApiException('SERVICE_UNAVAILABLE');
      }
      if (mounted) {
        setState(() {
          plans = (p.body['items'] as List)
              .map((x) => Map<String, dynamic>.from(x as Map))
              .toList();
          orders = (o['items'] as List)
              .map((x) => Map<String, dynamic>.from(x as Map))
              .where((x) => x['planSnapshot'] != null)
              .toList();
        });
      }
    } catch (_) {
      if (mounted && revision == api.identityRevision) {
        setState(() => error = 'SERVICE_UNAVAILABLE');
      }
    } finally {
      if (mounted && revision == api.identityRevision) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
        appBar: AppBar(title: Text(l.customPlansTitle), actions: [
          IconButton(
              tooltip: l.deletionRefresh,
              onPressed: busy ? null : load,
              icon: const Icon(Icons.refresh))
        ]),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Text(l.customUnavailable),
          if (busy) const LinearProgressIndicator(),
          if (error != null) Text(localizedError(l, error)),
          for (final p in plans)
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.customSeconds(p['durationSeconds'] as int)),
                          Text(l.customBase(
                              'US\$${((p['usdBaseCents'] as int) / 100).toStringAsFixed(2)}')),
                          Text((p['description'] as Map?)?[
                                  l.localeName.startsWith('zh')
                                      ? 'zh'
                                      : 'en'] as String? ??
                              ''),
                          TextButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                      builder: (_) => _CustomRequestPage(
                                          plan: p,
                                          service: api))).then((_) => load()),
                              child: Text(l.customRequest))
                        ]))),
          const SizedBox(height: 20),
          Text(l.customOrdersTitle,
              style: Theme.of(context).textTheme.titleLarge),
          if (!busy && orders.isEmpty) Text(l.customEmpty),
          for (final o in orders)
            ListTile(
                title: Text(o['characterName'] as String? ?? ''),
                subtitle: Text(_status(l, o['status'])),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => _CustomOrderPage(
                                order: o,
                                service: api,
                                billing: widget.billing ??
                                    UnavailableCustomStoreBilling())))
                    .then((_) => load())),
        ]));
  }
}

String _status(AppLocalizations l, dynamic s) => switch (s) {
      'free_review' || 'approved_for_quote' => l.customStatusReview,
      'needs_info' => l.customStatusInfo,
      'quoted' => l.customStatusQuote,
      'in_production' => l.customStatusMaking,
      'quality_review' => l.customStatusQc,
      'user_acceptance' => l.customStatusAccept,
      'delivered' => l.customStatusDelivered,
      'rejected' => l.customStatusRejected,
      'withdrawn' => l.customStatusWithdrawn,
      _ => l.customStatusReview
    };

class _CustomRequestPage extends StatefulWidget {
  const _CustomRequestPage({required this.plan, required this.service});
  final Map<String, dynamic> plan;
  final CloudBusinessIntake service;
  @override
  State<_CustomRequestPage> createState() => _CustomRequestState();
}

class _CustomRequestState extends State<_CustomRequestPage> {
  final name = TextEditingController(), requirements = TextEditingController();
  final materials = <CloudOrderMaterial>[];
  late final CloudOrderSubmission submission;
  bool matchedAudio = false;
  bool consent = false, busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    submission = CloudOrderSubmission(
        request: widget.service.orderRequest,
        identityRevision: () => widget.service.identityRevision);
  }

  @override
  void dispose() {
    name.dispose();
    requirements.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    try {
      final result = await FilePicker.pickFiles(
          type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png']);
      if (result.isEmpty) return;
      if (result.length + materials.length > 8) throw const FormatException();
      final added = <CloudOrderMaterial>[];
      for (final file in result) {
        if (await file.length() > 8 * 1024 * 1024) {
          throw const FormatException();
        }
        added.add(CloudOrderMaterial(
            name: file.name, bytes: await file.readAsBytes()));
      }
      for (final x in added) {
        x.validate();
      }
      if (mounted) setState(() => materials.addAll(added));
    } catch (_) {
      if (mounted) setState(() => error = context.l10n.customImageError);
    }
  }

  Future<void> submit() async {
    if (name.text.trim().isEmpty ||
        requirements.text.trim().isEmpty ||
        !consent) {
      setState(() => error = context.l10n.customValidation);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await submission.submit({
        'audioMode': matchedAudio ? 'matched' : 'none',
        'planId': widget.plan['id'],
        'planVersion': widget.plan['version'],
        'characterName': name.text.trim(),
        'requirements': requirements.text.trim(),
        'sourceType': 'original',
        'requestedFeatures': <String>[],
        'materialCount': materials.length,
        'marketRegion': '',
        'privacyConsentVersion': 'custom-private-reference-v1'
      }, materials);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.customSubmitted)));
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) setState(() => error = context.l10n.errorNetwork);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
        appBar: AppBar(title: Text(l.customRequest)),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Text(l.customSeconds(widget.plan['durationSeconds'] as int)),
          SwitchListTile(
              value: matchedAudio,
              onChanged: busy || submission.started
                  ? null
                  : (v) => setState(() => matchedAudio = v),
              title:
                  Text(matchedAudio ? l.customAudioMatched : l.customAudioNone),
              subtitle: Text(l.customAudioRate(
                  (widget.plan['audio'] as Map?)?['markupPercent'] as int? ??
                      20))),
          Text(l.customAudioHelp),
          Text(l.customAudioTotal(
              'US\$${(((matchedAudio ? (widget.plan['audio'] as Map)['totalUsdCents'] : widget.plan['usdBaseCents']) as int) / 100).toStringAsFixed(2)}')),
          TextField(
              controller: name,
              maxLength: 120,
              enabled: !busy && !submission.started,
              decoration: InputDecoration(labelText: l.customName)),
          TextField(
              controller: requirements,
              maxLength: 10000,
              minLines: 3,
              maxLines: 8,
              enabled: !busy && !submission.started,
              decoration: InputDecoration(labelText: l.customRequirements)),
          Text(l.customPrivacy),
          CheckboxListTile(
              value: consent,
              onChanged: busy || submission.started
                  ? null
                  : (v) => setState(() => consent = v ?? false),
              title: Text(l.customConsent)),
          Text(l.customMaterialCount(materials.length)),
          for (final m in materials)
            ListTile(
                title: Text(m.name),
                trailing: IconButton(
                    tooltip: l.accountCancel,
                    onPressed: busy || submission.started
                        ? null
                        : () => setState(() => materials.remove(m)),
                    icon: const Icon(Icons.close))),
          OutlinedButton(
              onPressed: busy || submission.started ? null : pick,
              child: Text(l.customMaterials)),
          if (error != null) Text(error!),
          if (busy) const LinearProgressIndicator(),
          FilledButton(
              onPressed: busy ? null : submit, child: Text(l.customRequest))
        ]));
  }
}

class _CustomOrderPage extends StatefulWidget {
  const _CustomOrderPage(
      {required this.order, required this.service, required this.billing});
  final Map<String, dynamic> order;
  final CloudBusinessIntake service;
  final CustomStoreBilling billing;
  @override
  State<_CustomOrderPage> createState() => _CustomOrderState();
}

class _CustomOrderState extends State<_CustomOrderPage> {
  DownloadCancellation? downloadCancellation;
  int downloaded = 0, total = 0;
  Map<String, String> previewHeaders = {};
  late Map<String, dynamic> order;
  late final int identity;
  CustomStoreOffer? price;
  bool accepted = false, busy = false;
  String? error;
  String get root => '/v1/me/customization-orders/${order['id']}';
  @override
  void initState() {
    super.initState();
    identity = widget.service.identityRevision;
    order = widget.order;
    CloudBusinessIntake.identityChanges.addListener(identityChanged);
    refresh();
  }

  @override
  void dispose() {
    downloadCancellation?.cancel();
    CloudBusinessIntake.identityChanges.removeListener(identityChanged);
    super.dispose();
  }

  void identityChanged() {
    if (mounted && identity != widget.service.identityRevision) {
      downloadCancellation?.cancel();
      setState(() {
        previewHeaders = {};
        order = {'id': order['id']};
        price = null;
        error = context.l10n.errorSession;
      });
    }
  }

  Future<Map<String, String>> credentials() async {
    guard();
    final identity = await widget.service.downloadIdentity();
    guard();
    return {'Authorization': 'Bearer ${identity.token}'};
  }

  void guard() {
    if (identity != widget.service.identityRevision) {
      throw const CloudApiException('SESSION_EXPIRED');
    }
  }

  Future<void> refresh() async {
    setState(() => busy = true);
    try {
      guard();
      final o = await widget.service.orderRequest('GET', root);
      guard();
      final product = (o['planSnapshot'] as Map?)?[
          widget.billing.platform == 'apple'
              ? 'appleProductId'
              : 'googleProductId'] as String?;
      final headers = ['user_acceptance', 'delivered'].contains(o['status']) &&
              o['deliverable'] != null
          ? await credentials()
          : <String, String>{};
      final quote = product == null || product.isEmpty
          ? null
          : await widget.billing.product(product);
      guard();
      if (mounted) {
        setState(() {
          if ((order['offer'] as Map?)?['version'] !=
              (o['offer'] as Map?)?['version']) {
            accepted = false;
          }
          order = o;
          previewHeaders = headers;
          price = quote?.productId == product ? quote : null;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => error = context.l10n.errorServiceUnavailable);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> pay({bool restore = false}) async {
    if (price == null || !accepted) return;
    setState(() => busy = true);
    try {
      guard();
      final fresh = await widget.billing.product(price!.productId);
      guard();
      if (fresh == null ||
          fresh.productId != price!.productId ||
          fresh.localizedPrice != price!.localizedPrice) {
        if (mounted) {
          setState(() {
            price = fresh;
            accepted = false;
          });
        }
        return;
      }
      final proofs = restore
          ? await widget.billing.restore(fresh.productId, order['id'] as String)
          : [await widget.billing.purchase(fresh, order['id'] as String)];
      for (final proof in proofs) {
        if (proof == null) continue;
        guard();
        final result = await widget.service
            .contentRequest('POST', '$root/purchase', document: {
          'platform': widget.billing.platform,
          'proof': proof,
          'offerVersion': (order['offer'] as Map)['version'],
          'acceptedTerms': true
        });
        guard();
        if (result.statusCode != 200) {
          throw const CloudApiException('PAYMENT_NOT_READY');
        }
      }
      await refresh();
    } catch (_) {
      if (mounted) setState(() => error = context.l10n.customUnavailable);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> saveDelivery() async {
    final cancellation = DownloadCancellation();
    downloadCancellation = cancellation;
    setState(() {
      busy = true;
      error = null;
      downloaded = total = 0;
    });
    try {
      await downloadCustomDelivery(
          service: widget.service,
          orderId: order['id'] as String,
          cancellation: cancellation,
          guard: guard,
          onProgress: (received, length) {
            if (mounted) {
              setState(() {
                downloaded = received;
                total = length;
              });
            }
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.customSavedDelivery)));
      }
    } catch (_) {
      if (mounted) setState(() => error = context.l10n.downloadFailed);
    } finally {
      downloadCancellation = null;
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> supplement() async {
    var requirements = order['requirements'] as String? ?? '';
    final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text(ctx.l10n.customSupplement),
                content: SingleChildScrollView(
                    child: TextFormField(
                        initialValue: requirements,
                        onChanged: (v) => requirements = v,
                        minLines: 3,
                        maxLines: 8,
                        maxLength: 10000)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(ctx.l10n.accountCancel)),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(ctx.l10n.customSupplement))
                ]));
    if (!mounted || yes != true || requirements.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      guard();
      final response = await widget.service.contentRequest(
          'POST', '$root/plan-action', document: {
        'version': order['version'],
        'action': 'resubmit',
        'requirements': requirements
      });
      guard();
      if (response.statusCode != 200) throw const FormatException();
      await refresh();
    } catch (_) {
      if (mounted) setState(() => error = context.l10n.errorGeneric);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> addMaterials() async {
    setState(() => busy = true);
    try {
      guard();
      final files = await FilePicker.pickFiles(
          type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png']);
      guard();
      if (files.length + ((order['materials'] as List?)?.length ?? 0) > 8) {
        throw const FormatException();
      }
      for (final file in files) {
        if (await file.length() > 8 * 1024 * 1024) {
          throw const FormatException();
        }
        final material = CloudOrderMaterial(
            name: file.name, bytes: await file.readAsBytes());
        material.validate();
        guard();
        final query =
            Uri(queryParameters: {'name': material.name, 'slot': material.slot})
                .query;
        await widget.service.orderRequest('POST', '$root/materials?$query',
            bytes: material.bytes, contentType: material.contentType);
        guard();
      }
      await refresh();
    } catch (_) {
      if (mounted) setState(() => error = context.l10n.customImageError);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> action(String action) async {
    if (action == 'accept_delivery') {
      final yes = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: Text(ctx.l10n.customConfirmDelivery),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(ctx.l10n.accountCancel)),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(ctx.l10n.customAccept))
                  ]));
      if (!mounted || yes != true) return;
    }
    String note = '';
    if (action == 'request_revision') {
      final yes = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: Text(ctx.l10n.customRevise),
                  content: TextField(
                      onChanged: (v) => note = v,
                      maxLength: 2000,
                      decoration: InputDecoration(
                          labelText: ctx.l10n.customRevisionNote)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(ctx.l10n.accountCancel)),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(ctx.l10n.customRevise))
                  ]));
      if (yes != true || note.trim().isEmpty) return;
    }
    setState(() => busy = true);
    try {
      guard();
      final result = await widget.service.contentRequest(
          'POST', '$root/plan-action', document: {
        'version': order['version'],
        'action': action,
        'note': note
      });
      if (result.statusCode != 200) throw const FormatException();
      await refresh();
    } catch (_) {
      if (mounted) setState(() => error = context.l10n.errorGeneric);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final terms = (order['offer'] as Map?)?['terms'] as Map?;
    return Scaffold(
        appBar: AppBar(title: Text(l.customOrdersTitle), actions: [
          IconButton(
              tooltip: l.deletionRefresh,
              onPressed: busy ? null : refresh,
              icon: const Icon(Icons.refresh))
        ]),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Text(order['characterName'] as String? ?? ''),
          Text(_status(l, order['status'])),
          Text(l.customPrivacy),
          Text((order['planSnapshot'] as Map?)?['audioMode'] == 'matched'
              ? l.customAudioMatched
              : l.customAudioNone),
          if (widget.billing.testMode) Text(l.customTestMode),
          if (busy)
            LinearProgressIndicator(
                value: downloadCancellation != null && total > 0
                    ? downloaded / total
                    : null),
          if (downloadCancellation != null) ...[
            Text(l.customSavingDelivery),
            TextButton(
                onPressed: () => downloadCancellation?.cancel(),
                child: Text(l.accountCancel))
          ],
          if (['free_review', 'needs_info'].contains(order['status'])) ...[
            TextButton(
                onPressed: busy ? null : addMaterials,
                child: Text(l.customMaterials)),
            Text(l.customMaterialCount(
                (order['materials'] as List?)?.length ?? 0)),
            if (order['status'] == 'needs_info')
              FilledButton(
                  onPressed: busy ? null : supplement,
                  child: Text(l.customSupplement))
          ],
          if (order['status'] == 'delivered')
            FilledButton(
                onPressed: busy ? null : saveDelivery,
                child: Text(l.customSaveDelivery)),
          if (error != null) Text(error!),
          if ((order['productionUpdates'] as List?)?.isNotEmpty ?? false) ...[
            Text(l.customProgress,
                style: Theme.of(context).textTheme.titleMedium),
            for (final update in (order['productionUpdates'] as List).reversed)
              ListTile(
                  title: Text(_progressText(update as Map, l.localeName)),
                  subtitle:
                      Text(_progressDate(context, update['at'] as String?)))
          ],
          if (order['adminNote'] is String) Text(order['adminNote'] as String),
          if (terms != null) ...[
            Text(l.customTerms),
            Text(l.customRevisionLimit(order['revisionCount'] as int? ?? 0,
                terms['maxRevisions'] as int? ?? 0)),
            for (final f in [
              ('deliveryContent', l.customContent),
              ('deliveryPeriod', l.customPeriod),
              ('revisionScope', l.customRevisions),
              ('usageRights', l.customRights)
            ])
              ListTile(
                  title: Text(f.$2),
                  subtitle: Text(terms[f.$1] as String? ?? '')),
            if (order['status'] == 'quoted') ...[
              CheckboxListTile(
                  value: accepted,
                  onChanged: busy
                      ? null
                      : (v) => setState(() => accepted = v ?? false),
                  title: Text(l.customAcceptTerms)),
              if (price == null)
                Text(l.customUnavailable)
              else
                FilledButton(
                    onPressed: busy || !accepted ? null : () => pay(),
                    child: Text(l.customPay(price!.localizedPrice))),
              TextButton(
                  onPressed: busy || !accepted || price == null
                      ? null
                      : () => pay(restore: true),
                  child: Text(l.customRestore))
            ]
          ],
          if (previewHeaders.isNotEmpty)
            ContentPreviewPlayer(
                key: ValueKey('${order['id']}:${order['deliverable']?['id']}'),
                assetPath: null,
                networkUrl: widget.service.baseUri!
                    .resolve('$root/deliverable')
                    .toString(),
                httpHeaders: previewHeaders,
                refreshHttpHeaders: credentials),
          if (order['status'] == 'user_acceptance') ...[
            FilledButton(
                onPressed: busy ? null : () => action('accept_delivery'),
                child: Text(l.customAccept)),
            OutlinedButton(
                onPressed: busy ? null : () => action('request_revision'),
                child: Text(l.customRevise))
          ]
        ]));
  }
}

String _progressText(Map update, String language) {
  final text = update['text'] as Map? ?? {};
  final zh = text['zh'] as String? ?? '';
  return language.startsWith('zh') && zh.isNotEmpty
      ? zh
      : text['en'] as String? ?? '';
}

String _progressDate(BuildContext context, String? raw) {
  final date = DateTime.tryParse(raw ?? '')?.toLocal();
  if (date == null) return '';
  final format = MaterialLocalizations.of(context);
  return '${format.formatMediumDate(date)} ${format.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
}
