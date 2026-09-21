import 'dart:io';
import '../../localization/localization.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'cloud_business_intake.dart';

Future<bool> showCloudEmailSignIn(BuildContext context,
        {CloudBusinessIntake? service}) async =>
    await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            _EmailDialog(service ?? CloudBusinessIntake.instance)) ??
    false;

Future<bool> ensureCloudOrderEmail(BuildContext context,
    {CloudBusinessIntake? service}) async {
  final intake = service ?? CloudBusinessIntake.instance;
  final config = await intake.emailConfig();
  if (config['requireOrderEmail'] != true) return true;
  if (await intake.hasVerifiedEmail()) return true;
  if (!context.mounted) return false;
  return showCloudEmailSignIn(context, service: intake);
}

class _EmailDialog extends StatefulWidget {
  const _EmailDialog(this.service);
  final CloudBusinessIntake service;
  @override
  State<_EmailDialog> createState() => _EmailDialogState();
}

class _EmailDialogState extends State<_EmailDialog> {
  final email = TextEditingController(), code = TextEditingController();
  String? challenge, error;
  bool busy = false, enabled = false, checking = true;
  int seconds = 0;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    _config();
  }

  Future<void> _config() async {
    try {
      final value = await widget.service.emailConfig();
      if (!mounted) return;
      setState(() {
        enabled = value['enabled'] == true;
        if (!enabled) error = 'EMAIL_DISABLED';
      });
    } catch (e) {
      if (mounted) setState(() => error = e is CloudApiException ? e.code : e is SocketException || e is TimeoutException ? 'NETWORK_ERROR' : 'UNKNOWN');
    } finally {
      if (mounted) setState(() => checking = false);
    }
  }

  Future<void> _send() async {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.text.trim())) {
      setState(() => error = 'authInvalidEmail');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final value = await widget.service.startEmailSignIn(email.text);
      if (!mounted) return;
      setState(() {
        challenge = value['challengeId'] as String;
        seconds = (value['resendAfter'] as num).toInt();
        code.clear();
      });
      timer?.cancel();
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted || seconds <= 1) {
          t.cancel();
        }
        if (mounted) setState(() => seconds = seconds > 0 ? seconds - 1 : 0);
      });
    } catch (e) {
      if (mounted) setState(() => error = e is CloudApiException ? e.code : e is SocketException || e is TimeoutException ? 'NETWORK_ERROR' : 'UNKNOWN');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _verify() async {
    if (!RegExp(r'^\d{6}$').hasMatch(code.text.trim())) {
      setState(() => error = 'authInvalidCode');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.service.verifyEmailSignIn(challenge!, code.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = e is CloudApiException ? e.code : e is SocketException || e is TimeoutException ? 'NETWORK_ERROR' : 'UNKNOWN');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    email.dispose();
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !busy,
      child: AlertDialog(
        title: Text(context.l10n.authTitle),
        content: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(
                  context.l10n.authExplanation),
              TextField(
                  controller: email,
                  enabled: enabled && !busy && challenge == null,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(labelText: context.l10n.authEmail)),
              TextButton(
                  onPressed: enabled && !busy && seconds == 0 ? _send : null,
                  child: Text(seconds > 0
                      ? context.l10n.authResendSeconds(seconds)
                      : challenge == null
                          ? context.l10n.authSend
                          : context.l10n.authResend)),
              if (challenge != null) ...[
                Text(context.l10n.authSent),
                TextField(
                    controller: code,
                    enabled: !busy,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    decoration: InputDecoration(labelText: context.l10n.authCode)),
                TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() {
                              challenge = null;
                              code.clear();
                            }),
                    child: Text(context.l10n.authChange)),
              ],
              if (checking || busy) const LinearProgressIndicator(),
              if (error != null)
                Text(switch (error) {
                  'authInvalidEmail' => context.l10n.authInvalidEmail,
                  'authInvalidCode' => context.l10n.authInvalidCode,
                  _ => localizedError(context.l10n, error),
                },
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
            ])),
        actions: [
          TextButton(
              onPressed: busy ? null : () => Navigator.pop(context, false),
              child: Text(context.l10n.commonCancel)),
          FilledButton(
              onPressed: challenge != null && !busy ? _verify : null,
              child: Text(context.l10n.authVerify))
        ],
      ));
}
