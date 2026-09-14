import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/video/character_video_package.dart';
import 'package:hildors_cockpit/src/features/video/character_package_page.dart';

void main() {
  test('保留四个真实 Demo，播放选择以包内视频为单位', () {
    expect(officialVideoPackages, hasLength(4));
    final package = officialVideoPackages.first;
    expect(package.videos, isNotEmpty);
    expect(PackageVideoSelection(package, package.videos.first).key,
        isNot(package.id));
  });
  testWidgets('包内多选只返回勾选的视频，不返回整个角色', (tester) async {
    const package = CharacterVideoPackage(id: 'role', title: '测试角色', videos: [
      PackageVideo(
          id: 'idle', title: '待机', source: 'idle.mp4', durationSeconds: 10),
      PackageVideo(
          id: 'dance', title: '舞蹈', source: 'dance.mp4', durationSeconds: 20),
    ]);
    List<PackageVideoSelection>? result;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      result = await Navigator.of(context)
                          .push<List<PackageVideoSelection>>(MaterialPageRoute(
                              builder: (_) => const CharacterPackagePage(
                                  package: package, picking: true)));
                    },
                    child: const Text('打开'))))));
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('舞蹈'));
    await tester.pump();
    await tester.tap(find.text('添加 1 个视频到待处理区'));
    await tester.pumpAndSettle();
    expect(result!.single.video.id, 'dance');
    expect(result!.single.package.id, 'role');
  });
}
