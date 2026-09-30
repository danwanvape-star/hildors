import 'package:flutter/material.dart';
import '../../localization/localization.dart';

Future<String?> chooseUploadDisplayName(BuildContext context, String initial) =>
    showDialog<String>(
        context: context, builder: (_) => _UploadNameDialog(initial));

class _UploadNameDialog extends StatefulWidget {
  const _UploadNameDialog(this.initial);
  final String initial;
  @override
  State<_UploadNameDialog> createState() => _UploadNameDialogState();
}

class _UploadNameDialogState extends State<_UploadNameDialog> {
  late final _controller = TextEditingController(
      text: widget.initial.characters.take(60).toString());
  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(context.l10n.uploadDisplayName),
        content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 60,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit()),
          Text(context.l10n.uploadDisplayNameNote),
        ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.playlistCancel)),
          ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) => FilledButton(
                  onPressed: value.text.trim().isEmpty ? null : _submit,
                  child: Text(context.l10n.p20UploadAction))),
        ],
      );
}
