import '../community/downloaded_character_store.dart';
import '../community/remote_catalog_repository.dart';
import '../community/verified_video_download.dart';
import 'cloud_business_intake.dart';

/// Private delivery uses the account-isolated offline library, never public media.
Future<void> downloadCustomDelivery(
    {required CloudBusinessIntake service,
    required String orderId,
    required DownloadCancellation cancellation,
    required void Function() guard,
    void Function(int, int)? onProgress,
    Future<DownloadedCharacterStore> Function(Uri, String) storeForAccount =
        DownloadedCharacterStore.forAccount}) async {
  guard();
  final identity = await service.downloadIdentity();
  guard();
  cancellation.check();
  final base = service.baseUri;
  if (base == null) throw const CloudApiException('SERVICE_UNAVAILABLE');
  final order =
      await service.orderRequest('GET', '/v1/me/customization-orders/$orderId');
  guard();
  cancellation.check();
  if (order['status'] != 'delivered' ||
      (order['payment'] as Map?)?['status'] != 'purchased') {
    throw const CloudApiException('DOWNLOAD_DENIED');
  }
  final media = order['deliverable'] as Map;
  final clip = RemoteCatalogClip(
      media['id'] as String,
      order['characterName'] as String? ?? '',
      (media['durationSeconds'] as num).toDouble());
  final package = RemoteCatalogPackage(
      id: 'custom-order-$orderId',
      title: clip.title,
      source: 'hildors',
      format: 'single',
      tags: const [],
      clips: [clip]);
  final store = await storeForAccount(base, identity.accountId);
  guard();
  cancellation.check();
  final file = await VerifiedVideoDownload(base, store.directory).download(
      packageId: package.id,
      clipId: clip.id,
      customOrderId: orderId,
      sessionToken: identity.token,
      cancellation: cancellation,
      onProgress: onProgress);
  var saved = false;
  try {
    guard();
    cancellation.check();
    final latest = await service.orderRequest(
        'GET', '/v1/me/customization-orders/$orderId');
    guard();
    cancellation.check();
    if (latest['status'] != 'delivered' ||
        (latest['payment'] as Map?)?['status'] != 'purchased' ||
        (latest['deliverable'] as Map?)?['id'] != clip.id) {
      throw const CloudApiException('DOWNLOAD_DENIED');
    }
    await store.save(package, clip, file);
    saved = true;
    guard();
    cancellation.check();
  } finally {
    if (!saved &&
        file.parent.parent.absolute.path == store.directory.absolute.path &&
        await file.parent.exists()) {
      await file.parent.delete(recursive: true);
    }
  }
}
