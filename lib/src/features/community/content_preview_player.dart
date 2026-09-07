import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../media/bundled_video_controller.dart';

class ContentPreviewPlayer extends StatefulWidget {
  const ContentPreviewPlayer({required this.assetPath, super.key});

  final String? assetPath;

  @override
  State<ContentPreviewPlayer> createState() => _ContentPreviewPlayerState();
}

class _ContentPreviewPlayerState extends State<ContentPreviewPlayer> {
  VideoPlayerController? _controller;
  String? _error;
  String? _technicalError;
  final _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final assetPath = widget.assetPath;
    if (assetPath == null) return;
    if (mounted) {
      setState(() {
        _error = null;
        _technicalError = null;
      });
    }
    try {
      final controller = await createBundledVideoController(assetPath);
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (error, stackTrace) {
      debugPrint('Preview video failed: ' + error.toString());
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _error = '预览加载失败，请稍后重试';
          _technicalError = error.toString();
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

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller?.value.isInitialized ?? false;
    return Container(
      height: 240,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ready)
            InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 4,
              boundaryMargin: const EdgeInsets.all(160),
              child: Center(
                child: AspectRatio(
                  aspectRatio: controller!.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),
            )
          else
            Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        if (_technicalError != null) ...[
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              _technicalError!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _initialize,
                          icon: const Icon(Icons.refresh),
                          label: const Text('重试'),
                        ),
                      ],
                    ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x99000000)],
              ),
            ),
          ),
          Center(
            child: IconButton.filled(
              tooltip: ready && controller!.value.isPlaying ? '暂停预览' : '播放预览',
              iconSize: 36,
              onPressed: ready ? _toggle : null,
              icon: Icon(
                ready && controller!.value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
            ),
          ),
          const Positioned(
            left: 14,
            bottom: 12,
            child: Chip(label: Text('双指缩放 · 拖动查看')),
          ),
          if (ready)
            Positioned(
              top: 10,
              right: 10,
              child: _PreviewZoomControls(
                onZoomOut: () => _zoomBy(0.8),
                onReset: _resetView,
                onZoomIn: () => _zoomBy(1.25),
              ),
            ),
        ],
      ),
    );
  }

  void _zoomBy(double factor) {
    final current = _transformationController.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(0.5, 4.0);
    _transformationController.value = Matrix4.diagonal3Values(next, next, 1);
  }

  void _resetView() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _controller?.dispose();
    super.dispose();
  }
}

class _PreviewZoomControls extends StatelessWidget {
  const _PreviewZoomControls({
    required this.onZoomOut,
    required this.onReset,
    required this.onZoomIn,
  });

  final VoidCallback onZoomOut;
  final VoidCallback onReset;
  final VoidCallback onZoomIn;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: '缩小',
              onPressed: onZoomOut,
              icon: const Icon(Icons.remove),
            ),
            TextButton(onPressed: onReset, child: const Text('1:1')),
            IconButton(
              tooltip: '放大',
              onPressed: onZoomIn,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      );
}
