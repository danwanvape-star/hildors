import 'package:flutter/material.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';

import 'src/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  VideoPlayerMediaKit.ensureInitialized(android: true, iOS: true);
  runApp(const CockpitApp());
}
