import 'package:flutter/material.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';

class PlaybackModeGuide extends StatelessWidget {
  const PlaybackModeGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.corePlaybackGuide)),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          _GuideCard(
            icon: Icons.video_library_outlined,
            title: context.l10n.coreLocalPlayback,
            description: context.l10n.coreLocalPlaybackBody,
          ),
          SizedBox(height: 12),
          _GuideCard(
            icon: Icons.speaker_outlined,
            title: context.l10n.coreBluetoothSpeaker,
            description: context.l10n.coreBluetoothSpeakerBody,
          ),
          SizedBox(height: 20),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                context.l10n.coreSeparateConnections,
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
        padding: EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 6),
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
