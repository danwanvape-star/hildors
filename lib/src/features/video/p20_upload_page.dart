import 'dart:async';
import '../../localization/localization.dart';
import '../../device/p20_v2_connection.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../device/p20_device_client.dart';
import '../../device/p20_command_session.dart';
import 'fan_framing_page.dart';
import 'p20_ffmpeg_preparation.dart';
import 'p20_mobile_media_engine.dart';
import 'p20_media_upload_flow.dart';
import 'p20_upload_strings.dart';

class P20DeviceDestination implements P20MediaDestination {
  P20DeviceDestination(this.client, this.session, this.onProgress);
  final P20DeviceClient client;
  final P20CommandSession session;
  final void Function(int, int) onProgress;
  @override
  Future<void> cancel() => client.disconnect();
  @override
  Future<void> upload(File file, int listId, String name) =>
      client.uploadFile(file, listId, name.codeUnits, onProgress: onProgress);
  @override
  Future<void> refresh(int listId) async {
    await session.queryVideos(listId: listId);
  }
}

class P20UploadPage extends StatefulWidget {
  const P20UploadPage(
      {required this.client,
      required this.session,
      required this.source,
      required this.asset,
      required this.list,
      required this.framing,
      this.engine,
      super.key});
  final P20DeviceClient client;
  final P20CommandSession session;
  final String source;
  final bool asset;
  final P20MediaList list;
  final FanFraming framing;
  final P20MediaEngine? engine;
  @override
  State<P20UploadPage> createState() => _P20UploadPageState();
}

class _P20UploadPageState extends State<P20UploadPage> {
  P20MediaUploadFlow? _flow;
  P20MediaStage _stage = P20MediaStage.idle;
  P20MediaStage _lastActiveStage = P20MediaStage.idle;
  StreamSubscription<DeviceConnectionState>? _connection;
  bool _busy = false,
      _attempted = false,
      _cancelled = false,
      _cleanupPending = false;
  double? _progress;
  Object? _error;
  String? _uploadedName;

  @override
  void initState() {
    super.initState();
    _connection = widget.client.connectionStates.listen((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _run() async {
    if (_attempted || !widget.client.isConnected) return;
    setState(() {
      _busy = true;
      _attempted = true;
    });
    final engine = widget.engine ?? P20MobileMediaEngine();
    P20FfmpegPreparation? preparation;
    Directory? assets;
    try {
      final scheme = Uri.tryParse(widget.source)?.scheme;
      if (!widget.asset && (scheme == 'http' || scheme == 'https')) {
        throw const FormatException('download_first');
      }
      final temp = await getTemporaryDirectory();
      if (_cancelled) throw const P20UploadCancelled();
      var source = File(widget.source);
      if (widget.asset) {
        assets = await temp.createTemp('p20-source-');
        final data = await rootBundle.load(widget.source);
        source = await File('${assets.path}/source.mp4').writeAsBytes(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      }
      if (_cancelled) throw const P20UploadCancelled();
      preparation = P20FfmpegPreparation(engine, temp,
          settings: P20TranscodeSettings(
              scale: widget.framing.scale,
              x: widget.framing.x,
              y: widget.framing.y));
      final name =
          'h${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(0x7fffffff).toRadixString(16)}';
      final flow = P20MediaUploadFlow(
          preparation,
          P20DeviceDestination(widget.client, widget.session, (done, total) {
            if (mounted) setState(() => _progress = done / total);
          }), onStage: (stage) {
        if (mounted) {
          setState(() {
            _stage = stage;
            if (stage != P20MediaStage.failed &&
                stage != P20MediaStage.cancelled) {
              _lastActiveStage = stage;
              _progress = stage == P20MediaStage.uploadingAudio ||
                      stage == P20MediaStage.uploadingVideo
                  ? 0
                  : null;
            }
          });
        }
      });
      _flow = flow;
      try {
        await flow.run(source, widget.list, name);
      } finally {
        if (flow.videoUploaded) _uploadedName = '$name.mp4';
      }
    } catch (error) {
      _error = error;
      _stage = error is P20UploadCancelled || _cancelled
          ? P20MediaStage.cancelled
          : P20MediaStage.failed;
    } finally {
      try {
        await preparation?.dispose();
      } catch (_) {
        _cleanupPending = true;
      }
      if (assets != null && engine.isIdle) {
        try {
          await assets.delete(recursive: true);
        } catch (_) {
          _cleanupPending = true;
        }
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    if (_cancelled) return;
    setState(() => _cancelled = true);
    try {
      await _flow?.cancel();
    } catch (_) {/* Flow reports final state. */}
  }

  @override
  void dispose() {
    _cancelled = true;
    unawaited(_connection?.cancel());
    if (_busy) unawaited(_flow?.cancel().catchError((Object _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = P20UploadStrings(context);
    final finishedFile = _uploadedName != null;
    return PopScope(
        canPop: !_busy && _uploadedName == null,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !_busy) Navigator.pop(context, _uploadedName);
        },
        child: Scaffold(
            appBar: AppBar(
                title: Text(text.title),
                automaticallyImplyLeading: false,
                leading: !_busy
                    ? BackButton(
                        onPressed: () => Navigator.pop(context, _uploadedName))
                    : null),
            body: ListView(padding: const EdgeInsets.all(24), children: [
              Text(widget.list == P20MediaList.daily
                  ? text.daily
                  : text.bluetooth),
              const SizedBox(height: 16),
              Text(text.settings),
              const SizedBox(height: 24),
              Text(text.stage(_stage)),
              if (_busy || _progress != null) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: _progress)
              ],
              if (_progress != null) ...[
                Text('${(_progress! * 100).floor()}%'),
                Text(text.confirmedProgress),
              ],
              if (!_attempted && !widget.client.isConnected)
                Text(text.disconnected),
              if (_error != null && _stage != P20MediaStage.cancelled) ...[
                const SizedBox(height: 16),
                Text(text.failureStage(_lastActiveStage)),
                if (_error is TimeoutException &&
                    ((_error as TimeoutException).message ?? '')
                        .startsWith('P20 cmd='))
                  SelectableText((_error as TimeoutException).message!),
                if (_error is P20UploadResponseMismatch)
                  SelectableText(
                      (_error as P20UploadResponseMismatch).diagnostic),
                Text(finishedFile
                    ? text.refreshFailed
                    : _error is FormatException &&
                            (_error as FormatException).message ==
                                'download_first'
                        ? text.downloadFirst
                        : text.error(_error!, _lastActiveStage)),
                if ((_lastActiveStage == P20MediaStage.uploadingAudio ||
                        _lastActiveStage == P20MediaStage.uploadingVideo) &&
                    widget.client.lastUploadSnapshot != null)
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(text.transferDetails(
                            widget.client.lastUploadSnapshot!)),
                        SelectableText(
                            'TX queued=${widget.client.lastUploadSnapshot!.sent} flushed=${widget.client.lastUploadSnapshot!.flushed} ACK=${widget.client.lastUploadSnapshot!.acknowledged}'),
                      ]),
              ],
              if (!_busy && _attempted)
                OutlinedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: Text(context.l10n.copyDeviceLog),
                    onPressed: () async {
                      await Clipboard.setData(
                          ClipboardData(text: widget.client.wireLog.text));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.deviceLogCopied)));
                    }),
              if (_flow?.audioUploaded == true && !finishedFile)
                Text(text.partial),
              if (_cleanupPending) Text(text.cleanupPending),
              const SizedBox(height: 24),
              if (!_attempted)
                FilledButton(
                    onPressed: widget.client.isConnected &&
                            widget.client.modernProtocol
                        ? _run
                        : null,
                    child: Text(text.start)),
              if (_busy)
                OutlinedButton(
                    onPressed: _cancelled ? null : _cancel,
                    child: Text(text.cancel)),
              if (!_busy && _attempted)
                FilledButton(
                    onPressed: () => Navigator.pop(context, _uploadedName),
                    child: Text(text.close)),
            ])));
  }
}
