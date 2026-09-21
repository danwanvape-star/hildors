import 'dart:async';
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
  const DashboardPage({super.key, this.autoConnect = true});
  final bool autoConnect;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
  Timer? _autoTimer;
  bool _autoConnecting = false;
  Future<void> _autoConnect() async {
    if (!mounted ||
        _autoConnecting ||
        _client.connectionState != DeviceConnectionState.disconnected) { return; }
    _autoConnecting = true;
    try {
      await _client.connect();
    } catch (_) {
      /* Connection state remains visible; retry while foregrounded. */
    } finally {
      _autoConnecting = false;
    }
  }

  void _startAutoConnect() {
    if (!widget.autoConnect) return;
    _autoTimer?.cancel();
    unawaited(_autoConnect());
    _autoTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _autoConnect());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startAutoConnect();
    } else {
      _autoTimer?.cancel();
    }
  }

  late final P20DeviceClient _client;
  late final P20CommandSession _session;
  late final P20ProjectionService _projection;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _client = P20DeviceClient(modernProtocol: true, verifyOnConnect: true);
    _session = P20CommandSession(_client);
    _projection = P20ProjectionService(_client, _session);
    WidgetsBinding.instance.addObserver(this);
    _startAutoConnect();
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
    WidgetsBinding.instance.removeObserver(this);
    _autoTimer?.cancel();
    _session.dispose();
    _client.dispose();
    super.dispose();
  }
}
