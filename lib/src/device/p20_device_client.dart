import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../protocol/p20_protocol.dart';
import 'reconnect_backoff.dart';

enum DeviceConnectionState { disconnected, connecting, reconnecting, connected }

class DeviceStatus {
  const DeviceStatus({
    this.poweredOn,
    this.playing,
    this.brightness,
    this.angle,
    this.playMode,
    this.baudRate,
  });

  final bool? poweredOn;
  final bool? playing;
  final int? brightness;
  final int? angle;
  final int? playMode;
  final int? baudRate;
}

class P20DeviceClient {
  P20DeviceClient({this.frameCrc = P20Protocol.crc});

  final int frameCrc;
  Socket? _socket;
  StreamSubscription<Uint8List>? _subscription;
  Timer? _reconnectTimer;
  final _decoder = P20FrameDecoder();
  final _frames = StreamController<P20Frame>.broadcast();
  final _connections = StreamController<DeviceConnectionState>.broadcast();

  String _host = '192.168.4.1';
  int _port = 8900;
  final _backoff = ReconnectBackoff();
  bool _manualDisconnect = true;
  bool _connecting = false;
  bool _disposed = false;
  DeviceConnectionState _connectionState = DeviceConnectionState.disconnected;

  Stream<P20Frame> get frames => _frames.stream;
  Stream<DeviceConnectionState> get connectionStates => _connections.stream;
  DeviceConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == DeviceConnectionState.connected;

  Future<void> connect({
    String host = '192.168.4.1',
    int port = 8900,
  }) async {
    if (_disposed) throw StateError('Client has been disposed');
    _host = host;
    _port = port;
    _manualDisconnect = false;
    _backoff.reset();
    _reconnectTimer?.cancel();
    await _closeTransport();
    await _open(reconnecting: false);
  }

  Future<void> _open({required bool reconnecting}) async {
    if (_connecting || _manualDisconnect || _disposed) return;
    _connecting = true;
    _emitConnection(reconnecting
        ? DeviceConnectionState.reconnecting
        : DeviceConnectionState.connecting);
    try {
      final socket = await Socket.connect(
        _host,
        _port,
        timeout: const Duration(seconds: 5),
      );
      if (_manualDisconnect || _disposed) {
        await socket.close();
        return;
      }
      socket.setOption(SocketOption.tcpNoDelay, true);
      _socket = socket;
      _subscription = socket.listen(
        (bytes) {
          for (final frame in _decoder.add(bytes)) {
            _frames.add(frame);
          }
        },
        onError: (_) => _handleTransportClosed(),
        onDone: _handleTransportClosed,
        cancelOnError: true,
      );
      _backoff.reset();
      _emitConnection(DeviceConnectionState.connected);
    } catch (_) {
      _emitConnection(DeviceConnectionState.disconnected);
      if (reconnecting) _scheduleReconnect();
      rethrow;
    } finally {
      _connecting = false;
    }
  }

  Future<void> _handleTransportClosed() async {
    if (_manualDisconnect || _disposed) return;
    await _closeTransport();
    _emitConnection(DeviceConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manualDisconnect || _disposed || _reconnectTimer?.isActive == true) {
      return;
    }
    final delay = _backoff.next();
    _emitConnection(DeviceConnectionState.reconnecting);
    _reconnectTimer = Timer(delay, () async {
      try {
        await _open(reconnecting: true);
        if (isConnected) queryStatus();
      } catch (_) {
        // _open schedules the next attempt after a failed reconnect.
      }
    });
  }

  Future<void> retryNow() async {
    if (_disposed) throw StateError('Client has been disposed');
    _manualDisconnect = false;
    _reconnectTimer?.cancel();
    _backoff.reset();
    await _closeTransport();
    await _open(reconnecting: true);
    if (isConnected) queryStatus();
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _backoff.reset();
    await _closeTransport();
    _emitConnection(DeviceConnectionState.disconnected);
  }

  Future<void> _closeTransport() async {
    final subscription = _subscription;
    final socket = _socket;
    _subscription = null;
    _socket = null;
    await subscription?.cancel();
    await socket?.close();
  }

  void _emitConnection(DeviceConnectionState state) {
    if (_disposed || _connectionState == state) return;
    _connectionState = state;
    _connections.add(state);
  }

  void send(P20Command command, [List<int> data = const []]) {
    final socket = _socket;
    if (socket == null || !isConnected) {
      throw StateError('Device is not connected');
    }
    socket.add(P20Protocol.encode(command, data, frameCrc));
  }

  void setPower(bool on) => send(P20Command.power, [on ? 0x01 : 0x02]);
  void setPlaying(bool playing) =>
      send(P20Command.playback, [playing ? 0x01 : 0x02]);
  void firstTrack() => send(P20Command.track, [0x01]);
  void previousTrack() => send(P20Command.track, [0x02]);
  void nextTrack() => send(P20Command.track, [0x03]);
  void queryStatus() => send(P20Command.queryStatus, [0x00]);
  void setBrightness(int value) =>
      send(P20Command.setBrightness, [value.clamp(1, 100).toInt()]);
  void setAngle(int value) =>
      send(P20Command.setAngle, P20Protocol.uint16BigEndian(value));

  DeviceStatus? parseStatus(P20Frame frame) {
    if (frame.command != P20Command.queryStatus.code || frame.data.length < 7) {
      return null;
    }
    return DeviceStatus(
      poweredOn: frame.data[0] == 0x01,
      playing: frame.data[1] == 0x01,
      brightness: frame.data[2],
      angle: (frame.data[3] << 8) | frame.data[4],
      playMode: frame.data[5],
      baudRate: frame.data[6],
    );
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    await _closeTransport();
    _disposed = true;
    await _frames.close();
    await _connections.close();
  }
}
