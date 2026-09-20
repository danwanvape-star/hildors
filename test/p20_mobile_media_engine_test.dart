import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/video/p20_mobile_media_engine.dart';
import 'package:hildors_cockpit/src/features/video/p20_media_upload_flow.dart';

void main() {
  test('cancel during a native start without completion returns promptly',
      () async {
    final job = StalledJob()..starting = Completer<void>();
    final engine = P20MobileMediaEngine(
        factory: (_, __) async => job,
        cancellationTimeout: const Duration(milliseconds: 10));
    final pending = engine.execute(['input']);
    await job.started.future;
    final assertion = expectLater(pending, throwsA(isA<P20UploadCancelled>()));
    await engine.cancel();
    await assertion.timeout(const Duration(milliseconds: 300));
    expect(engine.isIdle, isFalse);
    job.starting!.complete();
    job.completion.complete('');
  });
  test('missing native completion exits within timeout and remains non-idle',
      () async {
    final job = StalledJob();
    final engine = P20MobileMediaEngine(
      factory: (_, __) async => job,
      executionTimeout: const Duration(milliseconds: 10),
      cancellationTimeout: const Duration(milliseconds: 10),
    );
    await expectLater(
        engine.execute(['input']), throwsA(isA<TimeoutException>()));
    expect(job.cancelled, isTrue);
    expect(engine.isIdle, isFalse);
    job.completion.complete('');
    expect(engine.isIdle, isTrue);
  });
  test('cancelled engine does not start native sessions', () async {
    final engine = P20MobileMediaEngine();
    await engine.cancel();
    await expectLater(
        engine.execute(['-version']), throwsA(isA<P20UploadCancelled>()));
  });
}

class StalledJob implements P20NativeJob {
  final started = Completer<void>();
  Completer<void>? starting;
  final completion = Completer<String>();
  bool cancelled = false;
  @override
  bool get finished => completion.isCompleted;
  @override
  Future<String> get result => completion.future;
  @override
  Future<void> start() async {
    started.complete();
    await starting?.future;
  }

  @override
  Future<void> cancel() async {
    cancelled = true;
  }
}
