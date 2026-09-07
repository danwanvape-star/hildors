import 'dart:convert';
import 'dart:typed_data';

enum P20UploadDevice { p20, p11 }

enum P20UploadDisposition {
  ready,
  chunkAccepted,
  complete,
  restartUpload,
  writeFailed,
  duplicateFile,
  invalidLength,
  videoLimitReached,
  storageFull,
  cancelled,
  failed,
}

class P20UploadPolicy {
  const P20UploadPolicy._();

  static const int p20ChunkSize = 32768;
  static const int p11LegacyChunkSize = 35700;
  static const int maximumEncodedFileSize = 0xFFFFFFFF;

  static const int readyStatus = 0x00;
  static const int chunkAcceptedStatus = 0x01;
  static const int completeStatus = 0x02;
  static const int timeoutStatus = 0x80;
  static const int writeFailedStatus = 0x81;
  static const int duplicateFileStatus = 0x82;
  static const int invalidLengthStatus = 0x83;
  static const int videoLimitStatus = 0x84;
  static const int storageFullStatus = 0x85;
  static const int cancelledStatus = 0x86;

  static int chunkSizeFor(P20UploadDevice device) => switch (device) {
        P20UploadDevice.p20 => p20ChunkSize,
        P20UploadDevice.p11 => p11LegacyChunkSize,
      };

  /// Encodes the data section of the framed 0x31 upload request:
  /// 4-byte big-endian file length followed by the UTF-8 filename.
  static Uint8List encodeRequestData({
    required int fileSize,
    required String fileName,
  }) {
    if (fileSize < 0 || fileSize > maximumEncodedFileSize) {
      throw RangeError.range(
        fileSize,
        0,
        maximumEncodedFileSize,
        'fileSize',
      );
    }
    final normalized = fileName.trim();
    final nameBytes = utf8.encode(normalized);
    if (nameBytes.isEmpty || nameBytes.length > 32) {
      throw ArgumentError.value(
        fileName,
        'fileName',
        '文件名按UTF-8编码后必须为1至32字节',
      );
    }
    final bytes = ByteData(4)..setUint32(0, fileSize, Endian.big);
    return Uint8List.fromList([...bytes.buffer.asUint8List(), ...nameBytes]);
  }

  static Iterable<Uint8List> chunks(
    Uint8List bytes, {
    P20UploadDevice device = P20UploadDevice.p20,
  }) sync* {
    final chunkSize = chunkSizeFor(device);
    for (var offset = 0; offset < bytes.length; offset += chunkSize) {
      final end = (offset + chunkSize).clamp(0, bytes.length);
      yield Uint8List.sublistView(bytes, offset, end);
    }
  }

  /// Decodes the 4-byte big-endian packet sequence in a 0x01 response.
  static int decodeAcknowledgedSequence(List<int> responseData) {
    if (responseData.length != 5 || responseData.first != chunkAcceptedStatus) {
      throw const FormatException('上传包回执格式不正确');
    }
    return ByteData.sublistView(Uint8List.fromList(responseData), 1)
        .getUint32(0, Endian.big);
  }

  static P20UploadDisposition classifyStatus(int statusCode) =>
      switch (statusCode) {
        readyStatus => P20UploadDisposition.ready,
        chunkAcceptedStatus => P20UploadDisposition.chunkAccepted,
        completeStatus => P20UploadDisposition.complete,
        timeoutStatus => P20UploadDisposition.restartUpload,
        writeFailedStatus => P20UploadDisposition.writeFailed,
        duplicateFileStatus => P20UploadDisposition.duplicateFile,
        invalidLengthStatus => P20UploadDisposition.invalidLength,
        videoLimitStatus => P20UploadDisposition.videoLimitReached,
        storageFullStatus => P20UploadDisposition.storageFull,
        cancelledStatus => P20UploadDisposition.cancelled,
        _ => P20UploadDisposition.failed,
      };

  static String statusMessage(int statusCode) => switch (statusCode) {
        readyStatus => '文件名校验通过，等待上传',
        chunkAcceptedStatus => '上传包已接收',
        completeStatus => '文件上传完成',
        timeoutStatus => '上传等待超时，请重新上传整个文件',
        writeFailedStatus => '设备写入失败，上传已终止',
        duplicateFileStatus => '设备中已存在同名文件',
        invalidLengthStatus => '文件长度不正确，请重新选择文件',
        videoLimitStatus => '设备视频数量已满，请删除部分内容后重试',
        storageFullStatus => '设备存储空间不足，请清理内容后重试',
        cancelledStatus => '上传已取消',
        _ => '设备拒绝上传，状态码：0x${statusCode.toRadixString(16).toUpperCase()}',
      };
}
