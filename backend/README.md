# HILDORS 本地后台原型

这是后台建设的首个可运行增量：Node 24内置HTTP和SQLite，无第三方依赖。正式部署仍按`docs/backend_mvp_blueprint.md`迁移到业务框架和PostgreSQL；当前不是生产服务。

团队封闭测试的启动配置与Linux服务模板见`docs/team_staging_deployment.md`。该模式仍只监听本机，经SSH隧道访问，不是公开上线方案。

## 启动和测试

在项目根目录运行：

```powershell
node --test backend/test/api.test.mjs
node backend/src/server.mjs
```

默认地址`http://127.0.0.1:8787`。可设置`HILDORS_PORT`。
运营管理页面：`http://127.0.0.1:8787/console`。支持令牌连接、统计、搜索、状态筛选、内容草稿创建和二次确认下架。页面令牌只保存在内存中，刷新或退出后清除。使用管理功能前先配置下面的环境变量。
管理接口需要设置环境变量`HILDORS_ADMIN_TOKEN`后重启，通过`Authorization: Bearer <token>`访问；未配置时管理接口关闭。此令牌仅用于本地联调，不是正式用户认证或员工角色权限。

SQLite保存于`backend/data/catalog.sqlite`，已忽略提交。首次初始化四个现有Demo的元数据，不复制视频、不上传文件、不自动恢复已下架内容。

## 可用接口

- GET `/health`：健康与原型模式。
- GET `/v1/bootstrap`：真实能力开关，目前云下载、转码、支付均false。
- GET `/v1/catalog`：已发布内容；query/source/format/tag/limit/cursor筛选分页。
- GET `/v1/packages/{id}`：已发布包与单视频。
- GET `/admin/packages`：包括草稿和下架条目。
- POST `/admin/packages`：创建元数据草稿，格式示例见下。
- POST `/admin/packages/{id}/withdraw`：提交`{"version":2}`，校验版本后下架。
- POST `/admin/packages/{id}/review`：提交version、decision（approved/rejected）、note；通过还须rightsConfirmed=true及rightsReference。所有当前素材检查成功才允许通过。
- POST `/admin/packages/{id}/publish`：真实草稿必须人工审核通过且全部素材检查成功；发布只开放目录元数据，云下载及硬件转码仍为false。
- GET `/admin/audit`：需管理权限，最近100条创建、素材、检查、审核和发布记录。

```json
{
  "title": "测试角色包",
  "source": "creator",
  "format": "package",
  "tags": ["神话"],
  "clips": [{"id": "clip-1", "title": "待机"}]
}
```

Demo使用现有Flutter资源路径和ID；资源路径不是云端下载地址。hardwareReady始终false，不声明已有厂家转码。客户端提交demo、状态或就绪标记不能绕过发布检查。

## 当前限制与下一增量

已支持草稿内每条视频上传MP4、记录SHA-256、大小及待审核状态，并通过鉴权接口在浏览器预览。上传保存在backend/data/media，单次上限256MB是本地后台限制，不是硬件文件限制。替换后旧文件暂保留，避免误删；正式上线需增加保留期限和清理任务。

上传接口：PUT `/admin/packages/{id}/clips/{clipId}/media`，Bearer鉴权，Content-Type为video/mp4，If-Match为当前数字修订号，请求体为原始文件。预览接口GET `/admin/media/{mediaId}`，支持Range且需鉴权。前端先鉴权获取Blob再播放；大文件会占用浏览器内存，正式版应采用短期会话和流式播放。

上传时只校验MP4容器标识，不代表编码、版权或安全审核通过。后台已加入“检查并生成缩略图”：完整解码检查、时长/分辨率/编码提取、480×480黑底完整画面缩略图。浏览器可能无法解码部分原始素材。尚无正式认证、权益、支付、下载签名和App接入。当前version为记录并发修订号；正式不可变内容版本需另建表，不能直接把该数字当媒体包版本。

## 视频检查工具配置

配置`HILDORS_FFMPEG`和`HILDORS_FFPROBE`为工具绝对路径，或将完整Windows构建解压至`backend/data/tools/<构建目录>/bin/`。工具来源可从 https://ffmpeg.org/download.html 选择。2026-09-14已下载并校验FFmpeg 9.0.1，工具已在本机就绪。

Windows安装脚本`./backend/download-tools.ps1`采用33MB的7z包、断点续传、固定SHA256校验及官方7zr独立解压工具；校验失败不解压。运行`node backend/check-tools.mjs`可检查工具可执行性。工具仅保存在被Git忽略的data/tools内，不修改系统PATH、不打入APK。先前未完成的ffmpeg.zip和ffmpeg-mirror.zip不用于运行。

POST `/admin/packages/{id}/clips/{clipId}/inspect`需要管理鉴权，只处理草稿当前素材。本地同时运行一个任务，时长上限10分钟、宽高各不超过4096；每次外部工具调用超时120秒。请求保持到处理完成，目前不是持久队列，服务重启后可手动重试。处理工具只允许本地文件协议，参数不经shell执行。完整检查仍不等于内容审核或厂家格式适配。

GET `/admin/media/{mediaId}/thumbnail`需要管理鉴权，只有检查成功且仍被当前内容引用的缩略图可读取。素材被替换后，旧任务结果不能写到新素材上。

工具就绪后运行实际解码测试：

```powershell
$env:HILDORS_MEDIA_INTEGRATION = '1'
node --test backend/test/*.test.mjs
```

默认测试将此真实工具测试明确标为跳过；不会把缺少工具当作解码成功。

## 本轮审核流程验收

- 替换素材或重新检查都会撤销旧审核结果。
- 草稿未经检查不能审核通过；无授权材料记录不能通过。
- 审核和发布校验修订号，过期请求冲突返回409。
- 审核说明、材料记录和内部素材信息不返回公开目录。
- 发布后hardwareReady仍为false；真实下载、许可和厂家交付均尚未接入。
- 员工账号尚未实现，操作身份统一为local-admin；不能当作正式多人审计系统。
- 2026-09-14浏览器验证：登录、创建草稿、列表/计数更新及桌面布局通过。完整测试9项通过、0跳过，包括四个真实Demo的上传→解码→缩略图→审核→目录发布，以及损坏文件和重检查并发保护。

真实素材测试输出至`backend/data/acceptance/pipeline.json`和四张JPG。测试只在临时数据库中模拟审批，不构成生产内容授权，不改变现有内容库。所有文件的hardwareReady仍为false。

本轮验证覆盖：未授权拒绝、筛选分页、真实Demo路径、草稿不可公开、客户端不能伪造审核、并发版本冲突、下架不可见、重启持久化。
