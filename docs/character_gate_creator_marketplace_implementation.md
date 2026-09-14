# 角色之门：创作者市场与设备限定播放实现规格（V1）

## 1. 当前能力判断

现有Flutter工程已经具备以下基础：

- `CustomizationPage`定制入口，但仍是静态流程和SnackBar占位；
- `ContentDownloadService`下载状态接口，但当前实现只是本地进度模拟；
- `ExperiencePackManifest`内容包清单，可描述版本、设备和文件；
- `P20UploadTaskState`设备等待、分包确认、完成和失败状态；
- 社区内容、预览播放器和设备播放基础页面。

当前缺少：

- 用户账户与购买权益；
- 创作者身份、资格和收款资料；
- 原创角色权利包；
- 定制订单与里程碑；
- 服务端文件存储和短期下载凭证；
- 内容包签名与加密；
- 设备身份、设备绑定和许可证；
- 设备端解密与签名校验；
- 结算账本、退款和争议；
- 审核后台和审计日志。

因此当前版本不能对用户承诺“内容只能在绑定设备播放”。

## 2. 两阶段保护策略

### 阶段A：受控交付MVP

目的：完成商业和运营验证，但明确属于降低导出便利度，不是强DRM。

- 服务端确认购买权益；
- App使用登录态获取短期下载凭证；
- 内容保存在App私有目录；
- UI不提供分享、另存或文件路径；
- 正式包与公开预览完全分离；
- 包清单签名，App安装前校验；
- 传入绑定账户下登记的设备；
- 下载、传输和安装写入审计；
- 退款或撤销后阻止新下载和新设备安装；
- 对种子创作者如实说明设备端文件仍可能被高级用户提取。

### 阶段B：固件级设备限定播放

这是对外主张“仅限绑定设备播放”前的目标：

- 每台设备具有唯一设备身份和密钥对；
- 服务端验证设备证明或至少验证受信设备公钥；
- 每个内容包使用独立内容密钥加密；
- 服务端为指定设备封装内容密钥；
- 设备验证平台签名和许可证；
- 内容在设备内解密播放，不以明文长期存储；
- 固件拒绝未签名、已篡改或设备不匹配的包；
- 协议不提供正式内容导出；
- 换机、维修、转让和恢复走受控流程；
- 设置合理离线许可证和时钟策略。

如果P20硬件无法安全保存设备密钥或固件无法解密播放，必须将保护级别降级为阶段A，不能仅靠App加密宣称强设备绑定。

## 3. 系统边界

```text
Flutter App
  ├─ 角色商城与创作者主页
  ├─ 定制任务和订单
  ├─ 权益库
  ├─ 设备绑定
  └─ 受控安装器

Creator Workspace
  ├─ 入驻与资格
  ├─ 原创角色上架
  ├─ 任务工作台
  ├─ 里程碑提交
  └─ 收入与申诉

Platform Backend
  ├─ Account / Creator / Rights
  ├─ Catalog / Orders / Commission
  ├─ Review / Moderation
  ├─ Entitlement / Device License
  ├─ Package / Key / Delivery
  ├─ Ledger / Payout / Refund
  └─ Audit / Notice / Dispute

Admin Console
  ├─ KYC和资格审核
  ├─ 权利与内容审核
  ├─ 派单和产能
  ├─ 真机质检
  ├─ 结算和退款
  └─ 版权通知与申诉

P20/P11 Firmware
  ├─ 设备身份
  ├─ 包签名校验
  ├─ 许可证校验
  ├─ 加密存储/播放
  └─ 安装与播放回执
```

## 4. 核心数据模型

### CreatorProfile

```text
id
account_id
public_name
legal_name
country
creator_type: individual | sole_trader | company
trader_status
age_verified_at
identity_status
tax_status
payout_status
terms_version
status: draft | review | active | suspended | closed
created_at
```

公开名称与法定/税务身份必须分离。

### CreatorQualification

```text
id
creator_id
qualification: original_publisher | commission_creator
skill_tags
device_models
risk_ceiling
level: candidate | verified | pro | licensed_partner
test_result
approved_by
approved_at
expires_at
status
```

### OriginalCharacter

```text
id
creator_id
name
slug
description
age_rating
visual_version
rights_package_id
review_status
sales_status
created_at
```

### RightsPackage

```text
id
rights_holder_id
character_id
co_authors
source_evidence
third_party_components
ai_tool_declarations
music_voice_font_rights
territories
supported_devices
sales_start
sales_end
exclusivity
user_license_version
platform_license_version
derivative_policy
commission_policy
marketing_policy
post_delisting_policy
takedown_policy
reviewed_by
reviewed_at
```

### ContentPackage

```text
id
character_id
creator_id
package_type
version
manifest_version
preview_asset_id
master_asset_id
device_variants
content_hash
signature
encryption_key_ref
file_size
review_status
publication_status
```

### CommissionOrder

```text
id
customer_id
character_id
source_path
rights_risk
complexity_score
scope_snapshot
license_snapshot
quote_snapshot
assigned_creator_id
target_device_model
status
due_at
created_at
```

所有影响价格、工期和权利的内容保存不可变快照，不能只引用可能被后续修改的商品配置。

### CommissionMilestone

```text
id
order_id
type: accepted | baseline | action_draft | device_qa | delivery
version
asset_ids
submitted_at
platform_review_status
customer_review_status
revision_reason
approved_at
payout_release_percent
```

### DeviceEntitlement

```text
id
account_id
content_package_id
purchase_order_id
license_type: purchased | subscription | promotional
device_limit
territories
issued_at
download_until
offline_policy
status: active | refunded | revoked | recalled | expired
```

### DeviceLicense

```text
id
entitlement_id
device_id
package_version
wrapped_content_key
license_token_hash
issued_at
expires_at
offline_until
install_count
status
```

### LedgerEntry

```text
id
order_id
creator_id
entry_type: gross | tax | payment_fee | platform_fee | creator_share | refund | chargeback | reserve | payout
amount
currency
reference_id
created_at
```

账本只追加，不直接覆盖历史金额。

## 5. 内容包清单升级

现有`ExperiencePackManifest`建议升级为服务端签名的`CharacterContentManifest`：

```json
{
  "schemaVersion": 2,
  "packageId": "pkg_...",
  "characterId": "char_...",
  "version": "1.0.0",
  "creatorId": "creator_...",
  "rightsPackageId": "rights_...",
  "licensePolicyId": "license_...",
  "supportedModels": ["P20"],
  "minimumFirmware": "x.y.z",
  "territories": ["US", "DE", "FR"],
  "files": [
    {
      "role": "welcome",
      "path": "welcome.enc",
      "sha256": "...",
      "sizeBytes": 123456,
      "encryption": "aes-256-gcm"
    }
  ],
  "contentHash": "...",
  "signedAt": "...",
  "signatureKeyId": "platform-key-...",
  "signature": "..."
}
```

不要信任客户端传入的价格、创作者、权利状态、地区或包哈希；客户端只提交ID，服务端重新解析权威记录。

## 6. 角色上架接口

```text
POST   /v1/creators/applications
GET    /v1/creators/me
POST   /v1/creator-characters
PATCH  /v1/creator-characters/{id}
POST   /v1/creator-characters/{id}/rights-evidence
POST   /v1/creator-characters/{id}/packages
POST   /v1/content-packages/{id}/assets
POST   /v1/content-packages/{id}/submit-review
GET    /v1/content-packages/{id}/review-status
POST   /v1/content-packages/{id}/publish-request
POST   /v1/content-packages/{id}/delist-request
```

上传使用短期、单用途URL；完成后由服务端校验文件大小、媒体类型、哈希和上传会话，不把对象存储永久公开地址返回给客户端。

## 7. 定制接单接口

```text
POST   /v1/commission-requests
POST   /v1/commission-requests/{id}/rights-precheck
GET    /v1/commission-orders/{id}/quote
POST   /v1/commission-orders/{id}/checkout
GET    /v1/creator-jobs
POST   /v1/creator-jobs/{id}/accept
POST   /v1/creator-jobs/{id}/decline
POST   /v1/creator-jobs/{id}/milestones
POST   /v1/milestones/{id}/submit
POST   /v1/milestones/{id}/customer-review
POST   /v1/commission-orders/{id}/change-request
POST   /v1/commission-orders/{id}/disputes
GET    /v1/commission-orders/{id}/timeline
```

订单接受接口必须使用原子状态转换，避免两个创作者同时接到同一任务。

## 8. 权益和设备安装接口

```text
GET    /v1/library/entitlements
POST   /v1/devices/register
POST   /v1/devices/{id}/prove-possession
POST   /v1/entitlements/{id}/install-sessions
GET    /v1/install-sessions/{id}/manifest
POST   /v1/install-sessions/{id}/file-ticket
POST   /v1/install-sessions/{id}/progress
POST   /v1/install-sessions/{id}/complete
POST   /v1/device-licenses/{id}/renew
POST   /v1/device-licenses/{id}/transfer
POST   /v1/device-licenses/{id}/repair-recovery
```

安装会话必须校验：

- 登录用户；
- 权益有效；
- 设备属于该账户；
- 设备数量未超限；
- 包、设备和固件兼容；
- 地区和销售/下载政策；
- 退款、召回和欺诈状态；
- 当前会话未过期且未被重放。

## 9. 权限矩阵

| 资源 | 用户 | 接单制作师 | 原创发行者 | 审核员 | 设备 |
|---|---|---|---|---|---|
| 商店预览 | 查看 | 查看 | 查看自己的 | 查看 | 不需要 |
| 用户原始素材 | 上传/删除请求 | 任务期最小权限 | 无 | 按职责 | 不需要 |
| 角色源文件 | 无导出 | 仅任务工作区 | 自己上传 | 按职责 | 不接收 |
| 正式设备包 | 无直接文件权限 | 无 | 无 | 质检访问 | 经许可安装 |
| 权利证据 | 查看自身摘要 | 仅必要结论 | 自己提交 | 完整查看 | 不需要 |
| 订单价格 | 自己订单 | 自己任务结算 | 自己销售结算 | 按职责 | 不需要 |
| 法定/税务身份 | 自己 | 自己 | 自己 | 专门权限 | 不需要 |
| 设备许可 | 查看状态 | 无 | 无 | 支持权限 | 校验与使用 |

所有管理员接口按最小角色授权，不使用共享后台账号。

## 10. App页面模块

建议新增：

```text
lib/src/features/character_gate/
  character_gate_page.dart
  character_source_page.dart
  licensed_character_configurator.dart
  original_character_application_page.dart
  ip_wish_page.dart
  character_baseline_review_page.dart
  behavior_pack_builder_page.dart
  device_preview_page.dart
  commission_timeline_page.dart
  character_passport_page.dart

lib/src/features/creator_marketplace/
  creator_store_page.dart
  creator_profile_page.dart
  original_character_detail_page.dart
  creator_application_page.dart

lib/src/features/entitlements/
  entitlement_repository.dart
  device_license_repository.dart
  secure_install_service.dart
  install_session_state.dart
```

创作者工作台首发建议采用响应式Web后台，不必把复杂上架、税务、文件审核和结算功能全部塞进用户App。

## 11. 安装状态机

```text
idle
→ checking_entitlement
→ checking_device
→ requesting_license
→ downloading_encrypted_package
→ verifying_manifest
→ waiting_for_device
→ transferring
→ device_verifying
→ indexing
→ launching_first_play
→ completed
```

失败状态保存：

```text
failure_stage
retryable
acknowledged_bytes
package_version
device_id
license_id
error_code
user_message
support_reference
```

不要将购买成功、下载成功、传输成功、设备校验成功和首次播放成功合并成一个`downloaded`状态。

## 12. 安全威胁与控制

| 风险 | 控制 |
|---|---|
| 用户复制App缓存 | 私有目录、加密缓存、短期票据、及时清理 |
| 用户复制设备文件 | 设备绑定密钥、加密存储、播放时解密 |
| 修改清单替换文件 | 平台签名、哈希和固件校验 |
| 共享下载URL | 单用途短期URL、账户和会话绑定 |
| 伪造购买结果 | 服务端支付回调创建权益，客户端结果不作准 |
| 重放安装许可 | nonce、过期时间、设备ID和使用状态 |
| 创作者下载用户素材 | 最小权限、受控工作区、水印和审计 |
| 审核员滥用权限 | 分权、日志、批量导出限制和异常告警 |
| 退款后继续新装 | 权益状态阻止新许可证，已安装处理按购买规则 |
| 创作者下架影响已购用户 | 销售状态和用户权益状态分离 |

屏幕录像和外部摄像拍摄无法由该架构完全防止，属于残余风险。

## 13. 后台最小模块

### 创作者审核

- 身份、年龄、地区、税务和收款；
- 上架/接单资格；
- 测试任务和设备能力；
- 状态、限制和历史事件。

### 权利审核

- 原创过程和证据；
- 共同作者和第三方组件；
- AI、音乐、声音和字体；
- 地区、设备、期限和下架政策；
- 结论、理由和复审日期。

### 内容审核与质检

- 预览和正式包分离；
- 自动媒体检查；
- 内容安全；
- 品牌规范；
- P20/P11真机结果；
- 缺陷、修改和最终放行。

### 派单和里程碑

- 匹配候选；
- 并行订单上限；
- 接受/拒绝；
- 素材访问时间；
- 里程碑版本；
- 用户确认和变更报价。

### 结算与争议

- 订单级账本；
- 税费、渠道费、分成和准备金；
- 退款和拒付；
- 待结算和已结算；
- 争议证据、决定与申诉。

## 14. 可以人工替代的能力

P0可暂时人工完成：

- 创作者邀请和资格审批；
- 权利证据审核；
- 派单和复杂度判断；
- 报价；
- 里程碑审核；
- 真机质检记录；
- 争议决定；
- 月度结算复核。

即使人工完成，也必须在系统中保存结构化状态、证据、决定和账本，不能只依赖邮件、聊天和表格。

## 15. 上线前必须系统保证

- 服务端支付确认和权益创建；
- 用户只能访问自己的订单和权益；
- 创作者只能访问已接受任务的必要素材；
- 上传文件扫描、类型和大小限制；
- 商城预览与正式包隔离；
- 安装会话、短期票据和审计；
- 内容包哈希和签名；
- 设备绑定数量限制；
- 退款、召回和下架状态生效；
- 账本不可随意覆盖；
- 后台操作留痕；
- 用户删除请求能够传播到创作者工作区。

强设备DRM必须等固件密钥、许可证和解密播放完成后再对外承诺。

## 16. 开发阶段

### Sprint 1：业务骨架

- 角色之门三路径页面；
- 创作者和资格数据模型；
- 原创角色草稿、证据和审核状态；
- 定制申请、报价和里程碑；
- 管理后台基础队列。

### Sprint 2：交易与权益

- 服务端商品和价格快照；
- 支付回调；
- 订单账本；
- 内容权益库；
- 退款和下架状态；
- 创作者待结算视图。

### Sprint 3：受控交付

- 正式包和预览分离；
- 签名清单；
- 短期下载票据；
- App私有缓存；
- 设备绑定和安装会话；
- 上传失败恢复和审计。

### Sprint 4：固件级许可

- 设备身份和密钥；
- 包加密；
- 设备许可证；
- 固件签名和设备匹配校验；
- 加密保存/播放；
- 换机、维修和离线策略。

### Sprint 5：封闭测试

- 5–10名原创发行者；
- 3–5名接单制作师；
- 3个角色上架测试；
- 10类模拟定制订单；
- 退款、下架、召回、争议和设备恢复演练；
- 计算实际人工成本、安装成功率和单单毛利。

## 17. 技术验收标准

- 未购买账户不能获得正式包安装票据；
- 票据不能用于另一账户、设备、包或过期会话；
- 修改清单或包内容会被App或设备拒绝；
- 创作者不能访问未派给自己的订单素材；
- 创作者任务结束后访问自动失效；
- 退款后不能向新设备安装；
- 普通下架不影响符合政策的已购设备播放；
- 召回按规则阻止新安装和续签；
- 网络中断后从已确认分包恢复；
- 安装成功必须以设备回执和首次播放结果确认；
- 所有审核、许可、安装和结算关键操作可追溯。

## 18. 最终判断

创作者市场可以先做，但设备限定播放必须分清“业务限制”和“技术保证”：

```text
App隐藏导出 + 私有缓存
≠ 真正设备限定播放

账户权益 + 短期安装票据 + 签名清单
= 可运营的受控交付

设备身份 + 设备密钥 + 加密包 + 固件校验
= 可以对外主张的设备绑定播放
```

首发应先实现受控交付并限制创作者规模，同时把固件级许可证作为正式开放市场前的技术闸门。

结合现有Flutter模块拆分的用户端、创作者端、运营后台、权益安装、角色护照任务和发布闸门见 [character_gate_mvp_backlog.md](./character_gate_mvp_backlog.md)。
