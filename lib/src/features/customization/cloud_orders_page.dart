import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'cloud_business_intake.dart';
import 'cloud_order_submission.dart';

const _statuses = {
  'free_review': '待审核',
  'needs_info': '需补充资料',
  'approved_for_quote': '待报价',
  'quoted': '待确认报价',
  'in_production': '制作中',
  'quality_review': '平台质检中',
  'user_acceptance': '待验收',
  'delivered': '已交付',
  'rejected': '未通过',
  'withdrawn': '已撤回',
};

class CloudOrdersPage extends StatefulWidget {
  const CloudOrdersPage(
      {this.creator = false, this.request, this.materialRequest, super.key});
  final bool creator;
  final CloudOrderRequest? request;
  final Future<Uint8List> Function(String path)? materialRequest;
  @override
  State<CloudOrdersPage> createState() => _CloudOrdersPageState();
}

class _CloudOrdersPageState extends State<CloudOrdersPage> {
  List<Map<String, dynamic>> items = [];
  bool loading = true, busy = false;
  String? error;
  final pendingMaterials = <String, List<CloudOrderMaterial>>{};
  CloudOrderRequest get request =>
      widget.request ?? CloudBusinessIntake.instance.orderRequest;
  String get root =>
      widget.creator ? '/v1/me/creator-tasks' : '/v1/me/customization-orders';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final value = await request('GET', root);
      final result = (value['items'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (mounted) setState(() => items = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _action(Map<String, dynamic> order, String action,
      {Map<String, dynamic>? fields, String note = ''}) async {
    setState(() => busy = true);
    try {
      await request(
          'POST', '$root/${order['id']}${widget.creator ? '' : '/action'}',
          document: {
            'version': order['version'],
            'action': action,
            'note': note,
            if (fields != null) 'fields': fields,
          });
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _form(Map<String, dynamic> order, String action) async {
    final quote = action == 'quote';
    final amount = TextEditingController(),
        days = TextEditingController(),
        note = TextEditingController();
    var currency = 'CNY';
    final formKey = GlobalKey<FormState>();
    final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(quote
                  ? '提交报价'
                  : action == 'submit'
                      ? '提交成品'
                      : action == 'decline'
                          ? '谢绝任务'
                          : '申请修改'),
              content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    if (quote) ...[
                      TextFormField(
                          controller: amount,
                          decoration: const InputDecoration(labelText: '报价金额'),
                          keyboardType: TextInputType.number,
                          validator: (v) => (double.tryParse(v ?? '') ?? 0) >
                                      0 &&
                                  (double.tryParse(v ?? '')?.isFinite ?? false)
                              ? null
                              : '请输入有效金额'),
                      DropdownButtonFormField<String>(
                          initialValue: currency,
                          items: ['CNY', 'USD']
                              .map((v) =>
                                  DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) => currency = v!),
                      TextFormField(
                          controller: days,
                          decoration: const InputDecoration(labelText: '交付天数'),
                          keyboardType: TextInputType.number,
                          validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0
                              ? null
                              : '请输入正整数天数'),
                    ],
                    TextFormField(
                        controller: note,
                        maxLines: 3,
                        maxLength: 1000,
                        decoration: InputDecoration(
                            labelText: action == 'submit'
                                ? '成品链接或交付文件引用'
                                : quote
                                    ? '报价说明（可选）'
                                    : action == 'decline'
                                        ? '谢绝原因'
                                        : '修改要求'),
                        validator: (v) =>
                            quote || (v?.trim().isNotEmpty ?? false)
                                ? null
                                : '请填写内容'),
                  ]))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消')),
                FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context, true);
                      }
                    },
                    child: const Text('提交'))
              ],
            ));
    if (accepted == true && mounted) {
      await _action(order, action,
          note: note.text.trim(),
          fields: quote
              ? {
                  'quoteAmount': double.parse(amount.text),
                  'currency': currency,
                  'deliveryDays': int.parse(days.text)
                }
              : action == 'submit'
                  ? {'deliverableReference': note.text.trim()}
                  : null);
    }
    // Dialog route may still be animating out; controllers are released afterward.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    amount.dispose();
    days.dispose();
    note.dispose();
  }

  Future<void> _material(Map<String, dynamic> order, Map material) async {
    setState(() => busy = true);
    try {
      await showDialog<void>(
        context: context,
        builder: (context) => _OrderMaterialDialog(
          name: '${material['name'] ?? '素材'}',
          path: '$root/${order['id']}/materials/${material['id']}',
          load: widget.materialRequest ??
              CloudBusinessIntake.instance.orderMaterial,
        ),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _upload(Map<String, dynamic> order) async {
    setState(() => busy = true);
    final id = order['id'] as String;
    try {
      var materials = pendingMaterials[id];
      if (materials == null) {
        final existing = order['materials'] is List
            ? (order['materials'] as List).length
            : 0;
        if (existing >= 8) throw const FormatException('最多上传 8 张素材');
        final files = await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif']);
        if (files.isEmpty) return;
        materials = <CloudOrderMaterial>[];
        for (final file in files.take(8 - existing)) {
          if (await file.length() > 8 * 1024 * 1024) {
            throw const FormatException('每张图片不能超过 8 MB');
          }
          final material = CloudOrderMaterial(
              name: file.name, bytes: await file.readAsBytes());
          material.validate();
          materials.add(material);
        }
        pendingMaterials[id] = materials;
      }
      while (materials.isNotEmpty) {
        final material = materials.first;
        final query =
            Uri(queryParameters: {'name': material.name, 'slot': material.slot})
                .query;
        await request('POST', '$root/$id/materials?$query',
            bytes: material.bytes, contentType: material.contentType);
        materials.removeAt(0);
      }
      pendingMaterials.remove(id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('素材上传未完成：$e。请点击重试上传。')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _remove(Map<String, dynamic> order, Map material) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('移除素材？'),
              content: Text('移除 ${material['name'] ?? '此素材'} 后可重新上传。'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('移除'))
              ],
            ));
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      await request('DELETE',
          '$root/${order['id']}/materials/${material['id']}?version=${order['version']}');
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _card(Map<String, dynamic> order) {
    final status = order['status'];
    final workflow =
        order['workflow'] is Map ? order['workflow'] as Map : const {};
    final assigned = order['assignedCreatorId'] != null;
    Widget button(String label, VoidCallback action) =>
        OutlinedButton(onPressed: busy ? null : action, child: Text(label));
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${order['characterName']}',
                  style: Theme.of(context).textTheme.titleMedium),
              Text('${_statuses[status] ?? status} · ${order['id']}'),
              if (order['sourceType'] != null) Text('${order['sourceType']}'),
              if (order['requestedFeatures'] is List)
                Text((order['requestedFeatures'] as List).join(' · ')),
              if ('${order['requirements'] ?? ''}'.isNotEmpty)
                Text('${order['requirements']}'),
              if ('${order['adminNote'] ?? ''}'.isNotEmpty)
                Text('平台备注：${order['adminNote']}'),
              if (order['assignedCreatorName'] != null)
                Text('创作者：${order['assignedCreatorName']}'),
              if (workflow['quoteAmount'] != null)
                Text(
                    '报价：${workflow['quoteAmount']} ${workflow['currency']} · ${workflow['deliveryDays']} 天'),
              if (widget.creator && workflow['deliverableReference'] != null)
                SelectableText('成品：${workflow['deliverableReference']}'),
              if (!widget.creator && status == 'user_acceptance')
                const Text('平台已完成质检，请确认设备端交付效果后验收。'),
              if (order['materials'] is List && (!widget.creator || assigned))
                Wrap(spacing: 8, children: [
                  for (final material in order['materials'] as List)
                    if (material is Map)
                      button('查看素材 ${material['name'] ?? ''}',
                          () => _material(order, material)),
                ]),
              if (widget.creator &&
                  assigned &&
                  order['workflowHistory'] is List)
                for (final event in order['workflowHistory'] as List)
                  if (event is Map &&
                      '${event['note'] ?? ''}'.trim().isNotEmpty)
                    Text('${event['at'] ?? ''} · ${event['note']}'),
              if (!widget.creator &&
                  ['free_review', 'needs_info', 'approved_for_quote']
                      .contains(status) &&
                  order['materials'] is List)
                Wrap(spacing: 8, children: [
                  for (final material in order['materials'] as List)
                    if (material is Map)
                      button('移除素材 ${material['name'] ?? ''}',
                          () => _remove(order, material))
                ]),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (widget.creator &&
                    !assigned &&
                    order['dispatchMode'] == 'applications' &&
                    order['dispatchState'] == 'open')
                  button('申请任务', () => _action(order, 'apply')),
                if (widget.creator &&
                    assigned &&
                    status == 'approved_for_quote') ...[
                  button('提交报价', () => _form(order, 'quote')),
                  button('谢绝任务', () => _form(order, 'decline')),
                ],
                if (widget.creator && assigned && status == 'in_production')
                  button('提交成品', () => _form(order, 'submit')),
                if (!widget.creator && status == 'quoted')
                  button('接受报价', () => _action(order, 'accept_quote')),
                if (!widget.creator &&
                    ['free_review', 'needs_info', 'approved_for_quote']
                        .contains(status))
                  button(
                      pendingMaterials.containsKey(order['id'])
                          ? '重试上传'
                          : '补充素材',
                      () => _upload(order)),
                if (!widget.creator && status == 'user_acceptance') ...[
                  button('确认验收', () => _action(order, 'accept_delivery')),
                  button('申请修改', () => _form(order, 'request_revision')),
                ],
              ]),
            ])));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar:
            AppBar(title: Text(widget.creator ? '创作者任务' : '定制订单'), actions: [
          IconButton(
              onPressed: loading || busy ? null : _load,
              icon: const Icon(Icons.refresh))
        ]),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(error!),
                    TextButton(onPressed: _load, child: const Text('重试'))
                  ]))
                : items.isEmpty
                    ? const Center(child: Text('暂无订单或任务'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                            padding: const EdgeInsets.all(12),
                            children: items.map(_card).toList())),
      );
}

class _OrderMaterialDialog extends StatefulWidget {
  const _OrderMaterialDialog(
      {required this.name, required this.path, required this.load});
  final String name, path;
  final Future<Uint8List> Function(String) load;

  @override
  State<_OrderMaterialDialog> createState() => _OrderMaterialDialogState();
}

class _OrderMaterialDialogState extends State<_OrderMaterialDialog> {
  bool original = false;
  late Future<Uint8List> image;

  @override
  void initState() {
    super.initState();
    image = _fetch();
  }

  Future<Uint8List> _fetch() async =>
      widget.load(original ? widget.path : '${widget.path}?variant=preview');

  void _retry() => setState(() {
        image = _fetch();
      });

  Widget _failure(String message) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(message, textAlign: TextAlign.center),
        TextButton(onPressed: _retry, child: const Text('重试')),
      ]));

  @override
  Widget build(BuildContext context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.name, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Flexible(
                child: SizedBox(
              width: 600,
              height: MediaQuery.sizeOf(context).height * .6,
              child: FutureBuilder<Uint8List>(
                  future: image,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                          child: CircularProgressIndicator(
                              semanticsLabel: '素材加载中'));
                    }
                    if (snapshot.hasError) return _failure('素材加载失败，请重试');
                    return InteractiveViewer(
                        child: Image.memory(snapshot.data!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, error, stack) =>
                                _failure('设备无法预览此图片格式')));
                  }),
            )),
            Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
              if (!original)
                TextButton(
                    onPressed: () => setState(() {
                          original = true;
                          image = _fetch();
                        }),
                    child: const Text('查看原图')),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭')),
            ]),
          ]),
        ),
      );
}
