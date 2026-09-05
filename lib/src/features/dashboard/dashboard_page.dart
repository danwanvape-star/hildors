import 'package:flutter/material.dart';

import '../../device/p20_command_session.dart';
import '../../device/p20_device_client.dart';
import '../../experience/projection_service.dart';
import '../community/community_page.dart';
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
    _client = P20DeviceClient();
    _session = P20CommandSession(_client);
    _projection = P20ProjectionService(_client, _session);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(client: _client, projection: _projection),
      ExplorePage(projection: _projection),
      const CommunityPage(),
      ProfilePage(client: _client, session: _session),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: '探索',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt),
            label: '社区',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
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
