import 'dart:async';
import 'dart:io';
import '../protocol/p20_protocol.dart';

/// One command at a time. A timeout closes the socket so late replies cannot
/// satisfy a subsequent command with the same opcode.
class P20SingleConnection {
  P20SingleConnection(this.socket, {required this.onClosed}) {
    _subscription = socket.listen((bytes) {
      for (final frame in _decoder.add(bytes)) {
        if (frame.command == _command && _reply?.isCompleted == false) {
          _reply!.complete(frame);
        }
      }
    },
        onError: (Object e) => unawaited(close()),
        onDone: () => unawaited(close()));
  }
  final Socket socket;
  final void Function() onClosed;
  final _decoder = P20FrameDecoder(allowLegacyCrc: false);
  late final StreamSubscription<List<int>> _subscription;
  Future<void> _tail = Future.value();
  Completer<P20Frame>? _reply;
  int? _command;
  bool _closed = false;

  Future<P20Frame> request(int command, List<int> data,
      {Duration timeout = const Duration(seconds: 3)}) {
    final result = _tail.then((_) => _request(command, data, timeout));
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<P20Frame> _request(
      int command, List<int> data, Duration timeout) async {
    if (_closed) throw StateError('Device connection closed');
    _command = command;
    final pending = Completer<P20Frame>();
    _reply = pending;
    final length = data.length + 1;
    socket.add([
      0xaa,
      (length >> 24) & 255,
      (length >> 16) & 255,
      (length >> 8) & 255,
      length & 255,
      command,
      ...data,
      2,
      0xa5
    ]);
    try {
      return await pending.future.timeout(timeout);
    } catch (_) {
      await close();
      rethrow;
    } finally {
      _reply = null;
      _command = null;
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    if (_reply?.isCompleted == false) {
      _reply!.completeError(StateError('Device connection closed'));
    }
    socket.destroy();
    await _subscription.cancel();
    onClosed();
  }
}
