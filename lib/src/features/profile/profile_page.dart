import '../customization/custom_plans_page.dart';
import 'package:flutter/material.dart';
import '../community/content_governance.dart';
import 'account_page.dart';
import '../../config/launch_config.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';

import '../../device/p20_command_session.dart';
import '../../device/p20_device_client.dart';
import '../../theme/hildors_theme.dart';
import '../customization/character_gate_prototype_pages.dart';
import '../settings/lan_connection_guide.dart';
import '../settings/playback_mode_guide.dart';
import '../settings/settings_page.dart';
import '../video/playlist_management_page.dart';
import '../video/video_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({required this.client, required this.session, super.key});

  final P20DeviceClient client;
  final P20CommandSession session;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          toolbarHeight:
              56 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.5),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.coreProfile),
              Text(
                context.l10n.coreProfileLabel,
                style: TextStyle(
                  color: HildorsColors.teal,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.1,
                ),
              ),
            ],
          ),
        ),
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.9, -0.75),
              radius: 1.15,
              colors: [Color(0x36234F70), HildorsColors.background],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              _ProfileHero(),
              if (LaunchConfig.usFree)
                _Entry(
                  icon: Icons.email_outlined,
                  title: context.l10n.accountTitle,
                  subtitle: context.l10n.authEmail,
                  onTap: () => _open(context, const AccountPage()),
                ),
              if (LaunchConfig.usFree) _Entry(icon: Icons.movie_creation_outlined,title: context.l10n.customPlansTitle,subtitle: context.l10n.customOrdersTitle,onTap: () => _open(context,const CustomPlansPage())),
              SizedBox(height: 22),
              _SectionLabel(
                  index: '01', title: context.l10n.coreDeviceManagement),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.router_outlined,
                      label: context.l10n.coreDevices,
                      onTap: () => _open(
                        context,
                        SettingsPage(client: client, session: session),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.playlist_play_rounded,
                      label: context.l10n.corePlaylist,
                      onTap: () => _open(
                        context,
                        PlaylistManagementPage(
                          client: client,
                          session: session,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.video_library_outlined,
                      label: context.l10n.coreDeviceContent,
                      onTap: () => _open(
                        context,
                        VideoPage(client: client, session: session),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _SectionLabel(
                  index: '02', title: context.l10n.coreCharacterAssets),
              SizedBox(height: 10),
              if (!LaunchConfig.usFree)
                _Entry(
                  icon: Icons.auto_awesome_rounded,
                  eyebrow: context.l10n.coreServiceLabel,
                  title: context.l10n.coreCustomOrders,
                  subtitle: context.l10n.coreOrdersSubtitle,
                  accent: HildorsColors.purpleBright,
                  onTap: () =>
                      _open(context, MyCharactersPage(ordersOnly: true)),
                ),
              _Entry(
                icon: Icons.handyman_outlined,
                eyebrow: context.l10n.coreCreatorLabel,
                title: context.l10n.coreCreatorCenter,
                subtitle: LaunchConfig.usFree
                    ? context.l10n.coreCreatorFreeSubtitle
                    : context.l10n.coreCreatorSubtitle,
                onTap: () => _open(context, CreatorHubPage()),
              ),
              SizedBox(height: 24),
              _SectionLabel(index: '03', title: context.l10n.coreSupport),
              if (LaunchConfig.usFree)
                _Entry(
                  icon: Icons.shield_outlined,
                  title: context.l10n.governanceTitle,
                  subtitle: context.l10n.governanceReports,
                  onTap: () => _open(context, const ContentGovernancePage()),
                ),
              SizedBox(height: 10),
              _Entry(
                icon: Icons.play_circle_outline_rounded,
                title: context.l10n.corePlaybackGuide,
                subtitle: context.l10n.corePlaybackGuideSubtitle,
                onTap: () => _open(context, PlaybackModeGuide()),
              ),
              _Entry(
                icon: Icons.wifi_find_rounded,
                title: context.l10n.coreLanHelp,
                subtitle: context.l10n.coreLanHelpSubtitle,
                onTap: () => _open(context, LanConnectionGuide()),
              ),
              _Entry(
                icon: Icons.tune_rounded,
                title: context.l10n.coreAppSettings,
                subtitle: context.l10n.coreAppSettingsSubtitle,
                onTap: () => _open(
                  context,
                  SettingsPage(client: client, session: session),
                ),
              ),
              _Entry(
                icon: Icons.info_outline_rounded,
                title: context.l10n.coreAbout,
                subtitle: context.l10n.coreAboutSubtitle,
              ),
            ],
          ),
        ),
      );

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero();

  @override
  Widget build(BuildContext context) => Container(
        height: 172 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.5),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: HildorsColors.hairline),
          boxShadow: [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/content_thumbnails/space_pilot.jpg',
              fit: BoxFit.cover,
              alignment: Alignment(0, -0.22),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0x2234E7D4), Color(0xF205080D)],
                  stops: [0, 0.82],
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 18,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Color(0xB30D131C),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: HildorsColors.teal),
                ),
                child: Text(
                  context.l10n.coreLocalLabel,
                  style: TextStyle(
                    color: HildorsColors.teal,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 16,
              bottom: 18,
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    padding: EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Color(0x55FFFFFF)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.asset(
                        'assets/images/hildors_logo.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n.corePilotLabel,
                          style: TextStyle(
                            color: HildorsColors.teal,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          context.l10n.corePlayerProfile,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          context.l10n.coreLocalAccount,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: HildorsColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.index, required this.title});

  final String index;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(index,
              style: TextStyle(
                color: HildorsColors.teal,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
              )),
          SizedBox(width: 10),
          Container(width: 20, height: 1, color: HildorsColors.teal),
          SizedBox(width: 10),
          Expanded(
              child: Text(title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ))),
        ],
      );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: HildorsColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: HildorsColors.hairline),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: HildorsColors.blue, size: 26),
                SizedBox(height: 9),
                Text(label,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.accent = HildorsColors.blue,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? eyebrow;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Material(
          color: HildorsColors.surface,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              constraints: BoxConstraints(minHeight: 82),
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: HildorsColors.hairline),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withValues(alpha: 0.3)),
                    ),
                    child: Icon(icon, color: accent, size: 23),
                  ),
                  SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (eyebrow != null) ...[
                          Text(eyebrow!,
                              style: TextStyle(
                                color: accent,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.3,
                              )),
                          SizedBox(height: 2),
                        ],
                        Text(title,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        SizedBox(height: 3),
                        Text(subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: HildorsColors.textSecondary,
                              fontSize: 12,
                              height: 1.35,
                            )),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  if (onTap != null)
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 15, color: HildorsColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      );
}
