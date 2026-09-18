import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../media/bundled_video_controller.dart';

class ContentPreviewPlayer extends StatefulWidget {
  const ContentPreviewPlayer(
      {required this.assetPath,
      this.networkUrl,
      this.autoPlay = false,
      super.key});

  final String? assetPath;
  final String? networkUrl;
  final bool autoPlay;

  @override
  State<ContentPreviewPlayer> createState() => _ContentPreviewPlayerState();
}

class _ContentPreviewPlayerState extends State<ContentPreviewPlayer> {
  VideoPlayerController? _controller;
  bool _routeIsCurrent = true;
  String? _error;
  Timer? _slowTimer;
  Completer<void>? _cancelLoading;
  bool _slow = false;
  bool _buffering = false;
  bool _playing = false;
  int _generation = 0;
  bool get _hasSource =>
      (widget.networkUrl?.isNotEmpty ?? false) ||
      (widget.assetPath?.isNotEmpty ?? false);
  final _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeIsCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    final controller = _controller;
    if (!_routeIsCurrent && controller?.value.isPlaying == true) {
      controller!.pause();
    }
  }

  @override
  void didUpdateWidget(covariant ContentPreviewPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.networkUrl != widget.networkUrl ||
        oldWidget.assetPath != widget.assetPath) {
      _initialize();
    }
  }

  void _startSlowTimer() {
    _slowTimer?.cancel();
    _slowTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _error == null) setState(() => _slow = true);
    });
  }

  void _onPlaybackChanged() {
    final value = _controller?.value;
    if (!mounted || value == null) return;
    if (value.hasError) {
      _slowTimer?.cancel();
      if (_error == null) setState(() => _error = '视频播放失败，请重试');
      return;
    }
    if (_buffering == value.isBuffering && _playing == value.isPlaying) return;
    if (_buffering != value.isBuffering) {
      _slow = false;
      if (value.isBuffering) {
        _startSlowTimer();
      } else {
        _slowTimer?.cancel();
      }
    }
    setState(() {
      _buffering = value.isBuffering;
      _playing = value.isPlaying;
    });
  }

  Future<void> _initialize() async {
    final assetPath = widget.assetPath;
    final networkUrl = widget.networkUrl;
    final generation = ++_generation;
    if (_cancelLoading?.isCompleted == false) _cancelLoading!.complete();
    final cancelled = Completer<void>();
    _cancelLoading = cancelled;
    final old = _controller;
    _controller = null;
    old?.removeListener(_onPlaybackChanged);
    if (old != null) unawaited(old.dispose());
    _slowTimer?.cancel();
    if (mounted) {
      setState(() {
        _error = null;
        _slow = false;
        _buffering = false;
        _playing = false;
      });
    }
    if (!_hasSource) return;
    _startSlowTimer();
    try {
      final creation = networkUrl != null && networkUrl.isNotEmpty
          ? Future.value(
              VideoPlayerController.networkUrl(Uri.parse(networkUrl)))
          : createBundledVideoController(assetPath!, cancel: cancelled.future);
      final controller = await Future.any<VideoPlayerController?>([
        creation.then((controller) {
          if (!mounted || generation != _generation) {
            unawaited(controller.dispose());
          }
          return controller;
        }),
        cancelled.future.then((_) => null),
      ]).timeout(const Duration(seconds: 30));
      if (!mounted || generation != _generation || controller == null) return;
      _controller = controller;
      if (!controller.value.isInitialized) {
        await Future.any<void>([controller.initialize(), cancelled.future])
            .timeout(const Duration(seconds: 30));
      }
      if (!mounted || generation != _generation) return;
      await controller.setLooping(true);
      if (!mounted || generation != _generation) return;
      _slowTimer?.cancel();
      setState(() {
        _slow = false;
        _buffering = controller.value.isBuffering;
      });
      if (_buffering) _startSlowTimer();
      controller.addListener(_onPlaybackChanged);
      if (widget.autoPlay && _routeIsCurrent) {
        await controller.play();
      }
    } catch (error, stackTrace) {
      debugPrint('Preview video failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted && generation == _generation) {
        _generation++;
        if (!cancelled.isCompleted) cancelled.complete();
        _slowTimer?.cancel();
        final failed = _controller;
        _controller = null;
        failed?.removeListener(_onPlaybackChanged);
        if (failed != null) unawaited(failed.dispose());
        setState(() {
          _error = error is TimeoutException ? '视频加载超时，请重试' : '视频加载失败，请重试';
        });
      }
    }
  }

  Future<void> _toggle() async {
    final controller = _controller;
    if (controller == null) return;
    controller.value.isPlaying
        ? await controller.pause()
        : await controller.play();
    if (mounted) setState(() {});
  }

  void _resetView() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller?.value.isInitialized ?? false;
    return Container(
      height: 280,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ready)
            GestureDetector(
              onDoubleTap: _resetView,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1,
                maxScale: 3,
                boundaryMargin: const EdgeInsets.all(80),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: controller!.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
            ),
          if (!ready || _buffering || _error != null)
            ColoredBox(
              color: ready ? Colors.black54 : Colors.black,
              child: Center(
                  child: Padding(
                padding: const EdgeInsets.all(20),
                child: Semantics(
                    liveRegion: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_hasSource && _error == null) ...[
                          const SizedBox(
                              width: 28,
                              height: 28,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.5)),
                          const SizedBox(height: 16),
                        ],
                        Text(
                            _error ??
                                (!_hasSource
                                    ? '暂无可播放视频'
                                    : widget.networkUrl != null
                                        ? '视频正在缓冲，请稍候'
                                        : '视频正在加载，请稍候'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white)),
                        if (_slow && _error == null)
                          const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('加载较慢，请检查网络或重试',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70))),
                        if (_error != null || _slow)
                          TextButton.icon(
                              onPressed: _initialize,
                              icon: const Icon(Icons.refresh),
                              label: const Text('重试')),
                      ],
                    )),
              )),
            ),
          if (ready && _error == null)
            Positioned(
              right: 12,
              bottom: 12,
              child: IconButton.filledTonal(
                tooltip: controller!.value.isPlaying ? '暂停预览' : '播放预览',
                onPressed: _toggle,
                icon: Icon(
                  controller.value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
              ),
            ),
          if (ready && !_buffering && _error == null)
            const Positioned(
              left: 12,
              bottom: 12,
              child: Chip(label: Text('双指缩放 · 双击复位')),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _generation++;
    if (_cancelLoading?.isCompleted == false) _cancelLoading!.complete();
    _slowTimer?.cancel();
    _transformationController.dispose();
    _controller?.removeListener(_onPlaybackChanged);
    _controller?.dispose();
    super.dispose();
  }
}
