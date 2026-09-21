import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import '../../localization/localization.dart';
import '../../device/p20_v2_connection.dart';
import 'p20_media_upload_flow.dart';

class P20UploadStrings {
  P20UploadStrings(BuildContext context) : _l10n = context.l10n;
  final AppLocalizations _l10n;
  String get title => _l10n.p20UploadTitle;
  String get start => _l10n.p20UploadStart;
  String get cancel => _l10n.p20UploadCancel;
  String get close => _l10n.p20UploadClose;
  String get disconnected => _l10n.p20UploadDisconnected;
  String get daily => _l10n.p20UploadDaily;
  String get bluetooth => _l10n.p20UploadBluetooth;
  String get settings => _l10n.p20UploadSettings;
  String get downloadFirst => _l10n.p20UploadDownloadFirst;
  String get failed => _l10n.p20UploadFailed;
  String get confirmedProgress => _l10n.p20UploadConfirmedProgress;
  String failureStage(P20MediaStage value) =>
      _l10n.p20UploadFailureStage(stage(value));
  String transferDetails(P20UploadSnapshot snapshot) {
    final phase = [
      _l10n.p20UploadWaitingAcceptance,
      _l10n.p20UploadTransferring,
      _l10n.p20UploadWaitingCompletion,
      _l10n.p20UploadConfirmedCompletion
    ][snapshot.phase.index];
    return _l10n.p20UploadTransferDetails(
        phase, snapshot.acknowledged, snapshot.total);
  }

  String error(Object error, P20MediaStage stage) {
    if (error is P20DeviceUploadRejected) {
      final reason = switch (error.status) {
        0x80 => _l10n.p20UploadBusy,
        0x81 => _l10n.p20UploadWriteFailed,
        0x82 => _l10n.p20UploadAlreadyExists,
        0x85 => _l10n.p20UploadStorageFull,
        0x8a => _l10n.p20UploadBatteryLow,
        _ => _l10n.p20UploadRejected,
      };
      return '$reason (0x${error.status.toRadixString(16).toUpperCase()})';
    }
    if (error is TimeoutException) {
      final uploading = stage == P20MediaStage.uploadingAudio ||
          stage == P20MediaStage.uploadingVideo;
      return uploading
          ? (_l10n.p20UploadConfirmationTimeout)
          : (_l10n.p20UploadProcessingTimeout);
    }
    if (error is SocketException) {
      return _l10n.p20UploadConnectionLost;
    }
    if (error is FileSystemException) {
      return _l10n.p20UploadLocalFileError;
    }
    if (error is FormatException &&
        (stage == P20MediaStage.uploadingAudio ||
            stage == P20MediaStage.uploadingVideo)) {
      return _l10n.p20UploadInvalidReply;
    }
    return failed;
  }

  String get partial => _l10n.p20UploadPartial;
  String get refreshFailed => _l10n.p20UploadRefreshFailed;
  String get cleanupPending => _l10n.p20UploadCleanupPending;
  String stage(P20MediaStage stage) => [
        _l10n.p20UploadReady,
        _l10n.p20UploadExtractingAudio,
        _l10n.p20UploadConvertingVideo,
        _l10n.p20UploadUploadingAudio,
        _l10n.p20UploadUploadingVideo,
        _l10n.p20UploadRefreshing,
        _l10n.p20UploadComplete,
        _l10n.p20UploadIncomplete,
        _l10n.p20UploadCancelled
      ][stage.index];
}
