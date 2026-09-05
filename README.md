# Hildors 全息座舱控制 App

面向 Android 与 iOS 的 Flutter 控制端，依据 `P20产品通信协议.docx` 实现。

> 已确认：P20 完全兼容文档中的 P11 通信协议，App 统一以 P20 产品名对外展示。

## 当前 MVP

- TCP 连接设备默认热点地址 `192.168.4.1:8900`
- TCP 粘包、拆包及异常帧重新同步
- 断线自动重连与退避重试
- 开关机、播放/暂停、上一曲/下一曲
- 状态查询、亮度设置、角度设置
- 播放模式读取与设置、HC/ESP/MM版本查询
- 视频列表、指定播放和删除
- 同指令应答排队、3秒超时与设备错误码处理
- 协议编解码单元测试

## 本地启动

先安装 Flutter stable，并配置 Android Studio/Xcode。然后在项目根目录执行：

```shell
flutter create --platforms=android,ios .
flutter pub get
flutter test
flutter run
```

`flutter create` 只用于补齐 `android/`、`ios/` 等平台目录；现有 `lib/` 不应被覆盖。

## iOS 局域网权限

生成 iOS 工程后，需要在 `ios/Runner/Info.plist` 加入局域网使用说明。若后续加入 Bonjour 自动发现，还应配置 `NSBonjourServices`。

## 待厂家确认

- 角度的单位、有效范围和机械安全边界
- `crc` 是否确实为固定 `0x02`
- TCP 指令超时、重试和并发规则
- SSID、密码、文件名及版本字符串的编码
- 视频上传内容包是否带完整协议帧，以及最后半帧的长度规则
- App 通过设备 AP 控制时，手机是否仍需保持互联网访问



## 产品规格

- docs/product_decisions.md：已确认的产品和技术边界。
- docs/mvp_product_spec.md：首版状态机、页面结构、用户旅程与验收原则。
- docs/protocol_mapping.md：现有命令映射和新版协议需求。


