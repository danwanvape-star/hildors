import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../device/p20_device_client.dart';
import '../../device/p20_command_session.dart';

/// A view of the connected device, never populated from local playlist drafts.
class P20LivePlaylist extends ChangeNotifier {
  P20LivePlaylist(this.client, this.session, {this.listId = 0}) {
    _subscription = client.connectionStates.listen((state) {
      _invalidate();
      if (state == DeviceConnectionState.connected) unawaited(refresh());
    });
    if (client.isConnected) unawaited(refresh());
  }
  final P20DeviceClient client;
  final P20CommandSession session;
  late final StreamSubscription<DeviceConnectionState> _subscription;
  int listId;
  int _generation = 0;
  bool _disposed = false;
  bool loading = false, busy = false, loaded = false;
  List<P20VideoEntry> videos = const [];
  P20PlayMode? mode;
  String? error;
  bool get connected => client.isConnected;
  bool get canEdit => connected && loaded && !loading && !busy;
  bool _current(int generation) =>
      !_disposed && connected && generation == _generation;
  void _invalidate() {
    _generation++;
    videos = const [];
    mode = null;
    loaded = false;
    loading = false;
    busy = false;
    error = null;
    if (!_disposed) notifyListeners();
  }

  Future<void> selectList(int value) async {
    RangeError.checkValueInInterval(value, 0, 1);
    if (busy || listId == value) return;
    listId = value;
    _invalidate();
    await refresh();
  }

  Future<void> refresh({String? keepError}) async {
    if (_disposed || busy) return;
    if (!connected) {
      _invalidate();
      return;
    }
    final generation = ++_generation;
    final target = listId;
    loading = true;
    loaded = false;
    videos = const [];
    mode = null;
    error = keepError;
    notifyListeners();
    try {
      final files = await session.queryVideos(listId: target);
      if (!_current(generation)) return;
      // Playback mode is global in firmware (commands 08/09 have no LIST_ID).
      final currentMode = await session.queryPlayMode();
      if (!_current(generation)) return;
      videos = List.unmodifiable(files);
      mode = currentMode;
      loaded = true;
    } catch (failure) {
      if (_current(generation)) error = 'read_failed';
    } finally {
      if (_current(generation)) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _mutate(Future<void> Function(int, int) action) async {
    if (!canEdit) return;
    final generation = _generation;
    final target = listId;
    busy = true;
    error = null;
    notifyListeners();
    String? failureMessage;
    try {
      await action(target, generation);
    } catch (_) {
      failureMessage = 'operation_unconfirmed';
    } finally {
      if (_current(generation)) {
        busy = false;
        await refresh(keepError: failureMessage);
      }
    }
  }

  Future<void> move(int from, int to) async {
    if (!canEdit ||
        from == to ||
        from < 0 ||
        to < 0 ||
        from >= videos.length ||
        to >= videos.length) {
      return;
    }
    final before = videos.map((entry) => entry.fileName).toList();
    await _mutate((target, generation) async {
      final actual = await session.queryVideos(listId: target);
      if (!_current(generation)) return;
      if (!listEquals(before, actual.map((entry) => entry.fileName).toList())) {
        throw StateError('Device playlist changed');
      }
      await session.reorderVideos(
          total: actual.length, from: from, to: to, listId: target);
    });
  }

  Future<void> setMode(P20PlayMode value) =>
      _mutate((target, generation) async {
        await session.setPlayMode(value);
      });
  Future<void> delete(String name) async {
    if (!canEdit || !videos.any((entry) => entry.fileName == name)) return;
    await _mutate(
        (target, generation) => session.deleteVideo(name, listId: target));
  }

  Future<void> play(String name) async {
    if (!videos.any((entry) => entry.fileName == name)) return;
    await _mutate(
        (target, generation) => session.playVideo(name, listId: target));
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
