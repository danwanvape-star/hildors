import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/catalog_governance.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_repository.dart';

void main() {
  const items = [RemoteCatalogPackage(id:'p', title:'Title', source:'creator', format:'single', tags:[], creatorId:'creator-1', clips:[RemoteCatalogClip('c','Clip',1)])];
  test('block list hides only the current account creator selection', () async {
    Future<List<RemoteCatalogPackage>> load(Set<String> ids) => loadVisibleCatalog(load: () async => items, blocks: () async => ids, identityRevision: () => 1);
    expect(await load({'creator-1'}), isEmpty);
    expect(await load({}), items);
    expect(await load({'another-creator'}), items);
  });
  test('identity switch discards stale account filtering', () async {
    var revision = 1;
    await expectLater(loadVisibleCatalog(load: () async => items, blocks: () async {revision++; return {};}, identityRevision: () => revision), throwsStateError);
  });
  test('block service failure does not silently show blocked content', () async {
    await expectLater(loadVisibleCatalog(load: () async => items, blocks: () async => throw StateError('offline'), identityRevision: () => 1), throwsStateError);
  });
}
