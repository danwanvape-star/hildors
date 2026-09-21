import 'dart:async';
import 'dart:io';
import '../protocol/p20_protocol.dart' show P20Frame;
import 'p20_v2_protocol.dart';

enum P20UploadPhase { awaitingReady, streaming, awaitingCompletion, completed }

/// Safe transfer metadata only: never filenames, file contents or credentials.
class P20UploadSnapshot {
  const P20UploadSnapshot(this.phase, this.sent, this.acknowledged, this.total);
  final P20UploadPhase phase;
  final int sent, acknowledged, total;
}

class P20DeviceUploadRejected implements Exception {
  const P20DeviceUploadRejected(this.status);
  final int status;
  String get code => switch (status) {
        0x80 => 'device_busy',
        0x81 => 'write_failed',
        0x82 => 'duplicate_file',
        0x85 => 'storage_or_list_full',
        0x8a => 'battery_low',
        _ => 'upload_rejected',
      };
  @override
  String toString() => 'P20DeviceUploadRejected($code)';
}

/// Sole owner of a September-2026 device socket. Do not open concurrently with
/// the legacy client: the firmware only permits one TCP client.
class P20V2Connection {
  P20V2Connection(this._socket,
      {this.timeout = const Duration(seconds: 15), this.onClosed}) {
    _responses = StreamIterator(_incoming.stream);
    // Keep reading while idle so a paused response iterator cannot conceal EOF.
    _subscription = _socket.listen((bytes) {
      if (_closed) return;
      try {
        for (final frame in decoder.add(bytes)) {
          _incoming.add(frame);
        }
      } catch (_) {
        unawaited(close());
      }
    },
        onDone: () => unawaited(close()),
        onError: (Object _) => unawaited(close()));
  }
  final decoder = P20V2Decoder();
  final Socket _socket;
  final Duration timeout;
  final void Function()? onClosed;
  final _incoming = StreamController<P20Frame>();
  late final StreamSubscription<List<int>> _subscription;
  late final StreamIterator<P20Frame> _responses;
  Future<void> _tail = Future.value();
  bool _closed = false;

  Future<T> _exclusive<T>(Future<T> Function() action) {
    final result = _tail.then((_) async {
      if (_closed) throw StateError('P20 connection is closed');
      try {
        return await action();
      } catch (_) {
        // No request IDs: discard the transport after an ambiguous response.
        await close();
        rethrow;
      }
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<P20Frame> _next(int command) async {
    if (!await _responses.moveNext().timeout(timeout, onTimeout: () {
      throw TimeoutException(
          'P20 cmd=0x${command.toRadixString(16).padLeft(2, '0')} '
          'rx=${decoder.receivedBytes} valid=${decoder.validFrames} rejected=${decoder.rejectedFrames}',
          timeout);
    })) {
      throw const SocketException('Device disconnected');
    }
    final frame = _responses.current;
    if (frame.command != command) {
      throw const FormatException('Unexpected device response');
    }
    return frame;
  }

  Future<void> _write(List<int> bytes) async {
    if (_closed) throw StateError('P20 connection is closed');
    _socket.add(bytes);
    await _socket.flush().timeout(timeout);
  }

  Future<P20Frame> request(int command, [List<int> data = const []]) {
    if (command == 1 || command == 0x31) {
      throw ArgumentError('Use power or upload for this command');
    }
    return _exclusive(() async {
      await _write(P20V2Protocol.request(command, data));
      return _next(command);
    });
  }

  Future<void> power(bool on) =>
      _exclusive(() => _write(P20V2Protocol.request(1, [on ? 1 : 2])));

  Future<void> upload(File file, int listId, List<int> gbkName,
          {void Function(int acknowledged, int total)? onProgress,
          void Function(P20UploadSnapshot)? onState}) =>
      _exclusive(() async {
        final input = await file.open();
        try {
          final size = await input.length();
          final header = P20V2Protocol.uploadHeader(listId, size, gbkName);
          var sent = 0;
          var acknowledged = 0;
          var phase = P20UploadPhase.awaitingReady;
          void report() =>
              onState?.call(P20UploadSnapshot(phase, sent, acknowledged, size));
          report();
          onProgress?.call(0, size);
          await _write(P20V2Protocol.request(0x31, header));
          _status(await _next(0x31), 0);
          phase = P20UploadPhase.streaming;
          report();
          // Progress packets are notifications, not permission to send the next
          // block. Keep sending with socket backpressure while reading replies.
          Future<void> sendData() async {
            while (sent < size) {
              final wanted = (size - sent).clamp(1, 32768);
              final chunk = await input.read(wanted);
              if (chunk.length != wanted) {
                throw const FileSystemException('Upload source changed');
              }
              sent += chunk.length;
              await _write(chunk);
              report();
            }
            if (phase != P20UploadPhase.completed) {
              phase = P20UploadPhase.awaitingCompletion;
              report();
            }
          }

          Future<void> readProgress() async {
            var sequence = 0;
            while (true) {
              final response = await _next(0x31);
              if (response.data.length == 1 && response.data[0] == 2) {
                if (sent != size) {
                  throw const FormatException('Premature upload completion');
                }
                acknowledged = size;
                phase = P20UploadPhase.completed;
                report();
                onProgress?.call(size, size);
                return;
              }
              if (response.data.isEmpty || response.data[0] != 1) {
                _status(response, 1);
              }
              if (response.data.length != 5) {
                throw const FormatException('Invalid upload progress');
              }
              final acknowledgedSequence = (response.data[1] << 24) |
                  (response.data[2] << 16) |
                  (response.data[3] << 8) |
                  response.data[4];
              if (acknowledgedSequence != ++sequence ||
                  sequence * 32768 > sent) {
                throw const FormatException('Unexpected upload sequence');
              }
              acknowledged = sequence * 32768;
              report();
              onProgress?.call(acknowledged, size);
            }
          }

          final sender = sendData();
          final receiver = readProgress();
          try {
            await Future.wait([sender, receiver], eagerError: true);
          } catch (_) {
            // Stop both halves before releasing the file or command queue.
            await close();
            await Future.wait([
              sender.catchError((Object _) {}),
              receiver.catchError((Object _) {}),
            ]);
            rethrow;
          }
        } finally {
          await input.close();
        }
      });

  static void _status(P20Frame response, int expected) {
    if (response.data.isEmpty) {
      throw const FormatException('Missing upload status');
    }
    if (response.data[0] >= 0x80) {
      throw P20DeviceUploadRejected(response.data[0]);
    }
    if (response.data.length != 1 || response.data[0] != expected) {
      throw const FormatException('Unexpected upload status');
    }
  }

  /// Cancels an in-flight upload by disconnecting, never by injecting a command.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _socket.destroy();
    await _subscription.cancel();
    await _responses.cancel();
    unawaited(_incoming.close());
    onClosed?.call();
  }
}
