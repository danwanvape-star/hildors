# HILDORS 开发交接指南

更新日期：2026-09-17

本文用于将 HILDORS App、后台原型和云端测试环境交接到另一台电脑或另一个 Codex 账号。仓库是代码与技术文档的唯一交接源；密码、令牌、SSH 私钥和生产数据不得写入仓库。

## 1. 当前项目边界

- Flutter App：Android 与 iOS 共用一套 Dart 业务代码。
- 硬件控制：手机通过设备局域网连接 P20/P11，管理开机播放与蓝牙播放两套列表。
- 内容模型：单条视频与角色视频包是不同内容类型。角色包在列表中先展示角色主图，进入详情后再展示包内视频；加入播放列表的是包内视频，不是整个角色包。
- 内容后台：Node.js + SQLite 的团队封闭测试版本，包含内容、创作者申请、定制订单及运营流程原型。
- 云端测试环境：腾讯云弗吉尼亚 CVM；App API 通过 `https://api.hildors.com` 提供，管理后台只允许经 SSH 隧道访问。
- 硬件视频转码与上传协议仍有厂家待确认项，不能把普通 MP4 直接标记为硬件就绪。

产品和业务决策见 `docs/product_decisions.md`、`docs/mvp_product_spec.md`、`docs/character_video_package_flow.md`。后台规划见 `docs/backend_mvp_blueprint.md`。

## 2. GitHub 与权限交接

代码仓库：`https://github.com/danwanvape-star/hildors.git`（私有）。

如果新电脑使用原 GitHub 账号，登录 GitHub 后直接克隆。如果使用另一个 GitHub 账号，先由仓库所有者在仓库 Settings / Collaborators 中邀请该账号，并在新账号中接受邀请。Codex 账号与 GitHub 权限相互独立，切换 Codex 账号不会自动获得私有仓库访问权。

新电脑建议使用纯英文、较短路径：

```powershell
git clone https://github.com/danwanvape-star/hildors.git E:\HildorsApp
Set-Location E:\HildorsApp
git status
git log -5 --oneline
```

不要复制旧电脑的 `build/`、`.dart_tool/`、Android Gradle 缓存或整个工作目录作为主要迁移方式。不要提交 `.pem`、`.env`、管理密码、管理令牌、SQLite 数据库或用户媒体。

## 3. 新电脑开发环境

安装并配置：

- Git
- Flutter stable
- Android Studio、Android SDK 与可用的 Android JDK
- iOS 构建还需要 macOS、Xcode 和 CocoaPods
- Node.js 24（运行后台原型）

首次检查：

```powershell
Set-Location E:\HildorsApp
flutter doctor -v
flutter pub get
flutter analyze
flutter test
node --test backend/test/*.test.mjs
```

Android 构建应在纯英文路径下执行。项目曾在包含中文字符的 Windows 路径中出现 Android AOT/产物异常，因此不要把新工作副本放在微信目录或中文用户名下的深层路径。

开发版运行与正式包构建：

```powershell
flutter run
flutter build apk --release
```

版本号定义在 `pubspec.yaml`。发布新 APK 前同时递增语义版本和 build number，并完成真机安装、手机预览、局域网连接及两套播放列表回归。

## 4. APK 交接

本机发布目录 `releases/` 已被 Git 忽略。APK 通常超过 GitHub 单文件 100 MB 限制，不要直接提交进 Git 历史。应使用 GitHub Releases、受控对象存储或加密文件传输单独交接，并附 SHA-256 校验值。

## 5. 腾讯云测试环境

当前团队测试实例：

- 实例名：`hildors-api-prod-01`
- 地域：美国弗吉尼亚（`na-ashburn`）
- 公网地址：`43.130.113.123`
- SSH 用户：`ubuntu`
- systemd 服务：`hildors-team-staging.service`
- 部署目录：`/opt/hildors/backend`
- 持久数据目录：`/var/lib/hildors-api`

详细部署边界和验收记录见 `docs/team_staging_deployment.md`。

新电脑应在腾讯云创建一把新的 SSH 密钥并绑定该实例，不建议通过聊天、邮件或 Git 复制旧私钥。旧电脑确认退役后，可单独解绑旧密钥。

管理后台不直接暴露公网。新电脑取得 SSH 权限后建立本地隧道：

```powershell
ssh -N -L 127.0.0.1:18787:127.0.0.1:8787 -i C:\secure\hildors-new-key.pem ubuntu@43.130.113.123
```

保持命令窗口运行，然后访问：

```text
http://127.0.0.1:18787/console
```

管理员用户名和密码应通过密码管理器或当面安全交接。若凭据不可用，应在服务器上轮换凭据文件，而不是把现有凭据加入仓库。

常用只读检查：

```bash
sudo systemctl status hildors-team-staging.service
sudo journalctl -u hildors-team-staging.service -n 100 --no-pager
curl http://127.0.0.1:8787/health
curl http://127.0.0.1:8787/ready
```

部署代码前先备份并验证数据库/媒体恢复方式。不要用本地空数据覆盖 `/var/lib/hildors-api`，也不要在 SQLite 正在写入时只复制单个数据库文件。

## 6. 后台本地运行

后台原型默认只监听本机：

```powershell
node backend/src/server.mjs
```

默认入口：

- 健康检查：`http://127.0.0.1:8787/health`
- 就绪检查：`http://127.0.0.1:8787/ready`
- 管理后台：`http://127.0.0.1:8787/console`

团队模式所需环境变量和凭据文件格式见 `backend/deploy/team-staging.env.example`。只复制示例结构，不复制或提交真实值。

## 7. Codex 账号交接

Codex 对话历史不应被视为项目文档，另一个账号可能无法读取当前任务。新账号开始工作时，应先让 Codex 阅读：

1. 本文；
2. 根目录 `README.md`；
3. `docs/product_decisions.md`；
4. 与当次任务直接相关的规格文档；
5. `git status`、最近提交和相关测试。

建议给新 Codex 账号的首条指令：

```text
这是 HILDORS 项目的新工作副本。请先阅读 README.md、docs/development_handoff.md、docs/product_decisions.md 和与当前任务相关的规格；检查 git status 和最近提交，不要覆盖已有改动。所有修改先测试，再提交到当前私有仓库。任何密码、令牌、SSH 私钥、数据库和用户媒体都不得写入 Git。
```

## 8. 当前待办与风险

- 厂家仍需确认完整上传包字段、状态码重传策略以及硬件要求的转码参数。
- 普通手机 MP4、App 预览可播放与全息设备可播放是三种不同状态，不得混为一谈。
- 当前后台仍是团队测试原型；正式用户服务前需要 PostgreSQL、对象存储/CDN、正式身份认证、员工权限、审计、备份与隐私合规。
- 北美为主要目标市场，正式媒体分发不应长期依赖单机磁盘。
- 每次开发结束应保持工作树清晰、提交说明明确，并推送到私有仓库；服务器部署版本需能追溯到具体 Git 提交。

## 9. 迁移验收清单

- [ ] 新 GitHub 账号已获得私有仓库权限。
- [ ] 新电脑从 GitHub 全新克隆，`git status` 干净。
- [ ] `flutter doctor -v` 无阻断项。
- [ ] Flutter analyze 与测试通过。
- [ ] Android release APK 在英文路径成功构建并完成真机安装。
- [ ] 新 SSH 密钥已绑定服务器，旧密钥按需要撤销。
- [ ] SSH 隧道可以打开管理后台。
- [ ] 管理凭据通过安全渠道交接或完成轮换。
- [ ] App 可以访问公开 API，后台内容与持久数据未被覆盖。
- [ ] 新 Codex 账号已阅读交接文档和当前规格。

## 10. 新工作副本迁移记录

当前统一版本为 **0.1.44（45）**，在 0.1.43 合并版上修复认证上传提示，统一认证视频 15 MB 上限与英文创作者名称校验。后续以当前 `codex/content-admin-workflow` 的统一提交为基础开发，不再使用两个独立的 0.1.42 构建副本。合并范围见 [统一版交付记录](unified_release_0_1_43.md)，本次验证见 [认证上传修复记录](creator_upload_0_1_44.md)。

2026-09-17 Windows 工作副本的 D 盘工具配置、完整测试结果、Android APK 构建与校验记录，见 [迁移运行验证记录](migration_validation_2026_09_17.md)。Android 构建已通过；真机/P20 与服务器管理权限的验收状态以该记录为准，不应把构建成功视为完整硬件闭环。
