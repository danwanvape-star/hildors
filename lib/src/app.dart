import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import 'localization/locale_controller.dart';

import 'features/dashboard/dashboard_page.dart';
import 'theme/hildors_theme.dart';

class CockpitApp extends StatefulWidget {
  const CockpitApp({super.key, this.localeController});
  final LocaleController? localeController;
  @override State<CockpitApp> createState() => _CockpitAppState();
}

class _CockpitAppState extends State<CockpitApp> {
  late final _controller = widget.localeController ?? LocaleController();
  @override void initState() { super.initState(); if (widget.localeController == null) _controller.load(); }
  @override void dispose() { if (widget.localeController == null) _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => LocaleScope(controller: _controller,
    child: ListenableBuilder(listenable: _controller, builder: (context, _) => MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        debugShowCheckedModeBanner: false,
        locale: _controller.locale,
        localeListResolutionCallback: (preferred, supported) => resolveAppLocale(preferred),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: buildHildorsTheme(),
        home: const DashboardPage(),
      )),
  );
}
