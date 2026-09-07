import 'dart:typed_data';

enum P20UploadDisposition {
  success,
  restartUpload,
  duplicateFile,
  storageFull,
  cancelled,
  failed,
}

class P20UploadPolicy {
  const P20UploadPolicy._();

  static const int chunkSize = 32768;
  static const int readyStatus = 0x00;
  static const int successStatus = 0x01;
  static const int timeoutStatus = 0x80;
  static const int writeFailedStatus = 0x81;
  static const int duplicateFileStatus = 0x82;
  static const int storageFullStatus = 0x85;
  static const int cancelledStatus = 0x86;

  static Iterable<Uint8List> chunks(Uint8List bytes) sync* {
    for (var offset = 0; offset < bytes.length; offset += chunkSize) {
      final end = (offset + chunkSize).clamp(0, bytes.length);
      yield Uint8List.sublistView(bytes, offset, end);
    }
  }

  static P20UploadDisposition classifyStatus(int statusCode) {
    if (statusCode == successStatus) return P20UploadDisposition.success;
    if (statusCode == timeoutStatus) {
      return P20UploadDisposition.restartUpload;
    }
    if (statusCode == duplicateFileStatus) {
      return P20UploadDisposition.duplicateFile;
    }
    if (statusCode == storageFullStatus) {
      return P20UploadDisposition.storageFull;
    }
    if (statusCode == cancelledStatus) {
      return P20UploadDisposition.cancelled;
    }
    return P20UploadDisposition.failed;
  }

  static String statusMessage(int statusCode) => switch (statusCode) {
        readyStatus => '文件名校验通过，等待上传',
        successStatus => '上传包已接收',
        timeoutStatus => '上传等待超时，请重新上传整个文件',
        writeFailedStatus => '设备写入失败，上传已终止',
        duplicateFileStatus => '设备中已存在同名文件',
        storageFullStatus => '设备存储空间不足，请清理内容后重试',
        cancelledStatus => '上传已取消',
        _ => '设备拒绝上传，状态码：0x${statusCode.toRadixString(16).toUpperCase()}',
      };
}