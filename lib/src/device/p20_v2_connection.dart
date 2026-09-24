import 'dart:async';
import 'dart:io';
import 'p20_wire_log.dart';
import '../protocol/p20_protocol.dart' show P20Frame;
import 'p20_v2_protocol.dart';

/// Contains bounded protocol metadata only, never media bytes or filenames.
class P20UploadResponseMismatch extends FormatException {
  P20UploadResponseMismatch(super.message, P20Frame response, int expected)
      : diagnostic = [
          'RX cmd=0x',
          response.command.toRadixString(16),
          ' len=',
          response.data.length,
          ' data=',
          response.data
              .take(5)
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join(' '),
          ' expectedSeq=',
          expected
        ].join();
  final String diagnostic;
}

enum P20UploadPhase { awaitingReady, streaming, awaitingCompletion, completed }

/// Safe transfer metadata only: never filenames, file contents or credentials.
class P20UploadSnapshot {
  const P20UploadSnapshot(this.phase, this.sent, this.acknowledged, this.total,
      {this.flushed = 0});
  final P20UploadPhase phase;
  // Local queue/flush are not proof of device receipt.
  final int sent, acknowledged, total, flushed;
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
      {this.timeout = const Duration(seconds: 15),
      this.onClosed,
      this.wireLog}) {
    _responses = StreamIterator(_incoming.stream);
    // Keep reading while idle so a paused response iterator cannot conceal EOF.
    _subscription = _socket.listen((bytes) {
      if (_closed) return;
      if (_tracingUpload) wireLog?.record('RX', bytes);
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
  final P20WireLog? wireLog;
  final decoder = P20V2Decoder();
  final Socket _socket;
  final Duration timeout;
  final void Function()? onClosed;
  final _incoming = StreamController<P20Frame>();
  late final StreamSubscription<List<int>> _subscription;
  late final StreamIterator<P20Frame> _responses;
  Future<void> _tail = Future.value();
  bool _closed = false;
  bool _tracingUpload = false;
  int _requestStartRx = 0;

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
          'rx=${decoder.receivedBytes} valid=${decoder.validFrames} rejected=${decoder.rejectedFrames} '
          'last=${decoder.lastCommand == null ? "none" : "0x${decoder.lastCommand!.toRadixString(16).padLeft(2, '0')}"} '
          'deltaRx=${decoder.receivedBytes - _requestStartRx} '
          'pending=${decoder.pendingBytes} len=${decoder.pendingLength ?? -1}',
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

  Future<void> _write(List<int> bytes, {bool media = false}) async {
    if (_closed) throw StateError('P20 connection is closed');
    if (_tracingUpload) wireLog?.record('TX', bytes, media: media);
    _socket.add(bytes);
    await _socket.flush().timeout(timeout);
  }

  Future<P20Frame> request(int command, [List<int> data = const []]) {
    if (command == 1 || command == 0x31) {
      throw ArgumentError('Use power or upload for this command');
    }
    return _exclusive(() async {
      _requestStartRx = decoder.receivedBytes;
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
        _tracingUpload = true;
        try {
          final size = await input.length();
          final header = P20V2Protocol.uploadHeader(listId, size, gbkName);
          var sent = 0;
          var flushed = 0;
          var acknowledged = 0;
          var phase = P20UploadPhase.awaitingReady;
          void report() =>
              onState?.call(P20UploadSnapshot(phase, sent, acknowledged, size,
                  flushed: flushed));
          report();
          onProgress?.call(0, size);
          _requestStartRx = decoder.receivedBytes;
          await _write(P20V2Protocol.request(0x31, header));
          _status(await _next(0x31), 0);
          phase = P20UploadPhase.streaming;
          report();
          // Firmware requires stop-and-wait: never send another block until
          // the current block is acknowledged. The exclusive queue also keeps
          // status queries and controls out of the raw file stream.
          var sequence = 0;
          while (true) {
            if (sent < size) {
              final wanted = (size - sent).clamp(1, 32768);
              final chunk = await input.read(wanted);
              if (chunk.length != wanted) {
                throw const FileSystemException('Upload source changed');
              }
              sent += chunk.length;
              report();
              await _write(chunk, media: true);
              flushed = sent;
              if (sent == size) phase = P20UploadPhase.awaitingCompletion;
              report();
            }
            final response = await _next(0x31);
            if ((response.data.length == 1 || response.data.length == 5) &&
                response.data[0] == 2) {
              if (sent != size) {
                throw P20UploadResponseMismatch(
                    'Premature upload completion', response, sequence + 1);
              }
              acknowledged = size;
              phase = P20UploadPhase.completed;
              report();
              onProgress?.call(size, size);
              return;
            }
            if (response.data.isEmpty || response.data[0] != 1) {
              if (response.data.isNotEmpty && response.data[0] >= 0x80) {
                throw P20DeviceUploadRejected(response.data[0]);
              }
              throw P20UploadResponseMismatch(
                  'Unexpected upload status', response, sequence + 1);
            }
            if (response.data.length != 5) {
              throw P20UploadResponseMismatch(
                  'Invalid upload progress', response, sequence + 1);
            }
            // Manufacturer confirmed firmware may return a constant SEQ=2.
            // A valid progress status acknowledges only the one outstanding
            // block; never derive byte progress from the sequence field.
            if (acknowledged >= sent) {
              throw P20UploadResponseMismatch(
                  'Progress without outstanding data', response, sequence + 1);
            }
            sequence++;
            acknowledged = sent;
            report();
            onProgress?.call(acknowledged, size);
          }
        } finally {
          _tracingUpload = false;
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
