import 'package:flutter/material.dart';

class LanConnectionGuide extends StatelessWidget {
  const LanConnectionGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('局域网连接帮助')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Step(
            number: 1,
            title: '检查手机 Wi-Fi',
            description: '确认手机已连接 P20 热点，或与 P20 连接到同一个路由器。',
          ),
          _Step(
            number: 2,
            title: '确认控制地址',
            description: '设备热点模式默认使用 192.168.4.1，TCP 端口为 8900。',
          ),
          _Step(
            number: 3,
            title: '允许局域网权限',
            description: 'iOS 需要开启局域网权限；Android 需要允许附近设备和网络相关权限。',
          ),
          _Step(
            number: 4,
            title: '重新连接',
            description: '返回控制页点击连接。异常断开后 App 会按 1、2、4、8、15、30 秒自动重试。',
          ),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '手机显示“无互联网连接”并不代表控制失败。只要手机仍保持在 P20 局域网中，'
                'App 就可以继续控制设备。',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.description,
  });

  final int number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(child: Text('$number')),
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
