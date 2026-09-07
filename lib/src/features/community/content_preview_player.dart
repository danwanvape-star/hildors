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
      debugPrint('Preview video failed: $error');
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
          if (ready)
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
          if (ready)
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
    _transformationController.dispose();
    _controller?.dispose();
    super.dispose();
  }
}
