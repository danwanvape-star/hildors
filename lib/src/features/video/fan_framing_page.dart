import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import '../../media/bundled_video_controller.dart';

/// Coordinates are relative to the fixed fan diameter. The original video is
/// aspect-fit into the square, then scaled and translated around its centre.
class FanFraming {
  const FanFraming({this.scale = 1, this.x = 0, this.y = 0});
  final double scale, x, y;
  Map<String, dynamic> toJson() => {
        'version': 1,
        'scale': scale,
        'x': x,
        'y': y,
        'coordinateSpace': 'fanDiameter',
        'baseFit': 'contain',
        'mask': 'circle',
        'background': 'black',
      };
  factory FanFraming.fromJson(Map<String, dynamic> value) => FanFraming(
        scale: (value['scale'] as num).toDouble().clamp(0.2, 4),
        x: (value['x'] as num).toDouble().clamp(-0.3, 0.3),
        y: (value['y'] as num).toDouble().clamp(-0.3, 0.3),
      );
  static double fullScale(double aspect) {
    final width = aspect >= 1 ? 1.0 : aspect;
    final height = aspect >= 1 ? 1 / aspect : 1.0;
    return 1 / math.sqrt(width * width + height * height);
  }
}

class FanFramingPage extends StatefulWidget {
  const FanFramingPage({required this.source, this.asset = false, super.key});
  final String source;
  final bool asset;
  @override
  State<FanFramingPage> createState() => _FanFramingPageState();
}

class _FanFramingPageState extends State<FanFramingPage> {
  VideoPlayerController? _player;
  FanFraming _frame = const FanFraming();
  FanFraming _start = const FanFraming();
  Offset _focal = Offset.zero;
  String? _error;
  bool _saving = false;
  bool _restoreFailed = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<File> _draftFile() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/fan_framing');
    await directory.create(recursive: true);
    // Keep filenames short while storing the full source identity in JSON.
    final bytes = utf8.encode('${widget.asset}:${widget.source}');
    var hash = 2166136261;
    for (final byte in bytes) {
      hash = ((hash ^ byte) * 16777619) & 0xffffffff;
    }
    return File('${directory.path}/${hash.toRadixString(16)}.json');
  }

  Future<void> _initialize() async {
    VideoPlayerController? player;
    try {
      if (widget.asset) {
        player = await createBundledVideoController(widget.source);
      } else {
        player = VideoPlayerController.file(File(widget.source));
        await player.initialize();
      }
      await player.setLooping(true);
      var frame =
          FanFraming(scale: FanFraming.fullScale(player.value.aspectRatio));
      try {
        final file = await _draftFile();
        if (await file.exists()) {
          final data =
              jsonDecode(await file.readAsString()) as Map<String, dynamic>;
          if (data['source'] == widget.source &&
              data['asset'] == widget.asset) {
            frame = FanFraming.fromJson(data);
          }
        }
      } catch (_) {
        _restoreFailed = true;
      }
      if (!mounted) {
        await player.dispose();
        return;
      }
      setState(() {
        _player = player;
        _frame = frame;
      });
    } catch (_) {
      await player?.dispose();
      if (mounted) setState(() => _error = '视频预览加载失败，请返回后重试。');
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final file = await _draftFile();
      await file.writeAsString(
          jsonEncode({
            ..._frame.toJson(),
            'source': widget.source,
            'asset': widget.asset,
            'sourceWidth': _player!.value.size.width,
            'sourceHeight': _player!.value.size.height,
            'status': 'framingOnly',
          }),
          flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('取景已保存。原视频未修改，尚未转码或上传。'),
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败，请重试')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _preset(bool fill) {
    final aspect = _player!.value.aspectRatio;
    setState(() => _frame = FanFraming(
        scale: fill
            ? math.max(aspect, 1 / aspect).clamp(0.2, 4)
            : FanFraming.fullScale(aspect)));
  }

  @override
  Widget build(BuildContext context) {
    final player = _player;
    return Scaffold(
      appBar: AppBar(title: const Text('调整风扇展示范围')),
      body: SafeArea(
          child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('圆圈内为设备显示范围',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('双指缩放、单指拖动。播放整段视频，检查头部、手脚和动作是否超出圆圈。'),
          const SizedBox(height: 16),
          AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(builder: (context, bounds) {
                final size = bounds.maxWidth;
                return DecoratedBox(
                  decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2)),
                  child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: ClipOval(
                        child: player == null
                            ? Center(
                                child: _error == null
                                    ? const CircularProgressIndicator()
                                    : Text(_error!,
                                        textAlign: TextAlign.center))
                            : GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onScaleStart: (details) {
                                  _start = _frame;
                                  _focal = details.localFocalPoint;
                                },
                                onScaleUpdate: (details) {
                                  final delta =
                                      (details.localFocalPoint - _focal) / size;
                                  setState(() => _frame = FanFraming(
                                        scale: (_start.scale * details.scale)
                                            .clamp(0.2, 4),
                                        x: (_start.x + delta.dx)
                                            .clamp(-0.3, 0.3),
                                        y: (_start.y + delta.dy)
                                            .clamp(-0.3, 0.3),
                                      ));
                                },
                                child: Transform.translate(
                                    offset: Offset(
                                        _frame.x * size, _frame.y * size),
                                    child: Transform.scale(
                                        scale: _frame.scale,
                                        child: Center(
                                            child: AspectRatio(
                                          aspectRatio: player.value.aspectRatio,
                                          child: VideoPlayer(player),
                                        )))),
                              ),
                      )),
                );
              })),
          if (player != null) ...[
            ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: player,
                builder: (context, value, _) => Column(children: [
                      Row(children: [
                        IconButton(
                            tooltip: value.isPlaying ? '暂停预览' : '播放预览',
                            onPressed: () => value.isPlaying
                                ? player.pause()
                                : player.play(),
                            icon: Icon(value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow)),
                        Expanded(
                            child: VideoProgressIndicator(player,
                                allowScrubbing: true,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20))),
                        Text(
                            '${value.position.inSeconds} / ${value.duration.inSeconds} 秒'),
                      ]),
                      if (value.hasError) const Text('播放失败，请返回后重试'),
                    ])),
            Row(children: [
              const Text('缩放'),
              Expanded(
                  child: Slider(
                      value: _frame.scale,
                      min: 0.2,
                      max: 4,
                      label: '${(_frame.scale * 100).round()}%',
                      onChanged: (value) => setState(() => _frame =
                          FanFraming(scale: value, x: _frame.x, y: _frame.y)))),
              Text('${(_frame.scale * 100).round()}%'),
            ]),
            Wrap(spacing: 8, children: [
              OutlinedButton(
                  onPressed: () => _preset(false), child: const Text('完整展示')),
              OutlinedButton(
                  onPressed: () => _preset(true), child: const Text('铺满圆形')),
              TextButton(
                  onPressed: () => _preset(false), child: const Text('重置')),
            ]),
            const Text('完整展示保留整帧画面；铺满圆形会裁掉边缘内容。'),
            if (_restoreFailed) const Text('上次取景未能读取，请重新调整后保存。'),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
              onPressed: player == null || _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? '保存中…' : '保存展示范围')),
          const SizedBox(height: 8),
          const OutlinedButton(onPressed: null, child: Text('转码并上传 · 暂未开放')),
          const Text('当前仅保存展示范围。设备转码接入后，可按此取景生成设备视频。',
              textAlign: TextAlign.center),
        ],
      )),
    );
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }
}
