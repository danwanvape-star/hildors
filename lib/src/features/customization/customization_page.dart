import 'package:flutter/material.dart';

class CustomizationPage extends StatelessWidget {
  const CustomizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('定制中心')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primaryContainer, colors.tertiaryContainer],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome, color: colors.onPrimaryContainer),
                const SizedBox(height: 18),
                Text('把照片变成专属全息内容',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text('提交照片和动作需求，由内容团队完成制作后交付到素材库。'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _JourneyStep(
              index: 1,
              icon: Icons.add_photo_alternate_outlined,
              title: '上传照片',
              detail: '人物、宠物或商品正面清晰照片'),
          const _JourneyStep(
              index: 2,
              icon: Icons.edit_note,
              title: '填写需求',
              detail: '选择风格、用途并描述动作和表情'),
          const _JourneyStep(
              index: 3,
              icon: Icons.hourglass_top,
              title: '等待制作',
              detail: '订单与上传接口接入后开放提交'),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('定制服务接口尚未接入，当前仅展示流程。')),
            ),
            icon: const Icon(Icons.rocket_launch_outlined),
            label: const Text('了解定制流程'),
          ),
        ],
      ),
    );
  }
}

class _JourneyStep extends StatelessWidget {
  const _JourneyStep(
      {required this.index,
      required this.icon,
      required this.title,
      required this.detail});

  final int index;
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: CircleAvatar(child: Text('$index')),
          title: Text(title),
          subtitle: Text(detail),
          trailing: Icon(icon),
        ),
      );
}
