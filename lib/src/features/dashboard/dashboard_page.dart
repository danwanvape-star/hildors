import 'package:flutter/material.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';

import '../../device/p20_command_session.dart';
import '../../device/p20_device_client.dart';
import '../../experience/projection_service.dart';
import '../community/collection_hub_page.dart';
import '../explore/explore_page.dart';
import '../home/home_page.dart';
import '../profile/profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final P20DeviceClient _client;
  late final P20CommandSession _session;
  late final P20ProjectionService _projection;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _client = P20DeviceClient(modernProtocol: true);
    _session = P20CommandSession(_client);
    _projection = P20ProjectionService(_client, _session);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        client: _client,
        session: _session,
        projection: _projection,
      ),
      CollectionHubPage(),
      ExplorePage(projection: _projection),
      ProfilePage(client: _client, session: _session),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Color(0xFA090E15),
          border: Border(
            top: BorderSide(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.8),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 28,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: context.l10n.coreHome,
            ),
            NavigationDestination(
              icon: Icon(Icons.collections_bookmark_outlined),
              selectedIcon: Icon(Icons.collections_bookmark),
              label: context.l10n.coreCollection,
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: context.l10n.coreExplore,
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: context.l10n.coreProfile,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _session.dispose();
    _client.dispose();
    super.dispose();
  }
}
