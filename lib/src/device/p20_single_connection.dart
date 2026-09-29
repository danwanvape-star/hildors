import 'dart:async';
import 'dart:collection';
import 'dart:io';
import '../protocol/p20_protocol.dart';
import 'p20_upload_policy.dart';
import 'p20_v2_protocol.dart';
import 'p20_v2_connection.dart' show P20DeviceUploadRejected;
import 'p20_wire_log.dart';

/// One command at a time. A timeout closes the socket so late replies cannot
/// satisfy a subsequent command with the same opcode.
class P20SingleConnection {
  P20SingleConnection(this.socket,
      {required this.onClosed,
      this.wireLog,
      this.traceConnectionProbe = false}) {
    _subscription = socket.listen((bytes) {
      if (traceConnectionProbe || _tracingListRead || _uploading) {
        wireLog?.record('RX', bytes);
      }
      for (final frame in _decoder.add(bytes)) {
        if (_uploading && frame.command == 0x31) {
          _uploadReplies.add(frame);
          if (_uploadReplies.length > 2) {
            unawaited(close());
          }
          if (_uploadAvailable?.isCompleted == false) {
            _uploadAvailable!.complete();
          }
        } else if (frame.command == _command && _reply?.isCompleted == false) {
          _reply!.complete(frame);
        }
      }
    },
        onError: (Object e) => unawaited(close()),
        onDone: () => unawaited(close()));
  }
  final P20WireLog? wireLog;
  bool traceConnectionProbe;
  final Socket socket;
  final void Function() onClosed;
  final _decoder =
      P20FrameDecoder(allowLegacyCrc: false, allowAdditiveCrc: true);
  late final StreamSubscription<List<int>> _subscription;
  Future<void> _tail = Future.value();
  Completer<P20Frame>? _reply;
  int? _command;
  bool _closed = false;
  bool _uploading = false;
  bool _tracingListRead = false;
  final _uploadReplies = Queue<P20Frame>();
  Completer<void>? _uploadAvailable;

  Future<P20Frame> request(int command, List<int> data,
      {Duration timeout = const Duration(seconds: 3)}) {
    if (_uploading) {
      return Future.error(StateError('Device upload in progress'));
    }
    final result = _tail.then((_) => _request(command, data, timeout));
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<P20Frame> _request(
      int command, List<int> data, Duration timeout) async {
    if (_closed) throw StateError('Device connection closed');
    _command = command;
    // Only non-sensitive list and playback-mode queries; never Wi-Fi settings.
    _tracingListRead = command == 0x36 || command == 0x08;
    final pending = Completer<P20Frame>();
    _reply = pending;
    final length = data.length + 1;
    final bytes = <int>[
      0xaa,
      (length >> 24) & 255,
      (length >> 16) & 255,
      (length >> 8) & 255,
      length & 255,
      command,
      ...data,
      2,
      0xa5
    ];
    if (traceConnectionProbe || _tracingListRead) wireLog?.record('TX', bytes);
    socket.add(bytes);
    try {
      return await pending.future.timeout(timeout);
    } catch (_) {
      await close();
      rethrow;
    } finally {
      _tracingListRead = false;
      _reply = null;
      _command = null;
    }
  }

  Future<void> upload(File file, List<int> name,
      {void Function(int acknowledged, int total)? onProgress,
      Duration timeout = const Duration(seconds: 10)}) async {
    if (_closed || _uploading) throw StateError('Device unavailable');
    if (name.any((b) => b < 0 || b > 127) ||
        name.length > 12 ||
        !RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]*\.mp4$')
            .hasMatch(String.fromCharCodes(name))) {
      throw ArgumentError(
          'Single-list filename must be ASCII .mp4, at most 12 bytes');
    }
    // Reserve before awaiting disk or queued commands: no new commands may join.
    _uploading = true;
    RandomAccessFile? source;
    try {
      await _tail;
      if (_closed) throw StateError('Device connection closed');
      source = await file.open();
      final size = await source.length();
      if (size == 0 || size > 0xffffffff) {
        throw ArgumentError('Invalid file size');
      }
      final header = [
        (size >> 24) & 255,
        (size >> 16) & 255,
        (size >> 8) & 255,
        size & 255,
        ...name
      ];
      // Vendor 01NZ.mp4 fixture: additive upload CRC, no playlist byte.
      final request = P20V2Protocol.request(0x31, header);
      wireLog?.record('TX', request);
      socket.add(request);
      await socket.flush().timeout(timeout);
      final ready = await _nextUploadReply(timeout);
      _checkStatus(ready);
      if (ready.data.length != 1 || ready.data.single != 0) {
        throw const FormatException('Expected upload ready');
      }
      if (_uploadReplies.isNotEmpty) {
        throw const FormatException('Unexpected early upload reply');
      }
      var sent = 0;
      onProgress?.call(0, size);
      while (sent < size) {
        if (_closed) throw StateError('Device connection closed');
        final count = (size - sent).clamp(0, P20UploadPolicy.p20ChunkSize);
        final bytes = await source.read(count);
        if (bytes.length != count) {
          throw const FormatException('Video changed during upload');
        }
        if (_closed) throw StateError('Device connection closed');
        if (_uploadReplies.isNotEmpty) {
          throw const FormatException('Unexpected early upload reply');
        }
        wireLog?.record('TX', bytes, media: true);
        socket.add(bytes);
        await socket.flush().timeout(timeout);
        sent += bytes.length;
        final ack = await _nextUploadReply(timeout);
        _checkStatus(ack);
        if (_isComplete(ack)) {
          if (sent != size) {
            throw const FormatException('Premature upload completion');
          }
          if (_uploadReplies.isNotEmpty) {
            throw const FormatException('Unexpected reply after completion');
          }
          onProgress?.call(sent, size);
          return;
        }
        // Confirmed firmware can return constant SEQ=2. Status acknowledges
        // only the one outstanding block; never interpret SEQ as byte count.
        P20UploadPolicy.decodeAcknowledgedSequence(ack.data);
        onProgress?.call(sent, size);
      }
      final complete = await _nextUploadReply(timeout);
      _checkStatus(complete);
      if (!_isComplete(complete) || _uploadReplies.isNotEmpty) {
        throw const FormatException('Expected upload completion');
      }
    } catch (_) {
      await close();
      rethrow;
    } finally {
      await source?.close();
      _command = null;
      _reply = null;
      _uploadReplies.clear();
      _uploading = false;
    }
  }

  Future<P20Frame> _nextUploadReply(Duration timeout) async {
    if (_closed) throw StateError('Device connection closed');
    if (_uploadReplies.isEmpty) {
      final available = Completer<void>();
      _uploadAvailable = available;
      try {
        await available.future.timeout(timeout);
      } finally {
        _uploadAvailable = null;
      }
    }
    if (_closed) throw StateError('Device connection closed');
    return _uploadReplies.removeFirst();
  }

  bool _isComplete(P20Frame frame) =>
      (frame.data.length == 1 || frame.data.length == 5) &&
      frame.data.first == 2;

  void _checkStatus(P20Frame frame) {
    if (frame.data.isEmpty) throw const FormatException('Empty upload reply');
    if (frame.data.first >= 0x80) {
      throw P20DeviceUploadRejected(frame.data.first);
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    if (_uploadAvailable?.isCompleted == false) {
      _uploadAvailable!.complete();
    }
    if (_reply?.isCompleted == false) {
      _reply!.completeError(StateError('Device connection closed'));
    }
    socket.destroy();
    await _subscription.cancel();
    onClosed();
  }
}
