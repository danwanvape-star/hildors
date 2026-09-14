import 'package:flutter/material.dart';
import 'character_gate_order_progress.dart';

/// Serializes a page's UI actions without retrying repository mutations.
mixin GateActionState<T extends StatefulWidget> on State<T> {
  bool gateActionBusy = false;

  Future<void> runGateAction(Future<void> Function() action) async {
    if (!mounted || gateActionBusy) return;
    setState(() => gateActionBusy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) showGateActionError(context);
    } finally {
      if (mounted) setState(() => gateActionBusy = false);
    }
  }
}

/// Presentation-only vocabulary. Business status values remain repository-owned.
/// New locales can extend this catalog without changing persisted order data.
abstract final class GateCopy {
  static String text(BuildContext context, String key,
      [Map<String, Object> values = const {}]) {
    final language = Localizations.localeOf(context).languageCode;
    var value =
        (_copy[language] ?? _copy['zh']!)[key] ?? _copy['zh']![key] ?? key;
    for (final entry in values.entries) {
      value = value.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return value;
  }

  static const _copy = {
    'zh': {
      'catalogAnonymous': '匿名创作者',
      'catalogAuthorMissing': '作者未提供',
      'catalogBy': '创作者：{name}',
      'catalogDateMissing': '上架时间未提供',
      'catalogPublished': '上架：{date}',
      'photoSelectionHelp': '长按照片可多选，也可分批添加。最多 8 张；满额后请先移除照片。',
      'photoSelectionFull': '已选满 8 张',
      'freeLibraryTitle': '免费原创角色',
      'catalog.celestial-mage.name': '星穹术士',
      'catalog.celestial-mage.category': '幻想神话',
      'catalog.neon-dancer.name': '霓虹舞者',
      'catalog.neon-dancer.category': '舞台偶像',
      'catalog.deep-sea-oracle.name': '深海先知',
      'catalog.deep-sea-oracle.category': '可爱陪伴',
      'catalog.crystal-knight.name': '水晶骑士',
      'catalog.crystal-knight.category': '战斗动作',
      'freeCollectionBadge': '免费原创',
      'freeClaim': '免费领取',
      'freeClaimed': '已加入收藏',
      'freeClaiming': '正在确认',
      'freeOriginalBadge': '原创角色',
      'freeDeviceBadge': '设备实测',
      'freeIncluded': '包含初次见面、3 个待机动作、1 个招牌动作和基础角色护照。',
      'freeDeliveryHelp': '领取后可从收藏页将角色传入绑定设备。正式视频和工程文件不可导出。',
      'freeClaimSuccess': '角色已加入本地收藏。云端账户权益尚未接入。',
      'collectionEmptyTitle': '还没有收藏角色',
      'collectionEmptyHelp': '免费领取的原创角色和已交付的付费定制将统一显示在这里。',
      'browseFreeCharacters': '浏览免费原创角色',
      'startFreeReview': '发起免费定制预审',
      'quoteEstimateMissing': '创作者建议制作费尚未提供',
      'photoPickFailed': '暂时无法选择照片，已保留原有选择。请重试。',
      'pickingPhotos': '正在选择照片…',
      'photo': '照片',
      'removePhoto': '移除照片',
      'reviewMissing': '提交前还需完成：',
      'needPhotos': '至少 {count} 张照片（最多 8 张）',
      'needName': '角色名称',
      'needFeatures': '功能需求',
      'needRegion': '常住地区',
      'needRights': '权利确认',
      'needPrivacy': '素材处理授权',
      'studio': '全息角色工作室',
      'secure': '绑定设备 · 受控交付',
      'journey': '从灵感到桌面，让角色成为你的收藏',
      'brief': '提交灵感',
      'quote': '确认报价',
      'make': '专属制作',
      'deliver': '验收与交付',
      'all': '全部任务',
      'available': '可申请',
      'working': '制作中',
      'search': '搜索角色名称',
      'noMatches': '没有匹配的任务',
      'reset': '清除筛选',
      'next': '当前阶段',
      'stageDone': '已完成',
      'stageUpcoming': '尚未进入',
      'stageInactive': '无进行中阶段',
      'stepReview': '等待免费预审结果；审核通过后才会提供制作方案。',
      'stepMatching': '预审已通过，正在匹配创作者；目前无需付款。',
      'stepEstimate': '创作者正在评估工作量和交期，请等待平台最终报价。',
      'stepPlatformQuote': '平台正在审核制作方案，最终报价发布后由你决定是否接受。',
      'stepAcceptQuote': '核对价格、修改次数和交付范围，再决定是否接受报价。',
      'stepPayment': '报价已接受，请核对付款前确认页；确认报价本身不会扣款。',
      'stepProduction': '角色正在制作，请关注预计交付日期和受控预览更新。',
      'stepRevision': '创作者正在根据修改意见调整内容，请等待新版本。',
      'stepQuality': '平台正在检查内容质量与设备播放效果，通过后将开放用户验收。',
      'stepApproval': '核对预览版本和约定范围，再决定验收或提出修改。',
      'stepDelivered': '验收已完成，可在我的角色中查看并发送到绑定设备。',
      'stepWithdrawn': '本次申请已结束，不会进入制作；可重新发起免费预审。',
      'stepRejected': '查看未通过原因，补齐资料后可以重新申请。',
      'stepDeclined': '你已结束本次报价流程，不会继续进入付款或制作。',
      'stepDispute': '等待平台处理争议；当前不处于正常制作或验收阶段。',
      'stepRefundPending': '退款正在处理，请等待平台更新处理结果。',
      'stepRefunded': '退款流程已完成，本订单不会继续制作或验收。',
      'stepUnknown': '暂时无法识别此订单阶段，请刷新状态或联系平台。',
      'quoteLocked': '预审通过后才会解锁',
      'quoteMatching': '等待创作者匹配，尚未形成报价',
      'quoteEstimating': '创作者正在评估工作量，尚待平台审核',
      'quotePlatform': '平台正在审核报价，尚未向你确认',
      'quoteWaiting': '等待你确认报价',
      'quoteAccepted': '报价已确认',
      'quoteDeclined': '报价已拒绝，本次报价流程结束',
      'quoteClosed': '申请已结束，不再进入报价流程',
      'quoteHistory': '请查看报价记录与平台处理结果',
      'quoteUnknown': '报价状态待确认',
      'loading': '正在加载内容',
      'loadFailed': '暂时无法加载内容',
      'loadHelp': '请稍后重试。加载失败不会更改你的订单或收藏。',
      'retry': '重新加载',
      'refresh': '刷新',
      'submitting': '正在提交…',
      'actionPending': '正在处理当前操作…',
      'validAmount': '请输入有效且大于零的制作费',
      'quoteBelowSuggestion': '最终价格不能低于同币种的创作者建议制作费',
      'validRevisions': '请输入大于或等于零的整数次数',
      'quoteOverrideRequired': '请填写调整结算币种的原因',
      'validDays': '请输入大于零的整数天数',
      'extensionDays': '请输入 1 至 30 的整数天数',
      'filterHelp': '试试其他状态，或清除筛选查看全部任务。',
      'actionUnconfirmed': '暂时无法确认操作结果。请先刷新状态，再决定是否重试。',
      'freeReviewTitle': '免费预审',
      'supplementReview': '正在补充申请 {id}。角色信息和功能需求已带入，请重新上传合格素材并再次确认授权。',
      'reviewHero': '先确认我们能否安全、稳定地完成',
      'selectedType': '已选择：{type}',
      'reviewFreeIntro': '预审不会收费。审核素材、权利和复杂度后，才会询问你是否接受报价。',
      'materialsHeading': '提交参考素材',
      'originalMaterialHelp': '至少 3 张：正面、侧面和背面，光线均匀、无滤镜。',
      'otherMaterialHelp': '至少 2 张：一张清晰全身图和一张补充角度或设定图。',
      'choosePhotos': '选择照片',
      'reselectPhotos': '已选 {count}/8 张，继续添加',
      'materialPolicy': '不接受：裸体或性化未成年人、非自愿亲密内容、仇恨符号、明显盗版水印素材。',
      'characterName': '角色名称',
      'characterNameHint': '例如：我的星际狐狸',
      'featuresQuestion': '想让角色做什么？',
      'featureIdle': '待机动作',
      'featureDance': '唱跳表演',
      'featureMusic': '音乐联动',
      'featureMemory': '角色记忆',
      'regionLabel': '你的常住地区',
      'regionHint': '请选择地区',
      'regionUs': '美国',
      'regionEea': '欧洲经济区',
      'regionUk': '英国',
      'regionJp': '日本',
      'regionCn': '中国大陆',
      'regionHk': '中国香港',
      'regionMo': '中国澳门',
      'regionTw': '中国台湾',
      'regionAsiaOther': '其他亚洲地区',
      'regionOther': '其他地区',
      'rightsTitle': '我确认对提交的角色和素材拥有必要权利',
      'rightsHelp': '第三方游戏或动漫 IP 请使用角色许愿入口。',
      'privacyTitle': '我同意平台为预审和制作处理本次上传素材',
      'privacyHelp': '素材不用于公开发布或训练其他用户的角色；撤回申请后按保留规则删除。',
      'submitReview': '提交免费预审',
      'noCharge': '此步不会产生费用',
      'duplicateReviewTitle': '已有整改申请正在处理中',
      'duplicateReviewBody': '同一申请不能重复提交。请返回“我的角色”查看最新审核进度。',
      'reviewSubmittedTitle': '已提交免费预审',
      'reviewSubmittedBody': '审核通过后才会提供报价；只有你确认报价后才进入付款。',
      'gotIt': '知道了',
      'typeOriginalFigure': '原创手办',
      'typeOriginalCharacter': '原创角色',
      'typeBrandCharacter': '品牌角色',
      'customOrderTitle': '专属定制',
      'sourceQuestion': '这位角色来自哪里？',
      'sourceIntro': '我们会先免费检查素材、角色来源、制作复杂度和设备适配风险。',
      'sourceOriginalTitle': '这是我想要的角色',
      'sourceOriginalHelp': '提交角色设定图、原创过程或你拥有的模型。',
      'sourceFigureTitle': '这是我的手办',
      'sourceFigureHelp': '使用多角度照片制作数字陈列或角色活化。',
      'sourceBrandTitle': '我代表品牌或权利方',
      'sourceBrandHelp': '品牌角色和商业用途需要补充权利与用途资料。',
      'sourceThirdPartyTitle': '这是我喜欢的游戏或动漫角色',
      'sourceThirdPartyHelp': '喜欢或购买实体商品，不一定包含数字改编权。',
      'authorizationTitle': '角色授权',
      'authorizationHero': '这位角色可能还没有进入 Hildors',
      'authorizationHelp': '没有适用授权时，我们不会接受付费定制。你可以提交愿望并关注未来开放状态。',
      'wishAction': '提交角色愿望',
      'wishTitle': '角色许愿',
      'wishHero': '希望谁进入角色之门？',
      'wishHelp': '许愿不会产生费用，也不代表平台已经获得授权或承诺上线。',
      'workName': '作品或游戏名称',
      'wishUnavailable': '原型：愿望提交接口尚未接入。',
    },
    'en': {
      'catalogAnonymous': 'Anonymous creator',
      'catalogAuthorMissing': 'Not provided',
      'catalogBy': 'Creator: {name}',
      'catalogDateMissing': 'Publish date not provided',
      'catalogPublished': 'Published: {date}',
      'photoSelectionHelp':
          'Touch and hold to select multiple photos, or add them in batches. Up to 8; remove a photo to add another.',
      'photoSelectionFull': '8 photos selected · Limit reached',
      'freeLibraryTitle': 'Free original characters',
      'catalog.celestial-mage.name': 'Celestial Mage',
      'catalog.celestial-mage.category': 'Fantasy & mythology',
      'catalog.neon-dancer.name': 'Neon Dancer',
      'catalog.neon-dancer.category': 'Stage idols',
      'catalog.deep-sea-oracle.name': 'Deep Sea Oracle',
      'catalog.deep-sea-oracle.category': 'Companions',
      'catalog.crystal-knight.name': 'Crystal Knight',
      'catalog.crystal-knight.category': 'Combat & action',
      'freeCollectionBadge': 'Free original',
      'freeClaim': 'Claim for free',
      'freeClaimed': 'Added to collection',
      'freeClaiming': 'Confirming',
      'freeOriginalBadge': 'Original character',
      'freeDeviceBadge': 'Device tested',
      'freeIncluded':
          'Includes a first greeting, 3 idle animations, 1 signature move, and a basic character passport.',
      'freeDeliveryHelp':
          'After claiming, send this character to a bound device from your collection. Final videos and project files cannot be exported.',
      'freeClaimSuccess':
          'Character added to your local collection. Cloud account entitlements are not connected yet.',
      'collectionEmptyTitle': 'Your collection starts here',
      'collectionEmptyHelp':
          'Free original characters and delivered commissions will appear here.',
      'browseFreeCharacters': 'Explore free characters',
      'startFreeReview': 'Start a free commission review',
      'quoteEstimateMissing': 'Creator estimate has not been provided',
      'photoPickFailed':
          'Photos could not be selected. Your previous selection was kept. Please try again.',
      'pickingPhotos': 'Selecting photos…',
      'photo': 'Photo',
      'removePhoto': 'Remove photo',
      'reviewMissing': 'Before submitting, complete:',
      'needPhotos': 'At least {count} photos (up to 8)',
      'needName': 'Character name',
      'needFeatures': 'Requested features',
      'needRegion': 'Region of residence',
      'needRights': 'Rights confirmation',
      'needPrivacy': 'Material processing consent',
      'studio': 'Holographic character studio',
      'secure': 'Bound device · Controlled delivery',
      'journey': 'From an idea to a collectible on your desk',
      'brief': 'Your brief',
      'quote': 'Approve quote',
      'make': 'Creation',
      'deliver': 'Review & delivery',
      'all': 'All tasks',
      'available': 'Available',
      'working': 'In production',
      'search': 'Search character name',
      'noMatches': 'No matching tasks',
      'reset': 'Clear filters',
      'next': 'Current stage',
      'stageDone': 'Complete',
      'stageUpcoming': 'Not started',
      'stageInactive': 'No active stage',
      'stepReview':
          'Awaiting free review. A production proposal follows approval.',
      'stepMatching':
          'Review approved. Matching a creator; no payment is needed yet.',
      'stepEstimate':
          'The creator is estimating the work and timeline. Await the platform quote.',
      'stepPlatformQuote':
          'The platform is reviewing the proposal. You decide whether to accept the final quote.',
      'stepAcceptQuote':
          'Check the price, revisions and scope before accepting.',
      'stepPayment':
          'Quote accepted. Review checkout details; accepting a quote does not charge you.',
      'stepProduction':
          'Your character is in production. Check delivery dates and protected preview updates.',
      'stepRevision':
          'The creator is applying your feedback. Await the next version.',
      'stepQuality':
          'The platform is checking content quality and device playback. Your review opens after these checks pass.',
      'stepApproval':
          'Check the preview version and agreed scope before approval or requesting revisions.',
      'stepDelivered':
          'Approved. Find your character in your collection and send it to a bound device.',
      'stepWithdrawn':
          'This request has ended. You can submit a new free review.',
      'stepRejected':
          'Review the feedback and update your materials before applying again.',
      'stepDeclined':
          'This quote was declined. Payment and production will not proceed.',
      'stepDispute':
          'Awaiting platform dispute resolution. Normal production and approval are paused.',
      'stepRefundPending':
          'The refund is being processed. Await the platform update.',
      'stepRefunded':
          'Refund complete. Production and approval will not continue for this order.',
      'stepUnknown':
          'This stage could not be recognized. Refresh the status or contact the platform.',
      'quoteLocked': 'Available after review approval',
      'quoteMatching': 'Matching a creator; no quote yet',
      'quoteEstimating':
          'Creator estimate in progress; platform review follows',
      'quotePlatform': 'Platform quote review in progress',
      'quoteWaiting': 'Awaiting your quote approval',
      'quoteAccepted': 'Quote accepted',
      'quoteDeclined': 'Quote declined; this quote process has ended',
      'quoteClosed': 'Request ended; no further quote',
      'quoteHistory': 'See the quote history and platform resolution',
      'quoteUnknown': 'Quote status unconfirmed',
      'loading': 'Loading content',
      'loadFailed': 'Content could not be loaded',
      'loadHelp': 'Please try loading your orders and collection again.',
      'retry': 'Try again',
      'refresh': 'Refresh',
      'submitting': 'Submitting…',
      'actionPending': 'Processing the current action…',
      'validAmount': 'Enter a valid amount greater than zero',
      'quoteBelowSuggestion':
          'The price must cover the creator estimate in this currency',
      'validRevisions': 'Enter a whole number of revisions, zero or greater',
      'quoteOverrideRequired':
          'Explain why the settlement currency is changing',
      'validDays': 'Enter a whole number of days greater than zero',
      'extensionDays': 'Enter a whole number of days from 1 to 30',
      'filterHelp': 'Try another status, or clear filters to see all tasks.',
      'actionUnconfirmed':
          'The result could not be confirmed. Refresh the status before trying again.',
      'freeReviewTitle': 'Free review',
      'supplementReview':
          'Updating request {id}. Character details and features are prefilled; upload eligible materials and confirm consent again.',
      'reviewHero':
          'First, let us confirm we can create it safely and reliably',
      'selectedType': 'Selected: {type}',
      'reviewFreeIntro':
          'The review is free. After checking materials, rights and complexity, we will ask whether you accept a quote.',
      'materialsHeading': 'Reference materials',
      'originalMaterialHelp':
          'At least 3 photos: front, side and back, evenly lit and without filters.',
      'otherMaterialHelp':
          'At least 2 photos: one clear full-body view and one extra angle or design reference.',
      'choosePhotos': 'Choose photos',
      'reselectPhotos': '{count}/8 photos · Add more',
      'materialPolicy':
          'Not accepted: nude or sexualized minors, non-consensual intimate content, hate symbols or clearly pirated watermarked material.',
      'characterName': 'Character name',
      'characterNameHint': 'Example: My cosmic fox',
      'featuresQuestion': 'What should the character do?',
      'featureIdle': 'Idle motion',
      'featureDance': 'Song & dance',
      'featureMusic': 'Music sync',
      'featureMemory': 'Character memory',
      'regionLabel': 'Your region of residence',
      'regionHint': 'Select a region',
      'regionUs': 'United States',
      'regionEea': 'European Economic Area',
      'regionUk': 'United Kingdom',
      'regionJp': 'Japan',
      'regionCn': 'Mainland China',
      'regionHk': 'Hong Kong, China',
      'regionMo': 'Macao, China',
      'regionTw': 'Taiwan, China',
      'regionAsiaOther': 'Other Asian region',
      'regionOther': 'Other region',
      'rightsTitle':
          'I confirm I have the required rights to this character and material',
      'rightsHelp':
          'Use the character wish entry for third-party game or anime IP.',
      'privacyTitle':
          'I consent to processing these materials for review and production',
      'privacyHelp':
          'Materials are not published or used to train other users’ characters, and follow the retention policy after withdrawal.',
      'submitReview': 'Submit free review',
      'noCharge': 'No charge at this step',
      'duplicateReviewTitle': 'An update is already under review',
      'duplicateReviewBody':
          'The same request cannot be submitted twice. Check the latest status in My Characters.',
      'reviewSubmittedTitle': 'Free review submitted',
      'reviewSubmittedBody':
          'A quote is provided only after approval. Payment begins only after you accept it.',
      'gotIt': 'Got it',
      'typeOriginalFigure': 'Original figure',
      'typeOriginalCharacter': 'Original character',
      'typeBrandCharacter': 'Brand character',
      'customOrderTitle': 'Custom character',
      'sourceQuestion': 'Where does this character come from?',
      'sourceIntro':
          'We first review the materials, character origin, production complexity and device compatibility at no charge.',
      'sourceOriginalTitle': 'This is the character I want',
      'sourceOriginalHelp':
          'Provide concept art, creation evidence or a model you own.',
      'sourceFigureTitle': 'This is my figure',
      'sourceFigureHelp':
          'Use multi-angle photos to create a digital display or bring the character to life.',
      'sourceBrandTitle': 'I represent the brand or rights holder',
      'sourceBrandHelp':
          'Brand characters and commercial use require additional rights and usage details.',
      'sourceThirdPartyTitle': 'This is a game or anime character I like',
      'sourceThirdPartyHelp':
          'Liking a character or buying merchandise may not include digital adaptation rights.',
      'authorizationTitle': 'Character rights',
      'authorizationHero': 'This character may not be available on Hildors yet',
      'authorizationHelp':
          'Without applicable rights, we cannot accept a paid commission. Submit a wish and follow future availability.',
      'wishAction': 'Submit a character wish',
      'wishTitle': 'Character wish',
      'wishHero': 'Who would you like to see in Character Gate?',
      'wishHelp':
          'A wish is free and does not mean the platform has secured rights or promised a release.',
      'workName': 'Work or game title',
      'wishUnavailable':
          'Prototype: character wish submission is not connected yet.',
    },
    'ja': {
      'catalogAnonymous': '匿名クリエイター',
      'catalogAuthorMissing': '未提供',
      'catalogBy': '制作者：{name}',
      'catalogDateMissing': '公開日未提供',
      'catalogPublished': '公開：{date}',
      'photoSelectionHelp': '長押しで複数選択するか、分けて追加できます。最大8枚。追加するには先に写真を削除してください。',
      'photoSelectionFull': '8枚選択済み・上限に達しました',
      'freeLibraryTitle': '無料オリジナルキャラクター',
      'catalog.celestial-mage.name': '星穹の魔術師',
      'catalog.celestial-mage.category': 'ファンタジー・神話',
      'catalog.neon-dancer.name': 'ネオンダンサー',
      'catalog.neon-dancer.category': 'ステージアイドル',
      'catalog.deep-sea-oracle.name': '深海の預言者',
      'catalog.deep-sea-oracle.category': '癒やしの仲間',
      'catalog.crystal-knight.name': 'クリスタルナイト',
      'catalog.crystal-knight.category': 'バトル・アクション',
      'freeCollectionBadge': '無料オリジナル',
      'freeClaim': '無料で入手',
      'freeClaimed': 'コレクションに追加済み',
      'freeClaiming': '確認中',
      'freeOriginalBadge': 'オリジナルキャラクター',
      'freeDeviceBadge': '実機確認済み',
      'freeIncluded': '初回の挨拶、3種類の待機モーション、1種類のシグネチャーモーション、基本キャラクターパスポートが含まれます。',
      'freeDeliveryHelp': '入手後、コレクションから連携済みデバイスへ転送できます。完成動画や制作ファイルは書き出せません。',
      'freeClaimSuccess': 'ローカルのコレクションに追加しました。クラウドアカウントの利用権連携は未接続です。',
      'collectionEmptyTitle': 'コレクションを始めましょう',
      'collectionEmptyHelp': '無料で受け取ったオリジナルキャラクターと納品済みのカスタム作品がここに表示されます。',
      'browseFreeCharacters': '無料キャラクターを見る',
      'startFreeReview': 'カスタム制作の無料審査へ',
      'quoteEstimateMissing': 'クリエイターの見積額はまだ提示されていません',
      'photoPickFailed': '写真を選択できませんでした。前の選択は保持されています。もう一度お試しください。',
      'pickingPhotos': '写真を選択中…',
      'photo': '写真',
      'removePhoto': '写真を削除',
      'reviewMissing': '送信前に必要な項目：',
      'needPhotos': '写真 {count} 枚以上（最大 8 枚）',
      'needName': 'キャラクター名',
      'needFeatures': '希望する機能',
      'needRegion': '居住地域',
      'needRights': '権利の確認',
      'needPrivacy': '素材処理への同意',
      'studio': 'ホログラムキャラクタースタジオ',
      'secure': '登録済みデバイスへ安全に転送',
      'journey': 'アイデアから、デスクで出会えるコレクションへ',
      'brief': '依頼内容',
      'quote': '見積もり確認',
      'make': '制作',
      'deliver': '確認・納品',
      'all': 'すべて',
      'available': '応募可能',
      'working': '制作中',
      'search': 'キャラクター名で検索',
      'noMatches': '該当する依頼はありません',
      'reset': '絞り込みを解除',
      'next': '現在のステップ',
      'stageDone': '完了',
      'stageUpcoming': '未開始',
      'stageInactive': '進行中のステップなし',
      'stepReview': '無料審査の結果をお待ちください。承認後に制作案をご案内します。',
      'stepMatching': '審査を通過し、クリエイターを選定中です。まだお支払いは不要です。',
      'stepEstimate': 'クリエイターが工数と納期を確認中です。正式な見積もりをお待ちください。',
      'stepPlatformQuote': 'プラットフォームが制作案を確認中です。最終見積もりの承認はお客様が選べます。',
      'stepAcceptQuote': '金額、修正回数、納品範囲を確認してから見積もりを承認してください。',
      'stepPayment': '見積もり承認済みです。支払い前の確認画面をご確認ください。承認だけでは課金されません。',
      'stepProduction': 'キャラクターを制作中です。納期と保護されたプレビューの更新をご確認ください。',
      'stepRevision': 'ご意見に基づいて修正中です。次のバージョンをお待ちください。',
      'stepQuality': 'プラットフォームがコンテンツ品質とデバイス再生を確認中です。合格後に検収できます。',
      'stepApproval': 'プレビューと合意した範囲を確認してから、検収または修正をご依頼ください。',
      'stepDelivered': '検収完了です。コレクションから登録済みデバイスへ送信できます。',
      'stepWithdrawn': 'この依頼は終了しました。新しい無料審査を申請できます。',
      'stepRejected': '審査結果を確認し、資料を補ってから再申請してください。',
      'stepDeclined': '見積もりを辞退しました。この依頼の支払いや制作には進みません。',
      'stepDispute': 'プラットフォームの対応をお待ちください。通常の制作と検収は一時停止中です。',
      'stepRefundPending': '返金処理中です。プラットフォームからの更新をお待ちください。',
      'stepRefunded': '返金が完了しました。この注文の制作と検収は終了しています。',
      'stepUnknown': '注文のステップを確認できません。更新するかプラットフォームにお問い合わせください。',
      'quoteLocked': '審査通過後にご案内します',
      'quoteMatching': 'クリエイター選定中・見積もり前',
      'quoteEstimating': '工数を確認中・その後プラットフォームが審査',
      'quotePlatform': 'プラットフォームが見積もりを審査中',
      'quoteWaiting': '見積もりの承認待ち',
      'quoteAccepted': '見積もり承認済み',
      'quoteDeclined': '見積もり辞退・この見積もりは終了',
      'quoteClosed': '依頼終了・見積もりには進みません',
      'quoteHistory': '見積もり履歴とプラットフォームの対応をご確認ください',
      'quoteUnknown': '見積もり状況を確認できません',
      'loading': 'コンテンツを読み込み中',
      'loadFailed': 'コンテンツを読み込めませんでした',
      'loadHelp': '注文やコレクションをもう一度読み込んでください。',
      'retry': '再読み込み',
      'refresh': '更新',
      'submitting': '送信中…',
      'actionPending': '現在の操作を処理中…',
      'validAmount': '0より大きい有効な金額を入力してください',
      'quoteBelowSuggestion': '同じ通貨のクリエイター見積額以上を入力してください',
      'validRevisions': '0以上の整数の修正回数を入力してください',
      'quoteOverrideRequired': '決済通貨を変更する理由を入力してください',
      'validDays': '0より大きい整数の日数を入力してください',
      'extensionDays': '1〜30の整数の日数を入力してください',
      'filterHelp': '別のステータスを選ぶか、絞り込みを解除してください。',
      'actionUnconfirmed': '操作結果を確認できませんでした。再試行する前に、最新の状態を確認してください。',
      'freeReviewTitle': '無料事前審査',
      'supplementReview':
          '申請 {id} を更新しています。キャラクター情報と希望機能は入力済みです。適切な素材を再アップロードし、同意事項を再確認してください。',
      'reviewHero': '安全かつ安定して制作できるか、まず確認します',
      'selectedType': '選択済み：{type}',
      'reviewFreeIntro': '事前審査は無料です。素材、権利、制作難易度を確認した後、見積もりを承認するかお伺いします。',
      'materialsHeading': '参考素材を提出',
      'originalMaterialHelp': '正面・側面・背面の写真を最低3枚。均一な明るさで、フィルターなしの写真をご用意ください。',
      'otherMaterialHelp': '全身が鮮明に見える写真1枚と、別角度または設定資料1枚の、最低2枚をご用意ください。',
      'choosePhotos': '写真を選択',
      'reselectPhotos': '{count}/8枚選択済み・追加',
      'materialPolicy': '受付不可：未成年者の裸体・性的表現、同意のない親密な内容、ヘイトシンボル、明らかな海賊版の透かし入り素材。',
      'characterName': 'キャラクター名',
      'characterNameHint': '例：星空のキツネ',
      'featuresQuestion': 'キャラクターに何をしてほしいですか？',
      'featureIdle': '待機モーション',
      'featureDance': '歌・ダンス',
      'featureMusic': '音楽連動',
      'featureMemory': 'キャラクター記憶',
      'regionLabel': '居住地域',
      'regionHint': '地域を選択',
      'regionUs': 'アメリカ',
      'regionEea': '欧州経済領域',
      'regionUk': 'イギリス',
      'regionJp': '日本',
      'regionCn': '中国本土',
      'regionHk': '中国香港',
      'regionMo': '中国マカオ',
      'regionTw': '中国台湾',
      'regionAsiaOther': 'その他のアジア地域',
      'regionOther': 'その他の地域',
      'rightsTitle': '提出するキャラクターと素材に必要な権利を保有していることを確認します',
      'rightsHelp': '第三者のゲーム・アニメIPは、キャラクターリクエストをご利用ください。',
      'privacyTitle': '事前審査と制作のために、今回の素材を処理することに同意します',
      'privacyHelp': '素材は公開や他ユーザーのキャラクター学習には使用せず、申請撤回後は保存規定に従って削除します。',
      'submitReview': '無料事前審査を送信',
      'noCharge': 'このステップでは料金は発生しません',
      'duplicateReviewTitle': '修正申請を審査中です',
      'duplicateReviewBody': '同じ申請を重複して送信することはできません。「マイキャラクター」で最新状況をご確認ください。',
      'reviewSubmittedTitle': '無料事前審査を送信しました',
      'reviewSubmittedBody': '審査通過後に見積もりをご案内します。お支払いは見積もり承認後にのみ開始します。',
      'gotIt': '確認しました',
      'typeOriginalFigure': 'オリジナルフィギュア',
      'typeOriginalCharacter': 'オリジナルキャラクター',
      'typeBrandCharacter': 'ブランドキャラクター',
      'customOrderTitle': '専属カスタム',
      'sourceQuestion': 'このキャラクターはどこから生まれましたか？',
      'sourceIntro': '素材、キャラクターの出所、制作難易度、デバイス適合リスクを無料で事前確認します。',
      'sourceOriginalTitle': '希望するキャラクター',
      'sourceOriginalHelp': '設定画、制作過程、または所有するモデルを提出してください。',
      'sourceFigureTitle': '自分のフィギュア',
      'sourceFigureHelp': '複数角度の写真から、デジタル展示やキャラクターの動きを制作します。',
      'sourceBrandTitle': 'ブランドまたは権利者を代表している',
      'sourceBrandHelp': 'ブランドキャラクターや商用利用には、権利と用途の追加資料が必要です。',
      'sourceThirdPartyTitle': '好きなゲーム・アニメのキャラクター',
      'sourceThirdPartyHelp': '好意やグッズの購入だけでは、デジタル改変権を含まない場合があります。',
      'authorizationTitle': 'キャラクターの権利',
      'authorizationHero': 'このキャラクターはまだ Hildors で提供できない可能性があります',
      'authorizationHelp':
          '適用できる権利がない場合、有料カスタムは受け付けません。リクエストを送り、今後の提供状況をご確認ください。',
      'wishAction': 'キャラクターをリクエスト',
      'wishTitle': 'キャラクターリクエスト',
      'wishHero': 'キャラクターゲートに誰を迎えたいですか？',
      'wishHelp': 'リクエストは無料です。プラットフォームの権利取得や提供開始を保証するものではありません。',
      'workName': '作品・ゲーム名',
      'wishUnavailable': 'プロトタイプ：キャラクターリクエストの送信機能は未接続です。',
    },
  };
}

void showGateActionError(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: GateDesign.surface,
    duration: const Duration(seconds: 6),
    content: Text(GateCopy.text(context, 'actionUnconfirmed'),
        style: const TextStyle(color: GateDesign.ink)),
  ));
}

/// Dialog routes are created above the page's scoped Theme. Reapply the module
/// theme here so directly opened pages and their dialogs stay consistent.
Future<T?> showGateDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) =>
    showDialog<T>(
      context: context,
      builder: (_) =>
          Theme(data: GateDesign.theme(), child: Builder(builder: builder)),
    );

abstract final class GateDesign {
  static const background = Color(0xFF090D18);
  static const surface = Color(0xFF141C2D);
  static const accent = Color(0xFF91F5DC);
  static const ink = Color(0xFFEEF3FF);
  static const muted = Color(0xFFADB9D0);

  static final ThemeData _theme = _buildTheme();
  static ThemeData theme() => _theme;

  static ThemeData _buildTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ).copyWith(
        primary: accent,
        onPrimary: background,
        surface: surface,
        onSurface: ink,
        onSurfaceVariant: muted,
        outline: const Color(0xFF44516A));
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: ink,
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0),
      cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 5),
          shape:
              shape.copyWith(side: const BorderSide(color: Color(0xFF29354C)))),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
            fontSize: 32, height: 1.2, fontWeight: FontWeight.w700, color: ink),
        headlineSmall: TextStyle(
            fontSize: 25, height: 1.3, fontWeight: FontWeight.w700, color: ink),
        titleLarge:
            TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: ink),
        titleMedium:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ink),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: muted),
      ),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0F1625),
          helperMaxLines: 4,
          errorMaxLines: 4,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding: const EdgeInsets.all(16)),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)))),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)))),
      chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF1C2940),
          selectedColor: const Color(0xFF245749),
          side: BorderSide.none,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF263D49),
          contentTextStyle: TextStyle(color: ink)),
      dividerTheme: const DividerThemeData(color: Color(0xFF29354C)),
    );
  }
}

/// Read-only page loading, with stale-response and disposed-route protection.
/// Repository writes and business transitions are deliberately not handled here.
mixin GateLoadState<T extends StatefulWidget> on State<T> {
  bool gateLoading = true;
  bool gateLoadFailed = false;
  int _loadGeneration = 0;

  Future<void> loadGateData<D>(
    Future<D> Function() fetch,
    void Function(D data) apply,
  ) async {
    if (!mounted) return;
    final generation = ++_loadGeneration;
    setState(() {
      gateLoading = true;
      gateLoadFailed = false;
    });
    try {
      final data = await fetch();
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        apply(data);
        gateLoading = false;
      });
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        gateLoading = false;
        gateLoadFailed = true;
      });
    }
  }
}

class GateLoadPanel extends StatelessWidget {
  const GateLoadPanel({required this.failed, required this.onRetry, super.key});
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Semantics(
                liveRegion: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (failed)
                      const Icon(Icons.cloud_off_outlined,
                          size: 40, color: GateDesign.muted)
                    else
                      CircularProgressIndicator(
                          semanticsLabel: GateCopy.text(context, 'loading')),
                    const SizedBox(height: 20),
                    Text(
                        GateCopy.text(
                            context, failed ? 'loadFailed' : 'loading'),
                        textAlign: TextAlign.center,
                        style: GateDesign.theme().textTheme.titleLarge),
                    if (failed) ...[
                      const SizedBox(height: 10),
                      Text(GateCopy.text(context, 'loadHelp'),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh),
                          label: Text(GateCopy.text(context, 'retry'))),
                    ],
                  ],
                )),
          ),
        ),
      );
}

class GateRefreshButton extends StatelessWidget {
  const GateRefreshButton(
      {required this.loading, required this.onRefresh, super.key});
  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: GateCopy.text(context, 'refresh'),
        onPressed: loading ? null : onRefresh,
        icon: const Icon(Icons.refresh),
      );
}

/// A module-scoped shell; each route also works when opened independently.
class GateScaffold extends StatelessWidget {
  const GateScaffold(
      {this.appBar, required this.body, this.wide = false, super.key});
  final PreferredSizeWidget? appBar;
  final Widget body;
  final bool wide;

  @override
  Widget build(BuildContext context) => Theme(
        data: GateDesign.theme(),
        child: Scaffold(
          appBar: appBar,
          body: DecoratedBox(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF101E2B),
                GateDesign.background,
                Color(0xFF171329)
              ],
            )),
            child: SafeArea(
                top: false,
                child: Center(
                    child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 1180 : 880),
                  child: body,
                ))),
          ),
        ),
      );
}

class GateSection extends StatelessWidget {
  const GateSection(
      {required this.eyebrow,
      required this.title,
      required this.description,
      this.icon = Icons.auto_awesome_outlined,
      super.key});
  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: GateDesign.accent, size: 18),
            const SizedBox(width: 8),
            Expanded(
                child: Text(eyebrow,
                    style: const TextStyle(
                        color: GateDesign.accent,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700)))
          ]),
          const SizedBox(height: 10),
          Text(title, style: GateDesign.theme().textTheme.headlineSmall),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(description,
                style: const TextStyle(color: GateDesign.muted, height: 1.5)),
          ],
        ]),
      );
}

/// Keeps long identifiers and actions readable at narrow widths and large text.
class GateDetailTile extends StatelessWidget {
  const GateDetailTile(
      {required this.title,
      required this.subtitle,
      required this.trailing,
      this.leading,
      super.key});

  final Widget title;
  final Widget subtitle;
  final Widget trailing;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
          final stacked = constraints.maxWidth < 560 * textScale;
          final details =
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            DefaultTextStyle.merge(
                style: const TextStyle(fontWeight: FontWeight.w600),
                child: title),
            const SizedBox(height: 6),
            DefaultTextStyle.merge(
                style: const TextStyle(color: GateDesign.muted),
                child: subtitle),
          ]);
          if (stacked) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(height: 12)
                  ],
                  details,
                  const SizedBox(height: 16),
                  trailing,
                ]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (leading != null) ...[leading!, const SizedBox(width: 16)],
            Expanded(child: details),
            const SizedBox(width: 20),
            ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: constraints.maxWidth * .36),
                child: trailing),
          ]);
        }),
      );
}

class GateStatus extends StatelessWidget {
  const GateStatus(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final attention = ['失败', '争议', '未通过', '逾期'].any(label.contains);
    final done = ['已交付', '已结算', '已认证'].contains(label);
    final closed = ['已撤回', '已拒绝报价', '已退款'].contains(label);
    final color = attention
        ? const Color(0xFFFFB5A5)
        : closed
            ? GateDesign.muted
            : GateDesign.accent;
    return Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
                attention
                    ? Icons.error_outline
                    : done
                        ? Icons.check_circle_outline
                        : closed
                            ? Icons.remove_circle_outline
                            : Icons.timelapse,
                size: 16,
                color: color),
            const SizedBox(width: 7),
            Flexible(
                child: Text(label,
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.w600))),
          ]),
        ));
  }
}

class GateJourney extends StatelessWidget {
  const GateJourney({this.stage = 0, this.complete = false, super.key});
  final int stage;
  final bool complete;

  factory GateJourney.forStatus(String status, {Key? key}) {
    final progress = GateOrderProgress.fromStatus(status);
    return GateJourney(
        stage: progress.stage, complete: progress.complete, key: key);
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final labels = ['brief', 'quote', 'make', 'deliver'];
        return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
                4,
                (index) => SizedBox(
                      width: (constraints.maxWidth -
                              (constraints.maxWidth < 440 ? 8 : 24)) /
                          (constraints.maxWidth < 440 ? 2 : 4),
                      child: Semantics(
                          selected: !complete && index == stage,
                          label: GateCopy.text(
                              context,
                              complete || (stage >= 0 && index < stage)
                                  ? 'stageDone'
                                  : index == stage
                                      ? 'next'
                                      : stage < 0
                                          ? 'stageInactive'
                                          : 'stageUpcoming'),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: complete || index == stage
                                    ? const Color(0xFF204139)
                                    : const Color(0xFF162135),
                                borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [
                              if (complete ||
                                  (stage >= 0 && index < stage)) ...[
                                const Icon(Icons.check,
                                    size: 14, color: GateDesign.accent),
                                const SizedBox(width: 5),
                              ],
                              Expanded(
                                  child: Text(
                                      '${index + 1}  ${GateCopy.text(context, labels[index])}',
                                      style: TextStyle(
                                          color: complete || index == stage
                                              ? GateDesign.accent
                                              : GateDesign.muted,
                                          fontSize: 12))),
                            ]),
                          )),
                    )));
      });
}

class GateOrderHint extends StatelessWidget {
  const GateOrderHint({required this.status, super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final progress = GateOrderProgress.fromStatus(status);
    return Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(
                progress.complete
                    ? Icons.check_circle_outline
                    : Icons.info_outline,
                size: 18,
                color: GateDesign.muted),
            const SizedBox(width: 8),
            Expanded(
                child: Text(GateCopy.text(context, progress.hintKey),
                    style:
                        const TextStyle(color: GateDesign.muted, height: 1.5))),
          ]),
        ));
  }
}

class GateColumns extends StatelessWidget {
  const GateColumns({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 2 : 1;
        return Wrap(spacing: 12, runSpacing: 4, children: [
          for (final child in children)
            SizedBox(
                width: (constraints.maxWidth - (columns - 1) * 12) / columns,
                child: child),
        ]);
      });
}
