import 'p20_upload_policy.dart';

enum P20UploadPhase {
  idle,
  waitingForDevice,
  transferring,
  completed,
  failed,
  cancelled,
}

class P20UploadTaskState {
  const P20UploadTaskState({
    required this.phase,
    required this.totalBytes,
    this.acknowledgedBytes = 0,
    this.acknowledgedChunks = 0,
    this.lastDeviceSequence,
    this.message,
  });

  factory P20UploadTaskState.waiting({required int totalBytes}) {
    return P20UploadTaskState(
      phase: P20UploadPhase.waitingForDevice,
      totalBytes: totalBytes,
    );
  }

  final P20UploadPhase phase;
  final int totalBytes;
  final int acknowledgedBytes;
  final int acknowledgedChunks;
  final int? lastDeviceSequence;
  final String? message;

  double get fraction => totalBytes == 0
      ? (phase == P20UploadPhase.completed ? 1 : 0)
      : (acknowledgedBytes / totalBytes).clamp(0, 1);

  P20UploadTaskState deviceReady() => _copyWith(
        phase: P20UploadPhase.transferring,
        message: '设备已就绪',
      );

  P20UploadTaskState acknowledgeChunk({
    required int byteCount,
    required int deviceSequence,
  }) {
    if (phase != P20UploadPhase.transferring) {
      throw StateError('只有传输中的任务可以确认数据包');
    }
    if (byteCount <= 0 || acknowledgedBytes + byteCount > totalBytes) {
      throw RangeError('确认的数据长度超出文件范围');
    }
    return _copyWith(
      acknowledgedBytes: acknowledgedBytes + byteCount,
      acknowledgedChunks: acknowledgedChunks + 1,
      lastDeviceSequence: deviceSequence,
      message: '设备已确认第 ${acknowledgedChunks + 1} 包',
    );
  }

  P20UploadTaskState finish() {
    if (acknowledgedBytes != totalBytes) {
      throw StateError('设备报告完成，但确认字节数与文件大小不一致');
    }
    return _copyWith(
      phase: P20UploadPhase.completed,
      message: P20UploadPolicy.statusMessage(
        P20UploadPolicy.completeStatus,
      ),
    );
  }

  P20UploadTaskState stopWithStatus(int statusCode) {
    final disposition = P20UploadPolicy.classifyStatus(statusCode);
    return _copyWith(
      phase: disposition == P20UploadDisposition.cancelled
          ? P20UploadPhase.cancelled
          : P20UploadPhase.failed,
      message: P20UploadPolicy.statusMessage(statusCode),
    );
  }

  P20UploadTaskState _copyWith({
    P20UploadPhase? phase,
    int? acknowledgedBytes,
    int? acknowledgedChunks,
    int? lastDeviceSequence,
    String? message,
  }) =>
      P20UploadTaskState(
        phase: phase ?? this.phase,
        totalBytes: totalBytes,
        acknowledgedBytes: acknowledgedBytes ?? this.acknowledgedBytes,
        acknowledgedChunks: acknowledgedChunks ?? this.acknowledgedChunks,
        lastDeviceSequence: lastDeviceSequence ?? this.lastDeviceSequence,
        message: message ?? this.message,
      );
}
