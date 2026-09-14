import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/dashboard/dashboard_page.dart';
import 'theme/hildors_theme.dart';

class CockpitApp extends StatelessWidget {
  const CockpitApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Hildors Cockpit',
        debugShowCheckedModeBanner: false,
        // Most product copy is currently Chinese. Keep the shipped UI coherent
        // until the remaining static strings move into the locale catalog.
        locale: const Locale('zh'),
        supportedLocales: const [
          Locale('zh'),
          Locale('en'),
          Locale('ja'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildHildorsTheme(),
        home: const DashboardPage(),
      );
}
