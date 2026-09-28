# Single and Dual P20 Device Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Recommended for this project: executing-plans in the current session, because tasks share connection and media interfaces.

**Goal:** 一个 App 支持单列表设备控制与无音频视频准备，保留现有双列表上传，并提供受控的单列表传输验证路径。

**Architecture:** 保留各页面共享的 P20DeviceClient 对象和 streams，内部为每次已验证连接绑定不可变的设备类型与独立协议传输。公共视频准备保持复用，媒体流程使用明确的设备能力，单列表上传在编码与末包验证前不对普通用户开放。

**Tech Stack:** Flutter 3.47.4、Dart 3.13.3、dart:io TCP、现有 FFmpeg 媒体引擎和 Flutter test，不新增平台依赖。

**Spec:** `docs/superpowers/specs/2026-09-28-single-dual-device-design.md`（已获用户“继续”确认）。

## Global Constraints

- 已同步基线：`98af6be48102f193a29d13c88d55d265adca382f`，版本 `0.1.66+67`；设计提交 `cd568e8`。执行前重新 fetch 核对远程，不覆盖另一台电脑的新代码。
- 保留本机六项未提交 CocoaPods / Xcode 配置，不通过 reset、clean 或全量暂存处置它们。
- 单列表一个视频列表，无音频播放能力，不抽取、不生成、不上传音频。
- 双列表继续使用现有 32768 字节分包、含列表 ID 的请求和状态 ACK 语义，厂家返回固定序号 2 的已验证行为不受影响。
- 单列表请求头尾 AA/A5，回复头尾 55/5A，CRC 固定 02；TCP `192.168.4.1:8900`；0x31 数据为大端长度和最多 32 字节的 `.bin` 文件名，无列表 ID；包长 35700。
- 厂家未明确的末包不填充、不截断；已有编码器仅为兼容性候选，传输完成不等于播放正确。
- 不新增读取 SSID 权限或插件，不改后台，不新增单列表音频，不进行无关界面重构。

## Review Focus

- 自动探测收到旧 socket 的延迟回复：不能把旧设备认作新设备；任务 2 覆盖。
- 用户在转码中切换硬件，转码随后完成：不得向新设备上传旧任务；任务 4 覆盖。
- 设备上传期间页面触发状态查询或重连：不得混入文件流；任务 3 覆盖。
- 空列表、畸形文件名及索引错误：不循环查询或显示上一设备内容；任务 5 覆盖。
- 直接从素材投放进入上传而绕过首页：仍应执行能力及验证门槛；任务 4、5 覆盖。

## 文件职责与执行准备

新增 `lib/src/device/p20_device_profile.dart` 定义类型与能力；新增 `p20_single_connection.dart` 承担单列表请求队列和独占上传，既有 `p20_v2_connection.dart` 保持双列表实现。客户端负责选择连接和连接代次；会话负责命令数据解释；媒体流程负责是否抽取音频；页面只消费这些决策。

所有路径以仓库根目录为基准。命令在 `/Users/huangruogu/Developer/HildorsApp` 或执行阶段创建的隔离工作树运行。Flutter 使用 `/Users/huangruogu/Developer/flutter/bin/flutter`。先按 using-git-worktrees 技能建立隔离工作树，保留原目录的 iOS 改动；需要 iOS 构建时仅复制已核对的六项本机配置到工作树，不提交它们。工作树从确认后的业务基线和设计文档开始，不修改原目录的用户改动。

每个任务按先失败测试、最小实现、通过测试、定向提交执行。只暂存任务文件，不使用 `git add .`。任何硬件证据改变协议假设，先更新设计和对应测试，不调整双列表逻辑来迎合单列表。

### Task 1: 明确设备能力与上传规则

**Files:** 新增 `lib/src/device/p20_device_profile.dart`、`test/p20_device_profile_test.dart`。

**Interfaces:** 定义 `enum P20DeviceKind { unknown, single, dual }`、`enum P20DevicePreference { auto, single, dual }`；`P20DeviceProfile.forKind(P20DeviceKind kind)` 返回不可变配置，提供 `kind`、`listCount`、`supportsAudio`、`videoExtension`、`maxNameBytes`、`chunkSize`；`bool supportsList(int listId)`。

- [ ] 写测试 `single_profile_has_one_silent_list`：single 的 listCount=1、supportsAudio=false、videoExtension='.bin'、maxNameBytes=32、chunkSize=35700；listId 0 有效，1/255 无效。dual 为 2、true、'.mp4'、61、32768；unknown 不支持任何列表。
- [ ] 运行 `flutter test --no-pub test/p20_device_profile_test.dart`，确认因缺少类型而失败。
- [ ] 实现配置和列表判定；不改变现有双列表文件名校验。
- [ ] 重跑该测试，要求全部通过。
- [ ] 定向提交 `feat: describe single and dual P20 capabilities`。

### Task 2: 验证连接、切换与命令隔离

**Files:** 新增 `lib/src/device/p20_single_connection.dart`、`test/p20_device_detection_test.dart`；修改 `lib/src/device/p20_device_client.dart`、`lib/src/device/p20_command_session.dart`；扩展 `test/p20_verified_connection_test.dart`。

**Interfaces:** `P20SingleConnection(Socket socket, {required void Function() onClosed})` 提供 `Future<P20Frame> request(int command, List<int> data, {Duration timeout = const Duration(seconds: 3)})` 和 `Future<void> close()`。客户端新增可选构造参数 `P20DevicePreference? preference`，省略时保留原 modernProtocol 参数语义；新增 `P20DeviceProfile get profile`、`int get generation`、`Future<void> setPreference(P20DevicePreference preference)`。既有 connect、requestFrame、frames、connectionStates 签名保留。modernProtocol 改为兼容 getter，由当前绑定的类型决定，断线不代表已识别设备。

- [ ] 用本地 ServerSocket 写失败测试：双列表正确回复一次连接成功；单列表 fallback 使用另一条 socket，请求字节固定为 `AA 00 00 00 02 04 00 02 A5`，回复 `55 00 00 00 02 04 32 02 5A`；CRC错误/亮度0或101/超时不得识别为单列表。现代亮度0的既有行为保留。
- [ ] 增加 `stale_probe_cannot_publish_connected`：取消或切换后旧回复不能改变 profile；手选 single 不探测 dual；全部失败时 profile=unknown，连接未成功；重连必须重新校验类型。
- [ ] 运行 `flutter test --no-pub test/p20_device_detection_test.dart test/p20_verified_connection_test.dart`，确认新断言失败。
- [ ] 实现顺序探测：TCP 连接超时5秒、每次查询3秒；旧连接完整关闭后才创建下一连接。每次断开或替换增加 generation；probe 完成前不发布 connected。single请求超时后关闭连接，避免迟到同命令回复被后续请求消费，并用延迟回复测试锁定此行为。setPreference 先关闭旧连接再连接；禁用期间的旧重连计时器。single transport 串行匹配命令回复，关闭时拒绝全部待处理请求。
- [ ] 将会话的 legacy 请求改由 client.requestFrame 路由到 single transport，保留缺省数据 `[0x00]`；禁止 disconnected/unknown 命令，frames 仍供状态订阅，但不再双重消费 pending completer。
- [ ] 运行上述测试及 `test/p20_shared_client_test.dart test/p20_modern_session_test.dart test/p20_v2_connection_test.dart`，全部通过后提交 `feat: detect and bind P20 device protocols`。

### Task 3: 单列表独占上传和保守验证策略

**Files:** 修改 `lib/src/device/p20_single_connection.dart`、`lib/src/device/p20_device_client.dart`；新增 `test/p20_single_connection_test.dart`。参考既有 `p20_upload_policy.dart`、`p20_upload_task.dart`，不改变双列表状态机。

**Interfaces:** single transport 新增 `Future<void> upload(File file, List<int> name, {void Function(int acknowledged, int total)? onProgress})`；客户端既有 uploadFile 路由时 single 必须 listId=0，dual 原样委托。验证构建使用 Dart define `HILDORS_SINGLE_UPLOAD_VALIDATION`，默认 false，客户端和页面均检查，不能由页面单独放行。

- [ ] 写独立字节测试：71400字节样本 `x.bin` 的请求为 `AA 00 00 00 0A 31 00 01 16 E8 78 2E 62 69 6E 02 A5`；00之前不发正文，01之前不发第二个35700包，两包后02才成功。fixture 仅验证传输，不标记为可播放样本。
- [ ] 写测试：0字节、35701字节、非ASCII/非.bin/超过32字节的名字在发送前拒绝；提前02、错误80～85、ACK畸形、后续序号重复/倒退/跳跃、断线和10秒无回复失败；上传期间 request 拒绝 busy，自动重连不会另建连接；取消关闭 socket，无额外命令字节。验证开关关闭时不发0x31。
- [ ] 运行 `flutter test --no-pub test/p20_single_connection_test.dart`，确认失败。
- [ ] 实现独占状态 waitingReady → waitingChunkAck → waitingComplete。验证期保守 ACK 策略：第一个01记录设备序号，之后必须递增1；重复、倒退或跳跃停止且记录诊断，不重传、不将该假设标为厂家事实。若最后一包后直接02且全部字节已发送，允许完成；进度最多到文件长度。未知末包长度拒绝，不填充。硬件证据与该策略不符时重新制定单列表规则。
- [ ] 运行新测试及 `test/p20_v2_connection_test.dart test/p20_v2_protocol_test.dart test/p20_upload_policy_test.dart`，尤其保证双列表固定序号2测试通过；定向提交 `feat: add guarded single-list upload transport`。

### Task 4: 无音频媒体流程与设备代次保护

**Files:** 修改 `lib/src/features/video/p20_media_upload_flow.dart`、`lib/src/features/video/p20_upload_page.dart`、`lib/src/features/video/p20_upload_strings.dart`；扩展 `test/p20_media_upload_flow_test.dart`；新增 `test/p20_single_upload_page_test.dart`。

**Interfaces:** 为 P20MediaUploadFlow 构造函数新增可选 `P20DeviceProfile profile`，缺省 dual 保持既有调用；run 签名保持不变。single 只接受 daily（内部listId=0），baseName最多28个ASCII字符。P20DeviceDestination 捕获创建时的 generation，每次 upload/refresh 前校验相等且连接有效。

- [ ] 写测试 `single_never_extracts_audio`：single 完成时 extractAudio调用0次，transcodeVideo1次，唯一 upload 为listId0和`clip.bin`，随后refresh(0)；阶段中没有 extractingAudio/uploadingAudio。single bluetooth 被拒绝；29字符baseName失败；dual既有音频顺序不变。
- [ ] 写测试：转码期间 generation 变化，输出完成后 upload调用0次；验证开关关闭的single页面不启动转码且解释“该机型视频上传待实机验证”；绕过首页直接打开上传页仍拦截；取消后临时文件清理且源文件保留。
- [ ] 运行 `flutter test --no-pub test/p20_media_upload_flow_test.dart test/p20_single_upload_page_test.dart`，确认新增断言失败。
- [ ] 实现 profile 驱动的音频分支与扩展名；保留FFmpeg和bin编码器算法。页面生成设备允许长度的名称，断线/代次变动取消整个流程；候选测试构建显示“传输完成，播放待验证”，普通dual文案不变。新增文案通过现有本地化机制提供。
- [ ] 重跑两个测试和 `test/p20_mobile_media_engine_test.dart test/fan_framing_test.dart`，全部通过后提交 `feat: prepare single-list video without audio`。

### Task 5: 全部入口采用设备能力

**Files:** 修改 `lib/src/features/dashboard/dashboard_page.dart`、`lib/src/features/home/home_page.dart`、`lib/src/features/control/control_page.dart`、`lib/src/features/settings/settings_page.dart`、`lib/src/features/video/video_page.dart`、`lib/src/features/video/playlist_management_page.dart`、`lib/src/features/video/p20_live_playlist.dart`、`lib/src/device/p20_command_session.dart`、`lib/src/experience/projection_service.dart`；按需要更新 `lib/src/localization/` 的既有文案定义。新增 `test/p20_device_capabilities_page_test.dart`，扩展 `test/p20_live_playlist_test.dart`、`test/p20_live_playlist_page_test.dart`。

**Interfaces:** dashboard 创建 `P20DeviceClient(preference: P20DevicePreference.auto, verifyOnConnect: true)`；设置页调用任务2的 setPreference；所有界面读取 client.profile。保持 session 的查询和控制公共签名，single 中 listId 仅允许0，unsupported 操作在发送前抛 P20CommandException。

- [ ] 写测试：single只展示唯一列表，无切换列表或音频入口；设置页选择类型触发重新验证；恢复出厂/格式化未适配入口不可操作；素材投放同样遵循single上传门槛，不能发送现代列表切换命令。
- [ ] 写列表测试：single空列表立即结束；总数超过50、回复索引不匹配、文件名长度不符报协议错误；断开清空列表；旧generation的查询结果不可覆盖新设备内容。既有dual上限96保持不变。
- [ ] 运行 `flutter test --no-pub test/p20_device_capabilities_page_test.dart test/p20_live_playlist_test.dart test/p20_live_playlist_page_test.dart`，确认新增断言失败。
- [ ] 实现入口、列表控制及能力检查；无设备时禁用操作。连接代次变化触发列表刷新/清空与媒体任务取消；避免仅用connection state去判断同状态的设备替换。素材投放继续经过同一上传目标与能力检查，不复制第二套流程。
- [ ] 重跑上述测试和 `test/p20_shared_client_test.dart test/device_controls_locale_test.dart test/home_single_screen_test.dart`，全部通过后提交 `feat: adapt P20 controls to detected device capabilities`。

### Task 6: 回归、构建与可复现硬件验证说明

**Files:** 新增 `docs/p20-single-device-validation.md`；修复只限前述任务文件及对应测试。

**Interfaces:** 验证文档记录基线commit、最终commit、测试命令、构建参数、机器SSID、固件信息、输入文件SHA256、传输结果和播放结果；未执行项明确写“未验证”。

- [ ] 执行 `flutter analyze --no-pub` 与 `flutter test --no-pub --reporter compact`，要求退出码0；记录跳过项和原因，不把跳过测试计为通过。
- [ ] 运行 `flutter build ios --simulator --debug --no-pub --dart-define=HILDORS_RELEASE_PROFILE=us_free --dart-define=HILDORS_API_BASE_URL=https://api.hildors.com`；要求退出码0，模拟器查看双列表默认入口和单列表未验证提示。iOS构建不等同APK或实机验证。
- [ ] 写硬件验证步骤：先在双列表重测原有两个列表上传；单列表先用厂家可播放文件和抓包确认ACK、末包，再用候选编码短视频检查画面方向/颜色/时长。默认开关保持false；验证构建额外指定 `--dart-define=HILDORS_SINGLE_UPLOAD_VALIDATION=true`，也不放宽已知文件长度约束。
- [ ] 如果缺少设备、厂家有效样本或末包证据，交付软件与明确的实机待验证清单，保持single普通上传门槛；不得宣称整体播放已完成。根据真实证据另行补充末包/编码兼容变更及回归测试后才能开放。
- [ ] 按选定执行技能完成代码审阅，处理发现的问题；定向提交验证文档。交付文件差异、测试结果、未验证项，不自动推送、合并或发布。

## 自查结论与执行交接

连接、控制、单列表音频排除、协议差异、视频复用和双列表保护均有对应任务；五类 Review Focus 已纳入任务测试。设备未知格式不由软件猜测，硬件证据仍是完整上传开放的前置条件。

建议选择 Native：由当前会话按任务顺序实施，最后独立审阅整体变更。这些任务共享客户端和会话接口，顺序实施更容易保持一致。另一选择是逐任务子代理实施并独立审阅，审阅频率更高，耗时与上下文成本也更高。实施前由用户审阅本计划并选择执行方式。
