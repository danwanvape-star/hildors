import '../../localization/localization.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../device/device_error_message.dart';
import '../../device/device_runtime_state.dart';
import '../../device/p20_command_session.dart';
import '../../device/p20_device_client.dart';
import 'device_status_panel.dart';

class ControlPage extends StatefulWidget {
  const ControlPage({this.client, super.key});

  final P20DeviceClient? client;

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> with WidgetsBindingObserver {
  late final P20DeviceClient _client;
  late final bool _ownsClient;
  late final P20CommandSession _session;
  final _hostController = TextEditingController(text: '192.168.4.1');
  StreamSubscription<Object?>? _frameSubscription;
  StreamSubscription<Object?>? _connectionSubscription;
  DeviceConnectionState _connection = DeviceConnectionState.disconnected;
  DeviceStatus _status = DeviceStatus();
  final DeviceRuntimeState _runtime = DeviceRuntimeState();
  double _brightness = 60;
  double _angle = 0;
  String? _error;
  String? _bluetoothSpeakerName;
  bool _loadingBluetoothName = false;
  bool _commandBusy = false;
  int _connectionGeneration = 0;
  bool? _playing;

  bool get _connected => _connection == DeviceConnectionState.connected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsClient = widget.client == null;
    _client = widget.client ?? P20DeviceClient(modernProtocol: true);
    _session = P20CommandSession(_client);
    _connection = _client.connectionState;
    if (_client.isConnected) {
      unawaited(_refreshBluetoothName());
      unawaited(_runCommand(() async {}));
    }
    _connectionSubscription = _client.connectionStates.listen((state) {
      _connectionGeneration++;
      if (mounted) {
        setState(() {
          _connection = state;
          _playing = null;
          _commandBusy = false;
        });
      }
      if (state == DeviceConnectionState.connected) {
        unawaited(_refreshBluetoothName());
        unawaited(_runCommand(() async {}));
      }
    });
    _frameSubscription = _client.frames.listen((frame) {
      final status = _client.parseStatus(frame);
      if (status != null && mounted) {
        setState(() {
          _status = status;
          _brightness = status.brightness?.toDouble() ?? _brightness;
          _angle = status.angle?.toDouble() ?? _angle;
        });
      }
    });
  }

  Future<void> _toggleConnection() async {
    setState(() => _error = null);
    try {
      if (_connected || _connection == DeviceConnectionState.reconnecting) {
        await _client.disconnect();
      } else {
        await _client.connect(host: _hostController.text.trim());
        unawaited(_runCommand(() async {}));
      }
    } catch (error, stackTrace) {
      debugPrint('Control connection failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() => _error = friendlyDeviceConnectionError(error));
      }
    }
  }

  void _guarded(VoidCallback action) {
    if (!_connected) return;
    try {
      action();
    } catch (error) {
      debugPrint('Device command failed: $error');
      setState(() => _error = '设备暂时没有响应，请确认连接后重试。');
    }
  }

  Future<void> _runCommand(Future<void> Function() action) async {
    if (!_connected || _commandBusy) return;
    final generation = _connectionGeneration;
    setState(() {
      _commandBusy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted || !_connected || generation != _connectionGeneration) {
        return;
      }
      if (_client.modernProtocol) {
        final status = await _session.queryDeviceStatus();
        if (!mounted || !_connected || generation != _connectionGeneration) {
          return;
        }
        final current = await _session.queryCurrentVideo();
        if (mounted && _connected && generation == _connectionGeneration) {
          setState(() {
            _status = status;
            _playing = current.playing;
            _brightness = status.brightness?.toDouble() ?? _brightness;
            _angle = status.angle?.toDouble() ?? _angle;
          });
        }
      } else {
        _client.queryStatus();
      }
    } catch (_) {
      if (mounted && generation == _connectionGeneration) {
        setState(() => _error = 'Device operation failed');
      }
    } finally {
      if (mounted && generation == _connectionGeneration) {
        setState(() => _commandBusy = false);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _client.isConnected) {
      unawaited(_runCommand(() async {}));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight:
            56 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.5),
        title: Text(context.l10n.controlsControlTitle, maxLines: 2),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            Text(_connectionLabel),
            _connectionCard(),
            SizedBox(height: 12),
            DeviceStatusPanel(connection: _connection, runtime: _runtime),
            SizedBox(height: 12),
            _bluetoothCard(),
            if (_error != null) ...[
              SizedBox(height: 12),
              Text(
                context.l10n.errorNetwork,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            SizedBox(height: 20),
            _quickControls(),
            SizedBox(height: 20),
            _sliderCard(
              title: context.l10n.controlsBrightness,
              value: _brightness,
              min: _client.modernProtocol ? 0 : 1,
              max: 100,
              suffix: '%',
              onChanged: (value) => setState(() => _brightness = value),
              onChangeEnd: (value) => unawaited(_runCommand(() async {
                if (_client.modernProtocol) {
                  await _session.setBrightness(value.round());
                } else {
                  _client.setBrightness(value.round());
                }
              })),
            ),
            SizedBox(height: 12),
            _sliderCard(
              title: context.l10n.controlsAngle,
              value: _angle,
              min: 0,
              max: 360,
              suffix: '°',
              onChanged: (value) => setState(() => _angle = value),
              onChangeEnd: (value) => unawaited(_runCommand(() async {
                if (_client.modernProtocol) {
                  await _session.setAngle(value.round());
                } else {
                  _client.setAngle(value.round());
                }
              })),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshBluetoothName() async {
    if (!_connected || _loadingBluetoothName) return;
    setState(() => _loadingBluetoothName = true);
    try {
      final name = await _session.queryBluetoothSpeakerName();
      if (mounted) setState(() => _bluetoothSpeakerName = name);
    } catch (error) {
      if (mounted) setState(() => _error = '读取蓝牙音箱名称失败：$error');
    } finally {
      if (mounted) setState(() => _loadingBluetoothName = false);
    }
  }

  Future<void> _editBluetoothName() async {
    final controller = TextEditingController(text: _bluetoothSpeakerName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.controlsSpeakerTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration:
              InputDecoration(labelText: context.l10n.controlsSpeakerName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.controlsCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(context.l10n.controlsSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;
    try {
      await _session.setBluetoothSpeakerName(name);
      if (mounted) setState(() => _bluetoothSpeakerName = name.trim());
    } catch (error) {
      if (mounted) setState(() => _error = '设置蓝牙音箱名称失败：$error');
    }
  }

  Widget _bluetoothCard() => Card(
        child: ListTile(
          leading: Icon(Icons.speaker),
          title: Text(context.l10n.controlsSpeaker),
          subtitle: Text(
            !_connected
                ? context.l10n.controlsConnectSpeaker
                : _loadingBluetoothName
                    ? context.l10n.controlsReading
                    : _bluetoothSpeakerName?.isNotEmpty == true
                        ? _bluetoothSpeakerName!
                        : context.l10n.controlsNameUnknown,
          ),
          trailing: Wrap(
            spacing: 4,
            children: [
              IconButton(
                tooltip: context.l10n.controlsRefreshName,
                onPressed: _connected && !_loadingBluetoothName
                    ? _refreshBluetoothName
                    : null,
                icon: Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: context.l10n.controlsEditName,
                onPressed: _connected ? _editBluetoothName : null,
                icon: Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ),
      );
  String get _connectionLabel => switch (_connection) {
        DeviceConnectionState.disconnected => context.l10n.controlsDisconnected,
        DeviceConnectionState.connecting => context.l10n.controlsConnecting,
        DeviceConnectionState.reconnecting => context.l10n.controlsReconnecting,
        DeviceConnectionState.connected => context.l10n.controlsConnected,
      };

  Widget _connectionCard() => Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hostController,
                  enabled: !_connected,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: context.l10n.controlsIp,
                    helperText: context.l10n.controlsPort,
                  ),
                ),
              ),
              SizedBox(width: 12),
              FilledButton(
                onPressed: _connection == DeviceConnectionState.connecting
                    ? null
                    : _toggleConnection,
                child: Text(_connection == DeviceConnectionState.reconnecting
                    ? context.l10n.controlsStopReconnect
                    : _connected
                        ? context.l10n.controlsDisconnect
                        : context.l10n.controlsConnect),
              ),
            ],
          ),
        ),
      );

  Widget _quickControls() => Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.controlsQuick,
                  style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _connected
                        ? () => _guarded(() {
                              _client.setPower(true);
                              unawaited(_runCommand(() async {}));
                            })
                        : null,
                    icon: Icon(Icons.power_settings_new),
                    label: Text(context.l10n.controlsPowerOn),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _connected
                        ? () => _guarded(() {
                              _client.setPower(false);
                              unawaited(_runCommand(() async {}));
                            })
                        : null,
                    icon: Icon(Icons.power_off),
                    label: Text(context.l10n.controlsPowerOff),
                  ),
                  IconButton.filledTonal(
                    onPressed: _connected && !_commandBusy
                        ? () => unawaited(_runCommand(() async {
                              if (_client.modernProtocol) {
                                await _session.changeTrack(2);
                              } else {
                                _client.previousTrack();
                              }
                            }))
                        : null,
                    tooltip: context.l10n.controlsPrevious,
                    icon: Icon(Icons.skip_previous),
                  ),
                  IconButton.filled(
                    onPressed: _connected && !_commandBusy
                        ? () => unawaited(_runCommand(() async {
                              final playing =
                                  !(_playing ?? _status.playing ?? false);
                              if (_client.modernProtocol) {
                                await _session.setPlaying(playing);
                              } else {
                                _client.setPlaying(playing);
                              }
                            }))
                        : null,
                    tooltip: (_playing ?? _status.playing ?? false)
                        ? context.l10n.controlsPause
                        : context.l10n.controlsPlay,
                    icon: Icon((_playing ?? _status.playing ?? false)
                        ? Icons.pause
                        : Icons.play_arrow),
                  ),
                  IconButton.filledTonal(
                    onPressed: _connected && !_commandBusy
                        ? () => unawaited(_runCommand(() async {
                              if (_client.modernProtocol) {
                                await _session.changeTrack(3);
                              } else {
                                _client.nextTrack();
                              }
                            }))
                        : null,
                    tooltip: context.l10n.controlsNext,
                    icon: Icon(Icons.skip_next),
                  ),
                  OutlinedButton.icon(
                    onPressed: _connected && !_commandBusy
                        ? () => unawaited(_runCommand(() async {}))
                        : null,
                    icon: Icon(Icons.refresh),
                    label: Text(context.l10n.controlsRefreshStatus),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _sliderCard({
    required String title,
    required double value,
    required double min,
    required double max,
    required String suffix,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) =>
      Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(title)),
                  Text('${value.round()}$suffix'),
                ],
              ),
              Slider(
                value: value.clamp(min, max).toDouble(),
                min: min,
                max: max,
                onChanged: _connected && !_commandBusy ? onChanged : null,
                onChangeEnd: onChangeEnd,
              ),
            ],
          ),
        ),
      );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _frameSubscription?.cancel();
    _connectionSubscription?.cancel();
    _hostController.dispose();
    unawaited(_session.dispose());
    if (_ownsClient) unawaited(_client.dispose());
    super.dispose();
  }
}
