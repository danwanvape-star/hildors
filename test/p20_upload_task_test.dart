import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_upload_task.dart';

void main() {
  test('progress only counts bytes acknowledged by the device', () {
    var task = P20UploadTaskState.waiting(totalBytes: 40000).deviceReady();

    task = task.acknowledgeChunk(byteCount: 32768, deviceSequence: 7);

    expect(task.acknowledgedBytes, 32768);
    expect(task.acknowledgedChunks, 1);
    expect(task.lastDeviceSequence, 7);
    expect(task.fraction, closeTo(0.8192, 0.0001));
  });

  test('completion requires all file bytes to be acknowledged', () {
    final task = P20UploadTaskState.waiting(totalBytes: 10)
        .deviceReady()
        .acknowledgeChunk(byteCount: 9, deviceSequence: 1);

    expect(task.finish, throwsStateError);
  });

  test('completion reaches one only after the final short packet', () {
    var task = P20UploadTaskState.waiting(totalBytes: 32770).deviceReady();
    task = task.acknowledgeChunk(byteCount: 32768, deviceSequence: 1);
    task = task.acknowledgeChunk(byteCount: 2, deviceSequence: 2).finish();

    expect(task.phase, P20UploadPhase.completed);
    expect(task.fraction, 1);
  });

  test('cancel and device errors produce terminal states', () {
    final waiting = P20UploadTaskState.waiting(totalBytes: 100);

    expect(waiting.stopWithStatus(0x86).phase, P20UploadPhase.cancelled);
    expect(waiting.stopWithStatus(0x85).phase, P20UploadPhase.failed);
  });
}
