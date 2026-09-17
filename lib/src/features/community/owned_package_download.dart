import 'package:flutter/foundation.dart';
import '../customization/cloud_business_intake.dart';
import 'download_access_repository.dart';
import 'downloaded_character_store.dart';
import 'remote_catalog_repository.dart';
import 'verified_video_cache.dart';
import 'verified_video_download.dart';

typedef DownloadIdentity = ({String accountId, String token});

/// Server entitlement checks remain mandatory even when a preview is public.
class OwnedPackageDownloadController extends ChangeNotifier {
  OwnedPackageDownloadController(
      {required this.package,
      required this.baseUri,
      required this.identity,
      this.storeForAccount = DownloadedCharacterStore.forAccount});
  final RemoteCatalogPackage package;
  final Uri baseUri;
  final Future<DownloadIdentity> Function() identity;
  final Future<DownloadedCharacterStore> Function(Uri, String) storeForAccount;
  final Set<String> completed = {}, allowed = {};
  bool busy = false, preparing = false, _disposed = false;
  int received = 0, total = 0;
  String message = '', activeTitle = '';
  DownloadedCharacterStore? _store;
  String? _accountId;
  DownloadCancellation? _cancellation;

  static OwnedPackageDownloadController configured(
      RemoteCatalogPackage package) {
    final cloud = CloudBusinessIntake.instance;
    final base = cloud.baseUri;
    if (base == null) throw StateError('尚未配置云端服务');
    return OwnedPackageDownloadController(
        package: package, baseUri: base, identity: cloud.downloadIdentity);
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<DownloadIdentity> _bind() async {
    final current = await identity();
    if (_disposed) throw DownloadCancelled();
    if (_accountId != null && _accountId != current.accountId) {
      throw StateError('账号已变化，请重新打开下载页面');
    }
    _accountId = current.accountId;
    _store ??= await storeForAccount(baseUri, current.accountId);
    return current;
  }

  String _denied(DownloadAccess access) => switch (access) {
        DownloadAccess.disabled => '下载暂未开放，请稍后重试',
        DownloadAccess.signInRequired => '请重新确认账号后下载',
        _ => '领取或购买后才能下载；已拥有的内容请确认仍可用',
      };

  Future<void> prepare() async {
    if (_disposed || busy || preparing) return;
    preparing = true;
    message = '';
    _changed();
    try {
      final current = await _bind();
      allowed.clear();
      completed.clear();
      final library = await _store!.load();
      for (final item in library.where((p) => p.id == package.id)) {
        completed.addAll(item.videos.map((v) => v.id));
      }
      for (final clip in package.clips) {
        final access = await DownloadAccessRepository(baseUri)
            .check(package.id, clip.id, current.token);
        if (_disposed) return;
        if (access == DownloadAccess.allowed) {
          allowed.add(clip.id);
        } else {
          message = _denied(access);
        }
      }
    } catch (_) {
      message = '暂时无法确认下载权限，请检查网络和账号后重试';
    } finally {
      preparing = false;
      _changed();
    }
  }

  Future<void> download(List<RemoteCatalogClip> clips) async {
    if (_disposed || busy || preparing) return;
    final cancellation = DownloadCancellation();
    _cancellation = cancellation;
    busy = true;
    message = '';
    _changed();
    try {
      for (final requested in clips) {
        cancellation.check();
        final clip = package.clips.firstWhere((c) => c.id == requested.id);
        final current = await _bind();
        cancellation.check();
        final access = await DownloadAccessRepository(baseUri)
            .check(package.id, clip.id, current.token);
        cancellation.check();
        if (access != DownloadAccess.allowed) {
          allowed.remove(clip.id);
          message = _denied(access);
          break;
        }
        allowed.add(clip.id);
        activeTitle = clip.title;
        received = total = 0;
        _changed();
        final cache = VerifiedVideoCache(_store!.directory, baseUri.origin);
        var file = await cache.find(package.id, clip.id);
        cancellation.check();
        file ??=
            await VerifiedVideoDownload(baseUri, _store!.directory).download(
                packageId: package.id,
                clipId: clip.id,
                sessionToken: current.token,
                cancellation: cancellation,
                onProgress: (count, length) {
                  received = count;
                  total = length;
                  _changed();
                });
        cancellation.check();
        await _store!.save(package, clip, file);
        completed.add(clip.id);
        _changed();
      }
      if (message.isEmpty) message = '下载完成，已加入我的角色';
    } on DownloadCancelled {
      message = '下载已取消，已完成的视频保留在我的角色';
    } catch (_) {
      message = '下载未完成，请检查网络、存储空间和账号权限后重试';
    } finally {
      busy = false;
      _cancellation = null;
      _changed();
    }
  }

  void cancel() => _cancellation?.cancel();
  @override
  void dispose() {
    _disposed = true;
    cancel();
    super.dispose();
  }
}
