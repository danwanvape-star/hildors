import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';

import '../../device/p20_command_session.dart';
import '../../device/p20_device_client.dart';
import '../../theme/hildors_theme.dart';
import 'package:hildors_cockpit/src/localization/language_settings_tile.dart';
import 'lan_connection_guide.dart';
import 'playback_mode_guide.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({required this.client, required this.session, super.key});

  final P20DeviceClient client;
  final P20CommandSession session;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  StreamSubscription<DeviceConnectionState>? _connectionSubscription;
  DeviceConnectionState _connection = DeviceConnectionState.disconnected;
  P20PlayMode? _playMode;
  String? _version;
  String? _message;
  bool _busy = false;

  bool get _connected => _connection == DeviceConnectionState.connected;

  @override
  void initState() {
    super.initState();
    _connection = widget.client.connectionState;
    _connectionSubscription = widget.client.connectionStates.listen((value) {
      if (mounted) {
        setState(() {
          _connection = value;
          if (value != DeviceConnectionState.connected) {
            _playMode = null;
            _version = null;
          }
        });
      }
    });
  }

  Future<void> _load() async {
    if (!_connected || _busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final mode = await widget.session.queryPlayMode();
      final version = await widget.session.queryVersionSummary();
      if (mounted) {
        setState(() {
          _playMode = mode;
          _version = version;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'read');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changePlayMode(P20PlayMode mode) async {
    if (!_connected || _busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.session.setPlayMode(mode);
      if (mounted) setState(() => _playMode = mode);
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'setting');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          toolbarHeight:
              56 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.5),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.coreDeviceSettings),
              Text(
                context.l10n.coreSystemLabel,
                style: TextStyle(
                  color: HildorsColors.teal,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.9, -0.85),
              radius: 1.1,
              colors: [Color(0x33244B67), HildorsColors.background],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              const LanguageSettingsTile(),
              _ConnectionPanel(
                state: _connection,
                busy: _busy,
                onRead: _connected && !_busy ? _load : null,
              ),
              if (_message != null) ...[
                SizedBox(height: 10),
                _InlineMessage(
                    message: _message == 'read'
                        ? context.l10n.coreReadFailed
                        : context.l10n.coreSettingFailed),
              ],
              SizedBox(height: 24),
              _SectionLabel(
                  index: '01', title: context.l10n.corePlaybackBehavior),
              SizedBox(height: 10),
              _SystemPanel(
                title: context.l10n.coreLoopMode,
                subtitle: _connected
                    ? context.l10n.coreLoopSubtitle
                    : context.l10n.coreConnectToChange,
                child: _ModeGrid(
                  selected: _playMode,
                  enabled: _connected && !_busy,
                  onSelected: _changePlayMode,
                ),
              ),
              SizedBox(height: 24),
              _SectionLabel(index: '02', title: context.l10n.coreDeviceInfo),
              SizedBox(height: 10),
              _SystemPanel(
                title: 'P20 / P11',
                subtitle: context.l10n.coreLanCockpit,
                trailing: _StatusPill(
                  label: _version ??
                      (_connected
                          ? context.l10n.coreNotRead
                          : context.l10n.coreDisconnected),
                  active: _version != null,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _connected && !_busy ? _load : null,
                    icon: Icon(Icons.sync_rounded),
                    label: Text(context.l10n.coreReadInfo),
                  ),
                ),
              ),
              SizedBox(height: 24),
              _SectionLabel(index: '03', title: context.l10n.coreHelp),
              SizedBox(height: 10),
              _HelpEntry(
                icon: Icons.play_circle_outline_rounded,
                title: context.l10n.corePlaybackGuide,
                subtitle: context.l10n.coreModesHelpSubtitle,
                onTap: () => _open(context, PlaybackModeGuide()),
              ),
              _HelpEntry(
                icon: Icons.wifi_find_rounded,
                title: context.l10n.coreLanHelp,
                subtitle: context.l10n.coreHotspotHelp,
                onTap: () => _open(context, LanConnectionGuide()),
              ),
            ],
          ),
        ),
      );

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }
}

class _ConnectionPanel extends StatelessWidget {
  const _ConnectionPanel({
    required this.state,
    required this.busy,
    required this.onRead,
  });

  final DeviceConnectionState state;
  final bool busy;
  final VoidCallback? onRead;

  bool get _connected => state == DeviceConnectionState.connected;

  String _title(BuildContext context) => switch (state) {
        DeviceConnectionState.disconnected =>
          context.l10n.coreDeviceDisconnected,
        DeviceConnectionState.connecting => context.l10n.coreDeviceConnecting,
        DeviceConnectionState.reconnecting =>
          context.l10n.coreDeviceReconnecting,
        DeviceConnectionState.connected => context.l10n.coreCockpitOnline,
      };

  String _subtitle(BuildContext context) => switch (state) {
        DeviceConnectionState.disconnected => context.l10n.coreGoHomeConnect,
        DeviceConnectionState.connecting => context.l10n.coreOpeningLan,
        DeviceConnectionState.reconnecting => context.l10n.coreRetryingLan,
        DeviceConnectionState.connected => context.l10n.coreLanReady,
      };

  @override
  Widget build(BuildContext context) {
    final accent =
        _connected ? HildorsColors.teal : HildorsColors.textSecondary;
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.14),
            HildorsColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.34)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  _connected ? Icons.router_rounded : Icons.wifi_off_rounded,
                  color: accent,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_title(context),
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    SizedBox(height: 3),
                    Text(_subtitle(context),
                        style: TextStyle(
                            color: HildorsColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              _StatusPill(
                label: switch (state) {
                  DeviceConnectionState.connected =>
                    context.l10n.coreOnlineLabel,
                  DeviceConnectionState.connecting =>
                    context.l10n.coreConnectingLabel,
                  DeviceConnectionState.reconnecting =>
                    context.l10n.coreReconnectingLabel,
                  DeviceConnectionState.disconnected =>
                    context.l10n.coreOfflineLabel,
                },
                active: _connected,
              ),
            ],
          ),
          if (busy) ...[
            SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          ] else if (_connected) ...[
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRead,
                icon: Icon(Icons.sync_rounded),
                label: Text(context.l10n.coreSync),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModeGrid extends StatelessWidget {
  const _ModeGrid(
      {required this.selected,
      required this.enabled,
      required this.onSelected});

  final P20PlayMode? selected;
  final bool enabled;
  final ValueChanged<P20PlayMode> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 10) / 2;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final mode in P20PlayMode.values)
                SizedBox(
                  width: width,
                  child: _ModeOption(
                    mode: mode,
                    selected: mode == selected,
                    enabled: enabled,
                    onTap: () => onSelected(mode),
                  ),
                ),
            ],
          );
        },
      );
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.mode,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final P20PlayMode mode;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected
            ? HildorsColors.teal.withValues(alpha: 0.14)
            : HildorsColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? HildorsColors.teal : HildorsColors.hairline,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 17,
                  color: enabled
                      ? (selected
                          ? HildorsColors.teal
                          : HildorsColors.textSecondary)
                      : HildorsColors.hairline,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _playModeLabel(context, mode),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: enabled
                          ? HildorsColors.textPrimary
                          : HildorsColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _SystemPanel extends StatelessWidget {
  const _SystemPanel({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HildorsColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: HildorsColors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      SizedBox(height: 3),
                      Text(subtitle,
                          style: TextStyle(
                              color: HildorsColors.textSecondary,
                              fontSize: 12)),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            SizedBox(height: 15),
            child,
          ],
        ),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
        constraints: BoxConstraints(maxWidth: 130),
        padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: (active ? HildorsColors.teal : HildorsColors.surfaceHighlight)
              .withValues(alpha: active ? 0.14 : 1),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: active ? HildorsColors.teal : HildorsColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: active ? 1.2 : 0,
          ),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.index, required this.title});

  final String index;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(index,
              style: TextStyle(
                color: HildorsColors.teal,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
              )),
          SizedBox(width: 10),
          Container(width: 20, height: 1, color: HildorsColors.teal),
          SizedBox(width: 10),
          Expanded(
              child: Text(title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ))),
        ],
      );
}

class _HelpEntry extends StatelessWidget {
  const _HelpEntry({
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
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Material(
          color: HildorsColors.surface,
          borderRadius: BorderRadius.circular(18),
          child: ListTile(
            onTap: onTap,
            minTileHeight: 76,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: HildorsColors.hairline),
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: HildorsColors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: HildorsColors.blue),
            ),
            title: Text(title),
            subtitle:
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 15),
          ),
        ),
      );
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Color(0xFF2B1719),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Color(0xFF713D42)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: Color(0xFFFFA8AE), size: 19),
            SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: TextStyle(color: Color(0xFFFFC8CC), fontSize: 12)),
            ),
          ],
        ),
      );
}

String _playModeLabel(BuildContext context, P20PlayMode mode) => switch (mode) {
      P20PlayMode.singleLoop => context.l10n.coreSingleLoop,
      P20PlayMode.sequenceLoop => context.l10n.coreSequenceLoop,
      P20PlayMode.randomLoop => context.l10n.coreRandomLoop,
      P20PlayMode.singleOnce => context.l10n.coreSingleOnce,
    };
