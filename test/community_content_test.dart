import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/community_content.dart';

void main() {
  test('only rights-verified community content can be downloaded', () {
    const verified = CommunityContent(
      id: '1',
      title: 'Original',
      creatorName: 'Creator',
      summary: 'Original work',
      category: 'Pets',
      license: CommunityLicense.personalUse,
      rightsStatus: CommunityRightsStatus.verified,
      playlistTarget: DevicePlaylistTarget.local,
      supportedModels: ['P20'],
      fileSizeMb: 10,
      durationSeconds: 12,
      version: '1.0',
    );
    const pending = CommunityContent(
      id: '2',
      title: 'Pending',
      creatorName: 'Creator',
      summary: 'Pending review',
      category: 'Pets',
      license: CommunityLicense.personalUse,
      rightsStatus: CommunityRightsStatus.pending,
      playlistTarget: DevicePlaylistTarget.local,
      supportedModels: ['P20'],
      fileSizeMb: 10,
      durationSeconds: 12,
      version: '1.0',
    );

    expect(verified.canDownload, isTrue);
    expect(verified.canInstall, isTrue);
    expect(pending.canDownload, isFalse);
    expect(pending.canInstall, isFalse);
  });
}
