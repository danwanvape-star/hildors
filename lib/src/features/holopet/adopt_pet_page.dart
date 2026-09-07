import 'package:flutter/material.dart';

import '../../experience/projection_service.dart';
import 'holopet_page.dart';
import 'holopet_profile.dart';

class AdoptPetPage extends StatefulWidget {
  const AdoptPetPage({required this.projection, super.key});
  final ProjectionService projection;
  @override
  State<AdoptPetPage> createState() => _AdoptPetPageState();
}

class _AdoptPetPageState extends State<AdoptPetPage> {
  var _selected = 0;
  final _pets = const [
    ('霓虹柴犬', '热情 · 勇敢 · 爱玩', Icons.pets, true),
    ('月光布偶猫', '温柔 · 安静 · 好奇', Icons.cruelty_free, false),
    ('星云小狐', '聪明 · 神秘 · 活泼', Icons.auto_awesome, false),
  ];

  Future<void> _adopt() async {
    final pet = _pets[_selected];
    if (!pet.$4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该角色的全息动作包正在制作中')),
      );
      return;
    }
    final controller = TextEditingController(text: '小光');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('领养 ${pet.$1}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('给你的新伙伴起一个名字。之后可以在宠物档案中修改。'),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: true,
            maxLength: 12,
            decoration: const InputDecoration(labelText: '宠物名字'),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('确认领养'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => HoloPetPage(
        projection: widget.projection,
        profile: HoloPetProfile.neonShiba(name: name),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('宠物角色库')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          children: [
            const Text('每个角色都有独立性格和全息动作包。首发角色可立即领养。'),
            const SizedBox(height: 18),
            for (var i = 0; i < _pets.length; i++) ...[
              _PetCard(
                pet: _pets[i],
                selected: _selected == i,
                onTap: () => setState(() => _selected = i),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: FilledButton.icon(
              onPressed: _adopt,
              icon: const Icon(Icons.favorite),
              label: Text('领养 ${_pets[_selected].$1}'),
            ),
          ),
        ),
      );
}

class _PetCard extends StatelessWidget {
  const _PetCard(
      {required this.pet, required this.selected, required this.onTap});
  final (String, String, IconData, bool) pet;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              pet.$1 == '霓虹柴犬'
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/holopet/holopet_master.png',
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(pet.$3, size: 46),
                    ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(pet.$1,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      if (pet.$4) const Chip(label: Text('首发')),
                    ]),
                    const SizedBox(height: 6),
                    Text(pet.$2),
                    const SizedBox(height: 8),
                    Text(
                      pet.$4 ? '4 个动作 · 支持 P20' : '即将开放',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? Theme.of(context).colorScheme.primary : null,
              ),
            ]),
          ),
        ),
      );
}
