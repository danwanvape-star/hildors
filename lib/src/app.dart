import 'package:flutter/material.dart';

import 'features/dashboard/dashboard_page.dart';
import 'theme/hildors_theme.dart';

class CockpitApp extends StatelessWidget {
  const CockpitApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Hildors Cockpit',
        debugShowCheckedModeBanner: false,
        theme: buildHildorsTheme(),
        home: const DashboardPage(),
      );
}
