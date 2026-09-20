import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:gbk_codec/gbk_codec.dart';

import '../protocol/p20_protocol.dart';
import 'p20_device_client.dart';

enum P20PlayMode { singleLoop, sequenceLoop, randomLoop, singleOnce }

enum P20WifiMode { disabled, accessPoint, station, accessPointAndStation }

class P20VideoEntry {
  const P20VideoEntry({
    required this.total,
    required this.index,
    required this.fileName,
    this.listId = 0,
  });

  final int total;
  final int index;
  final String fileName;
  final int listId;
}

class P20CurrentVideo {
  const P20CurrentVideo(
      {required this.index, required this.playing, this.listId = 0});

  final int index;
  final bool playing;
  final int listId;
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
    List<int>? data,
    Duration timeout = const Duration(seconds: 3),
  ]) {
    if (client.modernProtocol) {
      return client.requestFrame(command, data ?? const []);
    }
    final completer = Completer<P20Frame>();
    (_pending[command.code] ??= Queue()).add(completer);
    try {
      client.send(command, data ?? const [0x00]);
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

  Future<P20VideoEntry?> queryVideo(int index, {int listId = 0}) async {
    _validateList(listId);
    if (client.modernProtocol) {
      RangeError.checkValueInInterval(index, 0, 95, 'index');
      final frame = await request(P20Command.queryVideoList, [listId, index]);
      _requireLength(frame, 3);
      if (frame.data[0] != listId ||
          frame.data[2] != index ||
          frame.data[1] > 96) {
        throw const P20CommandException('播放列表应答不匹配');
      }
      if (frame.data[1] == 0 || index >= frame.data[1]) return null;
      if (frame.data.length == 3) throw const P20CommandException('视频文件名缺失');
      return P20VideoEntry(
          total: frame.data[1],
          index: index,
          listId: listId,
          fileName: gbk_bytes.decode(frame.data.sublist(3)));
    }
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

  Future<List<P20VideoEntry>> queryVideos({int listId = 0}) async {
    final videos = <P20VideoEntry>[];
    for (var index = 0; index < (client.modernProtocol ? 96 : 50); index++) {
      final video = await queryVideo(index, listId: listId);
      if (video == null) break;
      if (videos.isNotEmpty && videos.first.total != video.total) {
        throw const P20CommandException('设备列表已变化，请刷新');
      }
      videos.add(video);
      if (videos.length >= video.total) break;
    }
    return videos;
  }

  Future<P20CurrentVideo> queryCurrentVideo() async {
    final frame = await request(P20Command.queryCurrentVideo);
    if (client.modernProtocol) {
      _requireLength(frame, 3);
      return P20CurrentVideo(
          listId: frame.data[0],
          index: frame.data[1],
          playing: frame.data[2] == 1);
    }
    _requireLength(frame, 2);
    return P20CurrentVideo(index: frame.data[0], playing: frame.data[1] == 1);
  }

  Future<void> playVideo(String fileName, {int listId = 0}) async {
    final frame =
        await request(P20Command.playVideo, _filePayload(fileName, listId));
    _requireSuccess(frame);
  }

  Future<void> deleteVideo(String fileName, {int listId = 0}) async {
    final frame =
        await request(P20Command.deleteVideo, _filePayload(fileName, listId));
    _requireSuccess(frame);
  }

  Future<void> deleteAllVideos({int listId = 0}) async {
    _validateList(listId);
    final frame = await request(
        P20Command.deleteAllVideos, [client.modernProtocol ? listId : 0xFF]);
    _requireSuccess(frame, resultIndex: 1);
  }

  Future<void> reorderVideos({
    required int total,
    required int from,
    required int to,
    int listId = 0,
  }) async {
    _validateList(listId);
    final frame = await request(P20Command.reorderVideos,
        [if (client.modernProtocol) listId, total, from, to]);
    _requireSuccess(frame, resultIndex: client.modernProtocol ? 1 : 0);
  }

  static void _validateList(int listId) =>
      RangeError.checkValueInInterval(listId, 0, 1, 'listId');

  List<int> _filePayload(String name, int listId) {
    _validateList(listId);
    if (!client.modernProtocol) return utf8.encode(name);
    final bytes = gbk_bytes.encode(name);
    if (bytes.isEmpty ||
        bytes.length > 61 ||
        gbk_bytes.decode(bytes) != name ||
        name.contains('/') ||
        name.contains('\\') ||
        name.contains('\u0000')) {
      throw const P20CommandException('设备文件名不合法');
    }
    return [listId, ...bytes];
  }

  Future<String> queryBluetoothSpeakerName() async {
    final frame = await request(P20Command.queryBluetoothSpeakerName);
    if (client.modernProtocol) {
      _requireLength(frame, 1);
      if (frame.data.length != frame.data[0] + 1) {
        throw const P20CommandException('蓝牙名称长度不合法');
      }
      return gbk_bytes.decode(frame.data.sublist(1));
    }
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
