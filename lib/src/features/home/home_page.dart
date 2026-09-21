import 'dart:async';

import 'package:flutter/material.dart';
import '../../config/launch_config.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';
import '../../device/p20_command_session.dart';
import '../../device/p20_device_client.dart';
import '../../experience/projection_service.dart';
import '../control/control_page.dart';
import '../customization/character_gate_prototype_pages.dart';
import '../video/device_playlist_draft.dart';
import '../video/playlist_management_page.dart';
import '../../theme/hildors_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.client,
    required this.session,
    required this.projection,
    super.key,
  });

  final P20DeviceClient client;
  final P20CommandSession session;
  final ProjectionService projection;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DeviceConnectionState _connection;
  StreamSubscription<DeviceConnectionState>? _subscription;
  String? _error;

  @override
  void initState() {
    super.initState();
    _connection = widget.client.connectionState;
    _subscription = widget.client.connectionStates.listen((state) {
      if (mounted) setState(() => _connection = state);
    });
  }

  bool get _busy =>
      _connection == DeviceConnectionState.connecting ||
      _connection == DeviceConnectionState.reconnecting;

  Future<void> _connect() async {
    setState(() => _error = null);
    try {
      await widget.client.connect();
    } catch (error, stackTrace) {
      debugPrint('Device connection failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() => _error = 'connection');
      }
    }
  }

  void _openControl() => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ControlPage(client: widget.client),
        ),
      );

  void _openPlaylist(DevicePlaylistKind kind) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlaylistManagementPage(
            client: widget.client,
            session: widget.session,
            initialKind: kind,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          toolbarHeight:
              56 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.5),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/hildors_logo.jpg',
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HILDORS'),
                  Text(
                    context.l10n.coreCharacterPortal,
                    style: TextStyle(
                      color: HildorsColors.textSecondary,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: context.l10n.coreDeviceControl,
              onPressed: _openControl,
              icon: Icon(Icons.tune),
            ),
          ],
        ),
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.9, -0.85),
              radius: 1.15,
              colors: [
                Color(0x3328688C),
                Color(0x110A3438),
                Colors.transparent
              ],
            ),
          ),
          child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Column(
                            children: [
                              _DeviceCard(
                                connection: _connection,
                                busy: _busy,
                                error: _error,
                                onConnect: _connect,
                                onControl: _openControl,
                              ),
                              SizedBox(height: 10),
                              _NowPlayingCard(
                                height: (constraints.maxHeight - 258)
                                        .clamp(286.0, 600.0) *
                                    MediaQuery.textScalerOf(context)
                                        .scale(1)
                                        .clamp(1.0, 2.5),
                                connected: _connection ==
                                    DeviceConnectionState.connected,
                                onOpenStartup: () =>
                                    _openPlaylist(DevicePlaylistKind.startup),
                                onOpenBluetooth: () =>
                                    _openPlaylist(DevicePlaylistKind.bluetooth),
                              ),
                              SizedBox(height: 10),
                              if (!LaunchConfig.usFree)
                                const _CustomizationShortcut(),
                            ],
                          ))))),
        ),
      );

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class _CustomizationShortcut extends StatelessWidget {
  const _CustomizationShortcut();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123C3D), Color(0xFF111B2C), Color(0xFF241A35)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Color(0x3327E7D4), blurRadius: 26, offset: Offset(0, 10)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: colors.secondary.withValues(alpha: 0.28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => CharacterSourcePage()),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14, 10, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.secondary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.auto_awesome, color: colors.secondary),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.coreCharacterPortal,
                        style: TextStyle(
                          color: HildorsColors.teal,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        context.l10n.coreCustomCharacter,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NowPlayingCard extends StatelessWidget {
  const _NowPlayingCard({
    required this.height,
    required this.connected,
    required this.onOpenStartup,
    required this.onOpenBluetooth,
  });

  final bool connected;
  final double height;
  final VoidCallback onOpenStartup;
  final VoidCallback onOpenBluetooth;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: BoxConstraints(minHeight: height),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF090E13),
        image: const DecorationImage(
          image: AssetImage('assets/images/p20_product_showcase.jpg'),
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
          opacity: 0.35,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.secondary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.corePlaylists,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(context.l10n.corePlaylistSubtitle,
              style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          _StatusPill(connected: connected),
          const SizedBox(height: 16),
          _PlaylistShortcut(
            icon: Icons.wb_sunny_outlined,
            title: context.l10n.coreDisplay,
            subtitle: context.l10n.coreStartupSubtitle,
            onTap: onOpenStartup,
          ),
          const SizedBox(height: 10),
          _PlaylistShortcut(
            icon: Icons.graphic_eq,
            title: context.l10n.coreMusic,
            subtitle: context.l10n.coreBluetoothSubtitle,
            onTap: onOpenBluetooth,
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.connected});
  final bool connected;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: connected
              ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(connected ? Icons.wifi : Icons.wifi_off, size: 14),
          SizedBox(width: 5),
          Flexible(
              child: Text(connected
                  ? context.l10n.coreOnline
                  : context.l10n.coreDisconnected)),
        ]),
      );
}

class _PlaylistShortcut extends StatelessWidget {
  const _PlaylistShortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Color(0xE61A2229),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      size: 28,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right, size: 28),
                ],
              ),
            ),
          ),
        ),
      );
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard(
      {required this.connection,
      required this.busy,
      required this.error,
      required this.onConnect,
      required this.onControl});

  final DeviceConnectionState connection;
  final bool busy;
  final String? error;
  final VoidCallback onConnect;
  final VoidCallback onControl;

  @override
  Widget build(BuildContext context) {
    final connected = connection == DeviceConnectionState.connected;
    final status = switch (connection) {
      DeviceConnectionState.connected => context.l10n.coreDeviceConnected,
      DeviceConnectionState.connecting => context.l10n.coreConnecting,
      DeviceConnectionState.reconnecting => context.l10n.coreReconnecting,
      DeviceConnectionState.disconnected => context.l10n.coreDeviceDisconnected,
    };
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(connected ? Icons.wifi : Icons.wifi_off,
                    color: connected
                        ? Theme.of(context).colorScheme.primary
                        : null),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(status,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(context.l10n.coreLanControl),
                    ],
                  ),
                ),
              ],
            ),
            if (error != null) ...[
              SizedBox(height: 10),
              Text(context.l10n.coreConnectionFailed,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: busy ? null : (connected ? onControl : onConnect),
                  icon: busy
                      ? SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(connected ? Icons.tune : Icons.link),
                  label: Text(connected
                      ? context.l10n.coreDeviceControl
                      : context.l10n.coreConnectP20),
                ),
                if (!connected) ...[
                  OutlinedButton(
                      onPressed: onControl,
                      child: Text(context.l10n.coreConnectionSettings)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
