import 'dart:async';

import 'package:flutter/material.dart';

import '../../device/p20_command_session.dart';
import '../../device/p20_device_client.dart';
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
    _connectionSubscription = widget.client.connectionStates.listen((value) {
      if (mounted) setState(() => _connection = value);
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
    } catch (error) {
      if (mounted) setState(() => _message = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changePlayMode(P20PlayMode? mode) async {
    if (mode == null || !_connected) return;
    setState(() => _busy = true);
    try {
      await widget.session.setPlayMode(mode);
      if (mounted) {
        setState(() => _playMode = mode);
      }
    } catch (error) {
      if (mounted) setState(() => _message = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设备设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_connected)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('请先在“控制”页连接设备'),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<P20PlayMode>(
                initialValue: _playMode,
                decoration: const InputDecoration(labelText: '播放模式'),
                items: P20PlayMode.values
                    .map((mode) => DropdownMenuItem(
                          value: mode,
                          child: Text(_playModeLabel(mode)),
                        ))
                    .toList(),
                onChanged: _connected && !_busy ? _changePlayMode : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('设备版本'),
              subtitle: Text(_version ?? '尚未读取'),
              trailing: IconButton(
                onPressed: _connected && !_busy ? _load : null,
                icon: const Icon(Icons.download),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('本机播放与蓝牙音响'),
              subtitle: const Text('了解两种工作模式和连接方式'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PlaybackModeGuide(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.wifi_find),
              title: const Text('局域网连接帮助'),
              subtitle: const Text('排查设备无法连接或反复断线'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LanConnectionGuide(),
                ),
              ),
            ),
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _message!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  String _playModeLabel(P20PlayMode mode) => switch (mode) {
        P20PlayMode.singleLoop => '单曲循环',
        P20PlayMode.sequenceLoop => '顺序循环',
        P20PlayMode.randomLoop => '随机循环',
        P20PlayMode.singleOnce => '单曲一次',
      };

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }
}
