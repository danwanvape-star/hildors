import 'package:flutter/material.dart';
import 'locale_controller.dart';
import 'localization.dart';
class LanguageSettingsTile extends StatelessWidget {
  const LanguageSettingsTile({super.key});
  @override Widget build(BuildContext context) {
    final controller = LocaleScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    final strings = context.l10n;
    final labels = {LanguageChoice.system: strings.languageSystem, LanguageChoice.english: strings.languageEnglish, LanguageChoice.chinese: strings.languageChinese};
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(strings.languageTitle, style: Theme.of(context).textTheme.titleMedium),
      DropdownButton<LanguageChoice>(
        key: const Key('language-choice'), isExpanded: true,
        value: controller.choice,
        items: labels.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(),
        onChanged: (value) async {
          if (value == null) return;
          try { await controller.setChoice(value); } catch (_) {
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.languageSaveFailed)));
          }
        },
      ),
      Text(strings.languageFallback, style: Theme.of(context).textTheme.bodySmall),
    ])));
  }
}
