// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get accountTitle => '账号管理';

  @override
  String get accountGuest => '访客账号';

  @override
  String get accountNone => '尚未登录';

  @override
  String get accountSignOut => '退出所有设备';

  @override
  String get accountSignOutConfirm =>
      '这会使此账号在所有设备上的登录失效，不会删除账号或本地视频。访问云端内容可能需要重新登录。';

  @override
  String get accountGuestWarning => '此访客账号尚未验证邮箱。退出后可能无法找回其云端内容，请先验证邮箱再退出。';

  @override
  String get accountSignedOut => '已退出所有设备。';

  @override
  String get accountCancel => '取消';

  @override
  String get applicationTitle => '创作者认证';

  @override
  String get applicationRefresh => '刷新审核结果';

  @override
  String get applicationRetry => '刷新重试';

  @override
  String get applicationLoadFailed => '加载申请失败，刷新后继续';

  @override
  String get applicationNoTags => '平台暂未配置角色标签，请稍后刷新重试';

  @override
  String get applicationApproved => '已认证创作者';

  @override
  String get applicationOpenStudio => '进入创作者工作台';

  @override
  String get applicationPending => '创作者申请审核中';

  @override
  String get applicationSuspended => '创作者资格已暂停';

  @override
  String get applicationReviewNote => '审核由平台人工完成。可刷新查看审核结果。';

  @override
  String get applicationRejected => '申请未通过，请根据审核意见修改后重新提交';

  @override
  String get applicationRoles => '擅长角色';

  @override
  String get applicationDirections => '擅长内容方向';

  @override
  String get applicationName => '创作者显示名称';

  @override
  String get applicationNameHint => '例如 NovaStudio 或 Nova2026';

  @override
  String get applicationNameRule => '仅限英文和数字，至少包含一个英文字母，最多 80 个字符';

  @override
  String get applicationEmail => '邮箱（创作者唯一识别）';

  @override
  String get applicationRegion => '创作者所在地';

  @override
  String get applicationChina => '中国大陆';

  @override
  String get applicationUs => '美国';

  @override
  String get applicationEea => '欧洲经济区';

  @override
  String get applicationUk => '英国';

  @override
  String get applicationJapan => '日本';

  @override
  String get applicationHk => '中国香港';

  @override
  String get applicationMo => '中国澳门';

  @override
  String get applicationTw => '中国台湾';

  @override
  String get applicationAsia => '其他亚洲地区';

  @override
  String get applicationOther => '其他地区';

  @override
  String get applicationAdult => '我已年满 18 岁';

  @override
  String get applicationAgreement => '我同意创作者规则、保密要求和禁止私下交易条款';

  @override
  String get applicationWorks => '本人创作的视频作品';

  @override
  String get applicationWorkNote =>
      '请上传至少 1 个本人创作的 MP4 视频，最多 10 个，每个不超过 15 MB。作品仅供认证审核，不会公开发布。人工审核将综合作品数量、质量及创意评定等级。';

  @override
  String get applicationUpload => '上传本人作品';

  @override
  String get applicationUploadFailed => '上传失败，作品未添加';

  @override
  String get applicationRetryUpload => '重试上传';

  @override
  String get applicationRemoveFailed => '移除失败项';

  @override
  String get applicationSample => '认证作品';

  @override
  String get applicationPrivate => '已上传 · 私有作品';

  @override
  String get applicationPreview => '预览作品';

  @override
  String get applicationRemove => '移除作品';

  @override
  String get applicationSave => '保存草稿';

  @override
  String get applicationSubmit => '提交创作者申请';

  @override
  String get applicationPreviewTitle => '认证作品预览';

  @override
  String get applicationInvalidName => '名称仅限英文字母和数字，至少包含一个英文字母，最多 80 个字符';

  @override
  String get applicationInvalidEmail => '请填写有效邮箱后上传作品';

  @override
  String get applicationRoleRequired => '请至少选择一个擅长角色类型';

  @override
  String get applicationDirectionRequired => '请至少选择一个擅长内容方向';

  @override
  String get applicationAdultRequired => '请确认已年满 18 岁';

  @override
  String get applicationAgreementRequired => '请阅读并同意创作者规则';

  @override
  String get applicationMp4 => '请选择 MP4 视频';

  @override
  String get applicationTooLarge => '单个视频不能超过 15 MB，请压缩后重新选择';

  @override
  String get applicationLimit => '最多上传 10 个作品';

  @override
  String get applicationEmailUsed => '该邮箱已被其他创作者使用，请更换邮箱';

  @override
  String get applicationInvalidFields => '请检查英文名称、角色、方向、邮箱及协议确认';

  @override
  String get applicationProcessorBusy => '视频检查繁忙，请稍后重试';

  @override
  String get applicationLocked => '申请已锁定，请刷新查看审核状态';

  @override
  String get applicationVideoLimit => '最多上传 10 个作品，请移除作品后重试';

  @override
  String get applicationVideoInvalid => '视频检查未通过，请选择可正常播放的 MP4 视频重试';

  @override
  String get applicationVideoRequired => '请至少上传 1 个检查通过的视频作品';

  @override
  String get applicationConflict => '申请已更新，请刷新后重试';

  @override
  String get applicationPreviewFailed => '视频预览失败，请返回后重试';

  @override
  String applicationGrade(String grade) {
    return '创作等级：$grade';
  }

  @override
  String applicationUploading(String name) {
    return '正在上传并检查：$name';
  }

  @override
  String get applicationDirectionAction => '简单动作';

  @override
  String get applicationDirectionDance => '歌舞表演';

  @override
  String get applicationDirectionEffects => '特效炫技';

  @override
  String get applicationDirectionGrowth => '角色成长';

  @override
  String get applicationGradeSilver => '白银';

  @override
  String get applicationGradeGold => '黄金';

  @override
  String get applicationGradeDiamond => '钻石';

  @override
  String get applicationGradeMaster => '宗师';

  @override
  String get applicationGradeLegend => '大神';

  @override
  String get authTitle => '邮箱登录 / 找回订单';

  @override
  String get authExplanation =>
      '邮箱用于接收审核、报价和交付通知，也可在其他设备登录找回该邮箱账户的订单。\n\n登录已有邮箱会切换账户，不会合并订单。此前未绑定邮箱的旧账户订单无法自动找回，请联系平台。';

  @override
  String get authEmail => '邮箱';

  @override
  String get authSend => '发送验证码';

  @override
  String get authResend => '重新发送';

  @override
  String get authSent => '验证码已发送，10 分钟内有效。';

  @override
  String get authCode => '6 位验证码';

  @override
  String get authChange => '更换邮箱';

  @override
  String get authVerify => '验证并登录';

  @override
  String get authInvalidEmail => '请输入有效邮箱';

  @override
  String get authInvalidCode => '请输入 6 位验证码';

  @override
  String authResendSeconds(int seconds) {
    return '$seconds 秒后可重发';
  }

  @override
  String get appName => 'Hildors';

  @override
  String get languageTitle => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageFallback => '中文变体统一使用简体中文，其他暂不支持的语言使用英文。';

  @override
  String get languageSaveFailed => '语言设置保存失败，请重试。';

  @override
  String get commonRetry => '重试';

  @override
  String get commonCancel => '取消';

  @override
  String get commonClose => '关闭';

  @override
  String get commonSave => '保存';

  @override
  String get commonLoading => '正在加载…';

  @override
  String get errorNetwork => '连接失败，请检查网络后重试。';

  @override
  String get errorSession => '请重新登录后继续。';

  @override
  String get errorPermission => '当前账号无法访问此内容。';

  @override
  String get errorConflict => '内容已更新，请刷新后重试。';

  @override
  String get errorTooLarge => '文件过大，请选择较小的文件。';

  @override
  String get errorRateLimit => '请求过于频繁，请稍后重试。';

  @override
  String get errorGeneric => '操作失败，请重试。';

  @override
  String get errorEmailCode => '请检查邮箱和验证码，验证码可能已过期。';

  @override
  String get errorServiceUnavailable => '服务暂不可用，请稍后重试。';

  @override
  String fileBytes(String value) {
    return '$value B';
  }

  @override
  String fileKilobytes(String value) {
    return '$value KB';
  }

  @override
  String fileMegabytes(String value) {
    return '$value MB';
  }

  @override
  String get catalogCollection => '藏品';

  @override
  String get catalogLibrary => '内容库';

  @override
  String get catalogMyCharacters => '我的角色';

  @override
  String get catalogLoadFailed => '暂时无法加载内容库';

  @override
  String get catalogCheckNetwork => '请检查网络连接后重试。';

  @override
  String get catalogSearch => '搜索角色、视频或题材';

  @override
  String get catalogRefresh => '刷新目录';

  @override
  String get catalogSource => '出处';

  @override
  String get catalogFormat => '形式';

  @override
  String get catalogGenre => '题材';

  @override
  String get catalogAll => '全部';

  @override
  String get catalogOfficial => 'HILDORS 出品';

  @override
  String get catalogCreatorWorks => '创作者作品';

  @override
  String get catalogAnonymous => '匿名创作者';

  @override
  String get catalogSingle => '单条视频';

  @override
  String get catalogPackage => '角色视频包';

  @override
  String get catalogEmpty => '暂无符合条件的内容';

  @override
  String get catalogClear => '清除筛选';

  @override
  String get catalogResults => '筛选结果';

  @override
  String get catalogDescriptionMissing => '角色简介待补充';

  @override
  String get catalogPackVideos => '包内视频';

  @override
  String get catalogVideo => '视频';

  @override
  String get catalogNoPreview => '视频预览暂不可用';

  @override
  String get catalogDurationUnknown => '时长待确认';

  @override
  String get catalogStoryMissing => '背景故事待补充';

  @override
  String get catalogStory => '背景故事';

  @override
  String get catalogStoryCollapse => '收起背景故事';

  @override
  String get catalogStoryExpand => '展开背景故事';

  @override
  String get catalogImageLoading => '图片加载中';

  @override
  String get catalogImageRetry => '图片加载失败，点击重试';

  @override
  String get playerNoSource => '暂无可播放视频';

  @override
  String get playerBuffering => '视频正在缓冲，请稍候';

  @override
  String get playerLoading => '视频正在加载，请稍候';

  @override
  String get playerSlow => '加载较慢，请检查网络或重试';

  @override
  String get playerPause => '暂停预览';

  @override
  String get playerPlay => '播放预览';

  @override
  String get playerZoom => '双指缩放 · 双击复位';

  @override
  String get playerFailed => '视频播放失败，请重试';

  @override
  String get playerTimeout => '视频加载超时，请重试';

  @override
  String get playerLoadFailed => '视频加载失败，请重试';

  @override
  String get playerAuthFailed => '授权刷新失败，请返回投稿列表重试';

  @override
  String get downloadTitle => '下载到我的角色';

  @override
  String get downloadUnavailable => '暂未开放购买';

  @override
  String get downloadFree => '免费下载';

  @override
  String get downloadInfo => '视频按条定价，免费内容可直接下载。付费视频暂未开放购买。下载后可在“我的角色”离线查看。';

  @override
  String get downloadCancel => '取消下载';

  @override
  String get downloadAvailable => '下载可用视频';

  @override
  String get downloadDone => '已下载';

  @override
  String get downloadRefresh => '刷新下载权限';

  @override
  String get downloadView => '查看我的角色';

  @override
  String get downloadDisabled => '下载暂未开放，请稍后重试';

  @override
  String get downloadSignIn => '请重新确认账号后下载';

  @override
  String get downloadDenied => '当前视频暂不可下载，请刷新权限后重试';

  @override
  String get downloadAccessFailed => '暂时无法确认下载权限，请检查网络和账号后重试';

  @override
  String get downloadFinished => '下载完成，已加入我的角色';

  @override
  String get downloadCancelled => '下载已取消，已完成的视频保留在我的角色';

  @override
  String get downloadFailed => '下载未完成，请检查网络、存储空间和账号权限后重试';

  @override
  String catalogSummary(int count, int creators) {
    return '共 $count 项内容 · 创作者作品 $creators 项';
  }

  @override
  String catalogRefreshed(int count, int creators) {
    return '目录已刷新：共 $count 项内容，含 $creators 项创作者作品';
  }

  @override
  String catalogCount(String format, int count) {
    return '$format · $count条';
  }

  @override
  String catalogSeconds(String seconds) {
    return '$seconds 秒';
  }

  @override
  String catalogCreatorSpace(String name) {
    return '$name 的空间';
  }

  @override
  String catalogPublished(int count) {
    return '已发布作品 · $count';
  }

  @override
  String downloadProgress(int count, int total) {
    return '已下载 $count/$total';
  }

  @override
  String downloadActive(String name) {
    return '正在下载：$name';
  }

  @override
  String downloadPrice(String price) {
    return 'US\$ $price · 购买下载';
  }

  @override
  String get controlsDeleteTitle => '删除本地下载？';

  @override
  String get controlsDeleteNote => '删除此角色包的 App 本地下载文件。云端权益会保留，需要时可重新下载。';

  @override
  String get controlsCancel => '取消';

  @override
  String get controlsDelete => '删除';

  @override
  String get controlsDeleteFailed => '删除失败，请重试';

  @override
  String get controlsDeleteLocal => '删除本地下载';

  @override
  String get controlsNoVideos => '此角色暂未提供可用视频，待内容包交付后选择。';

  @override
  String get controlsPreviewLocal => '预览本地视频';

  @override
  String get controlsExamples => '官方示例角色包 · 选择包内视频';

  @override
  String get controlsChooseList => '加入哪个播放列表？';

  @override
  String get controlsPendingNote => '先加入待处理区，不代表已上传到设备';

  @override
  String get controlsStartup => '日常展示';

  @override
  String get controlsBluetooth => '音乐联动';

  @override
  String get controlsAddFailed => '未能加入列表，请重试';

  @override
  String get controlsMyCharacters => '我的角色';

  @override
  String get controlsLoadFailed => '我的角色读取失败，点击重试';

  @override
  String get controlsEmpty => '还没有可选择的角色';

  @override
  String get controlsEmptyNote => '先到藏品内容库收藏角色，再选择其中的视频。';

  @override
  String get controlsLibrary => '内容库';

  @override
  String get controlsBrowse => '浏览内容库';

  @override
  String get controlsPickNote => '选择角色，再勾选需要加入当前列表的视频';

  @override
  String get controlsListNote => '选择角色中的视频，加入日常展示或音乐联动';

  @override
  String get controlsUnavailable => '暂无可用视频';

  @override
  String get controlsSelect => '选择视频';

  @override
  String get controlsAdd => '加入播放列表';

  @override
  String get controlsControlTitle => '全息座舱控制台';

  @override
  String get controlsBrightness => '亮度';

  @override
  String get controlsAngle => '角度（待厂家确认单位与范围）';

  @override
  String get controlsSpeakerTitle => '设置蓝牙音箱名称';

  @override
  String get controlsSpeakerName => '音箱名称';

  @override
  String get controlsSave => '保存';

  @override
  String get controlsSpeaker => '蓝牙音箱';

  @override
  String get controlsConnectSpeaker => '连接设备后读取音箱名称';

  @override
  String get controlsReading => '正在读取…';

  @override
  String get controlsNameUnknown => '名称尚未读取';

  @override
  String get controlsRefreshName => '刷新名称';

  @override
  String get controlsEditName => '修改名称';

  @override
  String get controlsDisconnected => '未连接';

  @override
  String get controlsConnecting => '连接中…';

  @override
  String get controlsReconnecting => '正在重连…';

  @override
  String get controlsConnected => '已连接';

  @override
  String get controlsIp => '设备 IP';

  @override
  String get controlsPort => '默认端口 8900';

  @override
  String get controlsStopReconnect => '停止重连';

  @override
  String get controlsDisconnect => '断开';

  @override
  String get controlsConnect => '连接';

  @override
  String get controlsQuick => '快捷控制';

  @override
  String get controlsPowerOn => '开机';

  @override
  String get controlsPowerOff => '关机';

  @override
  String get controlsPrevious => '上一个';

  @override
  String get controlsPause => '暂停';

  @override
  String get controlsPlay => '播放';

  @override
  String get controlsNext => '下一个';

  @override
  String get controlsRefreshStatus => '刷新状态';

  @override
  String get controlsStatus => '设备状态';

  @override
  String get controlsLan => '局域网控制';

  @override
  String get controlsMode => '工作模式';

  @override
  String get controlsAudioSource => '蓝牙音源';

  @override
  String get controlsProtocol => '等待新版协议';

  @override
  String get controlsLocalPlayback => '本机播放';

  @override
  String get controlsBluetoothWaiting => '蓝牙等待连接';

  @override
  String get controlsBluetoothAudio => '蓝牙音响';

  @override
  String get controlsWaitingSource => '等待音源连接';

  @override
  String get controlsAudioPlaying => '音频播放中';

  @override
  String get controlsAudioPaused => '音频已暂停';

  @override
  String get controlsWasDisconnected => '已断开';

  @override
  String get controlsBatteryFull => '已充满';

  @override
  String get controlsBattery => '设备电量';

  @override
  String get controlsProtocolNote =>
      '当前协议尚未提供工作模式和蓝牙状态。新版协议接入后，这里将实时显示“本机播放”或“蓝牙音响”。';

  @override
  String controlsPackageCount(int count) {
    return '角色视频包 · $count 个视频';
  }

  @override
  String controlsDownloaded(int count, int total) {
    return '已下载 $count/$total 个视频';
  }

  @override
  String controlsSeconds(int seconds) {
    return '$seconds 秒';
  }

  @override
  String controlsAddCount(int count) {
    return '添加 $count 个视频到待处理区';
  }

  @override
  String controlsVideoCount(int count) {
    return '$count 个视频';
  }

  @override
  String controlsAdded(String list) {
    return '已加入$list待处理区，尚未上传设备';
  }

  @override
  String controlsNamedPlaying(String name) {
    return '$name · 播放中';
  }

  @override
  String controlsNamedPaused(String name) {
    return '$name · 已暂停';
  }

  @override
  String controlsCharging(int percent) {
    return '$percent% · 充电中';
  }

  @override
  String get coreHome => '首页';

  @override
  String get coreCollection => '藏品';

  @override
  String get coreExplore => '发现';

  @override
  String get coreProfile => '我的';

  @override
  String get coreDeviceControl => '设备控制';

  @override
  String get coreCustomCharacter => '定制你的专属全息角色';

  @override
  String get corePlaylists => '设备播放列表';

  @override
  String get corePlaylistSubtitle => '日常展示与音乐联动';

  @override
  String get coreDisplay => '日常展示';

  @override
  String get coreStartupSubtitle => '管理开机后自动播放的内容';

  @override
  String get coreMusic => '音乐联动';

  @override
  String get coreBluetoothSubtitle => '管理连接蓝牙后播放的内容';

  @override
  String get coreOnline => '在线';

  @override
  String get coreDisconnected => '未连接';

  @override
  String get coreDeviceConnected => '设备已连接';

  @override
  String get coreConnecting => '正在连接…';

  @override
  String get coreReconnecting => '正在重连…';

  @override
  String get coreDeviceDisconnected => '设备未连接';

  @override
  String get coreLanControl => '局域网控制 · P20 / P11';

  @override
  String get coreConnectP20 => '连接 P20';

  @override
  String get coreConnectionSettings => '连接设置';

  @override
  String get coreDeviceManagement => '座舱管理';

  @override
  String get coreDevices => '设备';

  @override
  String get corePlaylist => '播放列表';

  @override
  String get coreDeviceContent => '设备内容';

  @override
  String get coreCharacterAssets => '角色资产';

  @override
  String get coreCustomOrders => '定制订单';

  @override
  String get coreOrdersSubtitle => '跟踪制作与交付；已领取角色请到藏品查看';

  @override
  String get coreCreatorCenter => '创作者中心';

  @override
  String get coreCreatorSubtitle => '入驻申请、任务制作与收益管理';

  @override
  String get coreSupport => '系统支持';

  @override
  String get corePlaybackGuide => '播放模式说明';

  @override
  String get corePlaybackGuideSubtitle => '了解日常展示与音乐联动的切换逻辑';

  @override
  String get coreLanHelp => '局域网连接帮助';

  @override
  String get coreLanHelpSubtitle => '连接 P20/P11 热点及常见问题排查';

  @override
  String get coreAppSettings => '设备与 App 设置';

  @override
  String get coreAppSettingsSubtitle => '设备参数、播放偏好与版本信息';

  @override
  String get coreAbout => '关于 HILDORS';

  @override
  String get coreAboutSubtitle => 'Character Portal · P20/P11 兼容架构';

  @override
  String get corePlayerProfile => '玩家档案';

  @override
  String get coreLocalAccount => '本地座舱账户 · 数据保存在当前设备';

  @override
  String get coreDeviceSettings => '设备设置';

  @override
  String get coreReadFailed => '读取失败，请确认手机已连接设备 Wi-Fi 后重试。';

  @override
  String get coreSettingFailed => '设置未生效，请检查设备连接后重试。';

  @override
  String get corePlaybackBehavior => '播放行为';

  @override
  String get coreLoopMode => '循环模式';

  @override
  String get coreLoopSubtitle => '选择设备当前播放列表的循环方式';

  @override
  String get coreConnectToChange => '连接设备后可读取并修改';

  @override
  String get coreDeviceInfo => '设备信息';

  @override
  String get coreLanCockpit => '局域网全息座舱';

  @override
  String get coreNotRead => '待读取';

  @override
  String get coreReadInfo => '读取设备信息';

  @override
  String get coreHelp => '帮助与说明';

  @override
  String get coreModesHelpSubtitle => '日常展示与音乐联动的自动切换逻辑';

  @override
  String get coreHotspotHelp => '设备热点连接与常见故障排查';

  @override
  String get coreDeviceConnecting => '正在连接设备';

  @override
  String get coreDeviceReconnecting => '正在恢复连接';

  @override
  String get coreCockpitOnline => '座舱在线';

  @override
  String get coreGoHomeConnect => '请先返回首页连接 P20 / P11';

  @override
  String get coreOpeningLan => '正在建立局域网控制通道';

  @override
  String get coreRetryingLan => '连接中断，正在自动重试';

  @override
  String get coreLanReady => '局域网控制通道已建立';

  @override
  String get coreSync => '同步设备状态';

  @override
  String get coreSingleLoop => '单曲循环';

  @override
  String get coreSequenceLoop => '顺序循环';

  @override
  String get coreRandomLoop => '随机循环';

  @override
  String get coreSingleOnce => '单曲一次';

  @override
  String get coreCheckWifi => '检查手机 Wi-Fi';

  @override
  String get coreCheckWifiBody => '确认手机已连接 P20 热点，或与 P20 连接到同一个路由器。';

  @override
  String get coreCheckAddress => '确认控制地址';

  @override
  String get coreCheckAddressBody => '设备热点模式默认使用 192.168.4.1，TCP 端口为 8900。';

  @override
  String get coreLanPermission => '允许局域网权限';

  @override
  String get coreLanPermissionBody => 'iOS 需要开启局域网权限；Android 需要允许附近设备和网络相关权限。';

  @override
  String get coreReconnect => '重新连接';

  @override
  String get coreReconnectBody => '返回控制页点击连接。异常断开后 App 会按 1、2、4、8、15、30 秒自动重试。';

  @override
  String get coreOfflineWifiHelp =>
      '手机显示“无互联网连接”并不代表控制失败。只要手机仍保持在 P20 局域网中，App 就可以继续控制设备。';

  @override
  String get coreLocalPlayback => '本机播放';

  @override
  String get coreLocalPlaybackBody =>
      'P20 播放设备内部视频，声音来自视频文件。适合开机自动播放、循环展示和固定内容播放。';

  @override
  String get coreBluetoothSpeaker => '蓝牙音响';

  @override
  String get coreBluetoothSpeakerBody =>
      '手机、电脑等外接设备通过蓝牙向 P20 输入声音，P20 同时播放为蓝牙状态配置的全息视频。';

  @override
  String get coreSeparateConnections =>
      '注意：Hildors App 始终通过 Wi-Fi 局域网控制 P20。“局域网控制已连接”和“蓝牙音源已连接”是两个独立状态。';

  @override
  String get coreCharacterPortal => '角色之门';

  @override
  String get coreExploreSubtitle => '定制专属角色，提交心愿，参与创作。';

  @override
  String get coreWishSubtitle => '提交心愿，关注授权进展';

  @override
  String get coreCreatorExploreSubtitle => '入驻、任务与收益';

  @override
  String get coreWish => '角色许愿';

  @override
  String get coreCustomize => '定制你的专属角色';

  @override
  String get coreEnter => '进入';

  @override
  String get coreCreatorFreeSubtitle => '申请创作者认证，发布免费内容';

  @override
  String get coreExploreFreeSubtitle => '发现创作机会，分享免费内容。';

  @override
  String get coreConnectionFailed => '无法连接设备。请检查设备 Wi-Fi 和连接设置后重试。';

  @override
  String get coreSystemLabel => '座舱系统';

  @override
  String get coreProfileLabel => '玩家档案';

  @override
  String get coreLocalLabel => '本地';

  @override
  String get corePilotLabel => 'HILDORS 玩家';

  @override
  String get coreServiceLabel => '核心服务';

  @override
  String get coreCreatorLabel => '创作者';

  @override
  String get coreOnlineLabel => '在线';

  @override
  String get coreConnectingLabel => '连接中';

  @override
  String get coreReconnectingLabel => '重连中';

  @override
  String get coreOfflineLabel => '离线';

  @override
  String get creatorWorkbench => '创作者工作台';

  @override
  String get creatorOriginal => '原创内容';

  @override
  String get creatorFreeNote => '上传独立视频或角色包，提交平台审核后发布。本版本仅支持免费投稿，审核通过后公开。';

  @override
  String get creatorPublishingNote =>
      '上传独立视频或角色包，提交平台审核后发布。标准创作者、认证创作者仅可发布免费内容；签约伙伴可选择付费。';

  @override
  String get creatorSubmissions => '上传内容 / 我的投稿';

  @override
  String get creatorTasks => '定制任务';

  @override
  String get creatorTasksNote => '查看可接任务和正在进行的定制订单';

  @override
  String get customPlansTitle => '定制视频套餐';

  @override
  String get customOrdersTitle => '我的定制订单';

  @override
  String get customUnavailable => '商店支付尚未接通，目前不会收款。';

  @override
  String customBase(String price) {
    return '美元基准参考价：$price；购买时以商店价格为准。';
  }

  @override
  String customSeconds(int seconds) {
    return '$seconds 秒视频';
  }

  @override
  String get customRequest => '提交需求审核';

  @override
  String get customName => '角色／项目名称';

  @override
  String get customRequirements => '定制需求';

  @override
  String get customMaterials => '添加参考图片';

  @override
  String customMaterialCount(int count) {
    return '$count 张参考图片';
  }

  @override
  String get customPrivacy => '参考素材用于评估及制作此私人订单；公开展示需另行获得同意。';

  @override
  String get customConsent => '我同意将这些素材用于此订单。';

  @override
  String get customValidation => '请填写项目名称及需求，并确认素材使用说明。';

  @override
  String get customImageError => '最多选择 8 张 JPG／PNG 图片，每张不超过 8 MB。';

  @override
  String get customSubmitted => '需求已提交审核，尚未付款。';

  @override
  String get customTerms => '付款前核对确认内容';

  @override
  String get customContent => '交付内容';

  @override
  String get customPeriod => '交付周期';

  @override
  String get customRevisions => '修改范围';

  @override
  String get customRights => '使用权限';

  @override
  String get customAcceptTerms => '我接受本次确认的交付范围与条款。';

  @override
  String customPay(String price) {
    return '支付 $price';
  }

  @override
  String get customRestore => '检查未完成的购买';

  @override
  String get customTestMode => '测试支付模式——不产生真实扣款';

  @override
  String get customAccept => '确认交付';

  @override
  String get customRevise => '申请修改';

  @override
  String get customRevisionNote => '请说明需要修改的内容';

  @override
  String get customStatusReview => '需求审核中';

  @override
  String get customStatusInfo => '待补充信息';

  @override
  String get customStatusQuote => '范围已确认，等待付款';

  @override
  String get customStatusMaking => '制作中';

  @override
  String get customStatusQc => '质量审核中';

  @override
  String get customStatusAccept => '等待验收';

  @override
  String get customStatusDelivered => '已交付';

  @override
  String get customStatusRejected => '需求未通过';

  @override
  String get customStatusWithdrawn => '已撤回／退款';

  @override
  String get customPending => '付款待处理；服务端验证成功后才开始制作。';

  @override
  String get customEmpty => '暂无可用内容。';

  @override
  String get customAudioNone => '无音频 · 基础套餐';

  @override
  String get customAudioMatched => '平台搭配音频';

  @override
  String get customAudioHelp => '平台根据视频内容搭配背景音乐或简单音效，不支持指定歌曲、配音或上传音频。';

  @override
  String customAudioTotal(String price) {
    return '美元参考总价：$price';
  }

  @override
  String customAudioRate(int percent) {
    return '音频搭配加价：$percent%';
  }

  @override
  String get customSupplement => '补充需求并重新提交';

  @override
  String get customSupplementSaved => '已重新提交需求，等待审核。';

  @override
  String get customSaveDelivery => '保存成品到我的角色';

  @override
  String get customSavedDelivery => '已保存到我的角色，可离线查看。';

  @override
  String get customSavingDelivery => '正在下载私密成品…';

  @override
  String get customConfirmDelivery => '确认将此版本作为最终交付？';

  @override
  String customRevisionLimit(int used, int limit) {
    return '已申请修改 $used 次，可用总次数 $limit 次';
  }

  @override
  String get customProgress => '制作进展';

  @override
  String get deletionTitle => '删除账号';

  @override
  String get deletionExplanation =>
      '申请删除 Hildors 账号及关联数据。提交后进入审核，不会立即删除数据或退出登录。你可以在此查看处理进度或取消待处理申请。';

  @override
  String get deletionSubmit => '提交账号删除申请';

  @override
  String get deletionConfirm => '确认提交删除申请？审核期间账号仍可使用。';

  @override
  String get deletionNone => '暂无删除申请。';

  @override
  String get deletionReceived => '已收到申请';

  @override
  String get deletionReview => '审核中';

  @override
  String get deletionInformation => '待补充信息';

  @override
  String get deletionCancelled => '申请已取消';

  @override
  String get deletionCancel => '取消删除申请';

  @override
  String get deletionRefresh => '刷新进度';

  @override
  String deletionReference(String id) {
    return '申请编号：$id';
  }

  @override
  String get devicePlayingDelete => '正在播放的视频不能删除，请先播放其他内容';

  @override
  String get deviceDeleteTitle => '永久删除设备文件？';

  @override
  String get deviceDeleteIntro => '以下视频将从全息设备中永久删除：';

  @override
  String get deviceDeleteNote => '此操作无法撤销。手机中已下载的副本和内容购买记录不会受到影响。';

  @override
  String get deviceCancel => '取消';

  @override
  String get deviceDelete => '永久删除';

  @override
  String get deviceVideoLibrary => '视频库';

  @override
  String get deviceRefresh => '刷新';

  @override
  String get deviceConnectFirst => '请先在“控制”页连接设备';

  @override
  String get deviceReadVideos => '读取视频列表';

  @override
  String get devicePlaying => '正在播放';

  @override
  String get devicePlay => '播放';

  @override
  String get deviceMore => '更多操作';

  @override
  String get deviceDeleteFrom => '从设备永久删除';

  @override
  String get frameSaved => '取景已保存。原视频未修改，尚未转码或上传。';

  @override
  String get frameSaveFailed => '保存失败，请重试';

  @override
  String get frameTitle => '调整风扇展示范围';

  @override
  String get frameCircle => '圆圈内为设备显示范围';

  @override
  String get frameInstructions => '双指缩放、单指拖动。播放整段视频，检查头部、手脚和动作是否超出圆圈。';

  @override
  String get framePause => '暂停预览';

  @override
  String get framePlay => '播放预览';

  @override
  String get framePlaybackFailed => '播放失败，请返回后重试';

  @override
  String get frameZoom => '缩放';

  @override
  String get frameFit => '完整展示';

  @override
  String get frameFill => '铺满圆形';

  @override
  String get frameReset => '重置';

  @override
  String get frameFitNote => '完整展示保留整帧画面；铺满圆形会裁掉边缘内容。';

  @override
  String get frameRestoreFailed => '上次取景未能读取，请重新调整后保存。';

  @override
  String get frameSaving => '保存中…';

  @override
  String get frameSave => '保存展示范围';

  @override
  String get frameUnavailable => '转码并上传 · 暂未开放';

  @override
  String get framePending => '当前仅保存展示范围。设备转码接入后，可按此取景生成设备视频。';

  @override
  String get framePreviewFailed => '视频预览加载失败，请返回后重试。';

  @override
  String deviceDeleted(String name) {
    return '已从设备永久删除 $name';
  }

  @override
  String frameTime(int position, int duration) {
    return '$position / $duration 秒';
  }

  @override
  String get governanceReport => '举报内容';

  @override
  String get governanceBlock => '屏蔽创作者';

  @override
  String get governanceCopyright => '侵犯版权';

  @override
  String get governanceAbuse => '骚扰或辱骂';

  @override
  String get governanceSexual => '色情内容';

  @override
  String get governanceViolence => '暴力内容';

  @override
  String get governanceSpam => '垃圾内容';

  @override
  String get governanceOther => '其他';

  @override
  String get governanceDetails => '补充说明（可选）';

  @override
  String get governanceReportNote => '举报将发送至审核团队。版权投诉请描述原作品及其所在位置，请勿填写敏感个人信息。';

  @override
  String get governanceCancel => '取消';

  @override
  String get governanceSubmit => '提交举报';

  @override
  String governanceReceived(String reference) {
    return '举报已收到，编号：$reference';
  }

  @override
  String get governanceBlockNote => '将在当前账号的内容库中隐藏此创作者的作品。您可以在“举报与屏蔽”中解除屏蔽。';

  @override
  String get governanceBlocked => '已屏蔽创作者。';

  @override
  String get governanceAuthError => '登录已失效，请重新登录。';

  @override
  String get governanceUnavailableError => '此内容已不可用。';

  @override
  String get governanceInvalidError => '请检查举报内容后重试。';

  @override
  String get governanceConflictError => '此操作暂不可用，请刷新后重试。';

  @override
  String get governanceNetworkError => '连接失败，请重试。';

  @override
  String get governanceTitle => '举报与屏蔽';

  @override
  String get governanceRefresh => '刷新';

  @override
  String get governanceReports => '我的举报';

  @override
  String get governanceBlocks => '已屏蔽创作者';

  @override
  String get governanceEmpty => '暂无记录。';

  @override
  String get governanceUnblock => '解除屏蔽';

  @override
  String get governanceStatusReceived => '已收到';

  @override
  String get governanceStatusReview => '审核中';

  @override
  String get governanceStatusAction => '已采取措施';

  @override
  String get governanceStatusNoViolation => '未发现违规';

  @override
  String get playlistFromCharacters => '从我的角色选择';

  @override
  String get playlistChooseCharacter => '选择已收藏角色中的视频';

  @override
  String get playlistFromPhone => '从手机导入视频';

  @override
  String get playlistFromDevice => '从设备已有视频添加';

  @override
  String get playlistPickFailed => '视频选择失败，请重试';

  @override
  String get playlistPendingSaveFailed => '待处理列表保存失败，退出后可能丢失，请重试';

  @override
  String get playlistRetry => '重试';

  @override
  String get playlistReselectTitle => '需要重新选择源视频';

  @override
  String get playlistReselectNote => '原文件已移动或系统缓存已清理。列表记录仍保留，请选择对应视频并重新确认取景。';

  @override
  String get playlistCancel => '取消';

  @override
  String get playlistReselect => '重新选择';

  @override
  String get playlistReadFailed => '无法读取视频，请稍后重试';

  @override
  String get playlistOriginalTitle => '需要原始视频';

  @override
  String get playlistOriginalNote =>
      '设备中的文件只有文件名，无法直接恢复原始画面。请从手机选择对应的原始视频，再调整画面。保存只记录取景参数；转码上传会新增设备文件，保留原有文件。';

  @override
  String get playlistChooseOriginal => '选择原始视频';

  @override
  String get playlistOriginalFailed => '无法读取原始视频，请稍后重试';

  @override
  String get playlistRemovePending => '移除待处理视频？';

  @override
  String get playlistRemovePendingNote => '只移除本列表记录，不删除手机源文件或设备视频。';

  @override
  String get playlistRemove => '移除';

  @override
  String get playlistReadLocalFailed => '本机列表读取失败，请重试';

  @override
  String get playlistSaveLocalFailed => '本机列表保存失败，请重试';

  @override
  String get playlistAddDevice => '从设备视频库添加';

  @override
  String get playlistAllAdded => '设备视频均已加入当前草案';

  @override
  String get playlistConnectFirst => '请先连接设备后再播放';

  @override
  String get playlistNotUploaded => '设备中没有此视频，请完成转码和上传后再播放';

  @override
  String get playlistRemoveTitle => '移出播放列表？';

  @override
  String get playlistRemoveList => '移出列表';

  @override
  String get playlistUndo => '撤销';

  @override
  String get playlistTitle => '设备播放列表';

  @override
  String get playlistReadDevice => '读取设备视频';

  @override
  String get playlistStartup => '开机播放';

  @override
  String get playlistBluetooth => '蓝牙播放';

  @override
  String get playlistStartupNote => '设备开机后自动播放此列表';

  @override
  String get playlistBluetoothNote => '连接蓝牙后，硬件自动切换到此列表';

  @override
  String get playlistLoop => '循环方式';

  @override
  String get playlistListLoop => '列表循环';

  @override
  String get playlistSingleLoop => '单曲循环';

  @override
  String get playlistOnce => '播放一次';

  @override
  String get playlistOrder => '播放顺序';

  @override
  String get playlistAddVideo => '添加视频';

  @override
  String get playlistPendingLoadFailed => '待处理列表读取失败，点击重试';

  @override
  String get playlistPending => '待处理视频 · 尚未上传设备';

  @override
  String get playlistPendingNote => '保留待处理记录，不复制源视频。完成取景后等待转码接入；请勿移动或删除源文件。';

  @override
  String get playlistConvertPending => '待转码 · 尚未上传设备';

  @override
  String get playlistFrame => '调整画面';

  @override
  String get playlistRemovePendingAction => '移除待处理视频';

  @override
  String get playlistEmpty => '当前播放列表为空';

  @override
  String get playlistFirst => '默认首条';

  @override
  String get playlistUp => '上移';

  @override
  String get playlistDown => '下移';

  @override
  String get playlistRemoveDraft => '移出草案';

  @override
  String get playlistSaveDevice => '保存到设备 · 等待新版协议';

  @override
  String get playlistRecovery => '蓝牙断开后的恢复策略';

  @override
  String get playlistRecoveryNote => '建议恢复连接前播放的普通视频；等待协议确认';

  @override
  String get playlistDisconnected => '设备未连接';

  @override
  String get playlistReadDeviceFailed => '设备网络已连接 · 读取失败';

  @override
  String get playlistReadDeviceReady => '设备网络已连接 · 点击读取';

  @override
  String get playlistReadNote => '读取设备内容后即可确认控制通道';

  @override
  String get playlistConnectNote => '连接设备 Wi-Fi 后再读取播放列表';

  @override
  String get playlistRead => '读取';

  @override
  String playlistSourceTitle(String name) {
    return '$name · 原始视频取景';
  }

  @override
  String playlistSent(String name) {
    return '已发送到设备播放：$name';
  }

  @override
  String playlistRemoveNote(String name) {
    return '“$name”只会从当前播放列表移除，不会删除手机或设备中的视频文件。';
  }

  @override
  String playlistRemoved(String name) {
    return '已将 $name 移出播放列表';
  }

  @override
  String playlistCount(int count) {
    return '$count 个视频';
  }

  @override
  String playlistDeviceCount(int count) {
    return '设备响应正常 · $count 个视频';
  }

  @override
  String get submissionDraftSaved => '已保存草稿，可继续上传视频并送审。';

  @override
  String get submissionTitle => '原创内容投稿';

  @override
  String get submissionRefresh => '刷新投稿';

  @override
  String get submissionCreate => '创建投稿';

  @override
  String get submissionEmpty => '还没有投稿。创建草稿后上传视频，检查通过即可送审。';

  @override
  String get submissionUpdated => '投稿信息已更新';

  @override
  String get submissionFree => '免费';

  @override
  String get submissionPaid => '付费';

  @override
  String get submissionPrice => '价格（USD）';

  @override
  String get submissionDecimals => '最多两位小数';

  @override
  String get submissionInvalidPrice => '请输入大于 0、最多两位小数的美元价格';

  @override
  String get submissionReviewNote => '所有视频均需平台审核后发布。';

  @override
  String get submissionCancel => '取消';

  @override
  String get submissionSavePrice => '保存价格';

  @override
  String get submissionSubmitted => '已提交平台审核，审核期间不可修改。';

  @override
  String get submissionPartnerNote => '签约伙伴可发布免费或付费视频；所有内容均需平台审核。';

  @override
  String get submissionFreeNote => '标准创作者、认证创作者仅可投稿免费独立视频或角色包；所有内容均需平台审核。';

  @override
  String get submissionCharacterPackage => '角色视频包';

  @override
  String get submissionSingleVideo => '独立视频';

  @override
  String get submissionRejectedReason => '退回原因';

  @override
  String get submissionReviewFeedback => '审核说明';

  @override
  String get submissionName => '标题';

  @override
  String get submissionNameRequired => '请填写标题';

  @override
  String get submissionFormat => '内容形式';

  @override
  String get submissionSingle => '单个视频';

  @override
  String get submissionPackage => '视频包';

  @override
  String get submissionTags => '内容标签';

  @override
  String get submissionNoTags => '平台暂未开放内容标签';

  @override
  String get submissionStory => '背景故事';

  @override
  String get submissionStoryRequired => '请填写背景故事';

  @override
  String get submissionVideos => '视频清单';

  @override
  String get submissionAddVideo => '添加视频';

  @override
  String get submissionRemoveVideo => '移除视频';

  @override
  String get submissionVideoNameRequired => '请填写视频标题';

  @override
  String get submissionSaveDraft => '保存草稿';

  @override
  String get submissionSaveInfo => '保存信息';

  @override
  String get submissionCoverUploaded => '封面已上传';

  @override
  String get submissionCover => '内容包封面';

  @override
  String get submissionCoverTypes => '支持 JPG 或 PNG';

  @override
  String get submissionReplace => '替换';

  @override
  String get submissionUpload => '上传';

  @override
  String get submissionSetPrice => '设置价格';

  @override
  String get submissionMakeFree => '改为免费';

  @override
  String get submissionReplaceMp4 => '替换 MP4';

  @override
  String get submissionUploadMp4 => '上传 MP4';

  @override
  String get submissionCheckVideo => '检查视频';

  @override
  String get submissionResubmit => '重新提交审核';

  @override
  String get submissionSubmit => '提交审核';

  @override
  String get submissionRequirements => '提交前需完成全部视频检查；视频包还需上传封面。';

  @override
  String get submissionInfo => '作品信息';

  @override
  String get submissionNoStory => '暂无背景介绍';

  @override
  String get submissionRetry => '重试';

  @override
  String get submissionPending => '审核中';

  @override
  String get submissionPublished => '已发布';

  @override
  String get submissionApproved => '审核通过，等待平台发布';

  @override
  String get submissionRejected => '退回修改';

  @override
  String get submissionDraft => '草稿';

  @override
  String get submissionNoMedia => '尚未上传视频';

  @override
  String get submissionChecked => '视频检查通过';

  @override
  String get submissionProcessing => '视频检查中';

  @override
  String get submissionFailed => '视频检查未通过，请替换后重试';

  @override
  String get submissionWaiting => '已上传，等待检查';

  @override
  String get submissionApprovalError => '创作者资格尚未通过或已暂停，请返回认证页查看';

  @override
  String get submissionDataError => '服务返回了无法识别的投稿数据';

  @override
  String get submissionLoadError => '投稿数据暂时无法加载，请稍后重试';

  @override
  String get submissionSessionError => '登录已失效，请重新认证创作者身份';

  @override
  String get submissionAccessError => '仅已认证且未停用的创作者可以投稿';

  @override
  String get submissionPaidError => '仅签约伙伴可设置付费视频，请改为免费后送审';

  @override
  String get submissionPriceError => '价格无效，请输入最多两位小数的美元金额';

  @override
  String get submissionConflictError => '投稿状态已经变化，请刷新后重试';

  @override
  String get submissionMediaError => '请先上传并检查全部视频';

  @override
  String get submissionCoverError => '内容包需要先上传封面';

  @override
  String get submissionTagError => '所选标签已失效，请刷新后重新选择';

  @override
  String get submissionServerError => '服务暂时不可用，请稍后重试';

  @override
  String get submissionRequestError => '操作未完成，请检查内容后重试';

  @override
  String get submissionAccountChanged => '账号已切换，请刷新投稿';

  @override
  String get submissionPreviewError => '视频尚未上传或预览服务不可用';

  @override
  String submissionVideoPrice(String name) {
    return '视频价格 · $name';
  }

  @override
  String submissionVideoName(int index) {
    return '视频 $index 标题';
  }

  @override
  String submissionLegacyTag(String name) {
    return '$name（旧标签）';
  }

  @override
  String get p20Refresh => '刷新设备列表';

  @override
  String get p20Daily => 'A 日常播放';

  @override
  String get p20Bluetooth => 'B 蓝牙播放';

  @override
  String get p20ConnectNote => '连接设备后显示机器内的播放列表';

  @override
  String get p20ConnectWifi => '手机先连接产品 Wi-Fi，再点击连接设备。';

  @override
  String get p20Connecting => '连接中…';

  @override
  String get p20Connect => '连接设备';

  @override
  String get p20Reading => '正在读取设备列表…';

  @override
  String get p20ReadFailed => '设备列表读取失败';

  @override
  String get p20Mode => '设备播放方式（A/B 共用）';

  @override
  String get p20OrderNote => '播放顺序来自设备。上移或下移后立即下发，并重新读取确认。';

  @override
  String get p20Empty => '设备当前列表为空';

  @override
  String get p20Pending => '手机待上传视频';

  @override
  String get p20PendingNote => '以下是手机待上传记录，不代表设备中已有内容。';

  @override
  String get p20Unconfirmed => '设备未确认操作，已重新读取实际状态，请检查后重试。';

  @override
  String get p20UploadEntry => '请从设备播放列表进入上传';

  @override
  String get p20UploadAction => '转码并上传';

  @override
  String get p20FramingNote => '保存只记录展示范围；点击转码并上传后，才会处理并传输设备文件。';

  @override
  String p20ConnectedCount(int count) {
    return '设备已连接 · $count 个视频';
  }

  @override
  String get p20UploadTitle => '上传到设备';

  @override
  String get p20UploadStart => '开始处理并上传';

  @override
  String get p20UploadCancel => '取消上传';

  @override
  String get p20UploadClose => '返回列表';

  @override
  String get p20UploadDisconnected => '请先返回首页连接设备 Wi-Fi，再进行上传。';

  @override
  String get p20UploadDaily =>
      'A 日常列表：支持有声和无声视频。有音轨时先提取 MP3，转码后先上传音频再上传视频；无音轨时仅转码并上传视频。';

  @override
  String get p20UploadBluetooth => 'B 蓝牙列表：支持有声和无声视频，均只转码并上传视频，不读取原视频音频。';

  @override
  String get p20UploadSettings => '298 × 298 · 20 帧/秒 · 使用当前取景范围';

  @override
  String get p20UploadDownloadFirst => '请先将视频下载到“我的角色”，再上传到设备。';

  @override
  String get p20UploadFailed => '处理或上传失败。请检查视频、设备连接和存储空间后重试。';

  @override
  String get p20UploadConfirmedProgress => '设备已确认接收进度';

  @override
  String get p20UploadFailureStageLabel => '失败阶段';

  @override
  String get p20UploadConfirmedLabel => '已确认';

  @override
  String get p20UploadBytesLabel => '字节';

  @override
  String get p20UploadBusy => '设备忙，请稍后重试。';

  @override
  String get p20UploadWriteFailed => '设备写入失败，请检查存储卡。';

  @override
  String get p20UploadAlreadyExists => '设备中已存在同名文件。';

  @override
  String get p20UploadStorageFull => '设备存储或列表已满。';

  @override
  String get p20UploadBatteryLow => '设备电量过低，请充电后重试。';

  @override
  String get p20UploadRejected => '设备拒绝接收文件。';

  @override
  String get p20UploadConfirmationTimeout => '等待设备确认超时。请记录下方阶段和进度，重新连接后再试。';

  @override
  String get p20UploadProcessingTimeout => '处理等待超时，请尝试较短的视频。';

  @override
  String get p20UploadConnectionLost => '设备连接已断开，请重新连接后重试。';

  @override
  String get p20UploadLocalFileError => '无法读取或写入本机文件，请检查源文件和手机可用空间。';

  @override
  String get p20UploadInvalidReply => '设备上传应答格式或进度序号不匹配，请核对设备固件协议。';

  @override
  String get p20UploadPartial => '音频已上传，视频未完成。本次不会自动重试或删除设备文件。';

  @override
  String get p20UploadRefreshFailed => '设备已确认文件上传成功，但列表读取失败。请重新连接后刷新列表，不要重复上传。';

  @override
  String get p20UploadCleanupPending => '临时文件仍被转码任务占用，将保留以避免中断写入。';

  @override
  String get p20UploadWaitingAcceptance => '等待设备允许接收';

  @override
  String get p20UploadTransferring => '文件传输';

  @override
  String get p20UploadWaitingCompletion => '等待设备完成确认';

  @override
  String get p20UploadConfirmedCompletion => '设备已确认完成';

  @override
  String get p20UploadReady => '准备就绪';

  @override
  String get p20UploadExtractingAudio => '正在检查并提取音频（如有）';

  @override
  String get p20UploadConvertingVideo => '正在转码视频';

  @override
  String get p20UploadUploadingAudio => '正在上传音频';

  @override
  String get p20UploadUploadingVideo => '正在上传视频';

  @override
  String get p20UploadRefreshing => '正在刷新设备列表';

  @override
  String get p20UploadComplete => '上传完成';

  @override
  String get p20UploadIncomplete => '上传未完成';

  @override
  String get p20UploadCancelled => '已取消';

  @override
  String get p20SingleOnce => '单次播放';

  @override
  String p20UploadFailureStage(String stage) {
    return '失败阶段：$stage';
  }

  @override
  String p20UploadTransferDetails(String phase, int acknowledged, int total) {
    return '$phase · 已确认 $acknowledged / $total 字节';
  }

  @override
  String get creatorMediaOpenFailed => '无法打开视频，请刷新投稿后重试';

  @override
  String creatorMediaPreviewLabel(String title) {
    return '预览视频：$title';
  }

  @override
  String get creatorMediaThumbnailPending => '缩略图暂未就绪，点击预览';

  @override
  String get creatorMediaPreview => '预览视频';
}
