# Hildors 定制板块：当前App差距与实施计划

## 1. 当前代码基线

- `CustomizationPage`目前是单个无状态展示页；
- 只展示“上传照片、填写需求、等待制作”三步说明；
- 按钮仅提示接口尚未接入；
- 尚无账号、地区、订单、角色、授权、支付、订阅和素材库领域模型；
- `pubspec.yaml`除Flutter外没有网络、持久化、文件选择、图片处理或支付依赖；
- 设备视频页目前支持读取列表、播放和删除；
- P20命令会话尚未实现`0x31`视频文件上传。

下一步不应把真实照片选择器直接连接任意AI工具，应先建立领域状态、地区/成年确认、授权边界、演示流程和后端API契约。

## 2. 建议模块结构

```text
lib/src/features/customization/
  customization_home_page.dart
  application/
    customization_coordinator.dart
    customization_routes.dart
  domain/
    customization_order.dart
    customization_status.dart
    character_profile.dart
    requirement_snapshot.dart
    consent_record.dart
    customization_asset.dart
    market_policy.dart
    subscription_plan.dart
  data/
    customization_repository.dart
    customization_api_repository.dart
    customization_demo_repository.dart
  presentation/
    start/
    intake/
    legal/
    checkout/
    order/
    library/
    subscription/
    privacy/
```

领域对象、数据层和Widget不应继续堆叠在一个页面文件中。

## 3. 首个可交互原型

后端和支付未接入前，使用`CustomizationDemoRepository`完成本地流程：

1. 市场：US / EU / UK；
2. 美国州或欧盟国家；
3. 成年确认；
4. 主体：人物 / 宠物 / 商品；
5. 人物关系：本人 / 受监护未成年人 / 其他成年人；
6. 照片要求示例；
7. 风格和标准动作；
8. 用途：个人 / 私人礼物 / 公开 / 商业；
9. 必需授权与默认关闭的可选授权；
10. 订单摘要和需求快照；
11. 模拟订单时间线；
12. 角色基准确认；
13. 预览问题反馈；
14. 素材库云端/手机/设备状态；
15. 订阅取消影响。

所有模拟页面显示`Demo mode — no files are uploaded and no payment is taken`，不得伪装成真实上传、支付或设备传输。

## 4. Sprint顺序

### Sprint 1：安全进入流程

- 定制首页；
- 地区和成年确认；
- 主体及人物关系；
- 照片要求；
- 风格、动作、用途；
- 授权和订单摘要。

完成标准：市场、主体和用途会改变必需授权；未成年人、公众人物和商用内容进入限制流程。

### Sprint 2：订单履约原型

- 订单状态时间线；
- 补件；
- 角色基准确认；
- 视频预览和结构化反馈；
- 质量问题/需求变更分支；
- 最终素材库。

完成标准：用户始终看到下一步；已确认版本不可覆盖；质量问题不显示补价。

### Sprint 3：后端基础

- 登录和用户市场；
- 草稿、订单、需求和授权API；
- 私有素材上传；
- 审核与生产后台；
- 通知和审计日志。

完成标准：服务端授权检查前，真实照片不会发送给外部AI工具。

### Sprint 4：交易与设备交付

- 报价、支付回调、退款和补价；
- 正式发布与下载；
- DeviceProfile；
- `0x31`上传协议；
- P20/P11保存及播放验证。

完成标准：支付、下载和设备安装分别幂等、状态独立。

### Sprint 5：订阅

- 套餐和点数；
- 发放、冻结、扣除、退回和过期账本；
- 自动续费提醒；
- 取消和宽限期；
- 角色工程及内容保留。

完成标准：关闭续费不删除已交付内容，重复支付事件不重复发点数。

## 5. 前端核心状态

```dart
enum CustomizationCustomerStatus {
  draft,
  paymentPending,
  underReview,
  supplementRequired,
  characterApprovalRequired,
  inProduction,
  qualityReview,
  customerReviewRequired,
  revisionInProgress,
  packaging,
  delivered,
  afterSales,
  closed,
}

enum CustomizationNextAction {
  continueDraft,
  pay,
  uploadSupplement,
  reviewCharacter,
  reviewVideo,
  acceptChangeQuote,
  download,
  transferToDevice,
  contactSupport,
  none,
}
```

避免使用`isPaid`、`isProducing`、`isDone`等可能互相冲突的布尔值。订单状态来自服务端并映射为唯一客户状态和下一步动作。

## 6. 地区策略对象

```dart
class MarketPolicy {
  final String market;
  final String? region;
  final int minimumAccountAge;
  final bool minorSubjectAllowed;
  final bool biometricWorkflowAllowed;
  final bool voiceCloneAllowed;
  final bool euImmediatePerformanceStep;
  final AiDisclosureMode aiDisclosureMode;
  final List<ConsentType> requiredConsents;
  final List<PrivacyRight> privacyRights;
  final SubscriptionNoticePolicy subscriptionNotices;
}
```

正式版由服务端返回版本化策略，前端内置保守兜底。加载失败时允许浏览，但禁止提交真实人物订单，不能回退为“全部允许”。

## 7. 必需技术能力

具体Flutter包在选型后确定，能力至少包括：

- HTTP、认证、超时和幂等；
- 安全令牌存储；
- 路由、深链接和状态管理；
- JSON序列化及不可变模型；
- 私有文件选择和照片权限；
- 分片上传、恢复和本地数据库；
- 图片压缩、EXIF清理和哈希；
- 视频信息读取、校验和预览；
- 支付SDK或后端Checkout；
- Push通知；
- 本地化、市场格式和法律文案版本；
- 脱敏的崩溃与分析；
- 设备文件传输任务。

不要一次性加入大量依赖。先评估维护状态、平台支持、数据流和隐私影响。

## 8. API最小返回

### 启动配置

```json
{
  "marketPolicyVersion": "us-ca-2026-09-v1",
  "market": "US",
  "region": "CA",
  "minimumAccountAge": 18,
  "availableSubjectTypes": ["person", "pet"],
  "requiredConsents": ["order_production", "rights_confirmation"],
  "aiDisclosureMode": "visible_and_machine_readable",
  "legalCopyBundle": "en-US-us-ca-2026-09-v1"
}
```

### 订单摘要

```json
{
  "orderId": "ord_xxx",
  "status": "characterApprovalRequired",
  "nextAction": "reviewCharacter",
  "requirementVersion": 2,
  "riskLevel": "L2",
  "promisedAt": "2026-09-15T17:00:00Z",
  "marketPolicyVersion": "us-ca-2026-09-v1",
  "consentSnapshotIds": ["con_x", "con_y"]
}
```

### 法律文案包

```json
{
  "bundleId": "en-US-us-ca-2026-09-v1",
  "locale": "en-US",
  "items": [
    {
      "key": "consent.orderProduction",
      "version": 3,
      "required": true,
      "defaultValue": false,
      "text": "..."
    }
  ]
}
```

App提交授权时回传每个条目的`key`、`version`和选择，不能只提交`acceptedTerms=true`。

## 9. App端照片处理边界

App端可以：

- 检查类型、大小、分辨率和数量；
- 去除非必要EXIF/GPS；
- 计算文件哈希；
- 展示拍摄指导；
- 只申请用户选择文件所必需的权限。

App端不能独自裁定：

- 是否为公众人物；
- 用户是否拥有肖像权；
- 是否构成特殊类别生物识别处理；
- 商标、音乐和商业使用是否合法；
- 自动拒绝是否为最终决定；
- 素材能否发送给某个AI供应商。

这些决定来自服务端政策、审核或人工复核。

## 10. 失败安全

- 市场策略加载失败：允许浏览，不允许人物提交；
- 法律文案版本缺失：禁止支付；
- 授权上传失败：不创建生产任务；
- AI供应商状态未知：转人工，不选择未批准工具；
- 地区信息冲突：使用更严格规则并要求确认；
- 监护关系不明：不收集未成年人照片；
- EU机器标记验证失败：不发布成品；
- 美国州规则不明：禁用生物识别和声音工作流；
- 支付结果不明：显示处理中，不重复下单；
- 删除部分失败：保持处理中并升级。

## 11. 分析和日志限制

禁止向分析、崩溃或普通日志发送：

- 用户照片、视频、声音；
- 完整自由文本和Prompt；
- 肖像、监护和身份证明；
- 文件URL；
- 支付凭证和API密钥；
- 面部或声音特征；
- 用户真实姓名与角色名称组合。

分析事件只使用随机ID、市场、页面、标准枚举和结果码。EU非必要分析SDK的同意另行设计。

## 12. 测试建议

```text
test/features/customization/
  market_policy_test.dart
  order_status_mapping_test.dart
  consent_validation_test.dart
  requirement_snapshot_test.dart
  subject_restriction_test.dart
  eu_withdrawal_flow_test.dart
  subscription_disclosure_test.dart
  cancellation_flow_test.dart
  privacy_request_test.dart
  library_location_state_test.dart
  device_transfer_state_test.dart
```

Widget测试至少覆盖：

- 可选同意默认关闭；
- 未勾选必需授权不能继续；
- 其他成年人显示授权要求；
- 未成年人进入监护流程；
- EU市场显示批准的撤回权步骤；
- 美国订阅按钮显示金额和周期；
- 取消先完成，再显示可选问卷；
- 设备结果未知不显示成功；
- 策略加载失败时人物提交被阻断。

## 13. 当前页面改造策略

现有`CustomizationPage`保留为路由入口，但以后只负责：

- 加载市场策略和进行中订单；
- 展示下一步；
- 进入新定制向导；
- 进入角色、素材库和订阅；
- 在Demo模式明确不会上传或付款。

完整表单必须拆为独立、可测试的步骤组件。

## 14. 第一轮开发任务

### CUS-001 领域模型

创建市场、主体、人物关系、用途、授权、订单状态和下一步动作；加入规则单测。

### CUS-002 Demo Repository

定义仓库接口及内存实现；模拟草稿、需求快照、订单和状态推进；明确标记非真实订单。

### CUS-003 定制首页

进行中订单优先；人物/宠物入口；角色和素材库；商品商用只显示申请。

### CUS-004 开始向导

市场、地区、成年确认、主体关系、限制场景和草稿恢复。

### CUS-005 需求向导

照片要求占位、风格、标准动作、用途和只读需求摘要，不读取真实照片。

### CUS-006 授权原型

必需与可选授权分离；可选默认关闭；根据市场和主体动态显示；记录文案版本。

### CUS-007 订单演示

时间线、角色基准确认、预览反馈、质量/变更分支和素材库三位置状态。

## 15. 首轮代码验收

- [ ] 定制页不再只有SnackBar占位；
- [ ] Demo模式不申请照片权限、不上传、不支付；
- [ ] 市场和地区能够影响流程；
- [ ] 成年确认是阻断条件；
- [ ] 人物关系分为本人、未成年人和其他成年人；
- [ ] 商品商用不能绕过申请；
- [ ] 必需授权未确认时不能生成订单摘要；
- [ ] 案例展示和AI改进默认关闭；
- [ ] 需求摘要有版本且确认后只读；
- [ ] 客户状态来自单一枚举；
- [ ] 角色基准未确认时不能进入视频制作；
- [ ] 质量问题与需求变更走不同分支；
- [ ] 素材库区分云端、手机和设备；
- [ ] EU/US文案从版本化bundle读取；
- [ ] 核心规则具备单元或Widget测试。
