import 'package:flutter/material.dart';

class CustomPetPage extends StatefulWidget {
  const CustomPetPage({super.key});
  @override
  State<CustomPetPage> createState() => _CustomPetPageState();
}

class _CustomPetPageState extends State<CustomPetPage> {
  final _name = TextEditingController();
  final _breed = TextEditingController();

  void _uploadUnavailable() => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('照片上传即将接入'),
          content: const Text('当前尚未配置安全上传与订单后端，因此不会模拟上传成功。接口接入后，这里将打开相册或相机。'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('知道了'))
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('定制我的宠物')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text('建立真实宠物档案', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('建议使用自然光、无遮挡、无滤镜照片。多角度素材能显著提高形象一致性。'),
          const SizedBox(height: 20),
          TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: '宠物名字')),
          const SizedBox(height: 12),
          TextField(
              controller: _breed,
              decoration: const InputDecoration(labelText: '品种（选填）')),
          const SizedBox(height: 24),
          Text('上传照片', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          const Text('至少提交正面、左侧、右侧和全身照。'),
          const SizedBox(height: 12),
          GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.35,
              children: [
                _PhotoSlot(
                    label: '正面照', mandatory: true, onTap: _uploadUnavailable),
                _PhotoSlot(
                    label: '左侧照', mandatory: true, onTap: _uploadUnavailable),
                _PhotoSlot(
                    label: '右侧照', mandatory: true, onTap: _uploadUnavailable),
                _PhotoSlot(
                    label: '全身照', mandatory: true, onTap: _uploadUnavailable),
              ]),
          const SizedBox(height: 24),
          const _ProcessStep(
              index: 1, title: 'AI 形象初稿', detail: '根据多角度照片建立统一角色形象'),
          const _ProcessStep(index: 2, title: '人工质检', detail: '检查花纹、体型和关键识别特征'),
          const _ProcessStep(
              index: 3, title: '用户确认', detail: '确认形象后再生成全息动作，减少返工'),
          const _ProcessStep(
              index: 4, title: '动作包交付', detail: '输出待机、行走、转圈、喂食、玩耍和睡觉'),
          const SizedBox(height: 16),
          FilledButton.icon(
              onPressed: _uploadUnavailable,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('提交定制资料')),
        ]),
      );

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    super.dispose();
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot(
      {required this.label, required this.mandatory, required this.onTap});
  final String label;
  final bool mandatory;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton(
      onPressed: onTap,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.add_photo_alternate_outlined),
        const SizedBox(height: 8),
        Text('$label${mandatory ? ' *' : ''}')
      ]));
}

class _ProcessStep extends StatelessWidget {
  const _ProcessStep(
      {required this.index, required this.title, required this.detail});
  final int index;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text('$index')),
      title: Text(title),
      subtitle: Text(detail));
}
