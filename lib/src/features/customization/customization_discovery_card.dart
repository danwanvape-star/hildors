import 'package:flutter/material.dart';

import 'character_gate_prototype_pages.dart';
import 'character_gate_ui.dart';

class CustomizationDiscoveryCard extends StatelessWidget {
  const CustomizationDiscoveryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = GateDesign.theme().colorScheme;
    return Theme(
        data: GateDesign.theme(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF06383A), Color(0xFF101B32), Color(0xFF281630)],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CharacterSourcePage(),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CHARACTER PORTAL',
                              style: TextStyle(
                                  color: GateDesign.accent,
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          Text(
                            '专属定制',
                            style: GateDesign.theme().textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          const Text('定制你的专属全息角色，先免费预审，再确认报价。'),
                          const SizedBox(height: 14),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('开始定制',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/content_thumbnails/celestial_mage.jpg',
                        width: 82,
                        height: 116,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
