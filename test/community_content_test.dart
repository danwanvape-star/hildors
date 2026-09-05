import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/community_content.dart';

void main() {
  test('only rights-verified community content can be installed', () {
    const verified = CommunityContent(
      id: '1',
      title: 'Original',
      creatorName: 'Creator',
      summary: 'Original work',
      license: CommunityLicense.personalUse,
      rightsStatus: CommunityRightsStatus.verified,
      playlistTarget: DevicePlaylistTarget.local,
      supportedModels: ['P20'],
      fileSizeMb: 10,
      version: '1.0',
    );
    const pending = CommunityContent(
      id: '2',
      title: 'Pending',
      creatorName: 'Creator',
      summary: 'Pending review',
      license: CommunityLicense.personalUse,
      rightsStatus: CommunityRightsStatus.pending,
      playlistTarget: DevicePlaylistTarget.local,
      supportedModels: ['P20'],
      fileSizeMb: 10,
      version: '1.0',
    );

    expect(verified.canInstall, isTrue);
    expect(pending.canInstall, isFalse);
  });
}
