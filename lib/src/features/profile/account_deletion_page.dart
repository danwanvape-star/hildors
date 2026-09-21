import 'package:flutter/material.dart';
import '../../localization/localization.dart';
import '../customization/cloud_business_intake.dart';

class AccountDeletionPage extends StatefulWidget {
  const AccountDeletionPage({super.key, required this.service});
  final CloudBusinessIntake service;
  @override
  State<AccountDeletionPage> createState() => _AccountDeletionPageState();
}

class _AccountDeletionPageState extends State<AccountDeletionPage> {
  late final int identity;
  Map<String, dynamic>? request;
  bool busy = true;
  String? error;
  @override
  void initState() {
    super.initState();
    identity = widget.service.identityRevision;
    load();
  }

  Future<void> load({String? action}) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (identity != widget.service.identityRevision) {
        throw const CloudApiException('SESSION_EXPIRED');
      }
      final result = await widget.service.contentRequest(
          action == null ? 'GET' : 'POST',
          '/v1/me/deletion-request${action == 'cancel' ? '/cancel' : ''}',
          document: action == null
              ? null
              : action == 'cancel'
                  ? {'version': request!['version']}
                  : {'confirm': true});
      if (identity != widget.service.identityRevision) {
        throw const CloudApiException('SESSION_EXPIRED');
      }
      if (result.statusCode != 200) {
        throw CloudApiException(result.statusCode == 409
            ? 'CONFLICT'
            : result.statusCode == 401
                ? 'SESSION_EXPIRED'
                : 'SERVICE_UNAVAILABLE');
      }
      final value = result.body['request'];
      if (value != null &&
          (value is! Map<String, dynamic> ||
              value['id'] is! String ||
              value['version'] is! int ||
              !['received', 'in_review', 'needs_information', 'cancelled']
                  .contains(value['status']))) {
        throw const CloudApiException('SERVICE_UNAVAILABLE');
      }
      if (mounted) {
        setState(() {
          request = value as Map<String, dynamic>?;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e is CloudApiException
              ? e.code
              : e is CloudSessionRecoveryRequired
                  ? 'SESSION_EXPIRED'
                  : 'NETWORK_ERROR';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  Future<void> submit() async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(context.l10n.deletionTitle),
                content: Text(context.l10n.deletionConfirm),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(context.l10n.accountCancel)),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(context.l10n.deletionSubmit))
                ]));
    if (yes == true && mounted) await load(action: 'submit');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final status = switch (request?['status']) {
      'received' => l.deletionReceived,
      'in_review' => l.deletionReview,
      'needs_information' => l.deletionInformation,
      'cancelled' => l.deletionCancelled,
      _ => l.deletionNone
    };
    return Scaffold(
        appBar: AppBar(title: Text(l.deletionTitle)),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text(l.deletionExplanation),
          const SizedBox(height: 20),
          if (busy) const LinearProgressIndicator(),
          Text(status),
          if (request != null)
            Text(l.deletionReference(request!['id'] as String)),
          if (request?['message'] is String &&
              (request!['message'] as String).isNotEmpty)
            Text(request!['message'] as String),
          if (error != null) Text(localizedError(l, error)),
          TextButton(
              onPressed: busy ? null : () => load(),
              child: Text(l.deletionRefresh)),
          if (request == null || request?['status'] == 'cancelled')
            FilledButton(
                onPressed: busy || error != null ? null : submit,
                child: Text(l.deletionSubmit))
          else
            OutlinedButton(
                onPressed:
                    busy || error != null ? null : () => load(action: 'cancel'),
                child: Text(l.deletionCancel)),
        ]));
  }
}
