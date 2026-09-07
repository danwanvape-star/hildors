# Hildors 定制板块产品与系统实现规格（V1）

## 1. V1 范围

V1 完成从提交照片到视频包传入设备的闭环：

`选择定制服务 → 创建角色 → 上传素材 → 填写需求 → 授权 → 报价支付 → 审核/补件 → 角色基准确认 → 制作 → 预览验收 → 素材库下载 → 传入设备 → 售后`

V1 不建设开放式 AI 创作平台，不允许用户直接选择 Grok、GPT 或其他内部工具。工具选择只存在于制作后台。

## 2. App 信息架构

### 2.1 定制首页

页面模块按以下顺序展示：

1. 进行中的订单：状态、下一步动作和预计交付时间；
2. 创建新定制：人物、宠物、商品；
3. 我的角色：已建立的角色档案和订阅状态；
4. 我的素材库：已交付视频、下载及设备传输状态；
5. 服务套餐：单次定制、持续角色订阅、主题内容包；
6. 定制须知：素材要求、授权、修改和退款规则；
7. 联系客服。

首页优先展示用户当前必须处理的事项，例如“补充照片”“确认角色基准”“提交修改意见”，不应只展示营销卡片。

### 2.2 新建定制流程

采用分步表单，自动保存草稿：

| 步骤 | 页面 | 主要内容 | 继续条件 |
|---|---|---|---|
| 1 | 选择主体 | 人物 / 宠物 / 商品 | 已选择且符合开放范围 |
| 2 | 上传照片 | 示例、拍摄指导、质量检测 | 达到最低数量且检测无阻断问题 |
| 3 | 主体资料 | 名称、年龄段/品种/品牌等 | 必填字段完成 |
| 4 | 定制需求 | 风格、动作、场景、声音、循环 | 至少选择一个动作 |
| 5 | 用途与设备 | 个人/公开/商用、P20/P11/暂无 | 用途和规格明确 |
| 6 | 授权确认 | 履约授权、权利声明和可选授权 | 必需授权单独确认 |
| 7 | 订单确认 | 交付清单、价格、工期、修改次数 | 用户确认需求快照 |
| 8 | 支付 | 支付方式、发票信息 | 支付成功 |

任何自动检测都要给用户明确修正方法，不能只显示“上传失败”。

### 2.3 订单详情

订单详情由五部分构成：

- 顶部状态与下一步按钮；
- 时间线：支付、审核、补件、确认、制作、质检、交付；
- 已确认需求：只读展示当前生效版本；
- 沟通与文件：结构化补件、预览和修改意见；
- 费用与权益：支付、补价、退款、修改次数和许可类型。

状态文案必须描述用户结果，不暴露内部模型或生产细节。例如显示“正在制作角色基准”，不显示“正在调用某模型”。

### 2.4 我的角色

角色档案包括：

- 角色名称、主体类型、封面和创建日期；
- 当前角色基准版本及确认状态；
- 订阅状态、月度额度、下次发放时间；
- 已交付动作和可购买主题包；
- 源素材保存期限、更新素材和申请删除入口。

角色基准更新必须生成新版本；旧视频仍关联旧版本，不得静默替换。

### 2.5 我的素材库

每个视频或视频包展示：

- 角色、动作、版本、封面、时长和交付时间；
- 云端、手机本地和各设备三个位置状态；
- 下载、传入设备、播放、重新转码、删除缓存；
- 使用许可：个人或商用；
- 更新提示和兼容设备型号。

云端删除、本地缓存删除和设备文件删除是三个不同操作，文案与确认框必须明确区分。

## 3. 用户可见状态

内部状态可以细分，App 对用户统一映射为以下状态：

| 用户状态 | 用户主操作 | 包含的内部状态 |
|---|---|---|
| 草稿 | 继续填写 | draft |
| 待支付 | 支付 / 取消 | quoted, payment_pending |
| 审核中 | 无需操作 | paid, auto_review, manual_review |
| 待补充资料 | 上传补件 | supplement_required |
| 待确认角色 | 查看并确认/反馈 | character_preview_ready |
| 制作中 | 查看预计时间 | queued, generating, editing |
| 质检中 | 无需操作 | internal_review, device_packaging |
| 待验收 | 确认或提交修改 | customer_review |
| 修改中 | 查看进度 | revision_queued, revision_working |
| 已交付 | 下载 / 传入设备 | delivered |
| 售后处理中 | 补充证据 | aftersales_open |
| 已关闭 | 查看结果 | cancelled, rejected, refunded, closed |

前端不得根据支付按钮返回或本地缓存自行推断订单成功；所有状态以服务端查询或签名事件为准。

## 4. 核心领域对象

### 4.1 CustomerOrder

```text
id
user_id
order_number
service_type             // one_off | subscription_redemption | content_pack
subject_type             // person | pet | product
character_id
usage_type               // personal | public_display | commercial
risk_level                // L1 | L2 | L3 | prohibited
internal_status
customer_status
requirement_version_id
quoted_amount
paid_amount
currency
promised_at
created_at / paid_at / delivered_at / closed_at
```

### 4.2 RequirementVersion

```text
id
order_id
version
structured_requirements
device_profile_id
deliverable_spec
license_type
revision_allowance
change_reason
confirmed_by_user_at
created_by
created_at
```

已被用户确认的版本不可修改，只能创建下一版本。

### 4.3 ConsentRecord

```text
id
user_id
order_id
consent_type              // fulfillment | cloud_retention | showcase | ai_improvement
policy_version
granted
scope
granted_at
withdrawn_at
evidence
```

必需授权和可选授权分别保存。用户撤回可选授权不能影响已支付订单的必要履约。

### 4.4 Asset

```text
id
order_id / character_id
owner_user_id
asset_type                // source_photo | reference | preview | final_video | device_package
storage_key
sha256
mime_type / size / width / height / duration
source_asset_ids
authorization_scope
retention_until
deleted_at
created_at
```

### 4.5 ProductionJob

```text
id
order_id
job_type                  // analysis | baseline | image | video | edit | qa | transcode
provider_id
workflow_version
input_asset_ids
output_asset_ids
status
attempt_number
cost_amount
operator_id
started_at / completed_at
failure_code
```

### 4.6 ReviewRecord

```text
id
order_id
asset_id
review_type               // rights | safety | baseline | quality | customer_acceptance
checklist_version
score
decision                  // pass | rework | reject
reason_codes
comment
reviewer_id
created_at
```

### 4.7 DevicePackage

```text
id
asset_id
package_version
device_model
firmware_min_version
manifest
sha256
download_status
created_at
```

## 5. API 边界建议

### 5.1 用户端接口

```text
POST   /customization/orders
PATCH  /customization/orders/{id}/draft
POST   /customization/orders/{id}/assets
POST   /customization/orders/{id}/consents
POST   /customization/orders/{id}/quote
POST   /customization/orders/{id}/confirm
POST   /customization/orders/{id}/payment-intent
GET    /customization/orders/{id}
POST   /customization/orders/{id}/supplements
POST   /customization/orders/{id}/baseline-decision
POST   /customization/orders/{id}/review-decision
POST   /customization/orders/{id}/change-request
GET    /customization/library
POST   /customization/assets/{id}/download-ticket
POST   /customization/orders/{id}/aftersales
```

支付成功状态只接收支付服务端回调更新。`payment-intent` 的客户端成功结果仅用于展示“正在确认支付”。

### 5.2 生产后台接口

```text
GET    /ops/customization/orders
POST   /ops/customization/orders/{id}/risk-review
POST   /ops/customization/orders/{id}/supplement-request
POST   /ops/customization/orders/{id}/assign
POST   /ops/customization/jobs
POST   /ops/customization/jobs/{id}/outputs
POST   /ops/customization/orders/{id}/qa
POST   /ops/customization/orders/{id}/preview-release
POST   /ops/customization/orders/{id}/delivery-release
POST   /ops/customization/orders/{id}/refund-review
POST   /ops/customization/assets/{id}/deletion-request
```

所有改变订单状态的请求需要幂等键、操作者身份和预期当前版本，防止重复点击或并发覆盖。

## 6. 状态机约束

- 未支付订单不能进入人工制作；
- 授权缺失、风险未通过或补件未完成时不能生成可识别人物内容；
- L2/L3 未确认角色基准时不能进入批量视频制作；
- 未通过内部质检的产物不能发布用户预览；
- 用户未验收且未满足约定自动验收条件时不能交付无水印成品；
- 最终视频未通过设备规格校验时不能生成可下载设备包；
- 已退款订单不能继续生产，除非售后主管创建有审计记录的恢复操作；
- 已交付版本不得覆盖，只能发布新版本并标记替代关系。

## 7. 通知规则

只在用户需要行动、承诺变化或资产可用时发送通知：

- 支付确认；
- 审核通过或拒绝；
- 需要补件；
- 角色基准待确认；
- 预计交付延期；
- 视频待验收；
- 修改意见已收到；
- 成品已交付；
- 订阅续费、失败、取消及额度到期；
- 素材或角色工程即将删除。

同一事件通过站内消息、Push、短信等多个渠道发送时使用同一事件 ID，避免重复提醒。制作过程中的每次内部生成不通知用户。

## 8. 异常恢复

| 异常 | 系统处理 | 用户呈现 |
|---|---|---|
| 上传中断 | 分片续传，保留草稿 | 显示已完成进度和重试 |
| 支付回调延迟 | 主动查询支付服务，不重复扣款 | 显示“支付确认中” |
| 外部 AI 工具失败 | 自动重试一次，随后切换或转人工 | 保持“制作中”，延误才通知 |
| 生成结果违规 | 隔离产物并转人工复核 | 不向用户展示违规预览 |
| 质检返工 | 创建关联返工任务 | 显示“质检中”，不消耗用户修改次数 |
| 云端下载中断 | 断点续传和哈希校验 | 显示恢复下载 |
| P20 传输中断 | 按协议续传或重新上传 | 明确区分下载失败和设备传输失败 |
| 设备空间不足 | 不开始传输 | 引导管理设备文件 |

## 9. 埋点与事件

V1 至少记录以下产品事件：

```text
customization_entry_viewed
customization_started
subject_type_selected
asset_upload_started / completed / rejected
requirement_completed
consent_granted / declined
quote_viewed
payment_started / confirmed / failed
supplement_requested / submitted
baseline_viewed / approved / rejected
preview_viewed
revision_submitted
order_accepted
package_download_started / completed / failed
device_transfer_started / completed / failed
subscription_started / renewed / cancelled
```

分析事件不得包含原始照片、完整提示词、身份证明、用户自由文本或可识别的人脸特征。

## 10. 开发优先级

### P0：形成交易闭环

- 定制首页、分步表单、素材上传、授权和需求快照；
- 报价、支付、订单状态和补件；
- 后台审核、角色基准、生产任务、质检和预览；
- 用户验收、最终素材库、下载和 P20 传输；
- 操作日志、权限和删除机制。

### P1：提高效率

- 自动素材质量检测和风险评分；
- 工具工作流编排、成本记录和失败切换；
- 订阅角色、额度账本和主题内容包；
- 质检评分、缺陷原因统计和运营看板。

### P2：扩大规模

- 商品商用客户自助申请；
- 多制作团队、供应商结算和产能调度；
- 多设备版本自动转码；
- 个性化动作推荐和订阅留存策略。

## 11. 上线闸门

以下任一项未完成，不应开放真实付费订单：

- 用户能够查看并确认最终需求快照；
- 必需授权、可选授权和隐私删除机制已拆分；
- 支付回调、退款和对账完成端到端测试；
- 后台能够阻止未审核订单进入外部 AI 工具；
- 人物和未成年人订单能正确进入人工审核；
- 质量缺陷与需求变更存在清晰裁定和操作入口；
- 成品通过真实 P20/P11 播放验证；
- 外部工具准入、企业账号、访问日志和停用预案已经建立；
- 用户可以申请售后、下载成品和删除源素材；
- 至少完成一轮包含失败、补件、返工、退款和传输中断的全链路演练。
