import 'dart:typed_data';

enum P20UploadDisposition { success, retry, storageFull, failed }

class P20UploadPolicy {
  const P20UploadPolicy._();

  static const int chunkSize = 32768;
  static const int successStatus = 0x01;
  static const int storageFullStatus = 0x85;

  static Iterable<Uint8List> chunks(Uint8List bytes) sync* {
    for (var offset = 0; offset < bytes.length; offset += chunkSize) {
      final end = (offset + chunkSize).clamp(0, bytes.length);
      yield Uint8List.sublistView(bytes, offset, end);
    }
  }

  static P20UploadDisposition classifyStatus(
    int statusCode, {
    Set<int> retryableStatusCodes = const {},
  }) {
    if (statusCode == successStatus) return P20UploadDisposition.success;
    if (statusCode == storageFullStatus) {
      return P20UploadDisposition.storageFull;
    }
    if (retryableStatusCodes.contains(statusCode)) {
      return P20UploadDisposition.retry;
    }
    return P20UploadDisposition.failed;
  }

  static String statusMessage(int statusCode) => switch (statusCode) {
        successStatus => '上传成功',
        storageFullStatus => '设备存储空间不足，请清理内容后重试',
        _ => '设备拒绝上传，状态码：0x${statusCode.toRadixString(16).toUpperCase()}',
      };
}
