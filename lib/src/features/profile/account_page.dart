import 'account_deletion_page.dart';
import 'package:flutter/material.dart';
import '../../localization/localization.dart';
import '../customization/cloud_business_intake.dart';
import '../customization/cloud_email_identity.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key, this.service});
  final CloudBusinessIntake? service;
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  CloudBusinessIntake get service =>
      widget.service ?? CloudBusinessIntake.instance;
  late Future<({String? email, bool signedIn, bool verified})> summary;
  bool busy = false;
  String? errorCode;
  @override
  void initState() {
    super.initState();
    summary = service.accountSummary();
  }

  Future<void> signIn() async {
    await showCloudEmailSignIn(context, service: service);
    if (mounted) {
      setState(() {
        summary = service.accountSummary();
        errorCode = null;
      });
    }
  }

  Future<void> signOut() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(context.l10n.accountSignOut),
              content: Text(context.l10n.accountSignOutConfirm),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(context.l10n.accountCancel)),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(context.l10n.accountSignOut))
              ],
            ));
    if (confirmed != true || !mounted) return;
    setState(() {
      busy = true;
      errorCode = null;
    });
    try {
      await service.signOutAllDevices();
      if (!mounted) return;
      setState(() {
        summary = service.accountSummary();
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.accountSignedOut)));
    } catch (error) {
      if (mounted) {
        setState(() {
          errorCode = error is CloudApiException ? error.code : 'NETWORK_ERROR';
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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.accountTitle)),
        body: FutureBuilder(
            future: summary,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text(context.l10n.errorGeneric));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final account = snapshot.data!;
              return ListView(padding: const EdgeInsets.all(20), children: [
                Text(account.email ??
                    (account.signedIn
                        ? context.l10n.accountGuest
                        : context.l10n.accountNone)),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: busy ? null : signIn,
                    child: Text(context.l10n.authTitle)),
                if (account.signedIn && !account.verified)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(context.l10n.accountGuestWarning)),
                if (account.signedIn)
                  OutlinedButton(
                      onPressed: busy || !account.verified ? null : signOut,
                      child: Text(context.l10n.accountSignOut)),
                if (account.signedIn)
                  TextButton(
                      onPressed: busy
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) =>
                                      AccountDeletionPage(service: service))),
                      child: Text(context.l10n.deletionTitle)),
                if (busy) const LinearProgressIndicator(),
                if (errorCode != null)
                  Text(localizedError(context.l10n, errorCode)),
              ]);
            }),
      );
}
