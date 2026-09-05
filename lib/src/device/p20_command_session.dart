import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import '../protocol/p20_protocol.dart';
import 'p20_device_client.dart';

enum P20PlayMode { singleLoop, sequenceLoop, randomLoop, singleOnce }

enum P20WifiMode { disabled, accessPoint, station, accessPointAndStation }

class P20VideoEntry {
  const P20VideoEntry({
    required this.total,
    required this.index,
    required this.fileName,
  });

  final int total;
  final int index;
  final String fileName;
}

class P20CurrentVideo {
  const P20CurrentVideo({required this.index, required this.playing});

  final int index;
  final bool playing;
}

class P20CommandException implements Exception {
  const P20CommandException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Matches one response to each request of the same command. This prevents
/// unrelated replies from being consumed when controls are used rapidly.
class P20CommandSession {
  P20CommandSession(this.client) {
    _subscription = client.frames.listen(_onFrame);
  }

  final P20DeviceClient client;
  final Map<int, Queue<Completer<P20Frame>>> _pending = {};
  late final StreamSubscription<P20Frame> _subscription;

  Future<P20Frame> request(
    P20Command command, [
    List<int> data = const [0x00],
    Duration timeout = const Duration(seconds: 3),
  ]) {
    final completer = Completer<P20Frame>();
    (_pending[command.code] ??= Queue()).add(completer);
    try {
      client.send(command, data);
    } catch (error, stackTrace) {
      _pending[command.code]?.remove(completer);
      completer.completeError(error, stackTrace);
    }
    return completer.future.timeout(
      timeout,
      onTimeout: () {
        _pending[command.code]?.remove(completer);
        throw TimeoutException('设备未在 ${timeout.inSeconds} 秒内应答');
      },
    );
  }

  void _onFrame(P20Frame frame) {
    final queue = _pending[frame.command];
    if (queue == null || queue.isEmpty) return;
    queue.removeFirst().complete(frame);
    if (queue.isEmpty) _pending.remove(frame.command);
  }

  Future<int> queryBrightness() async {
    final frame = await request(P20Command.queryBrightness);
    _requireLength(frame, 1);
    return frame.data[0];
  }

  Future<int> queryAngle() async {
    final frame = await request(P20Command.queryAngle);
    _requireLength(frame, 2);
    return (frame.data[0] << 8) | frame.data[1];
  }

  Future<P20PlayMode> queryPlayMode() async {
    final frame = await request(P20Command.queryPlayMode);
    _requireLength(frame, 1);
    final value = frame.data[0] - 1;
    if (value < 0 || value >= P20PlayMode.values.length) {
      throw P20CommandException('未知播放模式：${frame.data[0]}');
    }
    return P20PlayMode.values[value];
  }

  Future<void> setPlayMode(P20PlayMode mode) async {
    final frame = await request(P20Command.setPlayMode, [mode.index + 1]);
    _requireSuccess(frame, resultIndex: 1);
  }

  Future<P20VideoEntry?> queryVideo(int index) async {
    if (index < 0 || index > 254) {
      throw RangeError.range(index, 0, 254, 'index');
    }
    final frame = await request(P20Command.queryVideoList, [index]);
    _requireLength(frame, 2);
    if (frame.data[0] == 0) return null;
    return P20VideoEntry(
      total: frame.data[0],
      index: frame.data[1],
      fileName: utf8.decode(frame.data.sublist(2), allowMalformed: true),
    );
  }

  Future<List<P20VideoEntry>> queryVideos() async {
    final videos = <P20VideoEntry>[];
    for (var index = 0; index < 50; index++) {
      final video = await queryVideo(index);
      if (video == null) break;
      videos.add(video);
      if (videos.length >= video.total) break;
    }
    return videos;
  }

  Future<P20CurrentVideo> queryCurrentVideo() async {
    final frame = await request(P20Command.queryCurrentVideo);
    _requireLength(frame, 2);
    return P20CurrentVideo(index: frame.data[0], playing: frame.data[1] == 1);
  }

  Future<void> playVideo(String fileName) async {
    final frame = await request(P20Command.playVideo, utf8.encode(fileName));
    _requireSuccess(frame);
  }

  Future<void> deleteVideo(String fileName) async {
    final frame = await request(P20Command.deleteVideo, utf8.encode(fileName));
    _requireSuccess(frame);
  }

  Future<void> deleteAllVideos() async {
    final frame = await request(P20Command.deleteAllVideos, [0xFF]);
    _requireSuccess(frame, resultIndex: 1);
  }

  Future<void> reorderVideos({
    required int total,
    required int from,
    required int to,
  }) async {
    final frame = await request(P20Command.reorderVideos, [total, from, to]);
    _requireSuccess(frame);
  }

  Future<String> queryBluetoothSpeakerName() async {
    final frame = await request(P20Command.queryBluetoothSpeakerName);
    return utf8.decode(frame.data, allowMalformed: true).trim();
  }

  Future<void> setBluetoothSpeakerName(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      throw const P20CommandException('蓝牙音箱名称不能为空');
    }
    final frame = await request(
      P20Command.setBluetoothSpeakerName,
      utf8.encode(normalized),
    );
    _requireSuccess(frame);
  }

  Future<String> queryVersionSummary() async {
    final frame = await request(P20Command.queryVersion);
    var offset = 0;
    final versions = <String>[];
    for (var i = 0; i < 3 && offset < frame.data.length; i++) {
      final length = frame.data[offset++];
      if (offset + length > frame.data.length) {
        throw const P20CommandException('版本信息长度不合法');
      }
      versions.add(utf8.decode(
        frame.data.sublist(offset, offset + length),
        allowMalformed: true,
      ));
      offset += length;
    }
    return versions.where((value) => value.isNotEmpty).join('\n');
  }

  static void _requireLength(P20Frame frame, int minimum) {
    if (frame.data.length < minimum) {
      throw P20CommandException(
        '指令 0x${frame.command.toRadixString(16)} 应答长度不足',
      );
    }
  }

  static void _requireSuccess(P20Frame frame, {int resultIndex = 0}) {
    _requireLength(frame, resultIndex + 1);
    if (frame.data[resultIndex] != 0x01) {
      throw P20CommandException('设备操作失败，错误码：${frame.data[resultIndex]}');
    }
  }

  Future<void> dispose() async {
    await _subscription.cancel();
    for (final queue in _pending.values) {
      for (final completer in queue) {
        if (!completer.isCompleted) {
          completer.completeError(const P20CommandException('会话已关闭'));
        }
      }
    }
    _pending.clear();
  }
}
