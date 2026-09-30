import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../localization/localization.dart';

const supportEmail = 'support@marketing.hildors.com';
final supportMailUri = Uri(
    scheme: 'mailto',
    path: supportEmail,
    query: 'subject=${Uri.encodeComponent('Hildors App support')}');

class SupportPage extends StatefulWidget {
  const SupportPage({super.key, this.openMail});
  final Future<bool> Function(Uri)? openMail;
  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  bool _opening = false;
  bool _failed = false;
  Future<void> _write() async {
    setState(() {
      _opening = true;
      _failed = false;
    });
    var opened = false;
    try {
      opened = await (widget.openMail?.call(supportMailUri) ??
          launchUrl(supportMailUri));
    } catch (_) {/* Copy remains available without a mail app. */}
    if (mounted) {
      setState(() {
        _opening = false;
        _failed = !opened;
      });
    }
  }

  Future<void> _copy() async {
    try {
      await Clipboard.setData(const ClipboardData(text: supportEmail));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.supportEmailCopied)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.supportCopyFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(context.l10n.supportContact)),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        Text(context.l10n.supportInstructions),
        const SizedBox(height: 20),
        const SelectableText(supportEmail),
        const SizedBox(height: 20),
        FilledButton.icon(
            onPressed: _opening ? null : _write,
            icon: const Icon(Icons.email_outlined),
            label: Text(context.l10n.supportWriteEmail)),
        OutlinedButton.icon(
            onPressed: _copy,
            icon: const Icon(Icons.copy),
            label: Text(context.l10n.supportCopyEmail)),
        if (_failed) Text(context.l10n.supportNoMailApp),
      ]));
}
