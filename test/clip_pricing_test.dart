import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_repository.dart';

Map<String, dynamic> catalog(Object? pricing, {bool omit = false}) => {
      'id': 'p',
      'title': '角色',
      'status': 'published',
      'source': 'hildors',
      'format': 'single',
      'tags': [],
      'clips': [
        {
          'id': 'c',
          'title': '视频',
          'previewPath': '/preview',
          if (!omit) 'pricing': pricing,
        }
      ],
    };

void main() {
  test('missing pricing preserves legacy neutral copy', () {
    final clip =
        RemoteCatalogPackage.fromJson(catalog(null, omit: true)).clips.single;
    expect(clip.pricing, isNull);
    expect(clip.downloadLabel, '下载到我的角色');
  });
  test('valid USD prices survive URL resolution with exact cents', () async {
    for (final cents in [0, 1, 1099, 99999999]) {
      final repo = RemoteCatalogRepository('https://example.test',
          fetch: (_) async => jsonEncode({
                'items': [
                  catalog({
                    'mode': cents == 0 ? 'free' : 'paid',
                    'currency': 'USD',
                    'amountMinor': cents
                  })
                ]
              }));
      final clip = (await repo.load()).single.clips.single;
      expect(clip.pricing!.amountMinor, cents);
      expect(clip.previewUrl, 'https://example.test/preview');
      expect(
          clip.downloadLabel,
          cents == 0
              ? '免费下载'
              : 'US\$ ${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')} · 购买下载');
    }
  });
  test('malformed pricing fails closed', () {
    for (final raw in [
      null,
      'free',
      {},
      {'mode': 'free', 'currency': 'USD', 'amountMinor': 1},
      {'mode': 'paid', 'currency': 'USD', 'amountMinor': 0},
      {'mode': 'paid', 'currency': 'USD', 'amountMinor': -1},
      {'mode': 'paid', 'currency': 'USD', 'amountMinor': 100000000},
      {'mode': 'paid', 'currency': 'USD', 'amountMinor': 1.5},
      {'mode': 'paid', 'currency': 'USD', 'amountMinor': '100'},
      {'mode': 'paid', 'currency': 'EUR', 'amountMinor': 100},
      {'mode': 'other', 'currency': 'USD', 'amountMinor': 100}
    ]) {
      expect(() => RemoteCatalogPackage.fromJson(catalog(raw)),
          throwsFormatException,
          reason: '$raw');
    }
  });
}
