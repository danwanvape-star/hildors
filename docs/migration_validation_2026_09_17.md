# 2026-09-17 开发迁移与运行验证

## 本次范围与工作副本

优先完成开发环境迁移和运行验证，不调整产品功能、不部署云端服务。

- 仓库：私有 `danwanvape-star/hildors`。
- 工作副本：`C:\Users\DELL\HildorsApp`，从 GitHub 全新克隆，起点 `af4d4fe37070df4a937c84e8960dc32c8d0926b2`。
- 初始工作树干净；已完整阅读 README、development_handoff、product_decisions、character_video_package_flow，并检查最近五次提交。
- 按用户要求，新安装的开发工具和依赖缓存位于 `D:\HildorsTools`。原有角色素材工作目录未改动。

## 已安装与配置

| 工具 | 版本 / 路径 |
| --- | --- |
| Flutter stable / Dart | 3.47.4 / 3.13.3；`D:\HildorsTools\flutter` |
| Java | Temurin 21.0.12.1+1；`D:\HildorsTools\java` |
| Android SDK | Platform 35/36、Build Tools 36.0.0、Platform Tools、Command-line Tools、NDK 28.2.13676358、CMake 3.22.1；`D:\HildorsTools\android-sdk` |
| FFmpeg / ffprobe | 9.0.1 essentials；`D:\HildorsTools\ffmpeg` |
| Node | 24.19.0，沿用 Codex 已有运行时 |
| Pub / Gradle 缓存 | `D:\HildorsTools\pub-cache` / `D:\HildorsTools\gradle-cache` |

Flutter、Java、Android 命令行工具和 FFmpeg 下载包均核对发布方提供的校验值。Flutter 使用官方文档列出的 CFUG 镜像下载并核对官方发布元数据中的 SHA-256。没有升级项目的依赖锁文件。

本机 PowerShell 环境加载入口（不含凭据，不纳入仓库）：

```powershell
. D:\HildorsTools\Activate-Hildors.ps1
Set-Location C:\Users\DELL\HildorsApp
```

Flutter 的 Android SDK/JDK 路径已配置。环境脚本提供 Git、Node、FFmpeg 以及 D 盘缓存路径；新终端先加载此脚本。`flutter doctor -v` 的 Flutter、Android toolchain、Chrome 和网络检查均通过。Windows 桌面 Visual Studio 未安装，不影响本项目 Android/iOS 目标；iOS 仍需 macOS/Xcode。

## 验证结果

| 检查 | 本次实测 |
| --- | --- |
| `flutter pub get --enforce-lockfile` | 通过，保留原依赖版本 |
| `flutter analyze --no-pub` | 通过，No issues found |
| Flutter 完整测试，启用 `HILDORS_APP_E2E=1` | 308 项通过，无失败、无跳过 |
| Node 完整测试，启用 `HILDORS_MEDIA_INTEGRATION=1` | 18 项通过，无失败、无跳过 |
| 真实媒体链路 | 四个已有 Demo 的上传、解码、缩略图、审核及发布测试通过；App 下载、哈希校验和缓存恢复通过 |
| 本地后台启动 | 使用内存数据库和临时测试数据；health、ready、console、catalog 返回 200，未授权 admin 返回 401 |
| 公开 API，只读 GET | `https://api.hildors.com` 的 health、ready、catalog 返回 200；console、admin 返回 404 |
| Web 构建 | `flutter build web --no-pub --dart-define=HILDORS_API_BASE_URL=https://api.hildors.com` 通过 |
| Web 启动 | 本地 HTTP 返回 200；独立无头 Chrome 加载首页，存在 Flutter 视图、标题 Hildors Cockpit，未捕获 pageerror；已检查 390×844 首页截图 |
| Android release APK | **通过**：续传并校验 Gradle 9.3.1 / NDK 后，release 构建退出码 0，生成 129,270,656 字节 APK；签名和复制后的 SHA-256 验证通过 |
| 真机 / P20 | **未验收**：ADB 未发现连接的 Android 真机；未执行设备控制或上传 |
| SSH 隧道 / 管理账号 / 服务器备份恢复 | **未验收**：本次未接管服务器管理凭据、未部署或修改持久数据 |

Web 构建有 CupertinoIcons 字体资源提示，构建退出码为 0。浏览器预览仅证明首页可启动，不替代手机媒体播放、局域网控制、其他页面及硬件实测。公开 API 健康检查不证明服务器备份、容量或管理权限已交接。

本机日志及预览截图在 `D:\HildorsTools`，不纳入 Git。Web 产物在忽略的 `build/web`。

## 为恢复验证所作的最小修改

首轮 Flutter 测试有四项失败，均定位到测试落后于已有界面/流程：

- 创作者表单新增邮箱后，旧测试按字段下标把作品集填进邮箱框，并点击屏幕外的成年确认框。现在按邮箱 key / 作品集标签定位，滚动后点击，并验证邮箱确实保存。
- 提交 `3377979` 已将认证后入口改为无需先绑定收款账户即可进入任务大厅，且已有独立用例覆盖这一行为。本次同步旧导航用例，保留认证前不可见、审核状态、地域币种、认证后可见任务等断言。
- 目录降级测试仍断言旧标题；现验证布局服务失败后两类内容仍可浏览。
- 新增角色封面使视频清单位于首屏下方；测试显式滚动后再验证主图、详情和独立视频，保留列表不提前展示包内视频、详情不开放下载的断言。

未修改 `lib/` 或后台业务代码。补充根目录密钥、环境文件、数据库与本地媒体忽略规则；修正部署文档开头与已有上线记录矛盾的状态说明。没有新增密码、令牌、私钥、数据库或媒体到 Git。

## 后续验收与复现命令

先加载本机环境脚本，然后：

```powershell
$env:HILDORS_APP_E2E = '1'
$env:HILDORS_MEDIA_INTEGRATION = '1'
flutter analyze --no-pub
flutter test --no-pub
node --test backend/test/*.test.mjs
```

Gradle 9.3.1 与 NDK 已完成下载和整包校验，首次构建还自动补齐了 SDK 35 与 CMake。后续可直接重新构建：

```powershell
flutter build apk --release --no-pub --dart-define=HILDORS_API_BASE_URL=https://api.hildors.com
```

此处为构建验证，不是发布新版本。正式发布前按交接文档递增版本、核对签名和完成真机回归；构建 APK 不提交 Git。

仍需真机安装、手机视频预览、P20 局域网连接和两套播放列表验收，以及经安全渠道完成 SSH/管理权限交接。厂家上传/转码协议依赖仍然存在，测试通过不代表普通 MP4 已满足硬件播放要求。

## Android 构建续验结果

- 源码提交：`7b5413a`。本轮未修改 App 或后台代码；沿用此前已通过的 308 项 Flutter 和 18 项后台测试结果。
- Gradle 9.3.1 整包已核对官方 SHA-256，NDK r28c 已核对 Google 发布元数据中的 SHA-1。下载超时通过保留分段数据并续传解决。
- 构建命令与上文一致，首次构建耗时约 1661 秒，退出码 0。构建期间出现 SDK XML 兼容提示和部分依赖的 Java 8 source/target 弃用警告，未导致失败。
- APK：`D:\HildorsTools\releases\hildors-0.1.33+34-migration.apk`；校验文件为同路径加 `.sha256` 后缀。两者均在仓库外。
- 文件大小：129,270,656 字节（Flutter 报告 123.3 MB）。
- 包名：`com.hildors.hildors_cockpit`；versionName `0.1.33`、versionCode `34`；最低 SDK 24、目标 SDK 36。
- SHA-256：`f036785c029123f5884db618b31ed26b7320a7ae648ce04d07d08d595fa67ffa`。
- `apksigner verify --verbose --print-certs` 通过，v2 签名有效；签发者为 Android Debug，符合当前 Gradle release 使用 debug signingConfig 的配置。这是本机迁移验证包，不是正式发布包；若旧手机安装包使用另一把签名密钥，不能直接覆盖安装，不应为了安装而自动卸载或清除用户数据。
- 构建后再次检查 ADB，未发现已连接设备。真机安装、手机播放、P20 控制与两套列表、SSH 管理权限仍未验收。
