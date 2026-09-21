import 'package:flutter/material.dart';
import '../../config/launch_config.dart';
import '../../localization/localization.dart';
import '../community/creator_content_page.dart';
import '../community/creator_content_repository.dart';
import 'cloud_orders_page.dart';

class CreatorWorkbenchPage extends StatelessWidget {
  const CreatorWorkbenchPage({super.key, this.repository});
  final CreatorContentRepository? repository;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.creatorWorkbench)),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text(context.l10n.creatorOriginal, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(LaunchConfig.usFree ? context.l10n.creatorFreeNote : context.l10n.creatorPublishingNote),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.upload_file),
            label: Text(context.l10n.creatorSubmissions),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => CreatorContentPage(
                  repository: repository ??
                      RemoteCreatorContentRepository(
                          CloudCreatorContentTransport())),
            )),
          ),
          const SizedBox(height: 24),
          if (LaunchConfig.customizationOrders) Card(
              child: ListTile(
            leading: const Icon(Icons.assignment_outlined),
            title: Text(context.l10n.creatorTasks),
            subtitle: Text(context.l10n.creatorTasksNote),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const CloudOrdersPage(creator: true))),
          )),
        ]),
      );
}
