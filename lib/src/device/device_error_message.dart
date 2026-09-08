import 'dart:async';
import 'dart:io';

String friendlyDeviceConnectionError(Object error) {
  if (error is TimeoutException) {
    return '设备网络已连接，但设备未响应读取指令。请确认 App 通信端口与设备固件版本后重试。';
  }
  if (error is SocketException) {
    final code = error.osError?.errorCode;
    final message =
        '${error.message} ${error.osError?.message ?? ''}'.toLowerCase();

    if (code == 111 || code == 10061 || message.contains('refused')) {
      return '未找到设备。请确认设备已开机，并在手机 Wi-Fi 设置中连接设备热点后重试。';
    }
    if (code == 110 || code == 10060 || message.contains('timed out')) {
      return '连接超时。请确认手机已连接设备热点，靠近设备后重新连接。';
    }
    if (code == 101 ||
        code == 10051 ||
        message.contains('network is unreachable')) {
      return '当前网络无法访问设备。请先将手机 Wi-Fi 切换到设备热点。';
    }
  }
  return '暂时无法连接设备。请检查设备电源和手机 Wi-Fi 后重试。';
}
