import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../localization/localization.dart';

class AppVersionTile extends StatefulWidget {
  const AppVersionTile({super.key});
  @override
  State<AppVersionTile> createState() => _AppVersionTileState();
}

class _AppVersionTileState extends State<AppVersionTile> {
  late final Future<String?> version;
  @override
  void initState() {
    super.initState();
    version = const MethodChannel('hildors/app_info')
        .invokeMethod<String>('version')
        .catchError((Object _) => null);
  }

  @override
  Widget build(BuildContext context) => ListTile(
        leading: const Icon(Icons.info_outline),
        title: Text(context.l10n.appVersionLabel),
        subtitle: FutureBuilder<String?>(
            future: version,
            builder: (context, snapshot) =>
                SelectableText(snapshot.data ?? '—')),
      );
}
