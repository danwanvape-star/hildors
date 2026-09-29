import 'dart:typed_data';
import 'dart:async';
import 'p20_wire_log.dart';
import 'dart:io';
import 'p20_device_profile.dart';
import 'p20_single_connection.dart';

import '../protocol/p20_protocol.dart';
import 'reconnect_backoff.dart';
import 'p20_v2_connection.dart';

enum DeviceConnectionState { disconnected, connecting, reconnecting, connected }

class DeviceStatus {
  const DeviceStatus({
    this.poweredOn,
    this.playing,
    this.playerStatus,
    this.brightness,
    this.angle,
    this.playMode,
    this.baudRate,
    this.listId,
  });

  final bool? poweredOn;
  final bool? playing;
  final int? playerStatus;
  final int? brightness;
  final int? angle;
  final int? playMode;
  final int? baudRate;
  final int? listId;
}

class P20DeviceClient {
  P20DeviceClient(
      {this.frameCrc = P20Protocol.crc,
      bool modernProtocol = false,
      P20DevicePreference? preference,
      this.verifyOnConnect = false})
      : _preference = preference ??
            (modernProtocol
                ? P20DevicePreference.dual
                : P20DevicePreference.single),
        _verify = preference != null || verifyOnConnect,
        _configuredModern = modernProtocol;

  final wireLog = P20WireLog();
  final int frameCrc;
  P20DevicePreference _preference;
  final bool _verify;
  final bool _configuredModern;
  P20DeviceKind _kind = P20DeviceKind.unknown;
  int _generation = 0;
  int get generation => _generation;
  P20DevicePreference get preference => _preference;
  P20DeviceProfile get profile => P20DeviceProfile.forKind(_kind);
  bool get modernProtocol => _kind == P20DeviceKind.unknown
      ? (_preference == P20DevicePreference.dual || _configuredModern)
      : _kind == P20DeviceKind.dual;
  P20SingleConnection? _single;
  final bool verifyOnConnect;
  P20V2Connection? _modern;
  P20UploadSnapshot? lastUploadSnapshot;
  bool _uploading = false;
  bool get canUploadVideo =>
      isConnected &&
      (profile.kind == P20DeviceKind.dual ||
          profile.kind == P20DeviceKind.single);
  Socket? _socket;
  Timer? _reconnectTimer;
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
    if (_connecting || isConnected) return;
    _host = host;
    _port = port;
    _manualDisconnect = false;
    _backoff.reset();
    _reconnectTimer?.cancel();
    await _closeTransport();
    await _open(reconnecting: false);
  }

  Future<void> setPreference(P20DevicePreference preference) async {
    await disconnect();
    _preference = preference;
    await connect(host: _host, port: _port);
  }

  Future<void> _open({required bool reconnecting}) async {
    if (_connecting || _manualDisconnect || _disposed) return;
    _connecting = true;
    final attempt = _generation;
    bool current() =>
        !_disposed && !_manualDisconnect && attempt == _generation;
    _emitConnection(reconnecting
        ? DeviceConnectionState.reconnecting
        : DeviceConnectionState.connecting);
    final kinds = switch (_preference) {
      P20DevicePreference.auto => [P20DeviceKind.dual, P20DeviceKind.single],
      P20DevicePreference.dual => [P20DeviceKind.dual],
      P20DevicePreference.single => [P20DeviceKind.single],
    };
    Object? failure;
    try {
      for (final kind in kinds) {
        if (!current()) return;
        var stage = 'tcp';
        wireLog
            .event('mode=${kind.name} stage=tcp_start host=$_host port=$_port');
        try {
          final socket = await Socket.connect(_host, _port,
              timeout: const Duration(seconds: 5));
          if (!current()) {
            socket.destroy();
            return;
          }
          wireLog.event('mode=${kind.name} stage=tcp_connected');
          stage = 'probe';
          socket.setOption(SocketOption.tcpNoDelay, true);
          _socket = socket;
          void closed() {
            if (current() && isConnected && identical(_socket, socket)) {
              unawaited(_handleTransportClosed());
            }
          }

          P20Frame? reply;
          if (kind == P20DeviceKind.dual) {
            final transport = P20V2Connection(socket,
                wireLog: wireLog,
                onClosed: closed,
                traceConnectionProbe: _verify);
            _modern = transport;
            try {
              if (_verify) reply = await transport.request(4);
            } finally {
              transport.traceConnectionProbe = false;
            }
          } else {
            final transport = P20SingleConnection(socket,
                onClosed: closed,
                wireLog: wireLog,
                traceConnectionProbe: _verify);
            _single = transport;
            try {
              if (_verify) reply = await transport.request(4, [0]);
            } finally {
              transport.traceConnectionProbe = false;
            }
          }
          if (reply != null &&
              (reply.data.length != 1 ||
                  reply.data.single > 100 ||
                  (kind == P20DeviceKind.single && reply.data.single < 1))) {
            throw const FormatException('Invalid device brightness response');
          }
          if (!current()) return;
          wireLog.event(
              'mode=${kind.name} stage=${_verify ? "verified" : "unverified"}');
          _kind = kind;
          _backoff.reset();
          _emitConnection(DeviceConnectionState.connected);
          return;
        } catch (error) {
          if (!current()) return;
          final osCode =
              error is SocketException ? error.osError?.errorCode : null;
          wireLog.event(
              'mode=${kind.name} stage=${stage}_failed error=${error.runtimeType} osCode=${osCode ?? "none"}');
          failure = error;
          await _closeTransport(invalidate: false);
        }
      }
      if (current()) {
        _emitConnection(DeviceConnectionState.disconnected);
        if (reconnecting) _scheduleReconnect();
        throw failure ?? StateError('Device not recognized');
      }
    } finally {
      if (attempt == _generation) _connecting = false;
    }
  }

  Future<void> _handleTransportClosed() async {
    if (_manualDisconnect || _disposed) return;
    await _closeTransport();
    _emitConnection(DeviceConnectionState.disconnected);
    if (!_uploading) _scheduleReconnect();
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
    if (_uploading) throw StateError('Device upload in progress');
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

  Future<void> _closeTransport({bool invalidate = true}) async {
    if (invalidate) {
      _generation++;
      _connecting = false;
    }
    final socket = _socket;
    final modern = _modern;
    final single = _single;
    _modern = null;
    _single = null;
    _socket = null;
    _kind = P20DeviceKind.unknown;
    lastUploadSnapshot = null;
    if (modern != null) {
      await modern.close();
    }
    if (single != null) {
      await single.close();
    }
    socket?.destroy();
  }

  void _emitConnection(DeviceConnectionState state) {
    if (_disposed || _connectionState == state) return;
    _connectionState = state;
    _connections.add(state);
  }

  void send(P20Command command, [List<int> data = const []]) {
    if (modernProtocol) {
      final transport = _requireModern();
      final operation = command == P20Command.power
          ? transport.power(data.single == 1)
          : requestFrame(command, data).then<void>((_) {});
      // A failed command closes the transport; onClosed drives connection UI.
      unawaited(operation.catchError((Object _) {}));
      return;
    }
    if (!isConnected) throw StateError('Device is not connected');
    unawaited(requestFrame(command, data).catchError((Object error) {
      return P20Frame(command: command.code, data: Uint8List(0));
    }));
  }

  P20V2Connection _requireModern() {
    final transport = _modern;
    if (transport == null || !isConnected) {
      throw StateError('Device is not connected with the P20 v2 protocol');
    }
    return transport;
  }

  Future<P20Frame> requestFrame(P20Command command,
      [List<int> data = const []]) async {
    if (!isConnected) throw StateError('Device is not connected');
    if (!modernProtocol &&
        const {0x10, 0x73, 0x74, 0xc1, 0xc2}.contains(command.code)) {
      throw UnsupportedError('Unsupported single-list command');
    }
    final epoch = generation;
    final frame = modernProtocol
        ? await _requireModern().request(command.code, data)
        : await _single!.request(command.code, data);
    if (epoch != generation || _disposed) throw StateError('Device changed');
    _frames.add(frame);
    return frame;
  }

  Future<void> uploadFile(File file, int listId, List<int> gbkName,
      {void Function(int acknowledged, int total)? onProgress}) async {
    if (!canUploadVideo) {
      throw StateError('Device video upload is not available');
    }
    if (gbkName.length > profile.maxUploadNameBytes) {
      throw ArgumentError(
          'Upload filename exceeds 12 bytes including extension');
    }
    if (_uploading) throw StateError('Device upload in progress');
    _uploading = true;
    lastUploadSnapshot = null;
    final epoch = generation;
    try {
      if (profile.kind == P20DeviceKind.single) {
        if (listId != 0) throw ArgumentError.value(listId, 'listId');
        await _single!.upload(file, gbkName, onProgress: onProgress);
      } else {
        await _requireModern().upload(file, listId, gbkName,
            onProgress: onProgress, onState: (state) {
          if (epoch == generation) lastUploadSnapshot = state;
        });
      }
      if (epoch != generation) throw StateError('Device changed');
    } finally {
      _uploading = false;
    }
  }

  void setPower(bool on) => send(P20Command.power, [on ? 0x01 : 0x02]);
  void setPlaying(bool playing) =>
      send(P20Command.playback, [playing ? 0x01 : 0x02]);
  void firstTrack() => send(P20Command.track, [0x01]);
  void previousTrack() => send(P20Command.track, [0x02]);
  void nextTrack() => send(P20Command.track, [0x03]);
  void queryStatus() =>
      send(P20Command.queryStatus, modernProtocol ? const [] : const [0x00]);
  void setBrightness(int value) => send(
      P20Command.setBrightness, [value.clamp(modernProtocol ? 0 : 1, 100)]);
  void setAngle(int value) =>
      send(P20Command.setAngle, P20Protocol.uint16BigEndian(value));

  DeviceStatus? parseStatus(P20Frame frame) {
    if (frame.command != P20Command.queryStatus.code ||
        frame.data.length < (modernProtocol ? 8 : 7)) {
      return null;
    }
    if (modernProtocol &&
        (frame.data.length != 8 ||
            frame.data[1] > 5 ||
            frame.data[2] > 100 ||
            frame.data[5] < 1 ||
            frame.data[5] > 4 ||
            frame.data[7] > 1)) {
      return null;
    }
    return DeviceStatus(
      poweredOn: frame.data[0] == 0x01,
      playing: frame.data[1] == 0x01,
      brightness: frame.data[2],
      angle: (frame.data[3] << 8) | frame.data[4],
      playMode: frame.data[5],
      baudRate: frame.data[6],
      listId: modernProtocol ? frame.data[7] : null,
      playerStatus: modernProtocol ? frame.data[1] : null,
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
