import '../../localization/localization.dart';
import 'package:flutter/material.dart';
import '../video/character_package_picker.dart';
import 'collection_catalog_page.dart';

class CollectionHubPage extends StatefulWidget {
  const CollectionHubPage({super.key});
  @override
  State<CollectionHubPage> createState() => _CollectionHubPageState();
}

class _CollectionHubPageState extends State<CollectionHubPage> {
  int _selected = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(context.l10n.catalogCollection),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(52),
              child: Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: 0, label: Text(context.l10n.catalogLibrary)),
                      ButtonSegment(value: 1, label: Text(context.l10n.catalogMyCharacters)),
                    ],
                    selected: {_selected},
                    onSelectionChanged: (value) =>
                        setState(() => _selected = value.single),
                  )),
            )),
        // Recreate on tab changes so newly claimed characters are reloaded.
        body: switch (_selected) {
          0 => CollectionCatalogPage(),
          _ => CharacterPackagePicker(picking: false, embedded: true),
        },
      );
}
