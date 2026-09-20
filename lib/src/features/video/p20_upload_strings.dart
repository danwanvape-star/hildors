import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import '../../device/p20_v2_connection.dart';
import 'p20_media_upload_flow.dart';

class P20UploadStrings {
  P20UploadStrings(BuildContext context)
      : _zh = Localizations.localeOf(context).languageCode == 'zh';
  final bool _zh;
  String get title => _zh ? '上传到设备' : 'Upload to device';
  String get start => _zh ? '开始处理并上传' : 'Prepare and upload';
  String get cancel => _zh ? '取消上传' : 'Cancel upload';
  String get close => _zh ? '返回列表' : 'Back to playlist';
  String get disconnected => _zh
      ? '请先返回首页连接设备 Wi-Fi，再进行上传。'
      : 'Connect to the device from Home before uploading.';
  String get daily => _zh
      ? 'A 日常列表：支持有声和无声视频。有音轨时先提取 MP3，转码后先上传音频再上传视频；无音轨时仅转码并上传视频。'
      : 'A daily playlist accepts videos with or without sound. With audio: extract MP3, convert, upload audio then video. Without audio: convert and upload video only.';
  String get bluetooth => _zh
      ? 'B 蓝牙列表：支持有声和无声视频，均只转码并上传视频，不读取原视频音频。'
      : 'B Bluetooth playlist accepts videos with or without sound. Convert and upload video only; source audio is ignored.';
  String get settings => _zh
      ? '298 × 298 · 20 帧/秒 · 使用当前取景范围'
      : '298 × 298 · 20 fps · Current framing';
  String get downloadFirst => _zh
      ? '请先将视频下载到“我的角色”，再上传到设备。'
      : 'Download this video to My Characters before uploading to the device.';
  String get failed => _zh
      ? '处理或上传失败。请检查视频、设备连接和存储空间后重试。'
      : 'Preparation or upload failed. Check the video, device connection and storage, then try again.';
  String get confirmedProgress => _zh ? '设备已确认接收进度' : 'Confirmed by the device';
  String failureStage(P20MediaStage value) =>
      '${_zh ? '失败阶段' : 'Failed during'}: ${stage(value)}';
  String transferDetails(P20UploadSnapshot snapshot) {
    final phase = (_zh
        ? const ['等待设备允许接收', '文件传输', '等待设备完成确认', '设备已确认完成']
        : const [
            'Waiting for upload acceptance',
            'Transferring file',
            'Waiting for completion confirmation',
            'Device confirmed completion'
          ])[snapshot.phase.index];
    return '$phase · ${_zh ? '已确认' : 'Confirmed'} ${snapshot.acknowledged} / ${snapshot.total} ${_zh ? '字节' : 'bytes'}';
  }

  String error(Object error, P20MediaStage stage) {
    if (error is P20DeviceUploadRejected) {
      final reason = switch (error.status) {
        0x80 => _zh ? '设备忙，请稍后重试。' : 'Device is busy. Try again shortly.',
        0x81 => _zh
            ? '设备写入失败，请检查存储卡。'
            : 'Device could not write the file. Check its storage card.',
        0x82 => _zh ? '设备中已存在同名文件。' : 'The file already exists on the device.',
        0x85 => _zh ? '设备存储或列表已满。' : 'Device storage or playlist is full.',
        0x8a => _zh
            ? '设备电量过低，请充电后重试。'
            : 'Device battery is too low. Charge it and retry.',
        _ => _zh ? '设备拒绝接收文件。' : 'Device rejected the file.',
      };
      return '$reason (0x${error.status.toRadixString(16).toUpperCase()})';
    }
    if (error is TimeoutException) {
      final uploading = stage == P20MediaStage.uploadingAudio ||
          stage == P20MediaStage.uploadingVideo;
      return uploading
          ? (_zh
              ? '等待设备确认超时。请记录下方阶段和进度，重新连接后再试。'
              : 'Device confirmation timed out. Note the stage and progress below, then reconnect.')
          : (_zh
              ? '处理等待超时，请尝试较短的视频。'
              : 'Media processing timed out. Try a shorter video.');
    }
    if (error is SocketException) {
      return _zh
          ? '设备连接已断开，请重新连接后重试。'
          : 'Device connection was lost. Reconnect and retry.';
    }
    if (error is FileSystemException) {
      return _zh
          ? '无法读取或写入本机文件，请检查源文件和手机可用空间。'
          : 'Cannot read or write local files. Check the source and available phone storage.';
    }
    if (error is FormatException &&
        (stage == P20MediaStage.uploadingAudio ||
            stage == P20MediaStage.uploadingVideo)) {
      return _zh
          ? '设备上传应答格式或进度序号不匹配，请核对设备固件协议。'
          : 'Device reply or progress sequence did not match. Check the firmware protocol.';
    }
    return failed;
  }

  String get partial => _zh
      ? '音频已上传，视频未完成。本次不会自动重试或删除设备文件。'
      : 'Audio was uploaded but video did not finish. No device files have been deleted or automatically retried.';
  String get refreshFailed => _zh
      ? '设备已确认文件上传成功，但列表读取失败。请重新连接后刷新列表，不要重复上传。'
      : 'The device confirmed the upload, but the playlist could not be refreshed. Reconnect and refresh; do not upload again.';
  String get cleanupPending => _zh
      ? '临时文件仍被转码任务占用，将保留以避免中断写入。'
      : 'Temporary files are still in use and have been retained.';
  String stage(P20MediaStage stage) => (_zh
      ? const [
          '准备就绪',
          '正在检查并提取音频（如有）',
          '正在转码视频',
          '正在上传音频',
          '正在上传视频',
          '正在刷新设备列表',
          '上传完成',
          '上传未完成',
          '已取消',
        ]
      : const [
          'Ready',
          'Checking and extracting audio if present',
          'Converting video',
          'Uploading audio',
          'Uploading video',
          'Refreshing playlist',
          'Upload complete',
          'Upload incomplete',
          'Cancelled',
        ])[stage.index];
}
