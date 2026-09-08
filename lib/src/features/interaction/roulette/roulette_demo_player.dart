import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../media/bundled_video_controller.dart';

class RouletteDemoPlayer extends StatefulWidget {
  const RouletteDemoPlayer({required this.assetPath, super.key});

  final String assetPath;

  @override
  State<RouletteDemoPlayer> createState() => _RouletteDemoPlayerState();
}

class _RouletteDemoPlayerState extends State<RouletteDemoPlayer> {
  VideoPlayerController? _controller;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RouletteDemoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) _load();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final oldController = _controller;
    _controller = null;
    if (mounted) setState(() {});
    await oldController?.dispose();

    try {
      final controller = await createBundledVideoController(widget.assetPath);
      await controller.setLooping(true);
      await controller.play();
      if (!mounted || generation != _loadGeneration) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (error, stackTrace) {
      debugPrint('Roulette demo video failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Container(
      height: 250,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
      ),
      child: controller?.value.isInitialized == true
          ? Center(
              child: AspectRatio(
                aspectRatio: controller!.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            )
          : const Center(
              child: Icon(Icons.auto_awesome, color: Colors.cyan, size: 64),
            ),
    );
  }

  @override
  void dispose() {
    _loadGeneration++;
    _controller?.dispose();
    super.dispose();
  }
}
