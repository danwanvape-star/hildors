import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:file_picker/file_picker.dart';

import 'character_entitlement_repository.dart';
import 'character_gate_ui.dart';
import 'character_gate_order_progress.dart';
import 'character_gate_quality_review.dart';
import 'customization_order_repository.dart';
import 'creator_profile_repository.dart';
import 'cloud_business_intake.dart';
import '../video/character_video_package.dart';
import '../video/character_package_page.dart';
import '../video/character_package_picker.dart';

typedef MaterialPicker = Future<List<String>> Function();
typedef PreviewPicker = Future<bool> Function();

const _marketRegionLabels = {
  'us': '美国',
  'eea': '欧洲经济区',
  'uk': '英国',
  'jp': '日本',
  'cn_mainland': '中国大陆',
  'hk': '中国香港',
  'mo': '中国澳门',
  'tw': '中国台湾',
  'asia_other': '其他亚洲地区',
  'other': '其他地区',
  'unspecified': '未指定',
};

String _formatMoney(String? currency, int amountMinor) {
  final code = currency ?? 'USD';
  return code == 'JPY'
      ? '$code $amountMinor'
      : '$code ${(amountMinor / 100).toStringAsFixed(2)}';
}

bool _isPastDate(String? value) {
  final date = DateTime.tryParse(value ?? '');
  return date != null && date.toUtc().isBefore(DateTime.now().toUtc());
}

const _taxTreatmentLabels = {
  'tax_included': '价格已含适用税费',
  'calculated_at_checkout': '适用税费将在付款前计算',
  'not_applicable': '本订单不适用额外税费',
};

const characterGateCatalog = [
  (
    'celestial-mage',
    '星穹术士',
    '幻想神话',
    'assets/images/content_thumbnails/celestial_mage.jpg'
  ),
  (
    'neon-dancer',
    '霓虹舞者',
    '舞台偶像',
    'assets/images/content_thumbnails/neon_dancer.jpg'
  ),
  (
    'deep-sea-oracle',
    '深海先知',
    '可爱陪伴',
    'assets/images/content_thumbnails/deep_sea_oracle.jpg'
  ),
  (
    'crystal-knight',
    '水晶骑士',
    '战斗动作',
    'assets/images/content_thumbnails/crystal_knight.jpg'
  ),
];

class CharacterCatalogCredit {
  const CharacterCatalogCredit(
      {this.creatorName, this.anonymous = false, this.publishedAt});
  final String? creatorName;
  final bool anonymous;
  final DateTime? publishedAt;
}

class FreeOriginalCharactersPage extends StatefulWidget {
  const FreeOriginalCharactersPage(
      {this.repository, this.credits = const {}, super.key});

  final CharacterEntitlementRepository? repository;
  final Map<String, CharacterCatalogCredit> credits;

  @override
  State<FreeOriginalCharactersPage> createState() =>
      _FreeOriginalCharactersPageState();
}

class _FreeOriginalCharactersPageState extends State<FreeOriginalCharactersPage>
    with GateLoadState<FreeOriginalCharactersPage> {
  late final CharacterEntitlementRepository repository =
      widget.repository ?? const LocalCharacterEntitlementRepository();
  Set<String> claimedIds = const {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() => loadGateData(
      repository.loadClaimedCharacterIds, (ids) => claimedIds = ids);

  @override
  Widget build(BuildContext context) => GateScaffold(
        wide: true,
        appBar: AppBar(
            title: Text(GateCopy.text(context, 'freeLibraryTitle')),
            actions: [
              GateRefreshButton(loading: gateLoading, onRefresh: _reload),
            ]),
        body: gateLoading || gateLoadFailed
            ? GateLoadPanel(failed: gateLoadFailed, onRetry: _reload)
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: characterGateCatalog.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final character = characterGateCatalog[index];
                  final claimed = claimedIds.contains(character.$1);
                  final credit = widget.credits[character.$1];
                  final author = credit?.anonymous == true
                      ? GateCopy.text(context, 'catalogAnonymous')
                      : (credit?.creatorName?.trim().isNotEmpty == true
                          ? credit!.creatorName!.trim()
                          : GateCopy.text(context, 'catalogAuthorMissing'));
                  final published = credit?.publishedAt;
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () async {
                        await Navigator.of(context)
                            .push(MaterialPageRoute<void>(
                          builder: (_) => FreeCharacterDetailPage(
                            characterId: character.$1,
                            name: GateCopy.text(
                                context, 'catalog.${character.$1}.name'),
                            category: GateCopy.text(
                                context, 'catalog.${character.$1}.category'),
                            imagePath: character.$4,
                            repository: repository,
                          ),
                        ));
                        if (mounted) await _reload();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(character.$4,
                                    width: 76,
                                    height: 108,
                                    fit: BoxFit.contain,
                                    excludeFromSemantics: true),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(
                                        GateCopy.text(context,
                                            'catalog.${character.$1}.name'),
                                        style: GateDesign.theme()
                                            .textTheme
                                            .titleMedium),
                                    const SizedBox(height: 2),
                                    Text(
                                        GateCopy.text(context,
                                            'catalog.${character.$1}.category'),
                                        style: GateDesign.theme()
                                            .textTheme
                                            .bodySmall),
                                    const SizedBox(height: 6),
                                    Text(
                                        GateCopy.text(context, 'catalogBy',
                                            {'name': author}),
                                        style: GateDesign.theme()
                                            .textTheme
                                            .bodySmall),
                                    Text(
                                        published == null
                                            ? GateCopy.text(
                                                context, 'catalogDateMissing')
                                            : GateCopy.text(
                                                context, 'catalogPublished', {
                                                'date':
                                                    MaterialLocalizations.of(
                                                            context)
                                                        .formatMediumDate(
                                                            published.toLocal())
                                              }),
                                        style: GateDesign.theme()
                                            .textTheme
                                            .bodySmall),
                                    const SizedBox(height: 8),
                                    Text(
                                        GateCopy.text(
                                            context,
                                            claimed
                                                ? 'freeClaimed'
                                                : 'freeClaim'),
                                        style: const TextStyle(
                                            color: GateDesign.accent,
                                            fontWeight: FontWeight.w700)),
                                  ])),
                            ]),
                      ),
                    ),
                  );
                },
              ),
      );
}

class FreeCharacterDetailPage extends StatefulWidget {
  const FreeCharacterDetailPage({
    required this.characterId,
    required this.name,
    required this.category,
    required this.imagePath,
    required this.repository,
    super.key,
  });

  final String characterId;
  final String name;
  final String category;
  final String imagePath;
  final CharacterEntitlementRepository repository;

  @override
  State<FreeCharacterDetailPage> createState() =>
      _FreeCharacterDetailPageState();
}

class _FreeCharacterDetailPageState extends State<FreeCharacterDetailPage>
    with GateLoadState<FreeCharacterDetailPage> {
  var claimed = false;
  var claiming = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() => loadGateData(
      widget.repository.loadClaimedCharacterIds,
      (ids) => claimed = ids.contains(widget.characterId));

  Future<void> _claim() async {
    if (claiming || claimed || gateLoading) return;
    setState(() => claiming = true);
    try {
      await widget.repository.claim(widget.characterId);
      if (!mounted) return;
      setState(() => claimed = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('已加入我的角色\n${GateCopy.text(context, 'freeClaimSuccess')}'),
            action: SnackBarAction(
              label: '立即查看',
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => MyCharactersPage(
                        repository: widget.repository, charactersOnly: true),
                  ));
                }
              },
            )),
      );
    } catch (_) {
      if (mounted) showGateActionError(context);
    } finally {
      if (mounted) setState(() => claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) => GateScaffold(
        appBar: AppBar(title: Text(widget.name), actions: [
          GateRefreshButton(loading: gateLoading || claiming, onRefresh: _load),
        ]),
        body: gateLoading || gateLoadFailed
            ? GateLoadPanel(failed: gateLoadFailed, onRetry: _load)
            : ListView(
                scrollCacheExtent: const ScrollCacheExtent.pixels(600),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 420),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child:
                            Image.asset(widget.imagePath, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                          label: Text(
                              GateCopy.text(context, 'freeOriginalBadge'))),
                      Chip(
                          label:
                              Text(GateCopy.text(context, 'freeDeviceBadge'))),
                      Chip(label: Text(widget.category)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(widget.name,
                      style: GateDesign.theme().textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(GateCopy.text(context, 'freeIncluded')),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(GateCopy.text(context, 'freeDeliveryHelp')),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: claimed || claiming ? null : _claim,
                    icon: claiming
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(claimed ? Icons.check : Icons.add),
                    label: Semantics(
                        liveRegion: true,
                        child: Text(GateCopy.text(
                            context,
                            claiming
                                ? 'freeClaiming'
                                : (claimed ? 'freeClaimed' : 'freeClaim')))),
                  ),
                ],
              ),
      );
}

class MyCharactersPage extends StatefulWidget {
  const MyCharactersPage({
    this.charactersOnly = false,
    this.ordersOnly = false,
    this.repository,
    this.orderRepository,
    super.key,
  });

  final CharacterEntitlementRepository? repository;
  final CustomizationOrderRepository? orderRepository;
  final bool charactersOnly;
  final bool ordersOnly;

  @override
  State<MyCharactersPage> createState() => _MyCharactersPageState();
}

class _MyCharactersPageState extends State<MyCharactersPage>
    with GateLoadState<MyCharactersPage> {
  late final CharacterEntitlementRepository repository =
      widget.repository ?? const LocalCharacterEntitlementRepository();
  late final CustomizationOrderRepository orderRepository =
      widget.orderRepository ?? const LocalCustomizationOrderRepository();
  Set<String> claimedIds = const {};
  Set<String> deviceIds = const {};
  List<CustomizationOrder> orders = const [];
  String? sendingId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() => loadGateData(
        () async => (
          await repository.loadClaimedCharacterIds(),
          await repository.loadDeviceCharacterIds(),
          await orderRepository.loadOrders(),
        ),
        (data) {
          claimedIds = data.$1;
          deviceIds = data.$2;
          orders = data.$3;
        },
      );

  Future<void> _send(String id, String title) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => CharacterPackagePage(
        package: CharacterVideoPackage(id: id, title: title, videos: const []),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.charactersOnly && !widget.ordersOnly) {
      return CharacterPackagePicker(
          picking: false,
          repository: repository,
          orderRepository: orderRepository);
    }
    final characters = characterGateCatalog
        .where((character) =>
            !widget.ordersOnly && claimedIds.contains(character.$1))
        .toList();
    final deliveredOrders = orders
        .where((order) => !widget.ordersOnly && order.status == '已交付')
        .toList();
    final activeOrders = orders
        .where((order) =>
            !widget.charactersOnly &&
            (widget.ordersOnly || order.status != '已交付'))
        .toList();
    return GateScaffold(
      appBar:
          AppBar(title: Text(widget.ordersOnly ? '定制订单' : '我的角色'), actions: [
        GateRefreshButton(
            loading: gateLoading || sendingId != null, onRefresh: _reload),
      ]),
      body: gateLoading || gateLoadFailed
          ? GateLoadPanel(failed: gateLoadFailed, onRetry: _reload)
          : characters.isEmpty &&
                  deliveredOrders.isEmpty &&
                  activeOrders.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 52),
                        const SizedBox(height: 16),
                        Text(
                            widget.ordersOnly
                                ? '暂无定制订单'
                                : GateCopy.text(
                                    context, 'collectionEmptyTitle'),
                            style: GateDesign.theme().textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(GateCopy.text(context, 'collectionEmptyHelp')),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                  builder: (_) => FreeOriginalCharactersPage(
                                      repository: repository)),
                            );
                            if (mounted) await _reload();
                          },
                          icon: const Icon(Icons.auto_awesome_outlined),
                          label: Text(
                              GateCopy.text(context, 'browseFreeCharacters')),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                  builder: (_) => CharacterSourcePage(
                                      orderRepository: orderRepository)),
                            );
                            if (mounted) await _reload();
                          },
                          icon: const Icon(Icons.draw_outlined),
                          label:
                              Text(GateCopy.text(context, 'startFreeReview')),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('角色内容只能通过受控流程发送到设备，不提供原视频或工程文件下载。'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (activeOrders.isNotEmpty) ...[
                      Text('定制进度',
                          style: GateDesign.theme().textTheme.titleLarge),
                      const SizedBox(height: 8),
                      ...activeOrders.map(
                        (order) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const Icon(Icons.design_services_outlined),
                            title: Text(order.characterName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(order.sourceType),
                                    GateStatus(order.status),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                GateJourney.forStatus(order.status),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => CustomizationOrderDetailPage(
                                    order: order,
                                    repository: orderRepository,
                                    entitlementRepository: repository,
                                  ),
                                ),
                              );
                              await _reload();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (deliveredOrders.isNotEmpty) ...[
                      Text('我的定制角色',
                          style: GateDesign.theme().textTheme.titleLarge),
                      const SizedBox(height: 8),
                      ...deliveredOrders.map((order) {
                        final characterId = 'custom-${order.id}';
                        final onDevice = deviceIds.contains(characterId);
                        final sending = sendingId == characterId;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: GateDetailTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.auto_awesome_outlined),
                            ),
                            title: Text(order.characterName),
                            subtitle: Text('${order.sourceType} · 专属定制'),
                            trailing: FilledButton.tonalIcon(
                              onPressed: sendingId != null
                                  ? null
                                  : () =>
                                      _send(characterId, order.characterName),
                              icon: sending
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : Icon(onDevice
                                      ? Icons.check_circle_outline
                                      : Icons.cast_outlined),
                              label: Semantics(
                                liveRegion: true,
                                child: Text(onDevice
                                    ? '查看包内视频'
                                    : (sending ? '正在加载' : '查看包内视频')),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],
                    if (characters.isNotEmpty) const SizedBox(height: 8),
                    ...characters.map((character) {
                      final onDevice = deviceIds.contains(character.$1);
                      final sending = sendingId == character.$1;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        clipBehavior: Clip.antiAlias,
                        child: GateDetailTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(character.$4,
                                width: 104,
                                height: 130,
                                fit: BoxFit.cover,
                                excludeFromSemantics: true),
                          ),
                          title: Text(GateCopy.text(
                              context, 'catalog.${character.$1}.name')),
                          subtitle: Text(
                              '${GateCopy.text(context, 'catalog.${character.$1}.category')} · ${GateCopy.text(context, 'freeCollectionBadge')}'),
                          trailing: FilledButton.tonalIcon(
                            onPressed: sendingId != null
                                ? null
                                : () => _send(character.$1, character.$2),
                            icon: sending
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Icon(onDevice
                                    ? Icons.check_circle_outline
                                    : Icons.cast_outlined),
                            label: Semantics(
                              liveRegion: true,
                              child: Text(onDevice
                                  ? '查看包内视频'
                                  : (sending ? '正在加载' : '查看包内视频')),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}

class CustomizationOrderDetailPage extends StatefulWidget {
  const CustomizationOrderDetailPage({
    required this.order,
    required this.repository,
    this.entitlementRepository,
    super.key,
  });

  final CustomizationOrder order;
  final CustomizationOrderRepository repository;
  final CharacterEntitlementRepository? entitlementRepository;

  @override
  State<CustomizationOrderDetailPage> createState() =>
      _CustomizationOrderDetailPageState();
}

class _CustomizationOrderDetailPageState
    extends State<CustomizationOrderDetailPage>
    with GateLoadState<CustomizationOrderDetailPage> {
  late var order = widget.order;
  var actionBusy = false;
  String revisionDraft = '';
  String disputeDraft = '';
  String correctionDraft = '';

  Future<void> _runOrderAction(Future<void> Function() action) async {
    if (!mounted || actionBusy || gateLoading || gateLoadFailed) return;
    setState(() => actionBusy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) showGateActionError(context);
    } finally {
      if (mounted) setState(() => actionBusy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // The route already receives an order snapshot. Refresh is explicit.
    gateLoading = false;
  }

  Future<void> _withdraw() => _runOrderAction(() async {
        await widget.repository.withdrawReview(order.id);
        if (mounted) await _refreshOrder();
      });

  Future<void> _deleteMaterialsNow() => _runOrderAction(() async {
        final confirmed = await showGateDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            scrollable: true,
            title: const Text('立即删除参考素材？'),
            content: const Text('删除后无法恢复。如需再次申请，你必须重新上传素材；订单和审核记录仍会保留。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('确认删除'),
              ),
            ],
          ),
        );
        if (!mounted || confirmed != true) return;
        await widget.repository.requestImmediateMaterialDeletion(order.id);
        await _refreshOrder();
      });

  Future<void> _showPersonalData() => _runOrderAction(() async {
        final data = await widget.repository.exportPersonalData(order.id);
        if (!mounted || data == null) return;
        await showGateDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            scrollable: true,
            title: const Text('我的数据记录'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: SelectableText(
                  '订单编号：${data['orderId']}\n'
                  '角色名称：${data['characterName']}\n'
                  '来源类型：${data['sourceType']}\n'
                  '常住地区：${_marketRegionLabels[data['marketRegion']] ?? data['marketRegion']}\n'
                  '当前状态：${data['status']}\n'
                  '功能需求：${(data['requestedFeatures'] as List).join('、')}\n'
                  '隐私授权版本：${data['privacyConsentVersion'] ?? '-'}\n'
                  '授权时间：${data['privacyConsentAt'] ?? '-'}\n'
                  '审核结果：${data['reviewDecision'] ?? '-'}\n'
                  '审核说明：${data['reviewNote'] ?? '-'}\n'
                  '素材删除时间：${data['materialDeletedAt'] ?? '-'}\n\n'
                  '${data['mediaExclusionReason']}。',
                ),
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
        );
      });

  Future<void> _requestDataCorrection() => _runOrderAction(() async {
        var note = correctionDraft;
        final confirmed = await showGateDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            scrollable: true,
            title: const Text('申请更正数据'),
            content: TextFormField(
              key: const Key('privacy-correction-note'),
              initialValue: correctionDraft,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '说明哪项记录不准确，以及正确内容是什么。',
              ),
              onChanged: (value) => correctionDraft = note = value,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('提交申请'),
              ),
            ],
          ),
        );
        if (!mounted || confirmed != true || note.trim().isEmpty) return;
        final submitted = await widget.repository.requestPrivacyCorrection(
          orderId: order.id,
          note: note,
        );
        await _refreshOrder();
        if (!mounted || submitted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已有数据更正申请正在处理中')),
        );
      });

  Future<void> _acceptQuote() => _runOrderAction(() async {
        await widget.repository.acceptQuote(order.id);
        if (mounted) await _refreshOrder();
      });

  Future<void> _declineQuote() => _runOrderAction(() async {
        await widget.repository.declineQuote(order.id);
        if (mounted) await _refreshOrder();
      });

  Future<void> _refreshOrder() => loadGateData(
        () async {
          final orders = await widget.repository.loadOrders();
          return orders.firstWhere((item) => item.id == order.id);
        },
        (updated) => order = updated,
      );

  Future<void> _respondToDeliveryExtension(bool accepted) =>
      _runOrderAction(() async {
        final confirmed = await showGateDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(accepted ? '确认接受新交付日期？' : '确认拒绝延期？'),
            content: Text(
              accepted
                  ? '新交付日期为 ${order.proposedProductionDueAt?.split('T').first ?? '-'}。确认后会记录为你在App内作出的明确同意。'
                  : '拒绝后订单将进入平台争议处理，原交付日期保持不变。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('返回'),
              ),
              FilledButton(
                key: Key(accepted
                    ? 'confirm-accept-delivery-extension'
                    : 'confirm-decline-delivery-extension'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(accepted ? '确认接受' : '确认拒绝'),
              ),
            ],
          ),
        );
        if (!mounted || confirmed != true) return;
        await widget.repository.respondToDeliveryExtension(
          orderId: order.id,
          accepted: accepted,
        );
        await _refreshOrder();
      });

  Future<void> _requestRevision() => _runOrderAction(() async {
        var note = revisionDraft;
        final submitted = await showGateDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            scrollable: true,
            title: const Text('说明需要修改的内容'),
            content: TextFormField(
              key: const Key('revision-note'),
              initialValue: revisionDraft,
              minLines: 3,
              maxLines: 5,
              onChanged: (value) => revisionDraft = note = value,
              decoration: const InputDecoration(
                hintText: '例如：希望待机时的手部动作更自然。',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('提交修改意见'),
              ),
            ],
          ),
        );
        if (!mounted || submitted != true || note.trim().isEmpty) return;
        await widget.repository.requestRevision(order.id, note: note);
        await _refreshOrder();
      });

  Future<void> _approveDelivery() => _runOrderAction(() async {
        await widget.repository.approveDelivery(order.id);
        await widget.entitlementRepository?.claim('custom-${order.id}');
        await _refreshOrder();
      });

  Future<void> _openDispute() => _runOrderAction(() async {
        var reason = disputeDraft;
        final submitted = await showGateDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            scrollable: true,
            title: const Text('申请平台介入'),
            content: TextFormField(
              key: const Key('dispute-reason'),
              initialValue: disputeDraft,
              minLines: 3,
              maxLines: 5,
              onChanged: (value) => disputeDraft = reason = value,
              decoration: const InputDecoration(
                hintText: '说明延期、质量或交付范围问题。',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('提交平台处理'),
              ),
            ],
          ),
        );
        if (!mounted || submitted != true || reason.trim().isEmpty) return;
        await widget.repository.openDispute(orderId: order.id, reason: reason);
        await _refreshOrder();
      });

  @override
  Widget build(BuildContext context) {
    final progress = GateOrderProgress.fromStatus(order.status);
    final pending = order.status == '免费预审中';
    final rejected = order.status == '预审未通过';
    final quoted = order.status == '待确认报价';
    final awaitingPayment = order.status == '待支付';
    final inProduction = order.status == '制作中' || order.status == '修改中';
    final awaitingApproval = order.status == '待用户验收';
    final delivered = order.status == '已交付';
    final disputed = order.status == '争议处理中';
    final canOpenDispute = (inProduction || awaitingApproval || delivered) &&
        order.settlementStatus != '已结算';
    return GateScaffold(
      appBar: AppBar(title: const Text('定制申请详情'), actions: [
        GateRefreshButton(
            loading: gateLoading || actionBusy, onRefresh: _refreshOrder),
      ]),
      body: gateLoading || gateLoadFailed
          ? GateLoadPanel(failed: gateLoadFailed, onRetry: _refreshOrder)
          : AbsorbPointer(
              absorbing: actionBusy,
              child: ListView(
                scrollCacheExtent: const ScrollCacheExtent.pixels(600),
                padding: const EdgeInsets.all(20),
                children: [
                  if (actionBusy) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(GateCopy.text(context, 'actionPending')),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(order.characterName,
                      style: GateDesign.theme().textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(order.sourceType),
                        GateStatus(order.status)
                      ]),
                  const SizedBox(height: 12),
                  GateJourney.forStatus(order.status),
                  GateOrderHint(status: order.status),
                  if (order.productionDueAt != null &&
                      {'制作中', '修改中', '待平台质检', '待用户验收'}
                          .contains(order.status)) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: _isPastDate(order.productionDueAt)
                          ? GateDesign.theme().colorScheme.errorContainer
                          : null,
                      child: ListTile(
                        leading: const Icon(Icons.event_outlined),
                        title: const Text('预计交付日期'),
                        subtitle: Text(order.productionDueAt!.split('T').first),
                      ),
                    ),
                    if (order.deliveryExtensionReason != null)
                      Text('平台延期说明：${order.deliveryExtensionReason}'),
                    if (order.deliveryExtensionStatus == 'pending' &&
                        order.proposedProductionDueAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                          '平台建议新日期：${order.proposedProductionDueAt!.split('T').first}'),
                      Text(
                        '请于 ${order.deliveryExtensionResponseDueAt?.replaceFirst('T', ' ').split('.').first ?? '-'} UTC 前回复；未回复不会视为接受。',
                      ),
                      if (order.deliveryExtensionReminderCount > 0)
                        Text(
                            '平台已发送 ${order.deliveryExtensionReminderCount} 次确认提醒。'),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton(
                            key: const Key('accept-delivery-extension'),
                            onPressed: () => _respondToDeliveryExtension(true),
                            child: const Text('接受新日期'),
                          ),
                          OutlinedButton(
                            key: const Key('decline-delivery-extension'),
                            onPressed: () => _respondToDeliveryExtension(false),
                            child: const Text('拒绝并请求平台处理'),
                          ),
                        ],
                      ),
                    ],
                    if (order.deliveryExtensionStatus == 'escalated')
                      Text(
                        '延期请求因用户持续未响应，已转由平台人工处理；不会自动视为接受。'
                        '\n平台处理期限：${order.deliveryExtensionEscalationDueAt?.replaceFirst('T', ' ').split('.').first ?? '-'} UTC',
                      ),
                    if (order.deliveryExtensionResolutionEvidence != null)
                      Text(
                          '延期处理凭证：${order.deliveryExtensionResolutionEvidence}'),
                    if (order.deliveryExtensionVersion > 0)
                      _DeliveryExtensionTimeline(order: order),
                  ],
                  if (order.requestedFeatures.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: order.requestedFeatures
                          .map((feature) => Chip(label: Text(feature)))
                          .toList(),
                    ),
                  ],
                  if (order.materialCount > 0) ...[
                    const SizedBox(height: 10),
                    Text('已提交 ${order.materialCount} 个参考文件'),
                    const Text('隐私记录仅保留数量和授权时间，不保留本地路径或文件名。'),
                  ],
                  if (disputed) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: GateDesign.theme().colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('平台处理中：${order.disputeReason ?? ''}'),
                      ),
                    ),
                  ],
                  if (order.privacyCorrectionStatus != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.edit_note_outlined),
                        title: Text(order.privacyCorrectionStatus == 'pending'
                            ? '数据更正申请处理中'
                            : order.privacyCorrectionStatus == 'approved'
                                ? '数据更正申请已受理'
                                : '数据更正申请未受理'),
                        subtitle: Text(order.privacyCorrectionStatus ==
                                'pending'
                            ? '${order.privacyCorrectionNote ?? ''}\n预计答复日期：${order.privacyCorrectionDueAt?.split('T').first ?? '-'}'
                            : (order.privacyCorrectionResolutionNote ??
                                '平台未提供处理说明')),
                      ),
                    ),
                  ],
                  if (rejected) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: GateDesign.theme().colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('预审未通过',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(
                              '原因类别：${_reviewReasonLabels[order.reviewReasonCode] ?? '其他原因'}',
                            ),
                            const SizedBox(height: 4),
                            Text(order.reviewNote ?? '请根据平台反馈补充资料。'),
                            const SizedBox(height: 6),
                            const Text('本次未产生费用，也不会进入创作者任务池。'),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (order.materialDeletionScheduledAt != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.auto_delete_outlined),
                        title: Text(order.materialDeletedAt == null
                            ? '参考素材删除计划'
                            : '参考素材已删除'),
                        subtitle: Text(
                          order.materialDeletedAt == null
                              ? '计划于 ${order.materialDeletionScheduledAt!.split('T').first} 前从制作素材存储区删除；订单状态和审核记录继续保留。'
                              : '已于 ${order.materialDeletedAt!.split('T').first} 从制作素材存储区清理；订单状态和审核记录继续保留。',
                        ),
                        trailing: order.materialDeletedAt == null
                            ? TextButton(
                                onPressed: _deleteMaterialsNow,
                                child: const Text('立即删除'),
                              )
                            : const Icon(Icons.check_circle_outline),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const _OrderStage(
                    icon: Icons.check_circle,
                    title: '已提交申请',
                    description: '免费，未产生订单金额',
                    active: true,
                  ),
                  _OrderStage(
                    icon: order.status == '已撤回' || rejected
                        ? Icons.cancel_outlined
                        : (pending
                            ? Icons.hourglass_top
                            : progress.reviewPassed
                                ? Icons.check_circle
                                : Icons.help_outline),
                    title: order.status == '已撤回'
                        ? '申请已撤回'
                        : (rejected ? '预审未通过' : '权利与素材预审'),
                    description: order.status == '已撤回'
                        ? '未付款，不会进入制作'
                        : (rejected
                            ? (order.reviewNote ?? '需要补充资料')
                            : (pending
                                ? '平台检查是否可以承接'
                                : progress.reviewPassed
                                    ? '预审已通过'
                                    : '审核状态待确认')),
                    active: pending || progress.reviewPassed,
                  ),
                  _OrderStage(
                    icon: quoted
                        ? Icons.pending_actions_outlined
                        : Icons.request_quote_outlined,
                    title: '报价与交付方案',
                    description: GateCopy.text(context, progress.quoteKey),
                    active: progress.stage == 1,
                  ),
                  _OrderStage(
                    icon: Icons.payment_outlined,
                    title: '用户确认并付款',
                    description: order.status == '已退款'
                        ? '退款已完成，历史支付记录继续保留'
                        : order.status == '退款处理中'
                            ? '平台正在处理退款，请关注处理结果'
                            : inProduction ||
                                    awaitingApproval ||
                                    delivered ||
                                    order.paidAt != null
                                ? '平台已验证支付结果'
                                : '付款前必须看到价格、修改次数和交付范围',
                    active: awaitingPayment ||
                        inProduction ||
                        awaitingApproval ||
                        delivered,
                  ),
                  _OrderStage(
                    icon: Icons.movie_creation_outlined,
                    title: '制作、验收与设备交付',
                    description: delivered
                        ? '用户已验收，内容已进入交付状态'
                        : awaitingApproval
                            ? '第 ${order.previewVersion} 版受控预览等待确认'
                            : inProduction
                                ? '创作者正在按确认的交付范围制作'
                                : progress.stage < 0
                                    ? '当前不处于制作与验收阶段'
                                    : '验收通过后加入我的角色，不导出原视频',
                    active: inProduction || awaitingApproval || delivered,
                  ),
                  if (order.quoteAmountCents != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatMoney(
                                  order.quoteCurrency, order.quoteAmountCents!),
                              style: GateDesign.theme().textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                                '包含 ${order.includedRevisions} 次修改 · 预计 ${order.estimatedDeliveryDays} 天交付'),
                            const SizedBox(height: 6),
                            Text(
                              _taxTreatmentLabels[order.quoteTaxTreatment] ??
                                  '税费口径待确认',
                            ),
                            const SizedBox(height: 6),
                            const Text('报价由创作者提交工作量建议，由 Hildors 平台审核后向你发布。'),
                            const SizedBox(height: 6),
                            const Text('确认报价只代表同意交付方案，本步不会扣款。'),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (quoted)
                    FilledButton(
                      onPressed: _acceptQuote,
                      child: const Text('确认报价，前往支付'),
                    )
                  else if (awaitingPayment)
                    FilledButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CheckoutReviewPage(order: order),
                        ),
                      ),
                      child: const Text('查看付款前确认'),
                    )
                  else if (inProduction)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.verified_outlined),
                            SizedBox(width: 10),
                            Expanded(child: Text('支付已由平台后端验证，订单已进入制作。')),
                          ],
                        ),
                      ),
                    )
                  else if (awaitingApproval)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('受控预览 · 第 ${order.previewVersion} 版'),
                            const SizedBox(height: 6),
                            const Text('预览只能在 App 内查看，不提供视频下载。'),
                            const SizedBox(height: 6),
                            const Text('当前原型仅展示预览记录，真实受控播放尚未接入。'),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _approveDelivery,
                              child: const Text('确认验收并交付'),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: order.revisionsUsed <
                                      (order.includedRevisions ?? 0)
                                  ? _requestRevision
                                  : null,
                              child: Text(
                                '要求修改（${order.revisionsUsed}/${order.includedRevisions ?? 0}）',
                              ),
                            ),
                            if (order.revisionsUsed >=
                                (order.includedRevisions ?? 0)) ...[
                              const SizedBox(height: 8),
                              const Text('已用完本次报价包含的修改次数。'),
                            ],
                          ],
                        ),
                      ),
                    )
                  else if (delivered)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('已完成验收。请在“我的角色”中查看，并通过受控流程发送到绑定设备。'),
                      ),
                    )
                  else if (rejected)
                    FilledButton.tonalIcon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PrototypeReviewPage(
                            type: order.sourceType,
                            orderRepository: widget.repository,
                            initialOrder: order,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_outlined),
                      label: const Text('补充资料并重新申请'),
                    )
                  else if (progress.stage >= 0)
                    FilledButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.lock_outline),
                      label: Text(awaitingPayment ? '支付服务尚未接入' : '付款尚未开放'),
                    ),
                  if (quoted || awaitingPayment) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _declineQuote,
                      child: const Text('拒绝报价并结束订单'),
                    ),
                  ],
                  if (pending) ...[
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: actionBusy ? null : _withdraw,
                      child: Text(actionBusy ? '正在撤回' : '免费撤回申请'),
                    ),
                  ],
                  if (canOpenDispute) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _openDispute,
                      icon: const Icon(Icons.support_agent_outlined),
                      label: const Text('申请平台介入'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _showPersonalData,
                    icon: const Icon(Icons.manage_accounts_outlined),
                    label: const Text('查看我的数据记录'),
                  ),
                  const SizedBox(height: 6),
                  const Center(child: Text('数据副本不包含照片、预览视频或设备内容包')),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: order.privacyCorrectionStatus == 'pending'
                        ? null
                        : _requestDataCorrection,
                    icon: const Icon(Icons.edit_note_outlined),
                    label: Text(order.privacyCorrectionStatus == 'pending'
                        ? '数据更正申请处理中'
                        : '申请更正数据'),
                  ),
                ],
              ),
            ),
    );
  }
}

class CheckoutReviewPage extends StatefulWidget {
  const CheckoutReviewPage({required this.order, super.key});

  final CustomizationOrder order;

  @override
  State<CheckoutReviewPage> createState() => _CheckoutReviewPageState();
}

class _CheckoutReviewPageState extends State<CheckoutReviewPage> {
  var scopeConfirmed = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return GateScaffold(
      appBar: AppBar(title: const Text('付款前确认')),
      body: ListView(
        scrollCacheExtent: const ScrollCacheExtent.pixels(600),
        padding: const EdgeInsets.all(20),
        children: [
          Text(order.characterName,
              style: GateDesign.theme().textTheme.headlineSmall),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatMoney(order.quoteCurrency, order.quoteAmountCents!),
                    style: GateDesign.theme().textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text('包含修改：${order.includedRevisions} 次'),
                  Text('预计交付：${order.estimatedDeliveryDays} 天'),
                  Text(
                    _taxTreatmentLabels[order.quoteTaxTreatment] ?? '税费口径待确认',
                  ),
                  Text('功能范围：${order.requestedFeatures.join('、')}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('交付后内容进入你的角色权益库，并通过受控流程发送到绑定设备。不提供原视频、无水印文件或工程文件下载。'),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: scopeConfirmed,
            onChanged: (value) =>
                setState(() => scopeConfirmed = value ?? false),
            title: const Text('我已确认价格、修改次数、交期和设备交付范围'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.lock_outline),
            label: Text(scopeConfirmed ? '支付服务尚未接入' : '请先确认交付范围'),
          ),
          const SizedBox(height: 8),
          const Center(child: Text('当前原型不会发起扣款')),
        ],
      ),
    );
  }
}

class _OrderStage extends StatelessWidget {
  const _OrderStage({
    required this.icon,
    required this.title,
    required this.description,
    required this.active,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool active;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          icon,
          color: active ? GateDesign.accent : GateDesign.muted,
        ),
        title: Text(title),
        subtitle: Text(description),
      );
}

class CreatorHubPage extends StatefulWidget {
  const CreatorHubPage({
    this.orderRepository,
    this.profileRepository,
    super.key,
  });

  final CustomizationOrderRepository? orderRepository;
  final CreatorProfileRepository? profileRepository;

  @override
  State<CreatorHubPage> createState() => _CreatorHubPageState();
}

class _CreatorHubPageState extends State<CreatorHubPage>
    with GateLoadState<CreatorHubPage> {
  late final CreatorProfileRepository repository =
      widget.profileRepository ?? const LocalCreatorProfileRepository();
  final nameController = TextEditingController();
  final portfolioController = TextEditingController();
  final payoutReferenceController = TextEditingController();
  CreatorProfile? profile;
  bool submitting = false;
  var adultConfirmed = false;
  var agreementConfirmed = false;
  String? creatorMarketRegion;
  String? taxFormType;
  final selectedSkills = <String>{};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() =>
      loadGateData(repository.loadProfile, (loaded) => profile = loaded);

  Future<void> _submit() async {
    if (submitting || gateLoading || !mounted) return;
    final name = nameController.text.trim();
    final portfolio = portfolioController.text.trim();
    if (name.isEmpty ||
        portfolio.isEmpty ||
        selectedSkills.isEmpty ||
        creatorMarketRegion == null ||
        !adultConfirmed ||
        !agreementConfirmed) {
      return;
    }
    setState(() => submitting = true);
    try {
      await repository.submitApplication(
        displayName: name,
        portfolioUrl: portfolio,
        agreementVersion: 'creator-marketplace-v1',
        skillTags: selectedSkills.toList(),
        marketRegion: creatorMarketRegion!,
      );
      final cloudSaved =
          await CloudBusinessIntake.instance.submitCreatorProfile(
        displayName: name,
        portfolioUrl: portfolio,
        agreementVersion: 'creator-marketplace-v1',
        skillTags: selectedSkills.toList(),
        marketRegion: creatorMarketRegion!,
      );
      if (!cloudSaved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('申请已保存在本机，云端同步失败，请稍后重新提交。'),
        ));
      }
      if (mounted) await _reload();
    } catch (_) {
      if (mounted) showGateActionError(context);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Future<void> _submitPayoutAccount() async {
    if (submitting || gateLoading || !mounted) return;
    final reference = payoutReferenceController.text.trim();
    if (reference.isEmpty || taxFormType == null) return;
    setState(() => submitting = true);
    try {
      await repository.submitPayoutAccount(
        payoutAccountReference: reference,
        taxFormType: taxFormType!,
      );
      if (mounted) await _reload();
    } catch (_) {
      if (mounted) showGateActionError(context);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    portfolioController.dispose();
    payoutReferenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (gateLoading || gateLoadFailed) {
      return GateScaffold(
          appBar: AppBar(title: const Text('创作者工作台')),
          body: GateLoadPanel(failed: gateLoadFailed, onRetry: _reload));
    }
    if (profile?.status == '已认证' && profile?.payoutAccountStatus == '已核验') {
      return CreatorTaskBoardPage(
        orderRepository: widget.orderRepository,
        creatorSkills: profile!.skillTags.toSet(),
        creatorMarketRegion: profile!.marketRegion,
        creatorSettlementCurrency: profile!.settlementCurrency ??
            creatorSettlementCurrencyForRegion(profile!.marketRegion),
      );
    }
    if (profile?.status == '已认证') {
      final settlementCurrency = profile!.settlementCurrency ??
          creatorSettlementCurrencyForRegion(profile!.marketRegion);
      final isPending = profile!.payoutAccountStatus == '审核中';
      return GateScaffold(
        appBar: AppBar(title: const Text('设置创作者收款账户'), actions: [
          GateRefreshButton(loading: submitting, onRefresh: _reload),
        ]),
        body: ListView(
          scrollCacheExtent: const ScrollCacheExtent.pixels(600),
          padding: const EdgeInsets.all(20),
          children: [
            Text('结算币种：$settlementCurrency',
                style: GateDesign.theme().textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(settlementCurrency == 'CNY'
                ? '中国大陆创作者使用人民币结算。'
                : '中国大陆以外的创作者统一使用美元结算。'),
            const SizedBox(height: 16),
            if (isPending) ...[
              const Icon(Icons.hourglass_top, size: 48),
              const SizedBox(height: 12),
              const Text('收款账户与税务资料审核中'),
              const Text('审核完成前不能进入任务大厅；平台不会在应用内保存银行卡号。'),
            ] else ...[
              DropdownButtonFormField<String>(
                isExpanded: true,
                key: const Key('creator-tax-form'),
                initialValue: taxFormType,
                decoration: const InputDecoration(labelText: '税务资料类型'),
                items: (profile!.marketRegion == 'cn_mainland'
                        ? const ['中国大陆税务资料']
                        : const ['W-9（美国人士）', 'W-8BEN / 当地等效资料'])
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: submitting
                    ? null
                    : (value) => setState(() => taxFormType = value),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('creator-payout-reference'),
                controller: payoutReferenceController,
                enabled: !submitting,
                decoration: const InputDecoration(
                  labelText: '支付服务商账户引用',
                  helperText: '请勿填写银行卡号；这里只保存支付服务商生成的账户令牌。',
                  helperMaxLines: 4,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: !submitting &&
                        taxFormType != null &&
                        payoutReferenceController.text.trim().isNotEmpty
                    ? _submitPayoutAccount
                    : null,
                child: Text(submitting
                    ? GateCopy.text(context, 'submitting')
                    : '提交收款账户审核'),
              ),
            ],
          ],
        ),
      );
    }
    return GateScaffold(
      appBar: AppBar(title: const Text('申请成为创作者'), actions: [
        GateRefreshButton(loading: submitting, onRefresh: _reload),
      ]),
      body: ListView(
        scrollCacheExtent: const ScrollCacheExtent.pixels(600),
        padding: const EdgeInsets.all(20),
        children: [
          if (profile?.status == '审核中') ...[
            const Icon(Icons.hourglass_top, size: 52),
            const SizedBox(height: 16),
            Text('创作者申请审核中', style: GateDesign.theme().textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('审核通过前不能查看用户任务、素材或接单。'),
          ] else ...[
            const GateSection(
                eyebrow: 'JOIN THE CREATOR PROGRAM',
                title: '先完成创作者认证',
                description: '',
                icon: Icons.draw_outlined),
            const SizedBox(height: 8),
            const Text('平台将检查作品集、身份与收款资格。通过后才能访问脱敏任务。'),
            const SizedBox(height: 20),
            Text('擅长方向', style: GateDesign.theme().textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['待机动作', '唱跳表演', '音乐联动', '角色记忆']
                  .map(
                    (skill) => FilterChip(
                      label: Text(skill),
                      selected: selectedSkills.contains(skill),
                      onSelected: submitting
                          ? null
                          : (selected) => setState(() {
                                if (selected) {
                                  selectedSkills.add(skill);
                                } else {
                                  selectedSkills.remove(skill);
                                }
                              }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              key: const Key('creator-market-region'),
              initialValue: creatorMarketRegion,
              decoration: const InputDecoration(labelText: '创作者所在地'),
              items: _marketRegionLabels.entries
                  .where((entry) => entry.key != 'unspecified')
                  .map((entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ))
                  .toList(),
              onChanged: submitting
                  ? null
                  : (value) => setState(() => creatorMarketRegion = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              enabled: !submitting,
              decoration: const InputDecoration(labelText: '创作者显示名称'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: portfolioController,
              enabled: !submitting,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: '作品集链接'),
              onChanged: (_) => setState(() {}),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: adultConfirmed,
              onChanged: submitting
                  ? null
                  : (value) => setState(() => adultConfirmed = value ?? false),
              title: const Text('我已年满 18 岁'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: agreementConfirmed,
              onChanged: submitting
                  ? null
                  : (value) =>
                      setState(() => agreementConfirmed = value ?? false),
              title: const Text('我同意创作者规则、保密要求和禁止私下交易条款'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: !submitting &&
                      nameController.text.trim().isNotEmpty &&
                      portfolioController.text.trim().isNotEmpty &&
                      selectedSkills.isNotEmpty &&
                      creatorMarketRegion != null &&
                      adultConfirmed &&
                      agreementConfirmed
                  ? _submit
                  : null,
              child: Text(submitting
                  ? GateCopy.text(context, 'submitting')
                  : '提交创作者申请'),
            ),
          ],
        ],
      ),
    );
  }
}

class CreatorTaskBoardPage extends StatefulWidget {
  const CreatorTaskBoardPage({
    this.orderRepository,
    this.previewPicker,
    this.creatorSkills,
    this.creatorMarketRegion = 'other',
    this.creatorSettlementCurrency = 'USD',
    super.key,
  });

  final CustomizationOrderRepository? orderRepository;
  final PreviewPicker? previewPicker;
  final Set<String>? creatorSkills;
  final String creatorMarketRegion;
  final String creatorSettlementCurrency;

  @override
  State<CreatorTaskBoardPage> createState() => _CreatorTaskBoardPageState();
}

class PlatformOperationsPage extends StatefulWidget {
  const PlatformOperationsPage({
    required this.repository,
    this.now,
    super.key,
  });

  final CustomizationOrderRepository repository;
  final DateTime Function()? now;

  @override
  State<PlatformOperationsPage> createState() => _PlatformOperationsPageState();
}

class _PlatformOperationsPageState extends State<PlatformOperationsPage>
    with
        GateLoadState<PlatformOperationsPage>,
        GateActionState<PlatformOperationsPage>,
        WidgetsBindingObserver {
  static const operatorId = 'platform-operator-local';
  static const dataStaleAfter = Duration(minutes: 5);
  List<CustomizationOrder> orders = const [];
  String queueFilter = '全部';
  final queueSearchController = TextEditingController();
  Timer? leaseClock;
  DateTime? lastSyncedAt;
  DateTime get _now => (widget.now?.call() ?? DateTime.now()).toUtc();

  void _startLeaseClock() {
    leaseClock?.cancel();
    leaseClock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && orders.isNotEmpty) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startLeaseClock();
      if (!gateLoading && !gateActionBusy) {
        unawaited(_reload());
      } else if (mounted && orders.isNotEmpty) {
        setState(() {});
      }
    } else {
      leaseClock?.cancel();
      leaseClock = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    leaseClock?.cancel();
    queueSearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startLeaseClock();
    _reload();
  }

  Future<void> _reload() =>
      loadGateData(widget.repository.loadOrders, (loaded) {
        orders = loaded;
        lastSyncedAt = _now;
      });

  String get _lastSyncLabel {
    final value = lastSyncedAt;
    if (value == null) return '尚未同步';
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '最后同步：${twoDigits(value.hour)}:${twoDigits(value.minute)}:${twoDigits(value.second)} UTC';
  }

  bool get _isDataStale =>
      lastSyncedAt != null && _now.difference(lastSyncedAt!) > dataStaleAfter;

  Future<void> _open(CustomizationOrder order, Widget page) async {
    if (!mounted || gateActionBusy || gateLoading) return;
    if (order.operationsAssigneeId != null &&
        order.operationsAssigneeId != operatorId &&
        !_isOperationsClaimExpired(order)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('工单正由 ${order.operationsAssigneeId} 处理'),
        ),
      );
      return;
    }
    final needsClaim = order.operationsAssigneeId != operatorId ||
        _isOperationsClaimExpired(order);
    var ready = false;
    await runGateAction(() async {
      if (needsClaim) {
        await widget.repository.claimOperationsOrder(
          orderId: order.id,
          operatorId: operatorId,
        );
      } else {
        await widget.repository.renewOperationsOrderClaim(
          orderId: order.id,
          operatorId: operatorId,
        );
      }
      await _reload();
      final updated = orders.where((item) => item.id == order.id).firstOrNull;
      ready = updated?.operationsAssigneeId == operatorId &&
          updated != null &&
          !_isOperationsClaimExpired(updated);
    });
    if (!mounted || !ready) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('工单状态已变化，请刷新后重试')),
        );
      }
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
    await _reload();
    final updated = orders.where((item) => item.id == order.id).firstOrNull;
    if (updated?.operationsAssigneeId == operatorId &&
        updated != null &&
        !_isOperationsActionable(updated)) {
      await widget.repository.releaseOperationsOrder(
        orderId: updated.id,
        operatorId: operatorId,
      );
      await _reload();
    }
  }

  Future<void> _cleanDueMaterials() => runGateAction(() async {
        if (gateLoading || gateLoadFailed) return;
        final count = await widget.repository.processDueMaterialDeletions();
        await _reload();
        if (!mounted || gateLoadFailed) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(count == 0 ? '当前没有到期素材' : '已清理 $count 个订单的到期素材')),
        );
      });

  Future<void> _releaseExpiredAssignments() => runGateAction(() async {
        if (gateLoading || gateLoadFailed) return;
        final count =
            await widget.repository.processExpiredCreatorAssignments();
        await _reload();
        if (!mounted || gateLoadFailed) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(count == 0 ? '当前没有超时派单' : '已释放 $count 个超时派单')),
        );
      });

  Future<void> _toggleOperationsOwner(CustomizationOrder order) =>
      runGateAction(() async {
        String? resultMessage;
        var releasing = false;
        if (order.operationsAssigneeId == null ||
            _isOperationsClaimExpired(order)) {
          resultMessage =
              order.operationsAssigneeId == null ? '已领取工单' : '已接管过期工单';
          await widget.repository.claimOperationsOrder(
            orderId: order.id,
            operatorId: operatorId,
          );
        } else if (order.operationsAssigneeId == operatorId) {
          releasing = true;
          resultMessage = '已释放工单';
          await widget.repository.releaseOperationsOrder(
            orderId: order.id,
            operatorId: operatorId,
          );
        }
        await _reload();
        if (!mounted || gateLoadFailed || resultMessage == null) return;
        final updated = orders.where((item) => item.id == order.id).firstOrNull;
        final succeeded = updated != null &&
            (releasing
                ? updated.operationsAssigneeId == null
                : updated.operationsAssigneeId == operatorId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              succeeded ? resultMessage : '工单状态已变化，请刷新后重试',
            ),
          ),
        );
      });

  Future<void> _renewOperationsOwner(CustomizationOrder order) =>
      runGateAction(() async {
        final previousExpiry =
            DateTime.tryParse(order.operationsAssignmentExpiresAt ?? '');
        await widget.repository.renewOperationsOrderClaim(
          orderId: order.id,
          operatorId: operatorId,
        );
        await _reload();
        if (!mounted || gateLoadFailed) return;
        final updated = orders.where((item) => item.id == order.id).firstOrNull;
        final updatedExpiry =
            DateTime.tryParse(updated?.operationsAssignmentExpiresAt ?? '');
        final succeeded = updated?.operationsAssigneeId == operatorId &&
            previousExpiry != null &&
            updatedExpiry != null &&
            updatedExpiry.isAfter(previousExpiry);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              succeeded ? '工单已续期4小时' : '工单状态已变化，请刷新后重试',
            ),
          ),
        );
      });

  Future<void> _renewExpiringOperationsClaims() => runGateAction(() async {
        final expiring = orders.where(_isOperationsClaimExpiringSoon).toList();
        final previousExpiries = {
          for (final order in expiring)
            order.id:
                DateTime.tryParse(order.operationsAssignmentExpiresAt ?? ''),
        };
        for (final order in expiring) {
          await widget.repository.renewOperationsOrderClaim(
            orderId: order.id,
            operatorId: operatorId,
          );
        }
        await _reload();
        if (!mounted || gateLoadFailed) return;
        final renewedCount = orders.where((order) {
          final previousExpiry = previousExpiries[order.id];
          final updatedExpiry =
              DateTime.tryParse(order.operationsAssignmentExpiresAt ?? '');
          return order.operationsAssigneeId == operatorId &&
              previousExpiry != null &&
              updatedExpiry != null &&
              updatedExpiry.isAfter(previousExpiry);
        }).length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              renewedCount == 0
                  ? '工单状态已变化，请刷新后重试'
                  : '已续期 $renewedCount 个即将到期工单',
            ),
          ),
        );
      });

  bool _isOperationsClaimExpired(CustomizationOrder order) {
    final expiresAt =
        DateTime.tryParse(order.operationsAssignmentExpiresAt ?? '');
    return order.operationsAssigneeId != null &&
        (expiresAt == null || !_now.isBefore(expiresAt.toUtc()));
  }

  String _operationsOwnerLabel(CustomizationOrder order) {
    if (order.operationsAssigneeId == null) return '负责人：未领取';
    if (_isOperationsClaimExpired(order)) {
      return '负责人：${order.operationsAssigneeId} · 领取已过期，可接管';
    }
    final expiresAt = DateTime.parse(order.operationsAssignmentExpiresAt!);
    final remaining = expiresAt.toUtc().difference(_now);
    final roundedMinutes = (remaining.inSeconds / 60).ceil().clamp(1, 240);
    final durationLabel = roundedMinutes >= 60
        ? '${roundedMinutes ~/ 60}小时${roundedMinutes % 60 == 0 ? '' : '${roundedMinutes % 60}分钟'}'
        : '$roundedMinutes分钟';
    return '负责人：${order.operationsAssigneeId} · 租约剩余约$durationLabel';
  }

  bool _isOperationsClaimExpiringSoon(CustomizationOrder order) {
    if (order.operationsAssigneeId != operatorId) return false;
    final expiresAt =
        DateTime.tryParse(order.operationsAssignmentExpiresAt ?? '');
    if (expiresAt == null) return false;
    final remaining = expiresAt.toUtc().difference(_now);
    return !remaining.isNegative && remaining <= const Duration(minutes: 30);
  }

  String _operationsAuditLabel(String event) {
    final parts = event.split('|');
    if (parts.length != 3) return '最近操作：$event';
    final action = switch (parts[1]) {
      'claimed' => '领取',
      'reclaimed' => '重新领取',
      'taken_over' => '接管',
      'renewed' => '续期',
      'released' => '释放',
      _ => parts[1],
    };
    final operatorId = Uri.decodeComponent(parts[2]);
    return '最近操作：$action · $operatorId · ${parts[0]}';
  }

  Future<void> _showOperationsAudit(CustomizationOrder order) => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${order.characterName} · 运营记录'),
          content: SizedBox(
            width: 520,
            child: order.operationsAuditTrail.isEmpty
                ? const Text('暂无运营操作记录')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: order.operationsAuditTrail.length,
                    separatorBuilder: (_, __) => const Divider(height: 20),
                    itemBuilder: (_, index) {
                      final reverseIndex =
                          order.operationsAuditTrail.length - 1 - index;
                      return Text(
                        _operationsAuditLabel(
                          order.operationsAuditTrail[reverseIndex],
                        ).replaceFirst('最近操作：', ''),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      );

  String _queueLabel(CustomizationOrder order) {
    if (order.creatorCommunicationRiskStatus == 'performance_review') {
      return '创作者履约风险审查中';
    }
    if (order.creatorCommunicationRiskStatus == 'pending_review') {
      return '创作者沟通风险待评估';
    }
    if (_isExtensionEscalationOverdue(order)) return '延期人工处理已逾期';
    if (_isCreatorExtensionAcknowledgementOverdue(order)) {
      return '创作者延期通知确认已逾期';
    }
    if (order.deliveryExtensionStatus == 'escalated') return '延期等待人工处理';
    if (_isExtensionResponseOverdue(order)) return '延期响应已逾期';
    if (order.deliveryExtensionStatus == 'pending') return '等待用户确认延期';
    if (_isProductionOverdue(order)) return '制作交付已逾期';
    if (_isPrivacyOverdue(order)) return '数据更正已逾期';
    if (order.privacyCorrectionStatus == 'pending') return '待处理数据更正';
    if (order.status == '免费预审中') return '待平台预审';
    if (order.status == '待平台质检') return '待内容与设备质检';
    if (order.status == '待创作者申请') return '待派单';
    if (order.status == '平台审核报价') return '待审核报价';
    if (order.status == '争议处理中') return '争议处理';
    if (order.settlementStatus == '结算失败') return '创作者结算失败';
    if (order.settlementStatus == '待结算') return '待创作者结算';
    return order.status;
  }

  bool _isPrivacyOverdue(CustomizationOrder order) {
    if (order.privacyCorrectionStatus != 'pending') return false;
    final dueAt = DateTime.tryParse(order.privacyCorrectionDueAt ?? '');
    return dueAt != null && dueAt.toUtc().isBefore(_now);
  }

  bool _isExtensionResponseOverdue(CustomizationOrder order) {
    if (order.deliveryExtensionStatus != 'pending') return false;
    final dueAt = DateTime.tryParse(order.deliveryExtensionResponseDueAt ?? '');
    return dueAt != null && dueAt.toUtc().isBefore(_now);
  }

  bool _isExtensionEscalationOverdue(CustomizationOrder order) {
    if (order.deliveryExtensionStatus != 'escalated') return false;
    final dueAt =
        DateTime.tryParse(order.deliveryExtensionEscalationDueAt ?? '');
    return dueAt != null && dueAt.toUtc().isBefore(_now);
  }

  bool _isCreatorExtensionUnacknowledged(CustomizationOrder order) =>
      order.deliveryExtensionVersion >
      order.creatorExtensionAcknowledgedVersion;

  bool _isCreatorExtensionAcknowledgementOverdue(CustomizationOrder order) {
    if (!_isCreatorExtensionUnacknowledged(order)) return false;
    final dueAt =
        DateTime.tryParse(order.creatorExtensionAcknowledgementDueAt ?? '');
    return dueAt != null && dueAt.toUtc().isBefore(_now);
  }

  bool _isProductionOverdue(CustomizationOrder order) {
    if (!{'制作中', '修改中', '待平台质检', '待用户验收'}.contains(order.status)) return false;
    final dueAt = DateTime.tryParse(order.productionDueAt ?? '');
    return dueAt != null && dueAt.toUtc().isBefore(_now);
  }

  int _queuePriority(CustomizationOrder order) {
    if (_isPrivacyOverdue(order) ||
        _isExtensionEscalationOverdue(order) ||
        order.creatorCommunicationRiskStatus == 'performance_review') {
      return 0;
    }
    if (order.creatorCommunicationRiskStatus == 'pending_review' ||
        _isCreatorExtensionAcknowledgementOverdue(order) ||
        _isExtensionResponseOverdue(order) ||
        _isProductionOverdue(order)) {
      return 1;
    }
    if (order.status == '争议处理中' || order.settlementStatus == '结算失败') {
      return 2;
    }
    return 3;
  }

  DateTime _queueDueAt(CustomizationOrder order) {
    final dates = [
      order.deliveryExtensionEscalationDueAt,
      order.creatorExtensionAcknowledgementDueAt,
      order.deliveryExtensionResponseDueAt,
      order.productionDueAt,
      order.privacyCorrectionDueAt,
    ]
        .map((value) => DateTime.tryParse(value ?? '')?.toUtc())
        .whereType<DateTime>()
        .toList()
      ..sort();
    return dates.isEmpty ? DateTime.utc(9999) : dates.first;
  }

  bool _isOperationsActionable(CustomizationOrder order) =>
      order.status == '免费预审中' ||
      order.status == '待平台质检' ||
      order.status == '待创作者申请' ||
      order.status == '平台审核报价' ||
      order.status == '争议处理中' ||
      order.deliveryExtensionStatus == 'escalated' ||
      _isCreatorExtensionUnacknowledged(order) ||
      order.creatorCommunicationRiskStatus == 'pending_review' ||
      order.creatorCommunicationRiskStatus == 'performance_review' ||
      _isProductionOverdue(order) ||
      {'待结算', '结算失败'}.contains(order.settlementStatus) ||
      order.privacyCorrectionStatus == 'pending';

  @override
  Widget build(BuildContext context) {
    final actionable = orders.where(_isOperationsActionable).toList()
      ..sort((a, b) {
        final priority = _queuePriority(a).compareTo(_queuePriority(b));
        return priority != 0
            ? priority
            : _queueDueAt(a).compareTo(_queueDueAt(b));
      });
    final searchTerm = queueSearchController.text.trim().toLowerCase();
    final expiringClaimCount =
        actionable.where(_isOperationsClaimExpiringSoon).length;
    final takeoverCount = actionable
        .where((order) =>
            order.operationsAssigneeId != null &&
            _isOperationsClaimExpired(order))
        .length;
    final visible = actionable
        .where((order) => switch (queueFilter) {
              '高优先级' => _queuePriority(order) <= 1,
              '我的工单' => order.operationsAssigneeId == operatorId &&
                  !_isOperationsClaimExpired(order),
              '即将到期' => _isOperationsClaimExpiringSoon(order),
              '可接管' => order.operationsAssigneeId != null &&
                  _isOperationsClaimExpired(order),
              '未领取' => order.operationsAssigneeId == null ||
                  _isOperationsClaimExpired(order),
              '预审' => order.status == '免费预审中',
              '质检' => order.status == '待平台质检',
              '报价' => order.status == '平台审核报价',
              '争议' => order.status == '争议处理中',
              '结算' => {'待结算', '结算失败'}.contains(order.settlementStatus),
              '延期处理' => {'pending', 'escalated'}
                  .contains(order.deliveryExtensionStatus),
              '隐私请求' => order.privacyCorrectionStatus == 'pending',
              _ => true,
            })
        .where((order) =>
            searchTerm.isEmpty ||
            order.id.toLowerCase().contains(searchTerm) ||
            order.characterName.toLowerCase().contains(searchTerm) ||
            _queueLabel(order).toLowerCase().contains(searchTerm))
        .toList();
    return GateScaffold(
      wide: true,
      appBar: AppBar(title: const Text('平台运营队列'), actions: [
        if (expiringClaimCount > 0)
          IconButton(
            tooltip: '续期全部即将到期工单',
            onPressed: gateActionBusy ? null : _renewExpiringOperationsClaims,
            icon: const Icon(Icons.more_time_outlined),
          ),
        GateRefreshButton(
            loading: gateLoading || gateActionBusy, onRefresh: _reload),
        PopupMenuButton<String>(
          tooltip: '筛选运营队列',
          initialValue: queueFilter,
          icon: Icon(
              queueFilter == '全部' ? Icons.filter_list : Icons.filter_list_alt),
          onSelected: (value) => setState(() => queueFilter = value),
          itemBuilder: (_) => [
            '全部',
            '高优先级',
            '我的工单',
            '即将到期',
            '可接管',
            '未领取',
            '预审',
            '质检',
            '报价',
            '延期处理',
            '争议',
            '结算',
            '隐私请求'
          ]
              .map((value) => CheckedPopupMenuItem(
                  value: value,
                  checked: queueFilter == value,
                  child: Text(value)))
              .toList(),
        ),
      ]),
      body: gateLoading || gateLoadFailed
          ? GateLoadPanel(failed: gateLoadFailed, onRetry: _reload)
          : ListView(
              scrollCacheExtent: const ScrollCacheExtent.pixels(600),
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _lastSyncLabel,
                      key: const Key('platform-last-synced-at'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (_isDataStale)
                      ActionChip(
                        avatar:
                            const Icon(Icons.sync_problem_outlined, size: 18),
                        label: const Text('数据超过5分钟未同步，立即刷新'),
                        onPressed:
                            gateActionBusy || gateLoading ? null : _reload,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('待处理 ${actionable.length}')),
                    Chip(
                      avatar: const Icon(Icons.priority_high, size: 18),
                      label: Text(
                        '高优先级 ${actionable.where((order) => _queuePriority(order) <= 1).length}',
                      ),
                    ),
                    FilterChip(
                      avatar:
                          const Icon(Icons.assignment_ind_outlined, size: 18),
                      label: Text(
                        '我的工单 ${actionable.where((order) => order.operationsAssigneeId == operatorId && !_isOperationsClaimExpired(order)).length}',
                      ),
                      selected: queueFilter == '我的工单',
                      onSelected: (_) => setState(() => queueFilter = '我的工单'),
                    ),
                    FilterChip(
                      avatar: const Icon(Icons.timer_outlined, size: 18),
                      label: Text('即将到期 $expiringClaimCount'),
                      selected: queueFilter == '即将到期',
                      onSelected: (_) => setState(() => queueFilter = '即将到期'),
                    ),
                    FilterChip(
                      avatar: const Icon(Icons.swap_horiz_outlined, size: 18),
                      label: Text('可接管 $takeoverCount'),
                      selected: queueFilter == '可接管',
                      onSelected: (_) => setState(() => queueFilter = '可接管'),
                    ),
                    Chip(
                      avatar: const Icon(Icons.mark_email_unread_outlined,
                          size: 18),
                      label: Text(
                        '待确认延期 ${orders.where((order) => order.deliveryExtensionStatus == 'pending').length}',
                      ),
                    ),
                    Chip(
                      avatar: const Icon(Icons.notification_important_outlined,
                          size: 18),
                      label: Text(
                        '延期响应逾期 ${orders.where(_isExtensionResponseOverdue).length}',
                      ),
                    ),
                    Chip(
                      avatar:
                          const Icon(Icons.support_agent_outlined, size: 18),
                      label: Text(
                        '延期人工处理 ${orders.where((order) => order.deliveryExtensionStatus == 'escalated').length}',
                      ),
                    ),
                    Chip(
                      avatar: const Icon(Icons.timer_off_outlined, size: 18),
                      label: Text(
                        '人工处理逾期 ${orders.where(_isExtensionEscalationOverdue).length}',
                      ),
                    ),
                    Chip(
                      avatar: const Icon(Icons.mark_email_unread_outlined,
                          size: 18),
                      label: Text(
                        '创作者未确认 ${orders.where(_isCreatorExtensionUnacknowledged).length}',
                      ),
                    ),
                    Chip(
                      avatar:
                          const Icon(Icons.warning_amber_outlined, size: 18),
                      label: Text(
                        '创作者确认逾期 ${orders.where(_isCreatorExtensionAcknowledgementOverdue).length}',
                      ),
                    ),
                    Chip(
                      avatar: const Icon(Icons.person_off_outlined, size: 18),
                      label: Text(
                        '创作者沟通风险 ${orders.where((order) => order.creatorCommunicationRiskStatus == 'pending_review').length}',
                      ),
                    ),
                    Chip(
                      avatar: const Icon(Icons.schedule_outlined, size: 18),
                      label: Text(
                        '交付逾期 ${orders.where(_isProductionOverdue).length}',
                      ),
                    ),
                    Chip(
                      label: Text(
                        '争议 ${orders.where((order) => order.status == '争议处理中').length}',
                      ),
                    ),
                    Chip(
                      label: Text(
                        '待结算 ${orders.where((order) => order.settlementStatus == '待结算').length}',
                      ),
                    ),
                    Chip(
                      avatar: const Icon(Icons.error_outline, size: 18),
                      label: Text(
                        '结算失败 ${orders.where((order) => order.settlementStatus == '结算失败').length}',
                      ),
                    ),
                    Chip(
                      avatar:
                          const Icon(Icons.warning_amber_outlined, size: 18),
                      label: Text(
                          '隐私逾期 ${orders.where(_isPrivacyOverdue).length}'),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.timer_off_outlined, size: 18),
                      label: const Text('释放超时派单'),
                      onPressed:
                          gateActionBusy ? null : _releaseExpiredAssignments,
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.auto_delete_outlined, size: 18),
                      label: const Text('执行到期素材清理'),
                      onPressed: gateActionBusy ? null : _cleanDueMaterials,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('platform-queue-search'),
                  controller: queueSearchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    labelText: '搜索角色名、订单号或队列状态',
                    suffixIcon: queueSearchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: '清除搜索',
                            onPressed: () {
                              queueSearchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                if (queueFilter != '全部')
                  Align(
                      alignment: Alignment.centerLeft,
                      child: InputChip(
                          label: Text('当前筛选：$queueFilter'),
                          onDeleted: () => setState(() => queueFilter = '全部'))),
                if (visible.isEmpty)
                  const Center(child: Text('当前没有待处理订单'))
                else
                  ...visible.map(
                    (order) => Card(
                      key: Key('platform-order-${order.id}'),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('P${_queuePriority(order) + 1}'),
                        ),
                        title: Text(order.characterName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.resubmissionOfOrderId == null
                                ? _queueLabel(order)
                                : '${_queueLabel(order)} · 整改重审'),
                            Text(_operationsOwnerLabel(order)),
                            if (order.operationsAuditTrail.isNotEmpty)
                              Semantics(
                                button: true,
                                label: '查看运营操作记录',
                                child: InkWell(
                                  key: Key('operations-audit-${order.id}'),
                                  onTap: () => _showOperationsAudit(order),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      _operationsAuditLabel(
                                        order.operationsAuditTrail.last,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: order.operationsAssigneeId == operatorId &&
                                !_isOperationsClaimExpired(order)
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    key: Key(
                                        'renew-operations-order-${order.id}'),
                                    tooltip: '续期4小时',
                                    onPressed: gateActionBusy
                                        ? null
                                        : () => _renewOperationsOwner(order),
                                    icon: const Icon(Icons.update_outlined),
                                  ),
                                  IconButton(
                                    tooltip: '释放工单',
                                    onPressed: gateActionBusy
                                        ? null
                                        : () => _toggleOperationsOwner(order),
                                    icon: const Icon(
                                        Icons.person_remove_outlined),
                                  ),
                                ],
                              )
                            : IconButton(
                                tooltip: order.operationsAssigneeId == null
                                    ? '领取工单'
                                    : _isOperationsClaimExpired(order)
                                        ? '接管过期工单'
                                        : order.operationsAssigneeId ==
                                                operatorId
                                            ? '释放工单'
                                            : '已由其他人员领取',
                                onPressed: gateActionBusy ||
                                        (order.operationsAssigneeId != null &&
                                            order.operationsAssigneeId !=
                                                operatorId &&
                                            !_isOperationsClaimExpired(order))
                                    ? null
                                    : () => _toggleOperationsOwner(order),
                                icon: Icon(order.operationsAssigneeId == null
                                    ? Icons.person_add_alt_outlined
                                    : _isOperationsClaimExpired(order)
                                        ? Icons.swap_horiz_outlined
                                        : order.operationsAssigneeId ==
                                                operatorId
                                            ? Icons.person_remove_outlined
                                            : Icons.lock_outline),
                              ),
                        onTap: order.privacyCorrectionStatus == 'pending'
                            ? () => _open(
                                  order,
                                  PlatformPrivacyCorrectionPage(
                                    order: order,
                                    repository: widget.repository,
                                  ),
                                )
                            : order.status == '免费预审中'
                                ? () => _open(
                                      order,
                                      PlatformPreReviewPage(
                                        order: order,
                                        repository: widget.repository,
                                      ),
                                    )
                                : order.status == '待平台质检'
                                    ? () => _open(
                                          order,
                                          PlatformQualityReviewPage(
                                            order: order,
                                            repository: widget.repository,
                                          ),
                                        )
                                    : order.status == '待创作者申请'
                                        ? () => _open(
                                              order,
                                              PlatformAssignmentReviewPage(
                                                order: order,
                                                repository: widget.repository,
                                              ),
                                            )
                                        : order.status == '平台审核报价'
                                            ? () => _open(
                                                  order,
                                                  PlatformQuoteReviewPage(
                                                    order: order,
                                                    repository:
                                                        widget.repository,
                                                  ),
                                                )
                                            : order.status == '争议处理中'
                                                ? () => _open(
                                                      order,
                                                      PlatformDisputeReviewPage(
                                                        order: order,
                                                        repository:
                                                            widget.repository,
                                                      ),
                                                    )
                                                : _isProductionOverdue(order) ||
                                                        order.deliveryExtensionStatus ==
                                                            'escalated' ||
                                                        _isCreatorExtensionUnacknowledged(
                                                            order) ||
                                                        order.creatorCommunicationRiskStatus ==
                                                            'pending_review'
                                                    ? () => _open(
                                                          order,
                                                          PlatformProductionSlaPage(
                                                            order: order,
                                                            repository: widget
                                                                .repository,
                                                          ),
                                                        )
                                                    : {
                                                        '待结算',
                                                        '结算失败'
                                                      }.contains(order
                                                            .settlementStatus)
                                                        ? () => _open(
                                                              order,
                                                              PlatformPayoutReviewPage(
                                                                order: order,
                                                                repository: widget
                                                                    .repository,
                                                              ),
                                                            )
                                                        : null,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

const _reviewReasonLabels = {
  'rights_unverified': '权利或授权无法验证',
  'materials_incomplete': '素材数量或质量不足',
  'prohibited_content': '涉及禁止内容',
  'device_incompatible': '无法适配设备播放',
  'scope_unsupported': '需求超出当前服务范围',
  'other': '其他原因',
};

class PlatformPrivacyCorrectionPage extends StatefulWidget {
  const PlatformPrivacyCorrectionPage({
    required this.order,
    required this.repository,
    super.key,
  });

  final CustomizationOrder order;
  final CustomizationOrderRepository repository;

  @override
  State<PlatformPrivacyCorrectionPage> createState() =>
      _PlatformPrivacyCorrectionPageState();
}

class _PlatformPrivacyCorrectionPageState
    extends State<PlatformPrivacyCorrectionPage>
    with GateActionState<PlatformPrivacyCorrectionPage> {
  final resolutionDrafts = <bool, String>{};
  CustomizationOrder get order => widget.order;
  CustomizationOrderRepository get repository => widget.repository;

  Future<void> _resolve(BuildContext context, bool approved) =>
      runGateAction(() async {
        var note = resolutionDrafts[approved] ?? '';
        final confirmed = await showGateDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            scrollable: true,
            title: Text(approved ? '填写受理结果' : '填写拒绝原因'),
            content: TextFormField(
              key: const Key('privacy-correction-resolution'),
              initialValue: note,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: approved
                    ? '说明已核验或更正的内容，以及用户何时可以看到结果。'
                    : '说明无法更正的原因和可采取的下一步。',
              ),
              onChanged: (value) => resolutionDrafts[approved] = note = value,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('提交处理结果'),
              ),
            ],
          ),
        );
        if (!mounted || confirmed != true || note.trim().isEmpty) return;
        await repository.resolvePrivacyCorrection(
          orderId: order.id,
          approved: approved,
          resolutionNote: note,
        );
        if (context.mounted) Navigator.of(context).pop();
      });

  @override
  Widget build(BuildContext context) => GateScaffold(
        appBar: AppBar(title: const Text('数据更正申请')),
        body: ListView(
          scrollCacheExtent: const ScrollCacheExtent.pixels(600),
          padding: const EdgeInsets.all(20),
          children: [
            if (gateActionBusy) Text(GateCopy.text(context, 'actionPending')),
            Text(order.characterName,
                style: GateDesign.theme().textTheme.headlineSmall),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(order.privacyCorrectionNote ?? '未填写更正说明'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '内部答复截止：${order.privacyCorrectionDueAt?.split('T').first ?? '-'}',
            ),
            const SizedBox(height: 8),
            const Text('处理时应核对原始材料；不要直接覆盖审核、付款或交付历史。'),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: gateActionBusy ? null : () => _resolve(context, true),
              child: const Text('确认已核验并受理'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: gateActionBusy ? null : () => _resolve(context, false),
              child: const Text('拒绝更正申请'),
            ),
          ],
        ),
      );
}

const _requiredReviewChecks = {
  'rights_verified': '角色来源与商业使用权已核验',
  'materials_safe': '上传素材完整且符合隐私要求',
  'content_allowed': '不包含禁止或高风险内容',
  'device_compatible': '需求可在目标设备上稳定交付',
};

class PlatformPreReviewPage extends StatefulWidget {
  const PlatformPreReviewPage({
    required this.order,
    required this.repository,
    super.key,
  });

  final CustomizationOrder order;
  final CustomizationOrderRepository repository;

  @override
  State<PlatformPreReviewPage> createState() => _PlatformPreReviewPageState();
}

class _PlatformPreReviewPageState extends State<PlatformPreReviewPage>
    with GateActionState<PlatformPreReviewPage> {
  final selected = <String>{};
  String reason = '';
  String reasonCode = 'materials_incomplete';
  CustomizationOrder get order => widget.order;
  CustomizationOrderRepository get repository => widget.repository;

  Future<void> _approve(BuildContext context) => runGateAction(() async {
        final confirmed = await showGateDialog<bool>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              scrollable: true,
              title: const Text('确认预审检查'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _requiredReviewChecks.entries
                      .map(
                        (entry) => CheckboxListTile(
                          key: Key('review-check-${entry.key}'),
                          contentPadding: EdgeInsets.zero,
                          value: selected.contains(entry.key),
                          title: Text(entry.value),
                          onChanged: (checked) => setDialogState(() {
                            if (checked ?? false) {
                              selected.add(entry.key);
                            } else {
                              selected.remove(entry.key);
                            }
                          }),
                        ),
                      )
                      .toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: selected.length == _requiredReviewChecks.length
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  child: const Text('确认通过'),
                ),
              ],
            ),
          ),
        );
        if (!mounted || confirmed != true) return;
        await repository.approveForCreatorMatching(
          order.id,
          reviewChecks: selected.toList(),
        );
        if (context.mounted) Navigator.of(context).pop();
      });

  Future<void> _reject(BuildContext context) => runGateAction(() async {
        final confirmed = await showGateDialog<bool>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              scrollable: true,
              title: const Text('填写预审未通过原因'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    key: const Key('review-rejection-category'),
                    initialValue: reasonCode,
                    decoration: const InputDecoration(labelText: '标准原因类别'),
                    items: _reviewReasonLabels.entries
                        .map((entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => reasonCode = value ?? 'other'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('review-rejection-reason'),
                    initialValue: reason,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: '给用户的具体说明',
                      hintText: '说明缺少什么，以及如何补充',
                    ),
                    onChanged: (value) => reason = value,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('确认拒绝'),
                ),
              ],
            ),
          ),
        );
        if (!mounted || confirmed != true || reason.trim().isEmpty) return;
        await repository.rejectReview(
          orderId: order.id,
          reason: reason,
          reasonCode: reasonCode,
        );
        if (context.mounted) Navigator.of(context).pop();
      });

  @override
  Widget build(BuildContext context) => GateScaffold(
        appBar: AppBar(title: const Text('平台免费预审')),
        body: ListView(
          scrollCacheExtent: const ScrollCacheExtent.pixels(600),
          padding: const EdgeInsets.all(20),
          children: [
            if (gateActionBusy) Text(GateCopy.text(context, 'actionPending')),
            Text(order.characterName,
                style: GateDesign.theme().textTheme.headlineSmall),
            const SizedBox(height: 6),
            const Text('当前审核规则：customization-review-v1'),
            if (order.resubmissionOfOrderId != null) ...[
              const SizedBox(height: 10),
              Card(
                color: GateDesign.theme().colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    '整改重审 · 原申请 ${order.resubmissionOfOrderId}\n'
                    '上次未通过原因：${order.resubmissionReason ?? '未记录'}\n'
                    '请重点核验新素材是否已经补齐。',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.public_outlined),
              title: const Text('用户地区'),
              subtitle: Text(
                _marketRegionLabels[order.marketRegion] ?? order.marketRegion,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.copyright_outlined),
              title: const Text('权利声明'),
              subtitle: Text(order.privacyConsentVersion == null
                  ? '缺少授权记录'
                  : '已记录权利与隐私确认'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('素材完整度'),
              subtitle: Text('${order.materialCount} 个参考文件'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.animation_outlined),
              title: const Text('功能需求'),
              subtitle: Text(order.requestedFeatures.join('、')),
            ),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('通过前应人工核对角色来源、素材权利、禁止内容和设备适配风险。'),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: gateActionBusy ? null : () => _approve(context),
              child: const Text('通过预审并开放匹配'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: gateActionBusy ? null : () => _reject(context),
              child: const Text('预审不通过'),
            ),
          ],
        ),
      );
}

class _DeliveryExtensionTimeline extends StatelessWidget {
  const _DeliveryExtensionTimeline({
    required this.order,
    this.includeInternalDetails = false,
  });

  final CustomizationOrder order;
  final bool includeInternalDetails;

  String _time(String? value) =>
      value?.replaceFirst('T', ' ').split('.').first ?? '-';

  @override
  Widget build(BuildContext context) {
    final events = <(IconData, String, String)>[];
    if (order.deliveryExtensionNotifiedAt != null) {
      events.add((
        Icons.outgoing_mail,
        '平台提出延期',
        '${_time(order.deliveryExtensionNotifiedAt)} UTC'
      ));
    }
    if (order.deliveryExtensionReminderCount > 0) {
      events.add((
        Icons.notifications_outlined,
        '已向用户提醒 ${order.deliveryExtensionReminderCount} 次',
        '${_time(order.lastDeliveryExtensionReminderAt)} UTC',
      ));
    }
    if (order.creatorExtensionAcknowledgedAt != null) {
      events.add((
        Icons.done_all_outlined,
        '创作者已确认收到',
        '${_time(order.creatorExtensionAcknowledgedAt)} UTC'
      ));
    }
    if (order.deliveryExtensionEscalatedAt != null) {
      events.add((
        Icons.support_agent_outlined,
        '已转人工处理',
        '${_time(order.deliveryExtensionEscalatedAt)} UTC'
            '${includeInternalDetails ? ' · ${order.deliveryExtensionEscalatedBy ?? '-'}' : ''}',
      ));
    }
    if (order.deliveryExtensionRespondedAt != null) {
      final result = switch (order.deliveryExtensionStatus) {
        'accepted' => '延期已接受',
        'declined' => '延期已拒绝',
        'withdrawn' => '平台已撤回延期',
        _ => '延期已处理',
      };
      events.add((
        Icons.fact_check_outlined,
        result,
        '${_time(order.deliveryExtensionRespondedAt)} UTC'
            '${includeInternalDetails ? ' · ${order.deliveryExtensionResolvedBy ?? '-'}' : ''}',
      ));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('延期记录', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final event in events)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(event.$1, size: 20),
                title: Text(event.$2),
                subtitle: Text(event.$3),
              ),
          ],
        ),
      ),
    );
  }
}

class PlatformProductionSlaPage extends StatefulWidget {
  const PlatformProductionSlaPage({
    required this.order,
    required this.repository,
    super.key,
  });

  final CustomizationOrder order;
  final CustomizationOrderRepository repository;

  @override
  State<PlatformProductionSlaPage> createState() =>
      _PlatformProductionSlaPageState();
}

class _PlatformProductionSlaPageState extends State<PlatformProductionSlaPage>
    with
        GateLoadState<PlatformProductionSlaPage>,
        GateActionState<PlatformProductionSlaPage> {
  late var order = widget.order;
  bool daysEdited = false;

  bool get validDays {
    final days = int.tryParse(daysController.text);
    return days != null && days >= 1 && days <= 30;
  }

  @override
  void initState() {
    super.initState();
    gateLoading = false;
  }

  Future<void> _reload() => loadGateData(
        () async => (await widget.repository.loadOrders())
            .firstWhere((item) => item.id == order.id),
        (updated) => order = updated,
      );

  Future<void> _runSlaAction(Future<void> Function() action) async {
    if (gateLoading || gateLoadFailed) return;
    await runGateAction(action);
  }

  final daysController = TextEditingController(text: '3');
  final reasonController = TextEditingController();
  final resolutionEvidenceController = TextEditingController();
  final resolutionOperatorController = TextEditingController();
  final creatorRiskNoteController = TextEditingController();
  EscalatedExtensionResolution escalatedResolution =
      EscalatedExtensionResolution.proposalWithdrawn;
  CreatorCommunicationRiskResolution creatorRiskResolution =
      CreatorCommunicationRiskResolution.contactRestored;
  CreatorPerformanceReviewOutcome performanceReviewOutcome =
      CreatorPerformanceReviewOutcome.retainCreator;

  @override
  void dispose() {
    daysController.dispose();
    reasonController.dispose();
    resolutionEvidenceController.dispose();
    resolutionOperatorController.dispose();
    creatorRiskNoteController.dispose();
    super.dispose();
  }

  Future<void> _extend() => _runSlaAction(() async {
        final days = int.tryParse(daysController.text);
        if (days == null ||
            days < 1 ||
            days > 30 ||
            reasonController.text.trim().isEmpty) {
          return;
        }
        await widget.repository.extendProductionDeadline(
          orderId: order.id,
          additionalDays: days,
          reason: reasonController.text,
        );
        if (mounted) Navigator.of(context).pop();
      });

  Future<void> _sendReminder() => _runSlaAction(() async {
        await widget.repository.recordDeliveryExtensionReminder(
          orderId: order.id,
        );
        if (mounted) Navigator.of(context).pop();
      });

  Future<void> _escalate() => _runSlaAction(() async {
        await widget.repository.escalateDeliveryExtensionResponse(
          orderId: order.id,
        );
        if (mounted) Navigator.of(context).pop();
      });

  Future<void> _resolveEscalation() => _runSlaAction(() async {
        if (resolutionEvidenceController.text.trim().isEmpty ||
            resolutionOperatorController.text.trim().isEmpty) {
          return;
        }
        await widget.repository.resolveEscalatedDeliveryExtension(
          orderId: order.id,
          resolution: escalatedResolution,
          evidenceReference: resolutionEvidenceController.text,
          operatorId: resolutionOperatorController.text,
        );
        if (mounted) Navigator.of(context).pop();
      });

  Future<void> _sendCreatorReminder() => _runSlaAction(() async {
        await widget.repository.recordCreatorExtensionReminder(
          orderId: order.id,
        );
        if (mounted) Navigator.of(context).pop();
      });

  Future<void> _flagCreatorRisk() => _runSlaAction(() async {
        await widget.repository.flagCreatorCommunicationRisk(
          orderId: order.id,
        );
        if (mounted) Navigator.of(context).pop();
      });

  Future<void> _resolveCreatorRisk() => _runSlaAction(() async {
        if (creatorRiskNoteController.text.trim().isEmpty) return;
        await widget.repository.resolveCreatorCommunicationRisk(
          orderId: order.id,
          resolution: creatorRiskResolution,
          note: creatorRiskNoteController.text,
        );
        if (mounted) Navigator.of(context).pop();
      });

  Future<void> _resolvePerformanceReview() => _runSlaAction(() async {
        if (creatorRiskNoteController.text.trim().isEmpty) return;
        await widget.repository.resolveCreatorPerformanceReview(
          orderId: order.id,
          outcome: performanceReviewOutcome,
          note: creatorRiskNoteController.text,
        );
        if (mounted) Navigator.of(context).pop();
      });

  @override
  Widget build(BuildContext context) {
    final pending = order.deliveryExtensionStatus == 'pending';
    final escalated = order.deliveryExtensionStatus == 'escalated';
    final escalationDue =
        DateTime.tryParse(order.deliveryExtensionEscalationDueAt ?? '');
    final escalationOverdue = escalated &&
        escalationDue != null &&
        escalationDue.toUtc().isBefore(DateTime.now().toUtc());
    final responseDue =
        DateTime.tryParse(order.deliveryExtensionResponseDueAt ?? '');
    final responseOverdue = pending &&
        responseDue != null &&
        responseDue.toUtc().isBefore(DateTime.now().toUtc());
    final lastReminder =
        DateTime.tryParse(order.lastDeliveryExtensionReminderAt ?? '');
    final nextReminderAt =
        lastReminder?.toUtc().add(deliveryExtensionReminderCooldown);
    final reminderLimitReached = order.deliveryExtensionReminderCount >=
        maximumDeliveryExtensionReminders;
    final reminderCoolingDown = nextReminderAt != null &&
        DateTime.now().toUtc().isBefore(nextReminderAt);
    final canSendReminder =
        responseOverdue && !reminderLimitReached && !reminderCoolingDown;
    final resolutionOperator = resolutionOperatorController.text.trim();
    final sameOperatorForAcceptance =
        escalatedResolution == EscalatedExtensionResolution.userAccepted &&
            resolutionOperator == order.deliveryExtensionEscalatedBy;
    final canResolveEscalation =
        resolutionEvidenceController.text.trim().isNotEmpty &&
            resolutionOperator.isNotEmpty &&
            !sameOperatorForAcceptance;
    final reminderButtonLabel = reminderLimitReached
        ? '已达到3次提醒上限'
        : reminderCoolingDown
            ? '24小时提醒冷却中'
            : responseOverdue
                ? '发送延期确认提醒'
                : '仍在用户响应窗口内';
    final creatorNoticePending = order.deliveryExtensionVersion >
        order.creatorExtensionAcknowledgedVersion;
    final creatorNoticeDue =
        DateTime.tryParse(order.creatorExtensionAcknowledgementDueAt ?? '');
    final creatorNoticeOverdue = creatorNoticePending &&
        creatorNoticeDue != null &&
        !DateTime.now().toUtc().isBefore(creatorNoticeDue.toUtc());
    final lastCreatorReminder =
        DateTime.tryParse(order.lastCreatorExtensionReminderAt ?? '');
    final nextCreatorReminderAt =
        lastCreatorReminder?.toUtc().add(creatorExtensionReminderCooldown);
    final creatorReminderCoolingDown = nextCreatorReminderAt != null &&
        DateTime.now().toUtc().isBefore(nextCreatorReminderAt);
    final creatorReminderLimitReached =
        order.creatorExtensionReminderCount >= maximumCreatorExtensionReminders;
    final canSendCreatorReminder = creatorNoticeOverdue &&
        !creatorReminderCoolingDown &&
        !creatorReminderLimitReached;
    return GateScaffold(
      appBar: AppBar(title: const Text('交付逾期处理'), actions: [
        GateRefreshButton(
            loading: gateLoading || gateActionBusy, onRefresh: _reload)
      ]),
      body: gateLoading || gateLoadFailed
          ? GateLoadPanel(failed: gateLoadFailed, onRetry: _reload)
          : AbsorbPointer(
              absorbing: gateActionBusy,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (gateActionBusy)
                    Semantics(
                        liveRegion: true,
                        child: Text(GateCopy.text(context, 'actionPending'))),
                  Text(order.characterName,
                      style: GateDesign.theme().textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                      '当前截止：${order.productionDueAt?.split('T').first ?? '-'}'),
                  const SizedBox(height: 16),
                  if (order.deliveryExtensionVersion > 0) ...[
                    _DeliveryExtensionTimeline(
                      order: order,
                      includeInternalDetails: true,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (creatorNoticePending) ...[
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.mark_email_unread_outlined),
                        title: const Text('创作者尚未确认延期通知'),
                        subtitle: Text(
                          '确认期限：${order.creatorExtensionAcknowledgementDueAt?.replaceFirst('T', ' ').split('.').first ?? '-'} UTC\n'
                          '已提醒：${order.creatorExtensionReminderCount}/$maximumCreatorExtensionReminders 次'
                          '${nextCreatorReminderAt == null ? '' : '\n下次可提醒：${nextCreatorReminderAt.toIso8601String().replaceFirst('T', ' ').split('.').first} UTC'}',
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      key: const Key('send-creator-extension-reminder'),
                      onPressed:
                          canSendCreatorReminder ? _sendCreatorReminder : null,
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: Text(creatorReminderLimitReached
                          ? '已达到2次提醒上限'
                          : creatorReminderCoolingDown
                              ? '24小时提醒冷却中'
                              : creatorNoticeOverdue
                                  ? '提醒创作者确认收到'
                                  : '仍在创作者确认窗口内'),
                    ),
                    if (creatorReminderLimitReached &&
                        order.creatorCommunicationRiskStatus == null) ...[
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        key: const Key('flag-creator-communication-risk'),
                        onPressed: _flagCreatorRisk,
                        icon: const Icon(Icons.person_off_outlined),
                        label: const Text('标记创作者沟通风险'),
                      ),
                    ],
                    if (order.creatorCommunicationRiskStatus ==
                        'pending_review') ...[
                      Text(
                        '已转人工评估：${order.creatorCommunicationRiskFlaggedAt?.replaceFirst('T', ' ').split('.').first ?? '-'} UTC；系统未自动撤换创作者。',
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<
                          CreatorCommunicationRiskResolution>(
                        initialValue: creatorRiskResolution,
                        decoration:
                            const InputDecoration(labelText: '沟通风险评估结果'),
                        items: const [
                          DropdownMenuItem(
                            value: CreatorCommunicationRiskResolution
                                .contactRestored,
                            child: Text('已恢复联系，保留原创作者'),
                          ),
                          DropdownMenuItem(
                            value: CreatorCommunicationRiskResolution
                                .performanceReview,
                            child: Text('转履约风险审查'),
                          ),
                        ],
                        onChanged: gateActionBusy
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => creatorRiskResolution = value);
                                }
                              },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('creator-risk-resolution-note'),
                        controller: creatorRiskNoteController,
                        enabled: !gateActionBusy,
                        decoration:
                            const InputDecoration(labelText: '评估依据与处理说明'),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        key: const Key('resolve-creator-communication-risk'),
                        onPressed: creatorRiskNoteController.text.trim().isEmpty
                            ? null
                            : _resolveCreatorRisk,
                        child: const Text('登记沟通风险结论'),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                  if (order.creatorCommunicationRiskStatus ==
                      'performance_review') ...[
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.policy_outlined),
                        title: const Text('创作者履约风险审查'),
                        subtitle: const Text(
                          '当前自动结算已冻结。本页不会自动换人、扣款或退款。',
                        ),
                      ),
                    ),
                    DropdownButtonFormField<CreatorPerformanceReviewOutcome>(
                      initialValue: performanceReviewOutcome,
                      decoration: const InputDecoration(labelText: '履约审查结论'),
                      items: const [
                        DropdownMenuItem(
                          value: CreatorPerformanceReviewOutcome.retainCreator,
                          child: Text('保留创作者并恢复正常履约'),
                        ),
                        DropdownMenuItem(
                          value:
                              CreatorPerformanceReviewOutcome.openOrderDispute,
                          child: Text('升级为订单争议'),
                        ),
                      ],
                      onChanged: gateActionBusy
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(
                                    () => performanceReviewOutcome = value);
                              }
                            },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('performance-review-note'),
                      controller: creatorRiskNoteController,
                      enabled: !gateActionBusy,
                      decoration: const InputDecoration(labelText: '审查证据与处理说明'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      key: const Key('resolve-performance-review'),
                      onPressed: creatorRiskNoteController.text.trim().isEmpty
                          ? null
                          : _resolvePerformanceReview,
                      child: const Text('登记履约审查结论'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (escalated) ...[
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.support_agent_outlined),
                        title: const Text('延期请求已转人工处理'),
                        subtitle: Text(
                          '升级时间：${order.deliveryExtensionEscalatedAt?.replaceFirst('T', ' ').split('.').first ?? '-'} UTC\n'
                          '处理期限：${order.deliveryExtensionEscalationDueAt?.replaceFirst('T', ' ').split('.').first ?? '-'} UTC\n'
                          '操作人：${order.deliveryExtensionEscalatedBy ?? '-'}\n'
                          '${escalationOverdue ? '当前已超过48小时人工处理SLA。\n' : ''}'
                          '平台仍需联系用户并人工决定后续方案，系统不会代替用户同意延期。',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<EscalatedExtensionResolution>(
                      key: const Key('extension-escalation-resolution'),
                      initialValue: escalatedResolution,
                      decoration: const InputDecoration(labelText: '人工联系结果'),
                      items: const [
                        DropdownMenuItem(
                          value: EscalatedExtensionResolution.proposalWithdrawn,
                          child: Text('平台撤回延期方案'),
                        ),
                        DropdownMenuItem(
                          value: EscalatedExtensionResolution.userAccepted,
                          child: Text('用户明确接受新日期'),
                        ),
                        DropdownMenuItem(
                          value: EscalatedExtensionResolution.userDeclined,
                          child: Text('用户明确拒绝并进入争议'),
                        ),
                      ],
                      onChanged: gateActionBusy
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => escalatedResolution = value);
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('extension-resolution-evidence'),
                      controller: resolutionEvidenceController,
                      enabled: !gateActionBusy,
                      decoration: const InputDecoration(
                        labelText: '联系记录或用户同意凭证编号',
                        helperText: '必填；选择“用户接受”时必须能够证明其明确同意。',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('extension-resolution-operator'),
                      controller: resolutionOperatorController,
                      enabled: !gateActionBusy,
                      decoration: InputDecoration(
                        labelText: '处理人员ID',
                        helperText: escalatedResolution ==
                                EscalatedExtensionResolution.userAccepted
                            ? '接受延期需要另一名人员复核，不能与升级人相同。'
                            : '用于审计追踪，必填。',
                        errorText:
                            sameOperatorForAcceptance ? '复核人不能与升级人相同' : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      key: const Key('resolve-extension-escalation'),
                      onPressed:
                          canResolveEscalation ? _resolveEscalation : null,
                      child: const Text('登记人工处理结果'),
                    ),
                  ] else if (pending) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('已向用户提出延期'),
                            const SizedBox(height: 8),
                            Text(
                                '建议新日期：${order.proposedProductionDueAt?.split('T').first ?? '-'}'),
                            Text(
                                '响应截止：${order.deliveryExtensionResponseDueAt?.replaceFirst('T', ' ').split('.').first ?? '-'} UTC'),
                            Text(
                                '已提醒：${order.deliveryExtensionReminderCount} 次'),
                            Text(
                              order.creatorExtensionAcknowledgedVersion >=
                                      order.deliveryExtensionVersion
                                  ? '创作者已确认收到本次延期通知'
                                  : '创作者尚未确认收到（期限：${order.creatorExtensionAcknowledgementDueAt?.replaceFirst('T', ' ').split('.').first ?? '-'} UTC）',
                            ),
                            if (order.lastDeliveryExtensionReminderAt != null)
                              Text(
                                  '最近提醒：${order.lastDeliveryExtensionReminderAt!.replaceFirst('T', ' ').split('.').first} UTC'),
                            if (reminderCoolingDown)
                              Text(
                                  '下次可提醒：${nextReminderAt.toIso8601String().replaceFirst('T', ' ').split('.').first} UTC'),
                            const SizedBox(height: 8),
                            const Text('用户未回复不会被视为接受，原交付日期保持不变。'),
                          ],
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      key: const Key('send-delivery-extension-reminder'),
                      onPressed: canSendReminder ? _sendReminder : null,
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: Text(reminderButtonLabel),
                    ),
                    if (reminderLimitReached) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        key: const Key('escalate-delivery-extension'),
                        onPressed: _escalate,
                        icon: const Icon(Icons.support_agent_outlined),
                        label: const Text('转人工处理'),
                      ),
                    ],
                  ] else ...[
                    TextField(
                      key: const Key('delivery-extension-days'),
                      controller: daysController,
                      enabled: !gateActionBusy,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() => daysEdited = true),
                      decoration: InputDecoration(
                        labelText: '延期天数（1–30 天）',
                        errorMaxLines: 3,
                        errorText: daysEdited && !validDays
                            ? GateCopy.text(context, 'extensionDays')
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('delivery-extension-reason'),
                      controller: reasonController,
                      enabled: !gateActionBusy,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: '面向用户的延期原因',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: gateActionBusy ||
                              !validDays ||
                              reasonController.text.trim().isEmpty
                          ? null
                          : _extend,
                      child: const Text('确认延期并通知用户'),
                    ),
                    const SizedBox(height: 8),
                    const Text('延期不会修改已确认价格、创作者约定收入或用户争议权利。'),
                  ],
                ],
              ),
            ),
    );
  }
}

class PlatformQualityReviewPage extends StatefulWidget {
  const PlatformQualityReviewPage({
    required this.order,
    required this.repository,
    super.key,
  });

  final CustomizationOrder order;
  final CustomizationOrderRepository repository;

  @override
  State<PlatformQualityReviewPage> createState() =>
      _PlatformQualityReviewPageState();
}

class _PlatformQualityReviewPageState extends State<PlatformQualityReviewPage>
    with GateActionState<PlatformQualityReviewPage> {
  static const _checkLabels = {
    'media_integrity': '媒体文件完整且可解码',
    'content_safety': '内容安全与授权范围复核通过',
    'audio_sync': '音画同步符合交付标准',
    'transparent_background': '透明背景与边缘显示正常',
    'device_playback': '已在目标全息设备完成播放测试',
    'device_recovery': '中断后可安全恢复且不会产生残留内容',
  };

  final packageVersionController = TextEditingController();
  final failureController = TextEditingController();
  String? failedCheck;
  final passedChecks = <String>{};
  String deviceModel = 'P20';

  @override
  void dispose() {
    packageVersionController.dispose();
    failureController.dispose();
    super.dispose();
  }

  bool get canSubmit =>
      failedCheck == null &&
      passedChecks.containsAll(requiredCharacterQualityChecks) &&
      packageVersionController.text.trim().isNotEmpty &&
      !gateActionBusy;

  Future<void> _submit() => runGateAction(() async {
        if (failedCheck != null) return;
        final review = CharacterQualityReview(
          results: {
            for (final check in requiredCharacterQualityChecks)
              check: passedChecks.contains(check)
                  ? CharacterQualityCheckResult.passed
                  : CharacterQualityCheckResult.notTested,
          },
          reviewerId: 'platform-quality-reviewer-local',
          deviceModel: deviceModel,
          packageVersion: packageVersionController.text.trim(),
          reviewedAt: DateTime.now().toUtc().toIso8601String(),
        );
        if (!review.canRelease) return;
        await widget.repository.submitContentQualityReview(
          orderId: widget.order.id,
          expectedPreviewVersion: widget.order.previewVersion,
          review: review,
        );
        final updated = (await widget.repository.loadOrders())
            .where((order) => order.id == widget.order.id)
            .firstOrNull;
        if (!mounted) return;
        final saved = updated?.qualityReview;
        if (updated?.status != '待用户验收' ||
            saved?.canRelease != true ||
            saved?.reviewedAt != review.reviewedAt ||
            saved?.reviewerId != review.reviewerId ||
            saved?.packageVersion != review.packageVersion ||
            saved?.deviceModel != review.deviceModel) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未确认质检放行，已保留填写内容，请核对订单状态后重试')),
          );
          return;
        }
        Navigator.of(context).maybePop();
      });

  Future<void> _returnForRepair() => runGateAction(() async {
        if (failedCheck == null ||
            failureController.text.trim().isEmpty ||
            packageVersionController.text.trim().isEmpty) {
          return;
        }
        final submittedAt = DateTime.now().toUtc().toIso8601String();
        await widget.repository.submitContentQualityReview(
          orderId: widget.order.id,
          expectedPreviewVersion: widget.order.previewVersion,
          review: CharacterQualityReview(
            results: {
              for (final check in requiredCharacterQualityChecks)
                check: check == failedCheck
                    ? CharacterQualityCheckResult.failed
                    : passedChecks.contains(check)
                        ? CharacterQualityCheckResult.passed
                        : CharacterQualityCheckResult.notTested,
            },
            reviewerId: 'platform-quality-reviewer-local',
            deviceModel: deviceModel,
            packageVersion: packageVersionController.text.trim(),
            reviewedAt: submittedAt,
            failureNote: failureController.text.trim(),
          ),
        );
        final updated = (await widget.repository.loadOrders())
            .where((order) => order.id == widget.order.id)
            .firstOrNull;
        if (!mounted) return;
        final saved = updated?.qualityReview;
        if (updated?.status != '修改中' ||
            saved?.reviewedAt != submittedAt ||
            saved?.reviewerId != 'platform-quality-reviewer-local' ||
            saved?.deviceModel != deviceModel ||
            saved?.packageVersion != packageVersionController.text.trim() ||
            saved?.failureNote != failureController.text.trim() ||
            saved?.results[failedCheck] != CharacterQualityCheckResult.failed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未确认质检返工，已保留填写内容，请核对订单状态后重试')),
          );
          return;
        }
        Navigator.of(context).maybePop();
      });

  @override
  Widget build(BuildContext context) => GateScaffold(
        appBar: AppBar(title: const Text('平台内容质检')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GateSection(
                eyebrow: 'RELEASE GATE',
                title: widget.order.characterName,
                description: '所有检查和真机证据齐全后，才会向用户开放受控预览验收。',
                icon: Icons.verified_user_outlined,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('必检项目',
                          style: GateDesign.theme().textTheme.titleMedium),
                      const SizedBox(height: 8),
                      for (final check in requiredCharacterQualityChecks)
                        CheckboxListTile(
                          key: Key('quality-check-$check'),
                          contentPadding: EdgeInsets.zero,
                          value: passedChecks.contains(check),
                          onChanged: gateActionBusy
                              ? null
                              : (value) => setState(() {
                                    if (value == true) {
                                      passedChecks.add(check);
                                    } else {
                                      passedChecks.remove(check);
                                    }
                                  }),
                          title: Text(_checkLabels[check] ?? check),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: deviceModel,
                decoration: const InputDecoration(labelText: '真机测试型号'),
                items: const [
                  DropdownMenuItem(value: 'P20', child: Text('P20')),
                  DropdownMenuItem(value: 'P11', child: Text('P11')),
                ],
                onChanged: gateActionBusy
                    ? null
                    : (value) => setState(() => deviceModel = value ?? 'P20'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('quality-package-version'),
                controller: packageVersionController,
                enabled: !gateActionBusy,
                decoration: const InputDecoration(
                  labelText: '受控内容包版本',
                  hintText: '例如 1.0.0',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: canSubmit ? _submit : null,
                child: gateActionBusy
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(GateCopy.text(context, 'submitting')),
                        ],
                      )
                    : const Text('全部通过并提交用户验收'),
              ),
              const SizedBox(height: 8),
              const Text('质检页面不提供内容下载；通过后仅开放 App 内受控预览和绑定设备交付。'),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                key: const Key('quality-failed-check'),
                initialValue: '',
                decoration: const InputDecoration(labelText: '返工项目'),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('未标记失败（撤销失败选择）'),
                  ),
                  for (final check in requiredCharacterQualityChecks)
                    DropdownMenuItem(
                        value: check, child: Text(_checkLabels[check]!)),
                ],
                onChanged: gateActionBusy
                    ? null
                    : (value) => setState(() {
                          failedCheck =
                              value == null || value.isEmpty ? null : value;
                          if (failedCheck != null) {
                            passedChecks.remove(failedCheck);
                          }
                        }),
              ),
              TextField(
                key: const Key('quality-failure-note'),
                controller: failureController,
                enabled: !gateActionBusy,
                decoration: const InputDecoration(labelText: '返工原因与修复要求'),
                maxLines: 3,
                onChanged: (_) => setState(() {}),
              ),
              OutlinedButton(
                onPressed: gateActionBusy ||
                        failedCheck == null ||
                        failureController.text.trim().isEmpty ||
                        packageVersionController.text.trim().isEmpty
                    ? null
                    : _returnForRepair,
                child: const Text('退回创作者返工'),
              ),
              const Text('平台质检返工不扣除用户约定的修改次数。'),
            ],
          ),
        ),
      );
}

class PlatformPayoutReviewPage extends StatefulWidget {
  const PlatformPayoutReviewPage({
    required this.order,
    required this.repository,
    super.key,
  });

  final CustomizationOrder order;
  final CustomizationOrderRepository repository;

  @override
  State<PlatformPayoutReviewPage> createState() =>
      _PlatformPayoutReviewPageState();
}

class _PlatformPayoutReviewPageState extends State<PlatformPayoutReviewPage>
    with GateLoadState<PlatformPayoutReviewPage> {
  late var order = widget.order;
  bool recording = false;

  @override
  void initState() {
    super.initState();
    gateLoading = false;
  }

  Future<void> _reload() => loadGateData(
        () async => (await widget.repository.loadOrders())
            .firstWhere((item) => item.id == order.id),
        (updated) => order = updated,
      );
  final payoutReferenceController = TextEditingController();
  final accountVerificationController = TextEditingController();
  String failureCode = 'account_unavailable';

  bool get canRecord =>
      order.status == '已交付' && {'待结算', '结算失败'}.contains(order.settlementStatus);

  bool get isEligible {
    final date = DateTime.tryParse(order.payoutEligibleAt ?? '');
    return date != null && !DateTime.now().toUtc().isBefore(date.toUtc());
  }

  @override
  void dispose() {
    payoutReferenceController.dispose();
    accountVerificationController.dispose();
    super.dispose();
  }

  Future<void> _recordSuccess() => _record(true);
  Future<void> _recordFailure() => _record(false);

  Future<void> _record(bool success) async {
    if (!mounted ||
        recording ||
        gateLoading ||
        gateLoadFailed ||
        !isEligible ||
        !canRecord) {
      return;
    }
    final reference = payoutReferenceController.text.trim();
    final verification = accountVerificationController.text.trim();
    final code = failureCode;
    if (verification.isEmpty || (success && reference.isEmpty)) return;
    final previousAttempts = order.payoutAttemptCount;
    setState(() => recording = true);
    try {
      if (success) {
        await widget.repository.recordCreatorPayout(
            orderId: order.id,
            payoutReference: reference,
            payoutAccountVerificationReference: verification);
      } else {
        await widget.repository.recordCreatorPayoutFailure(
            orderId: order.id,
            failureCode: code,
            payoutAccountVerificationReference: verification);
      }
      if (!mounted) return;
      await _reload();
      if (!mounted || gateLoadFailed) return;
      final confirmed = success
          ? order.settlementStatus == '已结算' &&
              order.payoutReference == reference
          : order.settlementStatus == '结算失败' &&
              order.lastPayoutFailureCode == code &&
              order.payoutAttemptCount > previousAttempts;
      if (confirmed) {
        Navigator.of(context).pop();
      } else {
        showGateActionError(context);
      }
    } catch (_) {
      if (mounted) showGateActionError(context);
    } finally {
      if (mounted) setState(() => recording = false);
    }
  }

  @override
  Widget build(BuildContext context) => GateScaffold(
        appBar: AppBar(title: const Text('创作者结算处理'), actions: [
          GateRefreshButton(
              loading: gateLoading || recording, onRefresh: _reload)
        ]),
        body: gateLoading || gateLoadFailed
            ? GateLoadPanel(failed: gateLoadFailed, onRetry: _reload)
            : ListView(
                scrollCacheExtent: const ScrollCacheExtent.pixels(600),
                padding: const EdgeInsets.all(20),
                children: [
                  Text(order.characterName,
                      style: GateDesign.theme().textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Text(
                    '应付：${_formatMoney(order.creatorPayoutCurrency, order.creatorPayoutCents ?? 0)}',
                  ),
                  Text('状态：${order.settlementStatus ?? '-'}'),
                  Text('累计尝试：${order.payoutAttemptCount} 次'),
                  Text(
                    '可结算时间：${order.payoutEligibleAt?.split('T').first ?? '-'}',
                  ),
                  if (order.lastPayoutFailureCode != null)
                    Text('最近失败：${order.lastPayoutFailureCode}'),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('payout-account-verification'),
                    controller: accountVerificationController,
                    enabled: !recording,
                    decoration: const InputDecoration(
                      labelText: '支付服务商账户核验引用',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('payout-transaction-reference'),
                    controller: payoutReferenceController,
                    enabled: !recording,
                    decoration: const InputDecoration(labelText: '成功放款流水号'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    key: const Key('payout-failure-code'),
                    initialValue: failureCode,
                    decoration: const InputDecoration(labelText: '失败原因'),
                    items: const {
                      'account_unavailable': '账户暂不可用',
                      'account_restricted': '账户受限',
                      'provider_rejected': '支付服务商拒绝',
                      'compliance_review': '需要合规复核',
                    }
                        .entries
                        .map((entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ))
                        .toList(),
                    onChanged: recording
                        ? null
                        : (value) =>
                            setState(() => failureCode = value ?? failureCode),
                  ),
                  const SizedBox(height: 16),
                  if (!isEligible)
                    const Text('结算观察期尚未结束，当前不能发起放款。')
                  else if (!canRecord)
                    GateStatus(order.settlementStatus ?? order.status)
                  else ...[
                    FilledButton(
                      onPressed: !recording &&
                              accountVerificationController.text
                                  .trim()
                                  .isNotEmpty &&
                              payoutReferenceController.text.trim().isNotEmpty
                          ? _recordSuccess
                          : null,
                      child: Text(recording
                          ? GateCopy.text(context, 'submitting')
                          : '确认支付服务商已放款'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: !recording &&
                              accountVerificationController.text
                                  .trim()
                                  .isNotEmpty
                          ? _recordFailure
                          : null,
                      child: const Text('登记本次放款失败'),
                    ),
                  ],
                ],
              ),
      );
}

class PlatformDisputeReviewPage extends StatefulWidget {
  const PlatformDisputeReviewPage({
    required this.order,
    required this.repository,
    super.key,
  });

  final CustomizationOrder order;
  final CustomizationOrderRepository repository;

  @override
  State<PlatformDisputeReviewPage> createState() =>
      _PlatformDisputeReviewPageState();
}

class _PlatformDisputeReviewPageState extends State<PlatformDisputeReviewPage>
    with GateActionState<PlatformDisputeReviewPage> {
  CustomizationOrder get order => widget.order;
  CustomizationOrderRepository get repository => widget.repository;

  Future<void> _resolve(
    BuildContext context,
    DisputeResolution resolution,
  ) =>
      runGateAction(() async {
        await repository.resolveDispute(
            orderId: order.id, resolution: resolution);
        if (context.mounted) Navigator.of(context).pop();
      });

  @override
  Widget build(BuildContext context) => GateScaffold(
        appBar: AppBar(title: const Text('平台争议处理')),
        body: ListView(
          scrollCacheExtent: const ScrollCacheExtent.pixels(600),
          padding: const EdgeInsets.all(20),
          children: [
            if (gateActionBusy) Text(GateCopy.text(context, 'actionPending')),
            Text(order.characterName,
                style: GateDesign.theme().textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text('争议前状态：${order.disputePriorStatus ?? '-'}'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(order.disputeReason ?? '未提供原因'),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: gateActionBusy
                  ? null
                  : () => _resolve(context, DisputeResolution.resumeOrder),
              child: const Text('恢复原订单流程'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: gateActionBusy
                  ? null
                  : () => _resolve(context, DisputeResolution.refundApproved),
              child: const Text('批准进入退款处理'),
            ),
            const SizedBox(height: 8),
            const Text('批准仅改变订单状态；实际退款仍需支付服务确认。'),
          ],
        ),
      );
}

class PlatformAssignmentReviewPage extends StatefulWidget {
  const PlatformAssignmentReviewPage({
    required this.order,
    required this.repository,
    this.creatorDisplayNames = const {},
    super.key,
  });

  final CustomizationOrder order;
  final CustomizationOrderRepository repository;
  final Map<String, String> creatorDisplayNames;

  @override
  State<PlatformAssignmentReviewPage> createState() =>
      _PlatformAssignmentReviewPageState();
}

class _PlatformAssignmentReviewPageState
    extends State<PlatformAssignmentReviewPage>
    with GateLoadState<PlatformAssignmentReviewPage> {
  late var order = widget.order;
  String? assigningId;

  @override
  void initState() {
    super.initState();
    gateLoading = false;
  }

  Future<void> _reload() => loadGateData(
        () async => (await widget.repository.loadOrders())
            .firstWhere((item) => item.id == order.id),
        (updated) => order = updated,
      );

  Future<void> _assign(String creatorId) async {
    if (!mounted ||
        assigningId != null ||
        gateLoading ||
        gateLoadFailed ||
        order.status != '待创作者申请') {
      return;
    }
    setState(() => assigningId = creatorId);
    try {
      await widget.repository
          .assignCreator(orderId: order.id, creatorId: creatorId);
      if (!mounted) return;
      await _reload();
      if (!mounted || gateLoadFailed) return;
      if (order.assignedCreatorId == creatorId) {
        Navigator.of(context).pop();
      } else {
        showGateActionError(context);
      }
    } catch (_) {
      if (mounted) showGateActionError(context);
    } finally {
      if (mounted) setState(() => assigningId = null);
    }
  }

  @override
  Widget build(BuildContext context) => GateScaffold(
        appBar: AppBar(title: const Text('平台选择创作者'), actions: [
          GateRefreshButton(
              loading: gateLoading || assigningId != null, onRefresh: _reload)
        ]),
        body: gateLoading || gateLoadFailed
            ? GateLoadPanel(failed: gateLoadFailed, onRetry: _reload)
            : ListView(
                scrollCacheExtent: const ScrollCacheExtent.pixels(600),
                padding: const EdgeInsets.all(20),
                children: [
                  Text(order.characterName,
                      style: GateDesign.theme().textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('需求：${order.requestedFeatures.join('、')}'),
                  Text('参考素材：${order.materialCount} 个'),
                  const SizedBox(height: 8),
                  const Text('仅展示派单所需的脱敏摘要，不展示用户联系方式。'),
                  if (order.declinedAssignedCreatorIds.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: GateDesign.theme().colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          '历史退出 ${order.declinedAssignedCreatorIds.length} 人\n'
                          '最近原因：${order.lastCreatorDeclineReason ?? '未记录'}',
                        ),
                      ),
                    ),
                  ],
                  if (order.timedOutAssignedCreatorIds.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          '历史派单超时 ${order.timedOutAssignedCreatorIds.length} 人',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text('申请创作者（${order.applicantCreatorIds.length}）',
                      style: GateDesign.theme().textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (order.applicantCreatorIds.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('尚无创作者申请，暂时无法派单。'),
                      ),
                    )
                  else
                    ...order.applicantCreatorIds.map(
                      (creatorId) => Card(
                        child: GateDetailTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(
                            widget.creatorDisplayNames[creatorId] ?? '认证创作者',
                          ),
                          subtitle: Text('内部编号：$creatorId'),
                          trailing: FilledButton(
                            onPressed:
                                assigningId == null && order.status == '待创作者申请'
                                    ? () => _assign(creatorId)
                                    : null,
                            child:
                                Text(assigningId == creatorId ? '正在派单' : '选择'),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      );
}

class PlatformQuoteReviewPage extends StatefulWidget {
  const PlatformQuoteReviewPage({
    required this.order,
    required this.repository,
    super.key,
  });

  final CustomizationOrder order;
  final CustomizationOrderRepository repository;

  @override
  State<PlatformQuoteReviewPage> createState() =>
      _PlatformQuoteReviewPageState();
}

class _PlatformQuoteReviewPageState extends State<PlatformQuoteReviewPage> {
  final amountFocus = FocusNode();
  final revisionsFocus = FocusNode();
  final daysFocus = FocusNode();
  final overrideFocus = FocusNode();
  bool attempted = false;
  final amountController = TextEditingController();
  final revisionsController = TextEditingController(text: '2');
  final daysController = TextEditingController();
  final currencyOverrideController = TextEditingController();
  late var currency = defaultCurrencyForMarketRegion(widget.order.marketRegion);
  var taxTreatment = 'calculated_at_checkout';
  var publishing = false;

  int? get amountMinor {
    final value = double.tryParse(amountController.text);
    if (value == null || !value.isFinite) return null;
    final scaled = value * (currency == 'JPY' ? 1 : 100);
    return scaled.isFinite ? scaled.round() : null;
  }

  String? get amountError {
    final value = amountMinor;
    if (value == null || value <= 0) {
      return GateCopy.text(context, 'validAmount');
    }
    if (currency == (widget.order.creatorSuggestedCurrency ?? 'USD') &&
        value < (widget.order.creatorSuggestedAmountCents ?? 0)) {
      return GateCopy.text(context, 'quoteBelowSuggestion');
    }
    return null;
  }

  String? get revisionsError {
    final value = int.tryParse(revisionsController.text);
    return value == null || value < 0
        ? GateCopy.text(context, 'validRevisions')
        : null;
  }

  String? get daysError {
    final value = int.tryParse(daysController.text);
    return value == null || value <= 0
        ? GateCopy.text(context, 'validDays')
        : null;
  }

  String? get overrideError =>
      currency != defaultCurrencyForMarketRegion(widget.order.marketRegion) &&
              currencyOverrideController.text.trim().isEmpty
          ? GateCopy.text(context, 'quoteOverrideRequired')
          : null;

  @override
  void initState() {
    super.initState();
    final suggested = widget.order.creatorSuggestedAmountCents;
    final suggestedCurrency = widget.order.creatorSuggestedCurrency ?? 'USD';
    if (suggested != null && currency == suggestedCurrency) {
      amountController.text = currency == 'JPY'
          ? '$suggested'
          : (suggested / 100).toStringAsFixed(2);
    }
    final days = widget.order.estimatedDeliveryDays;
    if (days != null) daysController.text = '$days';
  }

  @override
  void dispose() {
    amountFocus.dispose();
    revisionsFocus.dispose();
    daysFocus.dispose();
    overrideFocus.dispose();
    amountController.dispose();
    revisionsController.dispose();
    daysController.dispose();
    currencyOverrideController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!mounted || publishing) return;
    setState(() => attempted = true);
    final errors = [
      (overrideFocus, overrideError),
      (amountFocus, amountError),
      (revisionsFocus, revisionsError),
      (daysFocus, daysError)
    ];
    for (final field in errors) {
      if (field.$2 != null) {
        field.$1.requestFocus();
        return;
      }
    }
    final revisions = int.tryParse(revisionsController.text);
    final days = int.tryParse(daysController.text);
    final amountCents = amountMinor!;
    setState(() => publishing = true);
    try {
      await widget.repository.publishPlatformQuote(
        orderId: widget.order.id,
        amountCents: amountCents,
        currency: currency,
        taxTreatment: taxTreatment,
        currencyOverrideReason: currencyOverrideController.text,
        includedRevisions: revisions!,
        estimatedDeliveryDays: days!,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) showGateActionError(context);
    } finally {
      if (mounted) setState(() => publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) => GateScaffold(
        appBar: AppBar(title: const Text('平台报价审核')),
        body: ListView(
          scrollCacheExtent: const ScrollCacheExtent.pixels(600),
          padding: const EdgeInsets.all(20),
          children: [
            Text(widget.order.characterName,
                style: GateDesign.theme().textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              widget.order.creatorSuggestedAmountCents == null
                  ? GateCopy.text(context, 'quoteEstimateMissing')
                  : '创作者建议制作费：${_formatMoney(widget.order.creatorSuggestedCurrency, widget.order.creatorSuggestedAmountCents!)}',
            ),
            const SizedBox(height: 6),
            const Text('最终价格应覆盖创作者结算、支付成本、税费、售后和平台服务。'),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: currency,
              decoration: const InputDecoration(labelText: '用户结算币种'),
              items: ['USD', 'EUR', 'GBP', 'JPY', 'CNY', 'HKD', 'MOP', 'TWD']
                  .map((value) =>
                      DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: publishing
                  ? null
                  : (value) => setState(() => currency = value ?? 'USD'),
            ),
            if (currency !=
                defaultCurrencyForMarketRegion(widget.order.marketRegion)) ...[
              const SizedBox(height: 12),
              TextField(
                key: const Key('currency-override-reason'),
                controller: currencyOverrideController,
                enabled: !publishing,
                focusNode: overrideFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => amountFocus.requestFocus(),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: '调整币种原因',
                  errorText: attempted ? overrideError : null,
                  errorMaxLines: 3,
                  hintText: '例如：用户书面要求使用美元结算',
                ),
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              key: const Key('platform-tax-treatment'),
              initialValue: taxTreatment,
              decoration: const InputDecoration(labelText: '税费口径'),
              items: _taxTreatmentLabels.entries
                  .map((entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ))
                  .toList(),
              onChanged: publishing
                  ? null
                  : (value) => setState(
                        () => taxTreatment = value ?? 'calculated_at_checkout',
                      ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('platform-final-amount'),
              controller: amountController,
              enabled: !publishing,
              focusNode: amountFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => revisionsFocus.requestFocus(),
              onChanged: (_) => setState(() {}),
              keyboardType:
                  TextInputType.numberWithOptions(decimal: currency != 'JPY'),
              decoration: InputDecoration(
                  labelText: '向用户发布的最终价格',
                  prefixText: '$currency ',
                  errorText: attempted ? amountError : null,
                  errorMaxLines: 3),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('platform-included-revisions'),
              controller: revisionsController,
              enabled: !publishing,
              focusNode: revisionsFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => daysFocus.requestFocus(),
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: '包含修改次数',
                  errorText: attempted ? revisionsError : null,
                  errorMaxLines: 3),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('platform-delivery-days'),
              controller: daysController,
              enabled: !publishing,
              focusNode: daysFocus,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => daysFocus.unfocus(),
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: '预计交付天数',
                  errorText: attempted ? daysError : null,
                  errorMaxLines: 3),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: publishing ? null : _publish,
              child: Text(publishing ? '正在发布' : '发布平台最终报价'),
            ),
          ],
        ),
      );
}

class _CreatorTaskBoardPageState extends State<CreatorTaskBoardPage>
    with GateLoadState<CreatorTaskBoardPage> {
  static const creatorId = 'local-certified-creator';
  late final CustomizationOrderRepository repository =
      widget.orderRepository ?? const LocalCustomizationOrderRepository();
  List<CustomizationOrder> tasks = const [];
  String taskFilter = 'all';
  bool taskBusy = false;
  final proposalAmounts = <String, String>{};
  final proposalDays = <String, String>{};
  final declineReasons = <String, String>{};

  Future<void> _runTaskAction(Future<void> Function() action) async {
    if (!mounted || taskBusy || gateLoading || gateLoadFailed) return;
    setState(() => taskBusy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) showGateActionError(context);
    } finally {
      if (mounted) setState(() => taskBusy = false);
    }
  }

  List<CustomizationOrder> get visibleTasks => tasks.where((task) {
        return switch (taskFilter) {
          'available' => task.status == '待创作者申请',
          'working' => task.status == '制作中' || task.status == '修改中',
          _ => true,
        };
      }).toList();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() => loadGateData(repository.loadOrders, (orders) {
        tasks = orders
            .where((order) =>
                (order.status == '待创作者申请' &&
                    !order.declinedAssignedCreatorIds.contains(creatorId) &&
                    !order.timedOutAssignedCreatorIds.contains(creatorId) &&
                    (widget.creatorSkills == null ||
                        order.requestedFeatures.any(
                          widget.creatorSkills!.contains,
                        ))) ||
                order.assignedCreatorId == creatorId)
            .toList();
      });

  Future<void> _claim(String orderId) => _runTaskAction(() async {
        await repository.applyForCreator(
          orderId: orderId,
          creatorId: creatorId,
        );
        await _reload();
      });

  Future<void> _withdrawApplication(String orderId) => _runTaskAction(() async {
        await repository.withdrawCreatorApplication(
          orderId: orderId,
          creatorId: creatorId,
        );
        await _reload();
        if (!mounted || gateLoadFailed) return;
        if (!tasks.any((task) =>
            task.id == orderId &&
            !task.applicantCreatorIds.contains(creatorId))) {
          showGateActionError(context);
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已撤回接单申请，你仍可在平台派单前重新申请。')),
        );
      });

  Future<void> _acknowledgeExtension(String orderId) =>
      _runTaskAction(() async {
        await repository.acknowledgeCreatorExtensionNotice(
          orderId: orderId,
          creatorId: creatorId,
        );
        await _reload();
      });

  Future<void> _openProposal(CustomizationOrder task) =>
      _runTaskAction(() async {
        final formKey = GlobalKey<FormState>();
        final settlementCurrency = widget.creatorSettlementCurrency;
        final submitted = await showGateDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            scrollable: true,
            title: const Text('提交工作量建议'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('此处仅填写建议制作费和工期。平台会另行审核并向用户发布最终报价。'),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('creator-proposal-amount'),
                    initialValue: proposalAmounts[task.id],
                    onChanged: (value) => proposalAmounts[task.id] = value,
                    validator: (value) {
                      final amount = double.tryParse(value ?? '');
                      return amount == null ||
                              !amount.isFinite ||
                              amount <= 0 ||
                              !(amount * 100).isFinite
                          ? GateCopy.text(context, 'validAmount')
                          : null;
                    },
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '建议制作费（$settlementCurrency）',
                      prefixText: settlementCurrency == 'CNY' ? '¥ ' : r'$ ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('creator-proposal-days'),
                    initialValue: proposalDays[task.id],
                    onChanged: (value) => proposalDays[task.id] = value,
                    validator: (value) {
                      final days = int.tryParse(value ?? '');
                      return days == null || days <= 0
                          ? GateCopy.text(context, 'validDays')
                          : null;
                    },
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '预计交付天数'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(dialogContext).pop(true);
                  }
                },
                child: const Text('提交平台审核'),
              ),
            ],
          ),
        );
        if (!mounted || submitted != true) {
          return;
        }
        final amount = double.parse(proposalAmounts[task.id]!);
        final days = int.parse(proposalDays[task.id]!);
        await repository.submitCreatorProposal(
          orderId: task.id,
          creatorId: creatorId,
          suggestedAmountCents: (amount * 100).round(),
          creatorMarketRegion: widget.creatorMarketRegion,
          estimatedDeliveryDays: days,
        );
        await _reload();
      });

  Future<void> _declineAssignedTask(CustomizationOrder task) =>
      _runTaskAction(() async {
        var reason = declineReasons[task.id] ?? '';
        final confirmed = await showGateDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            scrollable: true,
            title: const Text('确认无法承接'),
            content: TextFormField(
              key: const Key('creator-decline-reason'),
              initialValue: reason,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '原因',
                hintText: '例如：当前档期不足或需求超出擅长范围',
              ),
              onChanged: (value) => declineReasons[task.id] = reason = value,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('继续评估'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('退回平台重新匹配'),
              ),
            ],
          ),
        );
        if (!mounted || confirmed != true || reason.trim().isEmpty) return;
        await repository.declineAssignedTask(
          orderId: task.id,
          creatorId: creatorId,
          reason: reason,
        );
        await _reload();
      });

  Future<void> _submitPreview(CustomizationOrder task) =>
      _runTaskAction(() async {
        final selected = widget.previewPicker != null
            ? await widget.previewPicker!()
            : await FilePicker.pickFile(type: FileType.video) != null;
        if (!mounted || !selected) return;
        final reference =
            'protected-preview-${DateTime.now().microsecondsSinceEpoch}';
        await repository.submitCreatorPreview(
          orderId: task.id,
          creatorId: creatorId,
          previewReference: reference,
        );
        await _reload();
        if (!mounted || gateLoadFailed) return;
        if (!tasks.any((updated) =>
            updated.id == task.id && updated.previewReference == reference)) {
          showGateActionError(context);
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已提交受控预览，本机路径和文件名不会写入订单。')),
        );
      });

  String _creatorStatus(CustomizationOrder task) {
    if (task.deliveryExtensionStatus == 'escalated') return '延期正在人工处理';
    if (task.deliveryExtensionStatus == 'pending') return '等待用户确认延期';
    if (task.status == '平台审核报价') return '等待平台审核报价';
    if (task.status == '待确认报价' || task.status == '待支付') {
      return '等待用户确认并付款';
    }
    if (task.status == '制作中' || task.status == '修改中') return '已付款，待制作';
    if (task.status == '待用户验收') return '等待用户验收';
    if (task.status == '已交付') return task.settlementStatus ?? '待结算';
    return task.status;
  }

  int _earningsFor(Set<String> statuses) => tasks
      .where((task) =>
          task.assignedCreatorId == creatorId &&
          task.creatorPayoutCurrency == widget.creatorSettlementCurrency &&
          statuses.contains(task.settlementStatus))
      .fold(0, (total, task) => total + (task.creatorPayoutCents ?? 0));

  @override
  Widget build(BuildContext context) => GateScaffold(
        appBar: AppBar(title: const Text('创作者工作台'), actions: [
          GateRefreshButton(
              loading: gateLoading || taskBusy, onRefresh: _reload),
        ]),
        body: AbsorbPointer(
          absorbing: taskBusy,
          child: gateLoading || gateLoadFailed
              ? GateLoadPanel(failed: gateLoadFailed, onRetry: _reload)
              : ListView(
                  scrollCacheExtent: const ScrollCacheExtent.pixels(600),
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (taskBusy)
                      Semantics(
                        liveRegion: true,
                        child: Text(GateCopy.text(context, 'actionPending')),
                      ),
                    const Text('CREATOR STUDIO',
                        style: TextStyle(
                            color: GateDesign.accent,
                            letterSpacing: 2,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                            '已核验结算币种：${widget.creatorSettlementCurrency}',
                            style: const TextStyle(color: GateDesign.muted))),
                    Card(
                      key: const Key('creator-earnings-summary'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('收益概览',
                                style:
                                    GateDesign.theme().textTheme.titleMedium),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  label: Text(
                                    '托管中 ${_formatMoney(widget.creatorSettlementCurrency, _earningsFor({
                                              '平台托管中'
                                            }))}',
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    '观察期 ${_formatMoney(widget.creatorSettlementCurrency, _earningsFor({
                                              '待结算'
                                            }))}',
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    '结算失败 ${_formatMoney(widget.creatorSettlementCurrency, _earningsFor({
                                              '结算失败'
                                            }))}',
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    '已到账 ${_formatMoney(widget.creatorSettlementCurrency, _earningsFor({
                                              '已结算'
                                            }))}',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text('仅统计当前已核验币种；用户支付金额和其他币种不会混入。'),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              key: const Key(
                                  'open-creator-settlement-statement'),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      CreatorSettlementStatementPage(
                                    orders: tasks,
                                    creatorId: creatorId,
                                    settlementCurrency:
                                        widget.creatorSettlementCurrency,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.receipt_long_outlined),
                              label: const Text('查看结算明细'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final filter in ['all', 'available', 'working'])
                        ChoiceChip(
                            label: Text(GateCopy.text(context, filter)),
                            selected: taskFilter == filter,
                            onSelected: (_) =>
                                setState(() => taskFilter = filter)),
                    ]),
                    const SizedBox(height: 8),
                    if (visibleTasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(children: [
                          const Icon(Icons.work_outline,
                              size: 32, color: GateDesign.muted),
                          const SizedBox(height: 12),
                          Text(
                              taskFilter == 'all'
                                  ? '暂无可申请的合规任务'
                                  : GateCopy.text(context, 'noMatches'),
                              textAlign: TextAlign.center),
                          if (taskFilter != 'all') ...[
                            const SizedBox(height: 8),
                            Text(GateCopy.text(context, 'filterHelp'),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            OutlinedButton(
                                onPressed: () =>
                                    setState(() => taskFilter = 'all'),
                                child: Text(GateCopy.text(context, 'reset'))),
                          ],
                        ]),
                      )
                    else
                      ...visibleTasks.map(
                        (task) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(task.characterName,
                                    style: GateDesign.theme()
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 6),
                                Text(
                                    '${task.sourceType} · ${task.materialCount} 个素材'),
                                const SizedBox(height: 6),
                                Text(task.requestedFeatures.join('、')),
                                if (task.status == '创作者评估中' &&
                                    task.assignmentResponseDueAt != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    '请在 ${task.assignmentResponseDueAt!.replaceFirst('T', ' ').split('.').first} UTC 前提交报价',
                                  ),
                                ],
                                if ({'制作中', '修改中', '待平台质检', '待用户验收'}
                                        .contains(task.status) &&
                                    task.productionDueAt != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    '交付截止：${task.productionDueAt!.split('T').first}',
                                    style: _isPastDate(task.productionDueAt)
                                        ? TextStyle(
                                            color: GateDesign.theme()
                                                .colorScheme
                                                .error,
                                            fontWeight: FontWeight.w700,
                                          )
                                        : null,
                                  ),
                                ],
                                if (task.deliveryExtensionStatus ==
                                    'pending') ...[
                                  const SizedBox(height: 8),
                                  Card(
                                    color: GateDesign.theme()
                                        .colorScheme
                                        .secondaryContainer,
                                    child: ListTile(
                                      leading: const Icon(
                                          Icons.hourglass_top_outlined),
                                      title: const Text('延期尚未生效'),
                                      subtitle: Text(
                                        '平台建议新日期：${task.proposedProductionDueAt?.split('T').first ?? '-'}\n'
                                        '用户尚未明确接受，请仍按上方正式截止日期制作。\n'
                                        '请于 ${task.creatorExtensionAcknowledgementDueAt?.replaceFirst('T', ' ').split('.').first ?? '-'} UTC 前确认已知悉。',
                                      ),
                                    ),
                                  ),
                                ],
                                if (task.deliveryExtensionStatus ==
                                    'escalated') ...[
                                  const SizedBox(height: 8),
                                  Card(
                                    color: GateDesign.theme()
                                        .colorScheme
                                        .errorContainer,
                                    child: ListTile(
                                      leading: const Icon(
                                          Icons.support_agent_outlined),
                                      title: const Text('延期已转平台人工处理'),
                                      subtitle: const Text(
                                        '新日期仍未生效。在平台通知最终结果前，请依原截止日期履约。',
                                      ),
                                    ),
                                  ),
                                ],
                                if (task.deliveryExtensionStatus ==
                                    'accepted') ...[
                                  const SizedBox(height: 8),
                                  const Chip(
                                    avatar:
                                        Icon(Icons.verified_outlined, size: 18),
                                    label: Text('用户已接受延期，上方为新截止日期'),
                                  ),
                                ],
                                if (task.deliveryExtensionStatus ==
                                    'withdrawn') ...[
                                  const SizedBox(height: 8),
                                  const Text('平台已撤回延期方案，继续按原截止日期履约。'),
                                ],
                                if (task.deliveryExtensionVersion >
                                    task
                                        .creatorExtensionAcknowledgedVersion) ...[
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    key:
                                        Key('acknowledge-extension-${task.id}'),
                                    onPressed: () =>
                                        _acknowledgeExtension(task.id),
                                    icon: const Icon(Icons.done_all_outlined),
                                    label: const Text('我已知悉延期状态'),
                                  ),
                                  const Text(
                                    '确认已读不等于同意延期，也不改变约定收入。',
                                    style: TextStyle(
                                        color: GateDesign.muted, fontSize: 12),
                                  ),
                                ] else if (task.deliveryExtensionVersion >
                                    0) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '已知悉本次延期状态'
                                    '${task.creatorExtensionAcknowledgedAt == null ? '' : '：${task.creatorExtensionAcknowledgedAt!.replaceFirst('T', ' ').split('.').first} UTC'}',
                                    style: const TextStyle(
                                        color: GateDesign.muted, fontSize: 12),
                                  ),
                                ],
                                if (task.status == '修改中' &&
                                    task.qualityReview.hasFailure) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '平台质检返工：${task.qualityReview.failureNote ?? '请联系平台补充修复要求'}',
                                    key: Key('quality-repair-note-${task.id}'),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                      '受检内容包：${task.qualityReview.packageVersion ?? '未记录'} · 设备：${task.qualityReview.deviceModel ?? '未记录'}'),
                                  const Text('本次平台质检返工不扣除用户修改次数；提交新预览后需重新质检。'),
                                ],
                                if (task.status == '修改中' &&
                                    task.revisionNotes.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '最新修改意见：${task.revisionNotes.last}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                                if (task.creatorPayoutCents != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    '创作者结算：${_formatMoney(task.creatorPayoutCurrency, task.creatorPayoutCents!)}',
                                  ),
                                ],
                                if (task.settlementStatus == '待结算' &&
                                    task.payoutEligibleAt != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    '预计可结算日期：${task.payoutEligibleAt!.split('T').first}',
                                  ),
                                ],
                                if (task.settlementStatus == '结算失败') ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    '结算失败：${task.lastPayoutFailureCode ?? '需联系平台'}（已尝试 ${task.payoutAttemptCount} 次）',
                                    style: TextStyle(
                                      color:
                                          GateDesign.theme().colorScheme.error,
                                    ),
                                  ),
                                ],
                                if (task.settlementStatus == '已结算' &&
                                    task.payoutReference != null) ...[
                                  const SizedBox(height: 6),
                                  Text('到账流水：${task.payoutReference}'),
                                  if (task.settledAt != null)
                                    Text(
                                        '到账日期：${task.settledAt!.split('T').first}'),
                                ],
                                if (task.deliveryExtensionVersion > 0)
                                  _DeliveryExtensionTimeline(order: task),
                                const SizedBox(height: 12),
                                if (task.status == '待创作者申请')
                                  task.applicantCreatorIds.contains(creatorId)
                                      ? OutlinedButton(
                                          key: Key(
                                              'withdraw-application-${task.id}'),
                                          onPressed: () =>
                                              _withdrawApplication(task.id),
                                          child: const Text('撤回接单申请'),
                                        )
                                      : FilledButton(
                                          onPressed: () => _claim(task.id),
                                          child: Text(
                                            task.withdrawnApplicantCreatorIds
                                                    .contains(creatorId)
                                                ? '重新申请接单'
                                                : '申请接单',
                                          ),
                                        )
                                else if (task.status == '创作者评估中')
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      FilledButton.tonal(
                                        onPressed: () => _openProposal(task),
                                        child: const Text('填写工作量与建议报价'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            _declineAssignedTask(task),
                                        child: const Text('当前无法承接'),
                                      ),
                                    ],
                                  )
                                else if (task.status == '制作中' ||
                                    task.status == '修改中')
                                  FilledButton.tonalIcon(
                                    onPressed: () => _submitPreview(task),
                                    icon: const Icon(Icons.upload_outlined),
                                    label: Text(task.status == '修改中'
                                        ? '提交修改版预览'
                                        : '提交受控预览'),
                                  )
                                else
                                  Chip(label: Text(_creatorStatus(task))),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      );
}

class CreatorSettlementStatementPage extends StatelessWidget {
  const CreatorSettlementStatementPage({
    required this.orders,
    required this.creatorId,
    required this.settlementCurrency,
    super.key,
  });

  final List<CustomizationOrder> orders;
  final String creatorId;
  final String settlementCurrency;

  @override
  Widget build(BuildContext context) {
    final entries = orders
        .where((order) =>
            order.assignedCreatorId == creatorId &&
            order.creatorPayoutCurrency == settlementCurrency &&
            order.creatorPayoutCents != null)
        .toList()
      ..sort((a, b) => b.id.compareTo(a.id));
    final total = entries.fold<int>(
      0,
      (sum, order) => sum + (order.creatorPayoutCents ?? 0),
    );
    final paid = entries
        .where((order) => order.settlementStatus == '已结算')
        .fold<int>(0, (sum, order) => sum + (order.creatorPayoutCents ?? 0));
    return GateScaffold(
      appBar: AppBar(title: const Text('创作者结算明细')),
      body: ListView(
        scrollCacheExtent: const ScrollCacheExtent.pixels(600),
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('约定收入合计：${_formatMoney(settlementCurrency, total)}'),
                  Text('已到账合计：${_formatMoney(settlementCurrency, paid)}'),
                  const SizedBox(height: 8),
                  const Text('本明细仅包含创作者约定收入，不包含用户支付价、平台费用或其他币种。'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Center(child: Text('暂无结算记录'))
          else
            ...entries.map(
              (order) => Card(
                child: GateDetailTile(
                  title: Text(order.characterName),
                  subtitle: Text(
                    '订单 ${order.id}\n'
                    '${order.settlementStatus ?? '尚未进入结算'}'
                    '${order.settledAt == null ? '' : ' · ${order.settledAt!.split('T').first}'}'
                    '${order.payoutReference == null ? '' : '\n流水 ${order.payoutReference}'}',
                  ),
                  trailing: Text(
                    _formatMoney(
                      settlementCurrency,
                      order.creatorPayoutCents ?? 0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CharacterSourcePage extends StatelessWidget {
  const CharacterSourcePage({
    this.orderRepository,
    this.materialPicker,
    super.key,
  });

  final CustomizationOrderRepository? orderRepository;
  final MaterialPicker? materialPicker;

  @override
  Widget build(BuildContext context) => GateScaffold(
        appBar: AppBar(title: Text(GateCopy.text(context, 'customOrderTitle'))),
        body: ListView(
          scrollCacheExtent: const ScrollCacheExtent.pixels(600),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(GateCopy.text(context, 'sourceQuestion'),
                style: GateDesign.theme().textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(GateCopy.text(context, 'sourceIntro')),
            const SizedBox(height: 20),
            _SourceTile(
              icon: Icons.draw_outlined,
              title: GateCopy.text(context, 'sourceOriginalTitle'),
              subtitle: GateCopy.text(context, 'sourceOriginalHelp'),
              onTap: () => _openReview(context, '原创角色'),
            ),
            _SourceTile(
              icon: Icons.toys_outlined,
              title: GateCopy.text(context, 'sourceFigureTitle'),
              subtitle: GateCopy.text(context, 'sourceFigureHelp'),
              onTap: () => _openReview(context, '原创手办'),
            ),
            _SourceTile(
              icon: Icons.business_outlined,
              title: GateCopy.text(context, 'sourceBrandTitle'),
              subtitle: GateCopy.text(context, 'sourceBrandHelp'),
              onTap: () => _openReview(context, '品牌角色'),
            ),
            _SourceTile(
              icon: Icons.sports_esports_outlined,
              title: GateCopy.text(context, 'sourceThirdPartyTitle'),
              subtitle: GateCopy.text(context, 'sourceThirdPartyHelp'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const UnsupportedIpPage(),
                ),
              ),
            ),
          ],
        ),
      );

  void _openReview(BuildContext context, String type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PrototypeReviewPage(
          type: type,
          orderRepository: orderRepository,
          materialPicker: materialPicker,
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Icon(icon),
          title: Text(title),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(subtitle),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}

class PrototypeReviewPage extends StatefulWidget {
  const PrototypeReviewPage({
    required this.type,
    this.orderRepository,
    this.materialPicker,
    this.initialOrder,
    super.key,
  });

  final String type;
  final CustomizationOrderRepository? orderRepository;
  final MaterialPicker? materialPicker;
  final CustomizationOrder? initialOrder;

  @override
  State<PrototypeReviewPage> createState() => _PrototypeReviewPageState();
}

class _PrototypeReviewPageState extends State<PrototypeReviewPage> {
  static const _featureCopyKeys = {
    '待机动作': 'featureIdle',
    '唱跳表演': 'featureDance',
    '音乐联动': 'featureMusic',
    '角色记忆': 'featureMemory',
  };
  static const _regionCopyKeys = {
    'us': 'regionUs',
    'eea': 'regionEea',
    'uk': 'regionUk',
    'jp': 'regionJp',
    'cn_mainland': 'regionCn',
    'hk': 'regionHk',
    'mo': 'regionMo',
    'tw': 'regionTw',
    'asia_other': 'regionAsiaOther',
    'other': 'regionOther',
  };
  late final CustomizationOrderRepository repository =
      widget.orderRepository ?? const LocalCustomizationOrderRepository();
  final characterNameController = TextEditingController();
  var rightsConfirmed = false;
  var privacyConfirmed = false;
  String? marketRegion;
  final requestedFeatures = <String>{};
  final materialFileNames = <String>[];
  bool pickingMaterials = false;
  var submitting = false;

  @override
  void initState() {
    super.initState();
    final initialOrder = widget.initialOrder;
    if (initialOrder == null) return;
    characterNameController.text = initialOrder.characterName;
    requestedFeatures.addAll(initialOrder.requestedFeatures);
    if (initialOrder.marketRegion != 'unspecified') {
      marketRegion = initialOrder.marketRegion;
    }
  }

  int get minimumMaterials => widget.type == '原创手办' ? 3 : 2;

  List<String> get missingFields => [
        if (materialFileNames.length < minimumMaterials) 'needPhotos',
        if (characterNameController.text.trim().isEmpty) 'needName',
        if (requestedFeatures.isEmpty) 'needFeatures',
        if (marketRegion == null) 'needRegion',
        if (!rightsConfirmed) 'needRights',
        if (!privacyConfirmed) 'needPrivacy',
      ];

  String _typeLabel(BuildContext context) => GateCopy.text(
        context,
        switch (widget.type) {
          '原创手办' => 'typeOriginalFigure',
          '原创角色' => 'typeOriginalCharacter',
          '品牌角色' => 'typeBrandCharacter',
          _ => widget.type,
        },
      );

  Future<void> _pickMaterials() async {
    if (!mounted ||
        submitting ||
        pickingMaterials ||
        materialFileNames.length >= 8) {
      return;
    }
    setState(() => pickingMaterials = true);
    try {
      final names = widget.materialPicker != null
          ? await widget.materialPicker!()
          : (await FilePicker.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'],
            ))
              .map((file) => file.name)
              .toList();
      if (!mounted || names.isEmpty) return;
      setState(() {
        materialFileNames.addAll(names.take(8 - materialFileNames.length));
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(GateCopy.text(context, 'photoPickFailed')),
        ));
      }
    } finally {
      if (mounted) setState(() => pickingMaterials = false);
    }
  }

  @override
  void dispose() {
    characterNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!mounted || submitting || pickingMaterials) return;
    final name = characterNameController.text.trim();
    if (name.isEmpty ||
        !rightsConfirmed ||
        !privacyConfirmed ||
        marketRegion == null ||
        requestedFeatures.isEmpty) {
      return;
    }
    if (materialFileNames.length < minimumMaterials) return;
    setState(() => submitting = true);
    try {
      final submitted = await repository.submitReview(
        characterName: name,
        sourceType: widget.type,
        requestedFeatures: requestedFeatures.toList(),
        privacyConsentVersion: 'customization-privacy-${marketRegion!}-v1',
        materialCount: materialFileNames.length,
        marketRegion: marketRegion!,
        resubmissionOfOrderId: widget.initialOrder?.id,
        resubmissionReason: widget.initialOrder?.reviewNote,
      );
      if (!mounted) return;

      if (!submitted) {
        await showGateDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            scrollable: true,
            title: Text(GateCopy.text(context, 'duplicateReviewTitle')),
            content: Text(GateCopy.text(context, 'duplicateReviewBody')),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(GateCopy.text(context, 'gotIt')),
              ),
            ],
          ),
        );
        return;
      }
      final cloudSaved =
          await CloudBusinessIntake.instance.submitCustomizationOrder(
        characterName: name,
        sourceType: widget.type,
        requestedFeatures: requestedFeatures.toList(),
        privacyConsentVersion: 'customization-privacy-${marketRegion!}-v1',
        materialCount: materialFileNames.length,
        marketRegion: marketRegion!,
      );
      if (!cloudSaved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('需求已保存在本机，云端同步失败，请稍后重新提交。'),
        ));
      }
      if (!mounted) return;
      await showGateDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: Text(GateCopy.text(context, 'reviewSubmittedTitle')),
          content: Text(GateCopy.text(context, 'reviewSubmittedBody')),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(GateCopy.text(context, 'gotIt')),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) showGateActionError(context);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => GateScaffold(
        appBar: AppBar(title: Text(GateCopy.text(context, 'freeReviewTitle'))),
        body: ListView(
          scrollCacheExtent: const ScrollCacheExtent.pixels(600),
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.initialOrder != null) ...[
              Card(
                color: GateDesign.theme().colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(GateCopy.text(context, 'supplementReview',
                      {'id': widget.initialOrder!.id})),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Icon(Icons.fact_check_outlined,
                size: 54, color: GateDesign.theme().colorScheme.primary),
            const SizedBox(height: 20),
            Text(GateCopy.text(context, 'reviewHero'),
                style: GateDesign.theme().textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(GateCopy.text(
                context, 'selectedType', {'type': _typeLabel(context)})),
            const SizedBox(height: 10),
            Text(GateCopy.text(context, 'reviewFreeIntro')),
            const SizedBox(height: 20),
            Text(GateCopy.text(context, 'materialsHeading'),
                style: GateDesign.theme().textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(GateCopy.text(
                context,
                widget.type == '原创手办'
                    ? 'originalMaterialHelp'
                    : 'otherMaterialHelp')),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: submitting ||
                      pickingMaterials ||
                      materialFileNames.length >= 8
                  ? null
                  : _pickMaterials,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(pickingMaterials
                  ? GateCopy.text(context, 'pickingPhotos')
                  : materialFileNames.length >= 8
                      ? GateCopy.text(context, 'photoSelectionFull')
                      : materialFileNames.isEmpty
                          ? GateCopy.text(context, 'choosePhotos')
                          : GateCopy.text(context, 'reselectPhotos',
                              {'count': materialFileNames.length})),
            ),
            Text(GateCopy.text(context, 'photoSelectionHelp'),
                style: GateDesign.theme().textTheme.bodySmall),
            if (materialFileNames.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(materialFileNames.join('、')),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (var index = 0;
                            index < materialFileNames.length;
                            index++)
                          InputChip(
                            key: ValueKey('review-material-$index'),
                            label: Text(
                                '${GateCopy.text(context, 'photo')} ${index + 1}'),
                            tooltip: materialFileNames[index],
                            deleteButtonTooltipMessage:
                                '${GateCopy.text(context, 'removePhoto')} ${index + 1}',
                            onDeleted: submitting || pickingMaterials
                                ? null
                                : () => setState(
                                    () => materialFileNames.removeAt(index)),
                          ),
                      ]),
                    ]),
              ),
            const SizedBox(height: 8),
            Text(GateCopy.text(context, 'materialPolicy')),
            const SizedBox(height: 20),
            TextField(
              controller: characterNameController,
              enabled: !submitting,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: GateCopy.text(context, 'characterName'),
                hintText: GateCopy.text(context, 'characterNameHint'),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Text(GateCopy.text(context, 'featuresQuestion'),
                style: GateDesign.theme().textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['待机动作', '唱跳表演', '音乐联动', '角色记忆']
                  .map(
                    (feature) => FilterChip(
                      label: Text(GateCopy.text(
                          context, _featureCopyKeys[feature] ?? feature)),
                      selected: requestedFeatures.contains(feature),
                      onSelected: submitting
                          ? null
                          : (selected) => setState(() {
                                if (selected) {
                                  requestedFeatures.add(feature);
                                } else {
                                  requestedFeatures.remove(feature);
                                }
                              }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              key: const Key('market-region'),
              initialValue: marketRegion,
              decoration: InputDecoration(
                  labelText: GateCopy.text(context, 'regionLabel')),
              hint: Text(GateCopy.text(context, 'regionHint')),
              items: _regionCopyKeys.entries
                  .map((entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(GateCopy.text(context, entry.value))))
                  .toList(),
              onChanged: submitting
                  ? null
                  : (value) => setState(() {
                        marketRegion = value;
                        privacyConfirmed = false;
                      }),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: rightsConfirmed,
              onChanged: submitting
                  ? null
                  : (value) => setState(() => rightsConfirmed = value ?? false),
              title: Text(GateCopy.text(context, 'rightsTitle')),
              subtitle: Text(GateCopy.text(context, 'rightsHelp')),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: privacyConfirmed,
              onChanged: submitting
                  ? null
                  : (value) =>
                      setState(() => privacyConfirmed = value ?? false),
              title: Text(GateCopy.text(context, 'privacyTitle')),
              subtitle: Text(GateCopy.text(context, 'privacyHelp')),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: characterNameController.text.trim().isNotEmpty &&
                      rightsConfirmed &&
                      privacyConfirmed &&
                      marketRegion != null &&
                      requestedFeatures.isNotEmpty &&
                      materialFileNames.length >= minimumMaterials &&
                      !pickingMaterials &&
                      !submitting
                  ? _submit
                  : null,
              child: Text(submitting
                  ? GateCopy.text(context, 'submitting')
                  : GateCopy.text(context, 'submitReview')),
            ),
            if (missingFields.isNotEmpty && !submitting)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Semantics(
                    liveRegion: true,
                    child: Text(
                      '${GateCopy.text(context, 'reviewMissing')} ${missingFields.map((key) => GateCopy.text(context, key, {
                                'count': minimumMaterials
                              })).join(' · ')}',
                      key: const Key('review-missing-fields'),
                      style: const TextStyle(color: GateDesign.muted),
                    )),
              ),
            const SizedBox(height: 8),
            Center(child: Text(GateCopy.text(context, 'noCharge'))),
          ],
        ),
      );
}

class UnsupportedIpPage extends StatelessWidget {
  const UnsupportedIpPage({super.key});

  @override
  Widget build(BuildContext context) => GateScaffold(
        appBar:
            AppBar(title: Text(GateCopy.text(context, 'authorizationTitle'))),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.lock_outline,
                  size: 54, color: GateDesign.theme().colorScheme.primary),
              const SizedBox(height: 20),
              Text(GateCopy.text(context, 'authorizationHero'),
                  style: GateDesign.theme().textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text(GateCopy.text(context, 'authorizationHelp')),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => const IpWishPage()),
                ),
                child: Text(GateCopy.text(context, 'wishAction')),
              ),
            ],
          ),
        ),
      );
}

class IpWishPage extends StatefulWidget {
  const IpWishPage({super.key});

  @override
  State<IpWishPage> createState() => _IpWishPageState();
}

class _IpWishPageState extends State<IpWishPage> {
  final workController = TextEditingController();
  final characterController = TextEditingController();
  final characterFocus = FocusNode();

  @override
  void dispose() {
    workController.dispose();
    characterController.dispose();
    characterFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GateScaffold(
        appBar: AppBar(title: Text(GateCopy.text(context, 'wishTitle'))),
        body: ListView(
          scrollCacheExtent: const ScrollCacheExtent.pixels(600),
          padding: const EdgeInsets.all(20),
          children: [
            Text(GateCopy.text(context, 'wishHero'),
                style: GateDesign.theme().textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(GateCopy.text(context, 'wishHelp')),
            const SizedBox(height: 20),
            TextField(
              controller: workController,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => characterFocus.requestFocus(),
              decoration: InputDecoration(
                  labelText: GateCopy.text(context, 'workName')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: characterController,
              focusNode: characterFocus,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => characterFocus.unfocus(),
              decoration: InputDecoration(
                  labelText: GateCopy.text(context, 'characterName')),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(GateCopy.text(context, 'wishUnavailable'))),
              ),
              child: Text(GateCopy.text(context, 'wishAction')),
            ),
          ],
        ),
      );
}
