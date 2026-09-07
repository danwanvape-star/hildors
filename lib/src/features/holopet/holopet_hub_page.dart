import 'package:flutter/material.dart';

import '../../experience/projection_service.dart';
import 'adopt_pet_page.dart';
import 'custom_pet_page.dart';

class HoloPetHubPage extends StatelessWidget {
  const HoloPetHubPage({required this.projection, super.key});
  final ProjectionService projection;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('HOLOPET')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text('遇见你的全息伙伴', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('领养一个新伙伴，或把你熟悉的它带进全息世界。'),
            const SizedBox(height: 24),
            _PathCard(
              tag: '立即体验',
              icon: Icons.pets,
              title: '领养全息宠物',
              subtitle: '从官方角色库选择伙伴，立即开始养成与 P20 全息互动。',
              colors: const [Color(0xFF073B38), Color(0xFF112A46)],
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => AdoptPetPage(projection: projection),
              )),
            ),
            const SizedBox(height: 16),
            _PathCard(
              tag: '专属定制',
              icon: Icons.add_a_photo_outlined,
              title: '定制我的宠物',
              subtitle: '上传真实宠物的多角度照片，制作专属形象与动作包。',
              colors: const [Color(0xFF38204D), Color(0xFF18223D)],
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const CustomPetPage(),
              )),
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(children: [
                  Icon(Icons.shield_outlined),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('两种方式共享同一套喂养、成长和全息互动系统。'),
                  ),
                ]),
              ),
            ),
          ],
        ),
      );
}

class _PathCard extends StatelessWidget {
  const _PathCard(
      {required this.tag,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.colors,
      required this.onTap});
  final String tag;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(24),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(radius: 26, child: Icon(icon)),
                const Spacer(),
                Chip(label: Text(tag)),
              ]),
              const SizedBox(height: 28),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(subtitle),
              const SizedBox(height: 18),
              const Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('开始'),
                SizedBox(width: 5),
                Icon(Icons.arrow_forward),
              ]),
            ]),
          ),
        ),
      );
}
