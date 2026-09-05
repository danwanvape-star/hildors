import 'dart:async';

import 'package:flutter/material.dart';

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
  DeviceStatus _status = const DeviceStatus();
  final DeviceRuntimeState _runtime = const DeviceRuntimeState();
  double _brightness = 60;
  double _angle = 0;
  String? _error;
  String? _bluetoothSpeakerName;
  bool _loadingBluetoothName = false;

  bool get _connected => _connection == DeviceConnectionState.connected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsClient = widget.client == null;
    _client = widget.client ?? P20DeviceClient();
    _session = P20CommandSession(_client);
    _connection = _client.connectionState;
    if (_client.isConnected) unawaited(_refreshBluetoothName());
    _connectionSubscription = _client.connectionStates.listen((state) {
      if (mounted) setState(() => _connection = state);
      if (state == DeviceConnectionState.connected) {
        unawaited(_refreshBluetoothName());
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
        _client.queryStatus();
      }
    } catch (error) {
      if (mounted) setState(() => _error = '连接失败：$error');
    }
  }

  void _guarded(VoidCallback action) {
    if (!_connected) return;
    try {
      action();
    } catch (error) {
      setState(() => _error = '$error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _client.isConnected) {
      _guarded(_client.queryStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('全息座舱控制台'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text(_connectionLabel)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _connectionCard(),
            const SizedBox(height: 12),
            DeviceStatusPanel(connection: _connection, runtime: _runtime),
            const SizedBox(height: 12),
            _bluetoothCard(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            _quickControls(),
            const SizedBox(height: 20),
            _sliderCard(
              title: '亮度',
              value: _brightness,
              min: 1,
              max: 100,
              suffix: '%',
              onChanged: (value) => setState(() => _brightness = value),
              onChangeEnd: (value) =>
                  _guarded(() => _client.setBrightness(value.round())),
            ),
            const SizedBox(height: 12),
            _sliderCard(
              title: '角度（待厂家确认单位与范围）',
              value: _angle,
              min: 0,
              max: 360,
              suffix: '°',
              onChanged: (value) => setState(() => _angle = value),
              onChangeEnd: (value) =>
                  _guarded(() => _client.setAngle(value.round())),
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
        title: const Text('设置蓝牙音箱名称'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '音箱名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
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
          leading: const Icon(Icons.speaker),
          title: const Text('蓝牙音箱'),
          subtitle: Text(
            !_connected
                ? '连接设备后读取音箱名称'
                : _loadingBluetoothName
                    ? '正在读取…'
                    : _bluetoothSpeakerName?.isNotEmpty == true
                        ? _bluetoothSpeakerName!
                        : '名称尚未读取',
          ),
          trailing: Wrap(
            spacing: 4,
            children: [
              IconButton(
                tooltip: '刷新名称',
                onPressed: _connected && !_loadingBluetoothName
                    ? _refreshBluetoothName
                    : null,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: '修改名称',
                onPressed: _connected ? _editBluetoothName : null,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ),
      );
  String get _connectionLabel => switch (_connection) {
        DeviceConnectionState.disconnected => '未连接',
        DeviceConnectionState.connecting => '连接中…',
        DeviceConnectionState.reconnecting => '正在重连…',
        DeviceConnectionState.connected => '已连接',
      };

  Widget _connectionCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hostController,
                  enabled: !_connected,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: '设备 IP',
                    helperText: '默认端口 8900',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _connection == DeviceConnectionState.connecting
                    ? null
                    : _toggleConnection,
                child: Text(_connection == DeviceConnectionState.reconnecting
                    ? '停止重连'
                    : _connected
                        ? '断开'
                        : '连接'),
              ),
            ],
          ),
        ),
      );

  Widget _quickControls() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('快捷控制', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _connected
                        ? () => _guarded(() => _client.setPower(true))
                        : null,
                    icon: const Icon(Icons.power_settings_new),
                    label: const Text('开机'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _connected
                        ? () => _guarded(() => _client.setPower(false))
                        : null,
                    icon: const Icon(Icons.power_off),
                    label: const Text('关机'),
                  ),
                  IconButton.filledTonal(
                    onPressed: _connected
                        ? () => _guarded(_client.previousTrack)
                        : null,
                    tooltip: '上一个',
                    icon: const Icon(Icons.skip_previous),
                  ),
                  IconButton.filled(
                    onPressed: _connected
                        ? () => _guarded(() => _client.setPlaying(
                              !(_status.playing ?? false),
                            ))
                        : null,
                    tooltip: (_status.playing ?? false) ? '暂停' : '播放',
                    icon: Icon((_status.playing ?? false)
                        ? Icons.pause
                        : Icons.play_arrow),
                  ),
                  IconButton.filledTonal(
                    onPressed:
                        _connected ? () => _guarded(_client.nextTrack) : null,
                    tooltip: '下一个',
                    icon: const Icon(Icons.skip_next),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        _connected ? () => _guarded(_client.queryStatus) : null,
                    icon: const Icon(Icons.refresh),
                    label: const Text('刷新状态'),
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
          padding: const EdgeInsets.all(16),
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
                onChanged: _connected ? onChanged : null,
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
