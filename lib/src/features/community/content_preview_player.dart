import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ContentPreviewPlayer extends StatefulWidget {
  const ContentPreviewPlayer({required this.assetPath, super.key});

  final String? assetPath;

  @override
  State<ContentPreviewPlayer> createState() => _ContentPreviewPlayerState();
}

class _ContentPreviewPlayerState extends State<ContentPreviewPlayer> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final assetPath = widget.assetPath;
    if (assetPath == null) return;
    final controller = VideoPlayerController.asset(assetPath);
    try {
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _error = '预览加载失败，请稍后重试');
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
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller!.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            )
          else
            Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Text(_error!, textAlign: TextAlign.center),
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
            child: Chip(label: Text('手机预览')),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
