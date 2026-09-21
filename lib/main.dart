import 'package:flutter/material.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';

import 'src/app.dart';
import 'src/localization/locale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  VideoPlayerMediaKit.ensureInitialized(android: true, iOS: true);
  final localeController = LocaleController();
  await localeController.load();
  runApp(CockpitApp(localeController: localeController));
}
