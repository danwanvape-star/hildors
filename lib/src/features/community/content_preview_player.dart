import '../../localization/localization.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import '../../media/bundled_video_controller.dart';
import '../../media/preview_video_cache.dart';

class ContentPreviewPlayer extends StatefulWidget {
  const ContentPreviewPlayer(
      {required this.assetPath,
      this.networkUrl,
      this.autoPlay = false,
      this.httpHeaders = const {},
      this.refreshHttpHeaders,
      this.previewCache,
      super.key});

  final String? assetPath;
  final String? networkUrl;
  final bool autoPlay;
  final Map<String, String> httpHeaders;
  final Future<Map<String, String>> Function()? refreshHttpHeaders;
  final PreviewVideoCache? previewCache;

  @override
  State<ContentPreviewPlayer> createState() => _ContentPreviewPlayerState();
}

class _ContentPreviewPlayerState extends State<ContentPreviewPlayer> {
  PreviewVideoCache get _cache =>
      widget.previewCache ?? PreviewVideoCache.shared;
  VideoPlayerController? _controller;
  bool _routeIsCurrent = true;
  String? _error;
  Timer? _slowTimer;
  Completer<void>? _cancelLoading;
  bool _slow = false;
  bool _buffering = false;
  bool _playing = false;
  int _generation = 0;
  Duration _lastPosition = Duration.zero;
  bool _cacheScheduled = false;
  bool _retrying = false;
  Map<String, String>? _refreshedHeaders;
  Map<String, String> get _headers => _refreshedHeaders ?? widget.httpHeaders;
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
        oldWidget.assetPath != widget.assetPath ||
        !mapEquals(oldWidget.httpHeaders, widget.httpHeaders)) {
      _refreshedHeaders = null;
      _initialize();
    }
  }

  void _startSlowTimer() {
    _slowTimer?.cancel();
    _slowTimer = Timer(Duration(seconds: 10), () {
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
    final completedPass = value.isCompleted ||
        (_lastPosition > value.duration * 0.8 &&
            value.position < value.duration * 0.2);
    _lastPosition = value.position;
    if (_headers.isEmpty &&
        !_cacheScheduled &&
        completedPass &&
        widget.networkUrl != null) {
      _cacheScheduled = true;
      final generation = _generation;
      unawaited(_cache
          .warm(Uri.parse(widget.networkUrl!), cancel: _cancelLoading?.future)
          .whenComplete(() {
        if (mounted && generation == _generation) _cacheScheduled = false;
      }));
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
    _lastPosition = Duration.zero;
    _cacheScheduled = false;
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
          ? _networkController(Uri.parse(networkUrl), cancelled.future)
          : createBundledVideoController(assetPath!, cancel: cancelled.future);
      var controller = await Future.any<VideoPlayerController?>([
        creation.then((controller) {
          if (!mounted || generation != _generation) {
            unawaited(controller.dispose());
          }
          return controller;
        }),
        cancelled.future.then((_) => null),
      ]).timeout(Duration(seconds: 30));
      if (!mounted || generation != _generation || controller == null) return;
      _controller = controller;
      if (!controller.value.isInitialized) {
        try {
          await Future.any<void>([controller.initialize(), cancelled.future])
              .timeout(Duration(seconds: 30));
        } catch (_) {
          if (!mounted ||
              generation != _generation ||
              controller.dataSourceType != DataSourceType.file ||
              networkUrl == null ||
              networkUrl.isEmpty) {
            rethrow;
          }
          await controller.dispose();
          await _cache.discard(Uri.parse(networkUrl));
          if (!mounted || generation != _generation) return;
          controller = VideoPlayerController.networkUrl(Uri.parse(networkUrl),
              httpHeaders: _headers);
          _controller = controller;
          await Future.any<void>([controller.initialize(), cancelled.future])
              .timeout(Duration(seconds: 30));
        }
      }
      if (!mounted || generation != _generation) return;
      await controller.setLooping(true);
      if (!mounted || generation != _generation) return;
      _slowTimer?.cancel();
      setState(() {
        _slow = false;
        _buffering = controller!.value.isBuffering;
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

  Future<VideoPlayerController> _networkController(
      Uri uri, Future<void> cancel) async {
    if (_headers.isNotEmpty) {
      return VideoPlayerController.networkUrl(uri, httpHeaders: _headers);
    }
    final file = await _cache.validatedFile(uri, cancel: cancel);
    return file == null
        ? VideoPlayerController.networkUrl(uri)
        : VideoPlayerController.file(file);
  }

  Future<void> _retry() async {
    if (_retrying) return;
    _retrying = true;
    try {
      final refresh = widget.refreshHttpHeaders;
      if (refresh != null) {
        final headers = await refresh();
        if (!mounted) return;
        _refreshedHeaders = headers;
      }
      await _initialize();
    } catch (_) {
      if (mounted) setState(() => _error = '授权刷新失败，请返回投稿列表重试');
    } finally {
      _retrying = false;
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
      height: MediaQuery.textScalerOf(context).scale(1) > 1.4 ? 380 : 280,
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
                boundaryMargin: EdgeInsets.all(80),
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
                padding: EdgeInsets.all(20),
                child: Semantics(
                    liveRegion: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_hasSource && _error == null) ...[
                          SizedBox(
                              width: 28,
                              height: 28,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.5)),
                          SizedBox(height: 16),
                        ],
                        Text(
                            (_error == null ? null : switch (_error) {
'视频播放失败，请重试' => context.l10n.playerFailed,
'视频加载超时，请重试' => context.l10n.playerTimeout,
'视频加载失败，请重试' => context.l10n.playerLoadFailed,
'授权刷新失败，请返回投稿列表重试' => context.l10n.playerAuthFailed,
_ => context.l10n.playerLoadFailed,}) ??
                                (!_hasSource
                                    ? context.l10n.playerNoSource
                                    : widget.networkUrl != null
                                        ? context.l10n.playerBuffering
                                        : context.l10n.playerLoading),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white)),
                        if (_slow && _error == null)
                          Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(context.l10n.playerSlow,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70))),
                        if (_error != null || _slow)
                          TextButton.icon(
                              onPressed: _retry,
                              icon: Icon(Icons.refresh),
                              label: Text(context.l10n.commonRetry)),
                      ],
                    )),
              )),
            ),
          if (ready && _error == null)
            Positioned(
              right: 12,
              bottom: 12,
              child: IconButton.filledTonal(
                tooltip: controller!.value.isPlaying ? context.l10n.playerPause : context.l10n.playerPlay,
                onPressed: _toggle,
                icon: Icon(
                  controller.value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
              ),
            ),
          if (ready && !_buffering && _error == null)
            Positioned(
              left: 12,
              bottom: 12,
              child: Chip(label: Text(context.l10n.playerZoom)),
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
