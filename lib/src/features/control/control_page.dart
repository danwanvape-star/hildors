import '../../device/p20_device_profile.dart';
import '../../localization/localization.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../device/p20_command_session.dart';
import '../../device/p20_device_client.dart';

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
  StreamSubscription<Object?>? _frameSubscription;
  StreamSubscription<Object?>? _connectionSubscription;
  DeviceConnectionState _connection = DeviceConnectionState.disconnected;
  double _brightness = 60;
  double _angle = 0;
  P20PlayMode? _playMode;
  String? _error;
  bool _commandBusy = false;
  int _connectionGeneration = 0;

  bool get _connected => _connection == DeviceConnectionState.connected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsClient = widget.client == null;
    _client =
        widget.client ?? P20DeviceClient(preference: P20DevicePreference.auto);
    _session = P20CommandSession(_client);
    _connection = _client.connectionState;
    if (_client.isConnected) {
      unawaited(_runCommand(() async {}));
    }
    _connectionSubscription = _client.connectionStates.listen((state) {
      _connectionGeneration++;
      if (mounted) {
        setState(() {
          _connection = state;
          _playMode = null;
          _commandBusy = false;
        });
      }
      if (state == DeviceConnectionState.connected) {
        unawaited(_runCommand(() async {}));
      }
    });
    _frameSubscription = _client.frames.listen((frame) {
      final status = _client.parseStatus(frame);
      if (status != null && mounted) {
        setState(() {
          _brightness = status.brightness?.toDouble() ?? _brightness;
          _angle = status.angle?.toDouble() ?? _angle;
        });
      }
    });
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
      final mode = await _session.queryPlayMode();
      if (!mounted || !_connected || generation != _connectionGeneration) {
        return;
      }
      setState(() => _playMode = mode);
      if (_client.modernProtocol) {
        final status = await _session.queryDeviceStatus();
        if (!mounted || !_connected || generation != _connectionGeneration) {
          return;
        }
        if (mounted && _connected && generation == _connectionGeneration) {
          setState(() {
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
            if (_error != null) ...[
              SizedBox(height: 12),
              Text(
                context.l10n.errorNetwork,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            SizedBox(height: 20),
            Card(
                child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(context.l10n.corePlaybackBehavior,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<P20PlayMode>(
                    key: ValueKey(_playMode),
                    initialValue: _playMode,
                    isExpanded: true,
                    decoration: InputDecoration(
                        labelText: context.l10n.coreLoopMode,
                        helperText: _client.profile.kind == P20DeviceKind.dual
                            ? context.l10n.p20Mode
                            : null,
                        helperMaxLines: 2),
                    items: [
                      for (final mode in P20PlayMode.values)
                        DropdownMenuItem(
                            value: mode,
                            child: Text(switch (mode) {
                              P20PlayMode.singleLoop =>
                                context.l10n.coreSingleLoop,
                              P20PlayMode.sequenceLoop =>
                                context.l10n.coreSequenceLoop,
                              P20PlayMode.randomLoop =>
                                context.l10n.coreRandomLoop,
                              P20PlayMode.singleOnce =>
                                context.l10n.coreSingleOnce,
                            }))
                    ],
                    onChanged: _connected && !_commandBusy && _playMode != null
                        ? (mode) {
                            if (mode != null) {
                              unawaited(_runCommand(
                                  () => _session.setPlayMode(mode)));
                            }
                          }
                        : null,
                  ),
                ],
              ),
            )),
            SizedBox(height: 12),
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

  String get _connectionLabel => switch (_connection) {
        DeviceConnectionState.disconnected => context.l10n.controlsDisconnected,
        DeviceConnectionState.connecting => context.l10n.controlsConnecting,
        DeviceConnectionState.reconnecting => context.l10n.controlsReconnecting,
        DeviceConnectionState.connected => context.l10n.controlsConnected,
      };

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
    unawaited(_session.dispose());
    if (_ownsClient) unawaited(_client.dispose());
    super.dispose();
  }
}
