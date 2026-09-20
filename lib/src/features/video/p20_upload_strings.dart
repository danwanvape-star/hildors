import 'package:flutter/widgets.dart';
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
