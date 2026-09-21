import 'package:flutter/material.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';

class LanConnectionGuide extends StatelessWidget {
  const LanConnectionGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.coreLanHelp)),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          _Step(
            number: 1,
            title: context.l10n.coreCheckWifi,
            description: context.l10n.coreCheckWifiBody,
          ),
          _Step(
            number: 2,
            title: context.l10n.coreCheckAddress,
            description: context.l10n.coreCheckAddressBody,
          ),
          _Step(
            number: 3,
            title: context.l10n.coreLanPermission,
            description: context.l10n.coreLanPermissionBody,
          ),
          _Step(
            number: 4,
            title: context.l10n.coreReconnect,
            description: context.l10n.coreReconnectBody,
          ),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                context.l10n.coreOfflineWifiHelp,
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
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(child: Text('$number')),
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
