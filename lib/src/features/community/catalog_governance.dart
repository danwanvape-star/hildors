import 'remote_catalog_repository.dart';

/// Never display an old account's filter result after an identity change.
Future<List<RemoteCatalogPackage>> loadVisibleCatalog({
  required Future<List<RemoteCatalogPackage>> Function() load,
  required Future<Set<String>> Function() blocks,
  required int Function() identityRevision,
}) async {
  final revision = identityRevision();
  final items = await load();
  final hidden = await blocks();
  if (revision != identityRevision()) throw StateError('ACCOUNT_CHANGED');
  return items.where((item) => !hidden.contains(item.creatorId)).toList(growable: false);
}
