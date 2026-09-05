import 'package:flutter/material.dart';

class PlaybackModeGuide extends StatelessWidget {
  const PlaybackModeGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('播放模式说明')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _GuideCard(
            icon: Icons.video_library_outlined,
            title: '本机播放',
            description: 'P20 播放设备内部视频，声音来自视频文件。'
                '适合开机自动播放、循环展示和固定内容播放。',
          ),
          SizedBox(height: 12),
          _GuideCard(
            icon: Icons.speaker_outlined,
            title: '蓝牙音响',
            description: '手机、电脑等外接设备通过蓝牙向 P20 输入声音，'
                'P20 同时播放为蓝牙状态配置的全息视频。',
          ),
          SizedBox(height: 20),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '注意：Hildors App 始终通过 Wi-Fi 局域网控制 P20。'
                '“局域网控制已连接”和“蓝牙音源已连接”是两个独立状态。',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
