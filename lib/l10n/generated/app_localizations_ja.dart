// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get accountTitle => 'アカウント';

  @override
  String get accountGuest => 'ゲストアカウント';

  @override
  String get accountNone => '未ログイン';

  @override
  String get accountSignOut => 'すべてのデバイスからログアウト';

  @override
  String get accountSignOutConfirm =>
      'すべてのデバイスでこのアカウントからログアウトします。アカウントや端末内の動画は削除されません。クラウドのコンテンツを利用するには、再度ログインが必要になる場合があります。';

  @override
  String get accountGuestWarning =>
      'このゲストアカウントには確認済みのメールアドレスがありません。ログアウトするとクラウドのコンテンツを復元できなくなる場合があります。先にメールアドレスを確認してください。';

  @override
  String get accountSignedOut => 'すべてのデバイスからログアウトしました。';

  @override
  String get accountCancel => 'キャンセル';

  @override
  String get appVersionLabel => 'アプリのバージョン';

  @override
  String get applicationTitle => 'クリエイター認証';

  @override
  String get applicationRefresh => '審査状況を更新';

  @override
  String get applicationRetry => '更新して再試行';

  @override
  String get applicationLoadFailed => '申請を読み込めませんでした。更新して続行してください。';

  @override
  String get applicationNoTags => 'キャラクターのカテゴリはまだ利用できません。しばらくしてから再試行してください。';

  @override
  String get applicationApproved => '認証済みクリエイター';

  @override
  String get applicationOpenStudio => 'クリエイタースタジオを開く';

  @override
  String get applicationPending => '申請を審査中';

  @override
  String get applicationSuspended => 'クリエイター機能の利用停止中';

  @override
  String get applicationReviewNote => '担当チームが申請を個別に審査します。更新して状況をご確認ください。';

  @override
  String get applicationRejected => '審査のフィードバックに沿って申請を修正し、再提出してください。';

  @override
  String get applicationRoles => '得意なキャラクター分野';

  @override
  String get applicationDirections => '得意なコンテンツ分野';

  @override
  String get applicationName => 'クリエイター表示名';

  @override
  String get applicationNameHint => '例：NovaStudio、Nova2026';

  @override
  String get applicationNameRule => '英字を1文字以上含む英数字で、80文字以内にしてください。';

  @override
  String get applicationEmail => 'メールアドレス（クリエイター識別用）';

  @override
  String get applicationRegion => 'クリエイターの所在地';

  @override
  String get applicationChina => '中国本土';

  @override
  String get applicationUs => 'アメリカ合衆国';

  @override
  String get applicationEea => '欧州経済領域';

  @override
  String get applicationUk => 'イギリス';

  @override
  String get applicationJapan => '日本';

  @override
  String get applicationHk => '香港';

  @override
  String get applicationMo => 'マカオ';

  @override
  String get applicationTw => '台湾';

  @override
  String get applicationAsia => 'その他のアジア地域';

  @override
  String get applicationOther => 'その他の地域';

  @override
  String get applicationAdult => '私は18歳以上です';

  @override
  String get applicationAgreement => 'クリエイター規約、守秘義務、およびプラットフォーム外での取引禁止規則に同意します';

  @override
  String get applicationWorks => '自作の動画';

  @override
  String get applicationWorkNote =>
      '自作のMP4動画を1〜10本アップロードしてください。1本につき15 MBまでです。サンプルは非公開で、認証のためにのみ使用されます。担当チームが本数、品質、創造性を審査します。';

  @override
  String get applicationUpload => '作品をアップロード';

  @override
  String get applicationUploadFailed => 'アップロードに失敗しました。動画は追加されていません。';

  @override
  String get applicationRetryUpload => 'アップロードを再試行';

  @override
  String get applicationRemoveFailed => '失敗したアップロードを削除';

  @override
  String get applicationSample => '認証用サンプル';

  @override
  String get applicationPrivate => 'アップロード済み・非公開サンプル';

  @override
  String get applicationPreview => 'サンプルをプレビュー';

  @override
  String get applicationRemove => 'サンプルを削除';

  @override
  String get applicationSave => '下書きを保存';

  @override
  String get applicationSubmit => '申請を提出';

  @override
  String get applicationPreviewTitle => '認証用サンプルのプレビュー';

  @override
  String get applicationInvalidName => '英字を1文字以上含む英数字で、80文字以内にしてください。';

  @override
  String get applicationInvalidEmail => 'アップロードする前に有効なメールアドレスを入力してください。';

  @override
  String get applicationRoleRequired => '得意なキャラクター分野を1つ以上選択してください。';

  @override
  String get applicationDirectionRequired => '得意なコンテンツ分野を1つ以上選択してください。';

  @override
  String get applicationAdultRequired => '18歳以上であることを確認してください。';

  @override
  String get applicationAgreementRequired => 'クリエイター規約を読み、同意してください。';

  @override
  String get applicationMp4 => 'MP4動画を選択してください。';

  @override
  String get applicationTooLarge => '動画は1本につき15 MB以下にしてください。圧縮してから再試行してください。';

  @override
  String get applicationLimit => 'サンプルは10本までアップロードできます。';

  @override
  String get applicationEmailUsed =>
      'このメールアドレスは別のクリエイターが使用しています。別のアドレスをお使いください。';

  @override
  String get applicationInvalidFields => '名前、専門分野、メールアドレス、同意項目をご確認ください。';

  @override
  String get applicationProcessorBusy => '動画の検証が混み合っています。しばらくしてから再試行してください。';

  @override
  String get applicationLocked => 'この申請は編集できません。更新して審査状況をご確認ください。';

  @override
  String get applicationVideoLimit => '追加する前にサンプルを削除してください。上限は10本です。';

  @override
  String get applicationVideoInvalid =>
      '動画が検証に合格しませんでした。再生可能なMP4を選んで再試行してください。';

  @override
  String get applicationVideoRequired => '検証に合格する動画を1本以上アップロードしてください。';

  @override
  String get applicationConflict => '申請が変更されています。更新して再試行してください。';

  @override
  String get applicationPreviewFailed => 'プレビューに失敗しました。戻って再試行してください。';

  @override
  String applicationGrade(String grade) {
    return 'クリエイターランク：$grade';
  }

  @override
  String applicationUploading(String name) {
    return 'アップロード・検証中：$name';
  }

  @override
  String get applicationDirectionAction => 'シンプルな動作';

  @override
  String get applicationDirectionDance => '音楽とダンス';

  @override
  String get applicationDirectionEffects => '視覚効果';

  @override
  String get applicationDirectionGrowth => 'キャラクターの成長';

  @override
  String get applicationGradeSilver => 'シルバー';

  @override
  String get applicationGradeGold => 'ゴールド';

  @override
  String get applicationGradeDiamond => 'ダイヤモンド';

  @override
  String get applicationGradeMaster => 'マスター';

  @override
  String get applicationGradeLegend => 'レジェンド';

  @override
  String get authTitle => 'メールアドレスでログイン';

  @override
  String get authExplanation =>
      'メールアドレスでログインすると、別のデバイスからアカウントにアクセスしたり、サービスの通知を受け取ったりできます。ログインするとアカウントが切り替わります。データは統合されません。以前のアカウントに確認済みのメールアドレスがない場合は、復旧についてサポートにお問い合わせください。';

  @override
  String get authEmail => 'メールアドレス';

  @override
  String get authSend => 'コードを送信';

  @override
  String get authResend => 'コードを再送信';

  @override
  String get authSent => 'コードを送信しました。有効期限は10分です。';

  @override
  String get authCode => '6桁のコード';

  @override
  String get authChange => 'メールアドレスを変更';

  @override
  String get authVerify => '確認してログイン';

  @override
  String get authInvalidEmail => '有効なメールアドレスを入力してください。';

  @override
  String get authInvalidCode => '6桁のコードを入力してください。';

  @override
  String authResendSeconds(int seconds) {
    return '$seconds秒後に再送信';
  }

  @override
  String get appName => 'Hildors';

  @override
  String get languageTitle => '言語';

  @override
  String get languageSystem => 'システム設定に合わせる';

  @override
  String get languageEnglish => '英語';

  @override
  String get languageChinese => '簡体字中国語';

  @override
  String get languageFallback =>
      '中国語の各種設定には簡体字中国語が適用されます。その他の未対応言語には英語が適用されます。';

  @override
  String get languageSaveFailed => '言語設定を保存できませんでした。再試行してください。';

  @override
  String get commonRetry => '再試行';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonSave => '保存';

  @override
  String get commonLoading => '読み込み中…';

  @override
  String get errorNetwork => '接続できません。通信状況を確認して再試行してください。';

  @override
  String get errorSession => '続行するには再度ログインしてください。';

  @override
  String get errorPermission => 'このアカウントではこのコンテンツを利用できません。';

  @override
  String get errorConflict => 'この項目は変更されています。更新して再試行してください。';

  @override
  String get errorTooLarge => 'ファイルが大きすぎます。小さいファイルを選択してください。';

  @override
  String get errorRateLimit => 'リクエストが多すぎます。しばらくしてから再試行してください。';

  @override
  String get errorGeneric => 'エラーが発生しました。再試行してください。';

  @override
  String get errorEmailCode => 'メールアドレスと確認コードをご確認ください。コードの有効期限が切れている可能性があります。';

  @override
  String get errorServiceUnavailable => 'このサービスは一時的に利用できません。しばらくしてから再試行してください。';

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
  String get catalogCollection => 'コレクション';

  @override
  String get catalogLibrary => 'ライブラリ';

  @override
  String get catalogMyCharacters => 'マイキャラクター';

  @override
  String get catalogLoadFailed => 'ライブラリを読み込めません';

  @override
  String get catalogCheckNetwork => '通信状況を確認して再試行してください。';

  @override
  String get catalogSearch => 'キャラクター、動画、ジャンルを検索';

  @override
  String get catalogRefresh => 'ライブラリを更新';

  @override
  String get catalogSource => '提供元';

  @override
  String get catalogFormat => '形式';

  @override
  String get catalogGenre => 'ジャンル';

  @override
  String get catalogAll => 'すべて';

  @override
  String get catalogOfficial => 'Hildors公式';

  @override
  String get catalogCreatorWorks => 'クリエイター作品';

  @override
  String get catalogAnonymous => '匿名クリエイター';

  @override
  String get catalogSingle => '単体動画';

  @override
  String get catalogPackage => 'キャラクターパック';

  @override
  String get catalogEmpty => '一致するコンテンツがありません';

  @override
  String get catalogClear => '絞り込みを解除';

  @override
  String get catalogResults => '検索結果';

  @override
  String get catalogDescriptionMissing => 'キャラクターの説明はまだありません';

  @override
  String get catalogPackVideos => 'このパックの動画';

  @override
  String get catalogVideo => '動画';

  @override
  String get catalogNoPreview => '現在プレビューは利用できません';

  @override
  String get catalogDurationUnknown => '再生時間を取得できません';

  @override
  String get catalogStoryMissing => '背景ストーリーはまだありません';

  @override
  String get catalogStory => '背景ストーリー';

  @override
  String get catalogStoryCollapse => 'ストーリーを折りたたむ';

  @override
  String get catalogStoryExpand => 'ストーリーの全文を読む';

  @override
  String get catalogImageLoading => '画像を読み込み中';

  @override
  String get catalogImageRetry => '画像を読み込めませんでした。タップして再試行';

  @override
  String get playerNoSource => '利用できる動画がありません';

  @override
  String get playerBuffering => '動画をバッファリング中…';

  @override
  String get playerLoading => '動画を読み込み中…';

  @override
  String get playerSlow => '通常より時間がかかっています。通信状況を確認するか、再試行してください。';

  @override
  String get playerPause => 'プレビューを一時停止';

  @override
  String get playerPlay => 'プレビューを再生';

  @override
  String get playerZoom => 'ピンチで拡大・縮小、ダブルタップでリセット';

  @override
  String get playerFailed => '再生に失敗しました。再試行してください。';

  @override
  String get playerTimeout => '動画の読み込みがタイムアウトしました。再試行してください。';

  @override
  String get playerLoadFailed => '動画を読み込めませんでした。再試行してください。';

  @override
  String get playerAuthFailed => 'アクセス権を更新できませんでした。投稿一覧に戻って再試行してください。';

  @override
  String get downloadTitle => 'マイキャラクターに保存';

  @override
  String get downloadUnavailable => '購入は利用できません';

  @override
  String get downloadFree => '無料ダウンロード';

  @override
  String get downloadInfo => '無料動画はダウンロードして、マイキャラクターでオフライン視聴できます。購入は利用できません。';

  @override
  String get downloadCancel => 'ダウンロードをキャンセル';

  @override
  String get downloadAvailable => '利用可能な動画をダウンロード';

  @override
  String get downloadDone => 'ダウンロード済み';

  @override
  String get downloadRefresh => 'アクセス権を更新';

  @override
  String get downloadView => 'マイキャラクターを見る';

  @override
  String get downloadDisabled => 'ダウンロードは一時的に利用できません。しばらくしてから再試行してください。';

  @override
  String get downloadSignIn => 'ダウンロードするには再度ログインしてください。';

  @override
  String get downloadDenied => 'この動画はダウンロードできません。アクセス権を更新して再試行してください。';

  @override
  String get downloadAccessFailed =>
      'ダウンロードの権限を確認できませんでした。通信状況とアカウントを確認して再試行してください。';

  @override
  String get downloadFinished => 'ダウンロードが完了しました。マイキャラクターに保存しました。';

  @override
  String get downloadCancelled => 'ダウンロードをキャンセルしました。完了済みの動画はマイキャラクターに残ります。';

  @override
  String get downloadFailed =>
      'ダウンロードが完了しませんでした。通信状況、空き容量、アカウントの権限を確認して再試行してください。';

  @override
  String catalogSummary(int count, int creators) {
    return '$count件・クリエイター作品$creators件';
  }

  @override
  String catalogRefreshed(int count, int creators) {
    return 'ライブラリを更新しました：$count件、うちクリエイター作品$creators件';
  }

  @override
  String catalogCount(String format, int count) {
    return '$format・動画$count本';
  }

  @override
  String catalogSeconds(String seconds) {
    return '$seconds秒';
  }

  @override
  String catalogCreatorSpace(String name) {
    return '$nameの作品';
  }

  @override
  String catalogPublished(int count) {
    return '公開作品・$count件';
  }

  @override
  String downloadProgress(int count, int total) {
    return '$count/$total件ダウンロード済み';
  }

  @override
  String downloadActive(String name) {
    return 'ダウンロード中：$name';
  }

  @override
  String downloadPrice(String price) {
    return 'US\$ $price・購入してダウンロード';
  }

  @override
  String get controlsDeleteTitle => 'ダウンロード済みファイルを削除しますか？';

  @override
  String get controlsDeleteNote =>
      'このコレクションのダウンロード済みファイルをアプリから削除します。クラウドのアクセス権は保持されるため、再度ダウンロードできます。';

  @override
  String get controlsCancel => 'キャンセル';

  @override
  String get controlsDelete => '削除';

  @override
  String get controlsDeleteFailed => '削除できませんでした。再試行してください。';

  @override
  String get controlsDeleteLocal => 'ダウンロード済みファイルを削除';

  @override
  String get controlsNoVideos => 'このキャラクターにはまだ利用できる動画がありません。';

  @override
  String get controlsPreviewLocal => 'ダウンロード済み動画をプレビュー';

  @override
  String get controlsExamples => '公式サンプルコレクション・動画を選択';

  @override
  String get controlsChooseList => 'プレイリストを選択';

  @override
  String get controlsPendingNote => '動画はまずアップロード待ちに追加されます。デバイスにはまだアップロードされません。';

  @override
  String get controlsStartup => '日常表示';

  @override
  String get controlsBluetooth => '音楽モード';

  @override
  String get controlsAddFailed => '動画を追加できませんでした。再試行してください。';

  @override
  String get controlsMyCharacters => 'マイキャラクター';

  @override
  String get controlsLoadFailed => 'キャラクターを読み込めませんでした。タップして再試行してください。';

  @override
  String get controlsEmpty => 'キャラクターはまだありません';

  @override
  String get controlsEmptyNote => 'コンテンツライブラリからキャラクターをダウンロードし、動画を選択してください。';

  @override
  String get controlsLibrary => 'コンテンツライブラリ';

  @override
  String get controlsBrowse => 'コンテンツライブラリを見る';

  @override
  String get controlsPickNote => 'キャラクターを選んでから、このプレイリストに追加する動画を選択してください。';

  @override
  String get controlsListNote => 'キャラクターの動画を日常表示または音楽モードに追加します。';

  @override
  String get controlsUnavailable => '利用できる動画がありません';

  @override
  String get controlsSelect => '動画を選択';

  @override
  String get controlsAdd => 'プレイリストに追加';

  @override
  String get controlsControlTitle => 'コントロールパネル';

  @override
  String get controlsBrightness => '明るさ';

  @override
  String get controlsAngle => '角度（デバイスの単位と範囲は未確認）';

  @override
  String get controlsSpeakerTitle => 'Bluetoothスピーカー名を設定';

  @override
  String get controlsSpeakerName => 'スピーカー名';

  @override
  String get controlsSave => '保存';

  @override
  String get controlsSpeaker => 'Bluetoothスピーカー';

  @override
  String get controlsConnectSpeaker => 'デバイスを接続するとスピーカー名を取得できます。';

  @override
  String get controlsReading => '読み取り中…';

  @override
  String get controlsNameUnknown => '名前を未取得';

  @override
  String get controlsRefreshName => '名前を更新';

  @override
  String get controlsEditName => '名前を編集';

  @override
  String get controlsDisconnected => '未接続';

  @override
  String get controlsConnecting => '接続中…';

  @override
  String get controlsReconnecting => '再接続中…';

  @override
  String get controlsConnected => '接続済み';

  @override
  String get controlsIp => 'デバイスのIPアドレス';

  @override
  String get controlsPort => '既定のポート：8900';

  @override
  String get controlsStopReconnect => '再接続を停止';

  @override
  String get controlsDisconnect => '切断';

  @override
  String get controlsConnect => '接続';

  @override
  String get controlsQuick => 'クイック操作';

  @override
  String get controlsPowerOn => '電源を入れる';

  @override
  String get controlsPowerOff => '電源を切る';

  @override
  String get controlsPrevious => '前へ';

  @override
  String get controlsPause => '一時停止';

  @override
  String get controlsPlay => '再生';

  @override
  String get controlsNext => '次へ';

  @override
  String get controlsRefreshStatus => '状態を更新';

  @override
  String get controlsStatus => 'デバイスの状態';

  @override
  String get controlsLan => 'ローカルネットワーク操作';

  @override
  String get controlsMode => '動作モード';

  @override
  String get controlsAudioSource => 'Bluetooth音声ソース';

  @override
  String get controlsProtocol => 'プロトコル対応待ち';

  @override
  String get controlsLocalPlayback => 'デバイス再生';

  @override
  String get controlsBluetoothWaiting => 'Bluetooth接続待ち';

  @override
  String get controlsBluetoothAudio => 'Bluetooth音声';

  @override
  String get controlsWaitingSource => '音声ソースを待機中';

  @override
  String get controlsAudioPlaying => '音声を再生中';

  @override
  String get controlsAudioPaused => '音声を一時停止中';

  @override
  String get controlsWasDisconnected => '切断済み';

  @override
  String get controlsBatteryFull => '充電完了';

  @override
  String get controlsBattery => 'デバイスのバッテリー';

  @override
  String get controlsProtocolNote =>
      '現在のプロトコルは動作モードやBluetoothの状態を通知しません。これらの表示には、デバイス側のプロトコル更新が必要です。';

  @override
  String controlsPackageCount(int count) {
    return 'キャラクターコレクション・動画$count本';
  }

  @override
  String controlsDownloaded(int count, int total) {
    return '動画$count/$total本をダウンロード済み';
  }

  @override
  String controlsSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String controlsAddCount(int count) {
    return '動画$count本をアップロード待ちに追加';
  }

  @override
  String controlsVideoCount(int count) {
    return '動画$count本';
  }

  @override
  String controlsAdded(String list) {
    return '$listのアップロード待ちに追加しました。デバイスにはまだアップロードされていません。';
  }

  @override
  String controlsNamedPlaying(String name) {
    return '$name・再生中';
  }

  @override
  String controlsNamedPaused(String name) {
    return '$name・一時停止中';
  }

  @override
  String controlsCharging(int percent) {
    return '$percent%・充電中';
  }

  @override
  String get coreHome => 'ホーム';

  @override
  String get coreCollection => 'コレクション';

  @override
  String get coreExplore => '見つける';

  @override
  String get coreProfile => 'プロフィール';

  @override
  String get coreDeviceControl => 'デバイス操作';

  @override
  String get coreCustomCharacter => 'ホログラムキャラクターをカスタマイズ';

  @override
  String get corePlaylists => 'デバイスのプレイリスト';

  @override
  String get corePlaylistSubtitle => '表示モードと音楽モード';

  @override
  String get coreDisplay => '表示モード';

  @override
  String get coreStartupSubtitle => '起動時に再生するコンテンツを管理';

  @override
  String get coreMusic => '音楽モード';

  @override
  String get coreBluetoothSubtitle => 'Bluetooth音声とともに再生するコンテンツを管理';

  @override
  String get coreOnline => 'オンライン';

  @override
  String get coreDisconnected => '未接続';

  @override
  String get coreDeviceConnected => 'デバイス接続済み';

  @override
  String get coreConnecting => '接続中…';

  @override
  String get coreReconnecting => '再接続中…';

  @override
  String get coreDeviceDisconnected => 'デバイス未接続';

  @override
  String get coreLanControl => 'ローカルネットワーク操作・P20 / P20 PORTAL';

  @override
  String get coreConnectP20 => 'デバイスを接続';

  @override
  String get coreConnectionSettings => 'コントロールパネル';

  @override
  String get coreDeviceManagement => 'デバイス管理';

  @override
  String get coreDevices => 'デバイス';

  @override
  String get corePlaylist => 'プレイリスト';

  @override
  String get coreDeviceContent => 'デバイスのコンテンツ';

  @override
  String get coreCharacterAssets => 'キャラクター';

  @override
  String get coreCustomOrders => 'カスタム制作の注文';

  @override
  String get coreOrdersSubtitle => '制作と納品の状況を確認できます。受け取り済みのキャラクターはコレクションにあります。';

  @override
  String get coreCreatorCenter => 'クリエイターセンター';

  @override
  String get coreCreatorSubtitle => '申請、制作タスク、収益';

  @override
  String get coreSupport => 'サポート';

  @override
  String get corePlaybackGuide => '再生モード';

  @override
  String get corePlaybackGuideSubtitle => '表示モードと音楽モードの切り替えについて';

  @override
  String get coreLanHelp => 'ローカルネットワークのヘルプ';

  @override
  String get coreLanHelpSubtitle => 'P20 / P20 PORTALのアクセスポイントへの接続とトラブル対処';

  @override
  String get coreAppSettings => 'デバイスとアプリの設定';

  @override
  String get coreAppSettingsSubtitle => 'デバイスのオプション、再生設定、バージョン';

  @override
  String get coreAbout => 'HILDORSについて';

  @override
  String get coreAboutSubtitle => 'キャラクターポータル・P20 / P20 PORTAL対応';

  @override
  String get corePlayerProfile => 'プレイヤープロフィール';

  @override
  String get coreLocalAccount => 'この端末に保存されたローカルプロフィール';

  @override
  String get coreDeviceSettings => 'デバイス設定';

  @override
  String get coreReadFailed => 'デバイスの状態を取得できませんでした。デバイスのWi-Fiに接続して再試行してください。';

  @override
  String get coreSettingFailed => '設定を適用できませんでした。デバイスの接続を確認して再試行してください。';

  @override
  String get corePlaybackBehavior => '再生設定';

  @override
  String get coreLoopMode => 'リピートモード';

  @override
  String get coreLoopSubtitle => 'デバイスの現在のプレイリストの繰り返し方法を選択';

  @override
  String get coreConnectToChange => '接続すると設定を取得・変更できます';

  @override
  String get coreDeviceInfo => 'デバイス情報';

  @override
  String get coreLanCockpit => 'ローカルネットワーク上のデバイス';

  @override
  String get coreNotRead => '未取得';

  @override
  String get coreReadInfo => 'デバイス情報を取得';

  @override
  String get coreHelp => 'ヘルプ';

  @override
  String get coreModesHelpSubtitle => '表示モードと音楽モードの自動切り替え';

  @override
  String get coreHotspotHelp => 'デバイスのアクセスポイントへの接続とトラブル対処';

  @override
  String get coreDeviceConnecting => 'デバイスに接続中';

  @override
  String get coreDeviceReconnecting => '接続を復旧中';

  @override
  String get coreCockpitOnline => 'デバイスがオンライン';

  @override
  String get coreGoHomeConnect => 'ホームからP20 / P20 PORTALを接続してください';

  @override
  String get coreOpeningLan => 'ローカルネットワーク操作の接続を確立中';

  @override
  String get coreRetryingLan => '接続が中断されました。自動的に再試行しています';

  @override
  String get coreLanReady => 'ローカルネットワーク操作の接続が完了';

  @override
  String get coreSync => 'デバイスの状態を同期';

  @override
  String get coreSingleLoop => '1本リピート';

  @override
  String get coreSequenceLoop => '全件リピート';

  @override
  String get coreRandomLoop => 'シャッフル';

  @override
  String get coreSingleOnce => '1回再生';

  @override
  String get coreCheckWifi => 'スマートフォンのWi-Fiを確認';

  @override
  String get coreCheckWifiBody =>
      'スマートフォンをP20のアクセスポイント、またはP20と同じルーターに接続してください。';

  @override
  String get coreCheckAddress => '操作用アドレスを確認';

  @override
  String get coreCheckAddressBody =>
      'アクセスポイントモードの既定のアドレスは192.168.4.1、TCPポートは8900です。';

  @override
  String get coreLanPermission => 'ローカルネットワークへのアクセスを許可';

  @override
  String get coreLanPermissionBody =>
      'iOSではローカルネットワークへのアクセスを許可してください。Androidでは、要求された付近のデバイスおよびネットワークの権限を許可してください。';

  @override
  String get coreReconnect => '再接続';

  @override
  String get coreReconnectBody =>
      'デバイス操作に戻り、接続をタップしてください。予期しない切断が発生すると、アプリは1、2、4、8、15、30秒後に再試行します。';

  @override
  String get coreOfflineWifiHelp =>
      '「インターネット接続なし」と表示されても、デバイス操作に失敗したとは限りません。スマートフォンがP20のローカルネットワークに接続していれば、操作を続けられます。';

  @override
  String get coreLocalPlayback => 'デバイス再生';

  @override
  String get coreLocalPlaybackBody =>
      'P20はデバイスに保存された動画を音声とともに再生します。起動時の再生、繰り返し表示、固定コンテンツの表示に利用できます。';

  @override
  String get coreBluetoothSpeaker => 'Bluetoothスピーカー';

  @override
  String get coreBluetoothSpeakerBody =>
      'スマートフォンやパソコンからBluetoothでP20に音声を送信すると、P20はBluetoothモードに設定された動画を再生します。';

  @override
  String get coreSeparateConnections =>
      'HildorsはローカルWi-Fi経由でP20を操作します。ローカルネットワーク操作とBluetooth音声は別々の接続です。';

  @override
  String get coreCharacterPortal => 'キャラクターポータル';

  @override
  String get coreExploreSubtitle => 'キャラクターをカスタマイズし、リクエストを共有して、制作を楽しみましょう。';

  @override
  String get coreWishSubtitle => 'リクエストを共有し、ライセンスの最新情報を確認';

  @override
  String get coreCreatorExploreSubtitle => '申請、タスク、収益';

  @override
  String get coreWish => 'キャラクターのリクエスト';

  @override
  String get coreCustomize => 'キャラクターをカスタマイズ';

  @override
  String get coreEnter => '開く';

  @override
  String get coreCreatorFreeSubtitle => 'クリエイター認証を申請して無料コンテンツを公開';

  @override
  String get coreExploreFreeSubtitle => '無料コンテンツの制作・共有の機会を見つけましょう。';

  @override
  String get coreConnectionFailed =>
      '接続できません。スマートフォンをデバイスの Wi-Fi に接続して再試行してください。';

  @override
  String get coreSystemLabel => 'デバイスシステム';

  @override
  String get coreProfileLabel => 'プレイヤープロフィール';

  @override
  String get coreLocalLabel => 'ローカル';

  @override
  String get corePilotLabel => 'HILDORSパイロット';

  @override
  String get coreServiceLabel => '基本サービス';

  @override
  String get coreCreatorLabel => 'クリエイター';

  @override
  String get coreOnlineLabel => 'オンライン';

  @override
  String get coreConnectingLabel => '接続中';

  @override
  String get coreReconnectingLabel => '再接続中';

  @override
  String get coreOfflineLabel => 'オフライン';

  @override
  String get creatorWorkbench => 'クリエイタースタジオ';

  @override
  String get creatorOriginal => 'オリジナルコンテンツ';

  @override
  String get creatorFreeNote =>
      '動画やキャラクターコレクションをアップロードして審査に提出します。このバージョンでは無料の投稿のみ対応しています。承認後にコンテンツが公開されます。';

  @override
  String get creatorPublishingNote =>
      '動画やキャラクターコレクションをアップロードして審査に提出します。一般クリエイターと認証済みクリエイターは無料コンテンツを公開でき、パートナーは価格を設定できます。';

  @override
  String get creatorSubmissions => 'アップロード・自分の投稿';

  @override
  String get creatorTasks => 'カスタム制作案件';

  @override
  String get creatorTasksNote => '募集中の案件と進行中のカスタム制作の注文を確認';

  @override
  String get customPlansTitle => 'カスタム動画';

  @override
  String get customOrdersTitle => '自分のカスタム制作注文';

  @override
  String get customUnavailable => 'ストア決済はまだ接続されていません。お支払いは発生しません。';

  @override
  String get customWebsiteTitle => 'Hildors公式サイト';

  @override
  String get customWebsiteBody =>
      'Hildorsと対応ハードウェアについてご案内します。このバージョンではカスタム動画を購入できません。';

  @override
  String get customWebsiteButton => 'Hildors公式サイトを開く';

  @override
  String get customWebsiteError => 'Hildors公式サイトを開けませんでした。';

  @override
  String customBase(String price) {
    return '基本参考価格（米ドル）：$price。決済時にはストアの価格が適用されます。';
  }

  @override
  String customSeconds(int seconds) {
    return '$seconds秒の動画';
  }

  @override
  String get customRequest => '制作要件を審査に提出';

  @override
  String get customName => 'キャラクター名・プロジェクト名';

  @override
  String get customRequirements => '制作要件';

  @override
  String get customMaterials => '参考画像を追加';

  @override
  String customMaterialCount(int count) {
    return '参考画像$count枚';
  }

  @override
  String get customPrivacy => '参考資料は、この非公開注文の評価と制作に使用されます。公開には別途同意が必要です。';

  @override
  String get customConsent => 'この注文のためにこれらの資料を使用することに同意します。';

  @override
  String get customValidation => 'プロジェクト名と制作要件を入力し、資料の使用に関する説明に同意してください。';

  @override
  String get customImageError => 'JPGまたはPNG画像を8枚まで選択してください。1枚につき8 MB以下にしてください。';

  @override
  String get customSubmitted => '依頼を審査に提出しました。お支払いは発生していません。';

  @override
  String get customTerms => 'お支払いの前に確定した制作範囲をご確認ください';

  @override
  String get customContent => '納品物';

  @override
  String get customPeriod => '納期';

  @override
  String get customRevisions => '修正の範囲';

  @override
  String get customRights => '利用権';

  @override
  String get customAcceptTerms => '確定した制作範囲とその条件に同意します。';

  @override
  String customPay(String price) {
    return '$priceを支払う';
  }

  @override
  String get customRestore => '未完了の購入を確認';

  @override
  String get customTestMode => 'テスト決済・実際の請求は発生しません';

  @override
  String get customAccept => '納品を承認';

  @override
  String get customRevise => '修正を依頼';

  @override
  String get customRevisionNote => '修正してほしい内容を記入';

  @override
  String get customStatusReview => '制作要件を審査中';

  @override
  String get customStatusInfo => '追加情報が必要';

  @override
  String get customStatusQuote => '制作範囲が確定・お支払い待ち';

  @override
  String get customStatusMaking => '制作中';

  @override
  String get customStatusQc => '品質確認中';

  @override
  String get customStatusAccept => 'お客様の確認待ち';

  @override
  String get customStatusDelivered => '納品済み';

  @override
  String get customStatusRejected => '依頼は承認されませんでした';

  @override
  String get customStatusWithdrawn => '取り下げ済み・返金済み';

  @override
  String get customPending => 'お支払いは保留中です。サーバーでの確認が完了してから制作を開始します。';

  @override
  String get customEmpty => 'まだ項目がありません。';

  @override
  String get customAudioNone => '音声なし・基本プラン';

  @override
  String get customAudioMatched => 'プラットフォームによる音声選定';

  @override
  String get customAudioHelp =>
      '動画に合うBGMや簡単な効果音を選定します。特定の曲、ナレーション、アップロードされた音声には対応していません。';

  @override
  String customAudioTotal(String price) {
    return '参考合計金額（米ドル）：$price';
  }

  @override
  String customAudioRate(int percent) {
    return '音声選定の追加料金：$percent%';
  }

  @override
  String get customSupplement => '制作要件を更新して再提出';

  @override
  String get customSupplementSaved => '更新した制作要件を審査に提出しました。';

  @override
  String get customSaveDelivery => '納品物をマイキャラクターに保存';

  @override
  String get customSavedDelivery => 'マイキャラクターに保存しました。オフラインで利用できます。';

  @override
  String get customSavingDelivery => '非公開の納品物をダウンロード中…';

  @override
  String get customConfirmDelivery => 'このバージョンを最終納品として承認しますか？';

  @override
  String customRevisionLimit(int used, int limit) {
    return '修正依頼：$limit回中$used回';
  }

  @override
  String get customProgress => '制作の進捗';

  @override
  String get deletionTitle => 'アカウントを削除';

  @override
  String get deletionExplanation =>
      'Hildorsアカウントと関連データの削除を申請します。この操作は審査のための申請であり、すぐにデータが削除されたり、ログアウトされたりすることはありません。ここで状況を確認でき、保留中は申請を取り消せます。';

  @override
  String get deletionSubmit => 'アカウント削除を申請';

  @override
  String get deletionConfirm => '削除申請を提出しますか？審査中もアカウントは引き続き利用できます。';

  @override
  String get deletionNone => '保留中の削除申請はありません。';

  @override
  String get deletionReceived => '申請受付済み';

  @override
  String get deletionReview => '審査中';

  @override
  String get deletionInformation => '追加情報が必要';

  @override
  String get deletionCancelled => '申請を取り消しました';

  @override
  String get deletionCancel => '削除申請を取り消す';

  @override
  String get deletionRefresh => '状態を更新';

  @override
  String deletionReference(String id) {
    return '申請ID：$id';
  }

  @override
  String get devicePlayingDelete => 'この動画を削除する前に、別の動画を再生してください。';

  @override
  String get deviceDeleteTitle => 'このデバイスのファイルを完全に削除しますか？';

  @override
  String get deviceDeleteIntro => '次の動画をホログラムデバイスから完全に削除します：';

  @override
  String get deviceDeleteNote => 'この操作は取り消せません。スマートフォンにダウンロードしたコピーと購入履歴は残ります。';

  @override
  String get deviceCancel => 'キャンセル';

  @override
  String get deviceDelete => '完全に削除';

  @override
  String get deviceVideoLibrary => 'デバイスの動画';

  @override
  String get deviceRefresh => '更新';

  @override
  String get deviceConnectFirst => '先にデバイス操作からデバイスを接続してください。';

  @override
  String get deviceReadVideos => 'デバイスの動画を読み込む';

  @override
  String get devicePlaying => '再生中';

  @override
  String get devicePlay => '再生';

  @override
  String get deviceMore => 'その他の操作';

  @override
  String get deviceDeleteFrom => 'デバイスから削除';

  @override
  String get frameSaved => '表示範囲を保存しました。元の動画は変更されておらず、変換やアップロードも行われていません。';

  @override
  String get frameSaveFailed => '保存できませんでした。再試行してください。';

  @override
  String get frameTitle => '円形の表示範囲を調整';

  @override
  String get frameCircle => '円はデバイスの表示領域を示しています。';

  @override
  String get frameInstructions =>
      'ピンチで拡大・縮小し、ドラッグで位置を調整してください。動画を最後まで再生し、キャラクターと動きが円の中に収まることをご確認ください。';

  @override
  String get framePause => 'プレビューを一時停止';

  @override
  String get framePlay => 'プレビューを再生';

  @override
  String get framePlaybackFailed => '再生に失敗しました。戻って再試行してください。';

  @override
  String get frameZoom => '拡大・縮小';

  @override
  String get frameFit => '画面全体を収める';

  @override
  String get frameFill => '円いっぱいに表示';

  @override
  String get frameReset => 'リセット';

  @override
  String get frameFitNote => '「画面全体を収める」は動画全体を表示します。「円いっぱいに表示」は端を切り取ります。';

  @override
  String get frameRestoreFailed => '保存済みの表示範囲を読み込めませんでした。再度調整して保存してください。';

  @override
  String get frameSaving => '保存中…';

  @override
  String get frameSave => '表示範囲を保存';

  @override
  String get frameUnavailable => '変換してアップロード・利用不可';

  @override
  String get framePending => '現在は表示範囲のみ保存されます。デバイス用の動画変換はまだ利用できません。';

  @override
  String get framePreviewFailed => 'プレビューを読み込めませんでした。戻って再試行してください。';

  @override
  String deviceDeleted(String name) {
    return '$nameをデバイスから削除しました。';
  }

  @override
  String frameTime(int position, int duration) {
    return '$position / $duration秒';
  }

  @override
  String get copyDeviceLog => 'デバイス通信ログをコピー';

  @override
  String get deviceLogCopied => 'ログをコピーしました。プロトコルのメタデータが含まれますが、メディア本体は含まれません。';

  @override
  String get deviceDeleteAudioNote => '対応する音声ファイルも削除されます。';

  @override
  String get governanceReport => 'コンテンツを報告';

  @override
  String get governanceBlock => 'クリエイターをブロック';

  @override
  String get governanceCopyright => '著作権侵害';

  @override
  String get governanceAbuse => '嫌がらせ・暴言';

  @override
  String get governanceSexual => '性的なコンテンツ';

  @override
  String get governanceViolence => '暴力';

  @override
  String get governanceSpam => 'スパム';

  @override
  String get governanceOther => 'その他';

  @override
  String get governanceDetails => '詳細（任意）';

  @override
  String get governanceReportNote =>
      '報告は審査チームに送信されます。著作権に関する問題の場合は、元の作品とその掲載場所を記載してください。機密性の高い個人情報は含めないでください。';

  @override
  String get governanceCancel => 'キャンセル';

  @override
  String get governanceSubmit => '報告を送信';

  @override
  String governanceReceived(String reference) {
    return '報告を受け付けました。受付番号：$reference';
  }

  @override
  String get governanceBlockNote =>
      'このアカウントのカタログで、このクリエイターのコンテンツを非表示にします。「報告とブロックしたクリエイター」から解除できます。';

  @override
  String get governanceBlocked => 'クリエイターをブロックしました。';

  @override
  String get governanceAuthError => 'セッションの有効期限が切れました。再度ログインしてください。';

  @override
  String get governanceUnavailableError => 'このコンテンツは利用できなくなりました。';

  @override
  String get governanceInvalidError => '報告内容を確認して再試行してください。';

  @override
  String get governanceConflictError => 'この操作は利用できません。更新して再試行してください。';

  @override
  String get governanceNetworkError => '接続できませんでした。再試行してください。';

  @override
  String get governanceTitle => '報告とブロックしたクリエイター';

  @override
  String get governanceRefresh => '更新';

  @override
  String get governanceReports => '自分の報告';

  @override
  String get governanceBlocks => 'ブロックしたクリエイター';

  @override
  String get governanceEmpty => 'まだ項目がありません。';

  @override
  String get governanceUnblock => 'ブロックを解除';

  @override
  String get governanceStatusReceived => '受付済み';

  @override
  String get governanceStatusReview => '審査中';

  @override
  String get governanceStatusAction => '対応済み';

  @override
  String get governanceStatusNoViolation => '違反は確認されませんでした';

  @override
  String get playlistFromCharacters => 'マイキャラクターから選択';

  @override
  String get playlistChooseCharacter => 'キャラクターの動画を選択';

  @override
  String get playlistFromPhone => 'スマートフォンから読み込む';

  @override
  String get playlistFromDevice => 'デバイスにある動画を追加';

  @override
  String get playlistPickFailed => '動画を選択できませんでした。再試行してください。';

  @override
  String get playlistPendingSaveFailed =>
      'アップロード待ちの項目を保存できませんでした。この画面を離れると失われる可能性があります。再試行してください。';

  @override
  String get playlistRetry => '再試行';

  @override
  String get playlistReselectTitle => '元の動画を選び直す';

  @override
  String get playlistReselectNote =>
      'ファイルが移動されたか、一時キャッシュが削除されました。プレイリストの項目は残っています。元の動画を選び直し、表示範囲を確認してください。';

  @override
  String get playlistCancel => 'キャンセル';

  @override
  String get playlistReselect => '選び直す';

  @override
  String get playlistReadFailed => '動画を読み込めませんでした。再試行してください。';

  @override
  String get playlistOriginalTitle => '元の動画が必要です';

  @override
  String get playlistOriginalNote =>
      'デバイスから取得できるのはファイル名のみです。表示範囲を調整するには、スマートフォンから元の動画を選択してください。保存されるのは表示範囲のみです。変換してアップロードすると、元のファイルを残したまま、新しいファイルがデバイスに追加されます。';

  @override
  String get playlistChooseOriginal => '元の動画を選択';

  @override
  String get playlistOriginalFailed => '元の動画を読み込めませんでした。再試行してください。';

  @override
  String get playlistRemovePending => 'アップロード待ちの動画を削除しますか？';

  @override
  String get playlistRemovePendingNote =>
      'このプレイリストの項目のみ削除します。スマートフォンとデバイスの動画は残ります。';

  @override
  String get playlistRemove => '削除';

  @override
  String get playlistReadLocalFailed => '端末内のプレイリストを読み込めませんでした。再試行してください。';

  @override
  String get playlistSaveLocalFailed => '端末内のプレイリストを保存できませんでした。再試行してください。';

  @override
  String get playlistAddDevice => 'デバイスのライブラリから追加';

  @override
  String get playlistAllAdded => 'デバイスの動画はすべてこの下書きに追加済みです。';

  @override
  String get playlistConnectFirst => '再生する前にデバイスを接続してください。';

  @override
  String get playlistNotUploaded => 'この動画はデバイスにありません。再生するには変換とアップロードが必要です。';

  @override
  String get playlistRemoveTitle => 'プレイリストから削除しますか？';

  @override
  String get playlistRemoveList => 'プレイリストから削除';

  @override
  String get playlistUndo => '元に戻す';

  @override
  String get playlistTitle => 'デバイスのプレイリスト';

  @override
  String get playlistReadDevice => 'デバイスの動画を取得';

  @override
  String get playlistStartup => '起動時';

  @override
  String get playlistBluetooth => 'Bluetooth';

  @override
  String get playlistStartupNote => 'デバイスは起動時にこのプレイリストを再生します。';

  @override
  String get playlistBluetoothNote => 'Bluetoothが接続されると、このプレイリストに切り替わります。';

  @override
  String get playlistLoop => 'リピートモード';

  @override
  String get playlistListLoop => 'プレイリストをリピート';

  @override
  String get playlistSingleLoop => '1本リピート';

  @override
  String get playlistOnce => '1回再生';

  @override
  String get playlistOrder => '再生順序';

  @override
  String get playlistAddVideo => '動画を追加';

  @override
  String get playlistPendingLoadFailed =>
      'アップロード待ちの項目を読み込めませんでした。タップして再試行してください。';

  @override
  String get playlistPending => 'アップロード待ちの動画・デバイスに未送信';

  @override
  String get playlistPendingNote =>
      'アップロード待ちの項目は元のファイルを参照しています。変換はまだ利用できません。表示範囲を調整した後も、元のファイルを移動しないでください。';

  @override
  String get playlistConvertPending => '変換待ち・未アップロード';

  @override
  String get playlistFrame => '表示範囲を調整';

  @override
  String get playlistRemovePendingAction => 'アップロード待ちの動画を削除';

  @override
  String get playlistEmpty => 'このプレイリストは空です';

  @override
  String get playlistFirst => '既定で最初に再生する動画';

  @override
  String get playlistUp => '上へ移動';

  @override
  String get playlistDown => '下へ移動';

  @override
  String get playlistRemoveDraft => '下書きから削除';

  @override
  String get playlistSaveDevice => 'デバイスに保存・プロトコル対応待ち';

  @override
  String get playlistRecovery => 'Bluetooth切断後';

  @override
  String get playlistRecoveryNote =>
      '対応している場合は、直前のデバイス動画の再生を再開します。プロトコルの確認待ちです。';

  @override
  String get playlistDisconnected => 'デバイス未接続';

  @override
  String get playlistReadDeviceFailed => 'ネットワーク接続済み・デバイスから取得できません';

  @override
  String get playlistReadDeviceReady => 'ネットワーク接続済み・タップして取得';

  @override
  String get playlistReadNote => 'デバイスのコンテンツを取得して、操作用の接続を確認してください。';

  @override
  String get playlistConnectNote => 'デバイスのWi-Fiに接続してから、プレイリストを取得してください。';

  @override
  String get playlistRead => '取得';

  @override
  String playlistSourceTitle(String name) {
    return '$name・元の表示範囲';
  }

  @override
  String playlistSent(String name) {
    return 'デバイスに送信しました：$name';
  }

  @override
  String playlistRemoveNote(String name) {
    return '「$name」をこのプレイリストからのみ削除します。スマートフォンとデバイスのファイルは残ります。';
  }

  @override
  String playlistRemoved(String name) {
    return '$nameをプレイリストから削除しました';
  }

  @override
  String playlistCount(int count) {
    return '動画$count本';
  }

  @override
  String playlistDeviceCount(int count) {
    return 'デバイス応答あり・動画$count本';
  }

  @override
  String get playlistMoveToTop => '先頭に移動';

  @override
  String get submissionDraftSaved => '下書きを保存しました。動画をアップロードしてから審査に提出してください。';

  @override
  String get submissionTitle => '自分の投稿';

  @override
  String get submissionRefresh => '投稿を更新';

  @override
  String get submissionCreate => '投稿を作成';

  @override
  String get submissionEmpty => '投稿はまだありません。下書きを作成し、動画をアップロードして検証後に提出してください。';

  @override
  String get submissionUpdated => '投稿を更新しました。';

  @override
  String get submissionFree => '無料';

  @override
  String get submissionPaid => '有料';

  @override
  String get submissionPrice => '価格（米ドル）';

  @override
  String get submissionDecimals => '小数点以下2桁まで';

  @override
  String get submissionInvalidPrice => '0より大きい米ドル価格を、小数点以下2桁以内で入力してください。';

  @override
  String get submissionReviewNote => 'すべての動画は公開前に審査が必要です。';

  @override
  String get submissionCancel => 'キャンセル';

  @override
  String get submissionSavePrice => '価格を保存';

  @override
  String get submissionSubmitted => '審査に提出しました。審査中は編集できません。';

  @override
  String get submissionPartnerNote =>
      'パートナーは無料または有料の動画を公開できます。すべてのコンテンツに審査が必要です。';

  @override
  String get submissionFreeNote => '無料動画やキャラクターコレクションを審査に提出してください。';

  @override
  String get submissionCharacterPackage => 'キャラクターコレクション';

  @override
  String get submissionSingleVideo => '単体動画';

  @override
  String get submissionRejectedReason => '修正依頼あり';

  @override
  String get submissionReviewFeedback => '審査のフィードバック';

  @override
  String get submissionName => 'タイトル';

  @override
  String get submissionNameRequired => 'タイトルを入力してください。';

  @override
  String get submissionFormat => 'コンテンツの形式';

  @override
  String get submissionSingle => '単体動画';

  @override
  String get submissionPackage => '動画コレクション';

  @override
  String get submissionTags => 'コンテンツタグ';

  @override
  String get submissionNoTags => 'コンテンツタグはまだ利用できません。';

  @override
  String get submissionStory => '背景ストーリー';

  @override
  String get submissionStoryRequired => '背景ストーリーを入力してください。';

  @override
  String get submissionVideos => '動画';

  @override
  String get submissionAddVideo => '動画を追加';

  @override
  String get submissionRemoveVideo => '動画を削除';

  @override
  String get submissionVideoNameRequired => '動画のタイトルを入力してください。';

  @override
  String get submissionSaveDraft => '下書きを保存';

  @override
  String get submissionSaveInfo => '詳細を保存';

  @override
  String get submissionCoverUploaded => 'カバー画像をアップロード済み';

  @override
  String get submissionCover => 'コレクションのカバー画像';

  @override
  String get submissionCoverTypes => 'JPGまたはPNG';

  @override
  String get submissionReplace => '差し替え';

  @override
  String get submissionUpload => 'アップロード';

  @override
  String get submissionSetPrice => '価格を設定';

  @override
  String get submissionMakeFree => '無料にする';

  @override
  String get submissionReplaceMp4 => 'MP4を差し替え';

  @override
  String get submissionUploadMp4 => 'MP4をアップロード';

  @override
  String get submissionCheckVideo => '動画を検証';

  @override
  String get submissionResubmit => '審査に再提出';

  @override
  String get submissionSubmit => '審査に提出';

  @override
  String get submissionRequirements =>
      '提出前にすべての動画を検証してください。コレクションにはカバー画像も必要です。';

  @override
  String get submissionInfo => 'コンテンツの詳細';

  @override
  String get submissionNoStory => '背景ストーリーはまだありません。';

  @override
  String get submissionRetry => '再試行';

  @override
  String get submissionPending => '審査中';

  @override
  String get submissionPublished => '公開済み';

  @override
  String get submissionApproved => '承認済み・公開待ち';

  @override
  String get submissionRejected => '修正依頼あり';

  @override
  String get submissionDraft => '下書き';

  @override
  String get submissionNoMedia => '動画は未アップロード';

  @override
  String get submissionChecked => '検証合格';

  @override
  String get submissionProcessing => '動画を検証中';

  @override
  String get submissionFailed => '検証に失敗しました。動画を差し替えて再試行してください。';

  @override
  String get submissionWaiting => 'アップロード済み・検証待ち';

  @override
  String get submissionApprovalError =>
      'クリエイターの利用権限が未承認か、停止されています。認証ページをご確認ください。';

  @override
  String get submissionDataError => '投稿データを読み取れませんでした。更新して再試行してください。';

  @override
  String get submissionLoadError => '投稿を読み込めませんでした。しばらくしてから再試行してください。';

  @override
  String get submissionSessionError => 'セッションの有効期限が切れました。再度ログインしてください。';

  @override
  String get submissionAccessError => '有効な認証済みクリエイターアカウントが必要です。';

  @override
  String get submissionPaidError => 'このアカウントでは有料に設定できません。提出前に動画を無料にしてください。';

  @override
  String get submissionPriceError => '有効な米ドル価格を、小数点以下2桁以内で入力してください。';

  @override
  String get submissionConflictError => '投稿が変更されています。更新して再試行してください。';

  @override
  String get submissionMediaError => '先にすべての動画をアップロードし、検証してください。';

  @override
  String get submissionCoverError => '先にコレクションのカバー画像をアップロードしてください。';

  @override
  String get submissionTagError => '利用できなくなったタグがあります。更新して選び直してください。';

  @override
  String get submissionServerError => 'サービスを利用できません。しばらくしてから再試行してください。';

  @override
  String get submissionRequestError => '操作を完了できませんでした。コンテンツを確認して再試行してください。';

  @override
  String get submissionAccountChanged => 'アカウントが変更されました。投稿を更新してください。';

  @override
  String get submissionPreviewError => '動画が未アップロードか、プレビューを利用できません。';

  @override
  String submissionVideoPrice(String name) {
    return '動画の価格・$name';
  }

  @override
  String submissionVideoName(int index) {
    return '動画$indexのタイトル';
  }

  @override
  String submissionLegacyTag(String name) {
    return '$name（旧形式）';
  }

  @override
  String get supportContact => 'サポートに問い合わせる';

  @override
  String get supportInstructions =>
      '問題を再現する手順、アプリのバージョン、デバイスの機種をメールでお知らせください。関連するスクリーンショットも添付できます。';

  @override
  String get supportWriteEmail => 'メールを作成';

  @override
  String get supportCopyEmail => 'メールアドレスをコピー';

  @override
  String get supportEmailCopied => 'サポートのメールアドレスをコピーしました';

  @override
  String get supportCopyFailed => 'コピーできませんでした。メールアドレスを選択して手動でコピーしてください。';

  @override
  String get supportNoMailApp =>
      'メールアプリを開けませんでした。アドレスをコピーし、ご利用のメールサービスからお問い合わせください。';

  @override
  String get p20Refresh => 'デバイスのプレイリストを更新';

  @override
  String get p20Daily => 'A 日常表示';

  @override
  String get p20Bluetooth => 'B Bluetooth';

  @override
  String get p20ConnectNote => '接続すると、デバイスに保存されたプレイリストを表示できます';

  @override
  String get p20ConnectWifi => 'スマートフォンをデバイスのWi-Fiに接続し、「デバイスを接続」をタップしてください。';

  @override
  String get p20Connecting => '接続中…';

  @override
  String get p20Connect => 'デバイスを接続';

  @override
  String get p20Reading => 'デバイスのプレイリストを取得中…';

  @override
  String get p20ReadFailed => 'デバイスのプレイリストを取得できませんでした';

  @override
  String get p20Mode => '再生モード（A/B共通）';

  @override
  String get p20OrderNote => '順序はデバイスから取得します。動画を移動するとデバイスが更新され、確定した順序を再取得します。';

  @override
  String get p20Empty => 'このデバイスのプレイリストは空です';

  @override
  String get p20Pending => 'アップロード待ちの動画';

  @override
  String get p20PendingNote => 'これらの動画はスマートフォン上で待機しており、デバイスにはまだアップロードされていません。';

  @override
  String get p20Unconfirmed =>
      'デバイスから変更の確認応答がありませんでした。現在の状態を再取得しました。確認して再試行してください。';

  @override
  String get p20UploadEntry => 'アップロードするにはデバイスのプレイリストから開いてください';

  @override
  String get p20UploadAction => '変換してアップロード';

  @override
  String get p20FramingNote => '現在の表示範囲でアップロードします。別途保存する必要はありません。';

  @override
  String p20ConnectedCount(int count) {
    return 'デバイス接続済み・動画$count本';
  }

  @override
  String get p20UploadTitle => 'デバイスにアップロード';

  @override
  String get p20UploadStart => '準備してアップロード';

  @override
  String get p20UploadCancel => 'アップロードをキャンセル';

  @override
  String get p20UploadClose => 'プレイリストに戻る';

  @override
  String get p20UploadDisconnected => 'アップロードする前に、ホームからデバイスを接続してください。';

  @override
  String get p20UploadDaily =>
      'A 日常表示プレイリストは音声の有無にかかわらず動画を追加できます。音声ありの場合はMP3を抽出して変換し、音声、動画の順にアップロードします。音声なしの場合は動画のみ変換してアップロードします。';

  @override
  String get p20UploadBluetooth =>
      'B Bluetoothプレイリストは音声の有無にかかわらず動画を追加できます。動画のみ変換してアップロードし、元の音声は使用しません。';

  @override
  String get p20UploadSettings => '298 × 298・20 fps・現在の表示範囲';

  @override
  String get p20UploadDownloadFirst =>
      'デバイスにアップロードする前に、この動画をマイキャラクターにダウンロードしてください。';

  @override
  String get p20UploadFailed =>
      '準備またはアップロードに失敗しました。動画、デバイスの接続、空き容量を確認して再試行してください。';

  @override
  String get p20UploadConfirmedProgress => 'デバイスによる確認済み';

  @override
  String get p20UploadFailureStageLabel => '失敗した段階';

  @override
  String get p20UploadConfirmedLabel => '確認済み';

  @override
  String get p20UploadBytesLabel => 'バイト';

  @override
  String get p20UploadBusy => 'デバイスが処理中です。少し待ってから再試行してください。';

  @override
  String get p20UploadWriteFailed => 'デバイスにファイルを書き込めませんでした。ストレージカードをご確認ください。';

  @override
  String get p20UploadAlreadyExists => 'このファイルはすでにデバイスにあります。';

  @override
  String get p20UploadStorageFull => 'デバイスのストレージまたはプレイリストがいっぱいです。';

  @override
  String get p20UploadBatteryLow => 'デバイスのバッテリー残量が不足しています。充電して再試行してください。';

  @override
  String get p20UploadRejected => 'デバイスがファイルを拒否しました。';

  @override
  String get p20UploadConfirmationTimeout =>
      'デバイスの確認応答がタイムアウトしました。以下の段階と進捗を控えてから、再接続してください。';

  @override
  String get p20UploadProcessingTimeout => 'メディア処理がタイムアウトしました。短い動画でお試しください。';

  @override
  String get p20UploadConnectionLost => 'デバイスとの接続が切れました。再接続して再試行してください。';

  @override
  String get p20UploadLocalFileError =>
      '端末内のファイルを読み書きできません。元のファイルとスマートフォンの空き容量をご確認ください。';

  @override
  String get p20UploadInvalidReply =>
      'デバイスの応答または進捗の順序が一致しませんでした。ファームウェアのプロトコルをご確認ください。';

  @override
  String get p20UploadPartial =>
      '音声はアップロードされましたが、動画は完了していません。デバイスのファイルの削除や自動再試行は行っていません。';

  @override
  String get p20UploadRefreshFailed =>
      'デバイスがアップロードの完了を確認しましたが、プレイリストを更新できませんでした。再接続して更新してください。再アップロードは不要です。';

  @override
  String get p20UploadCleanupPending => '一時ファイルはまだ使用中のため、保持されています。';

  @override
  String get p20UploadWaitingAcceptance => 'アップロードの受付確認を待機中';

  @override
  String get p20UploadTransferring => 'ファイルを転送中';

  @override
  String get p20UploadWaitingCompletion => '完了の確認応答を待機中';

  @override
  String get p20UploadConfirmedCompletion => 'デバイスが完了を確認しました';

  @override
  String get p20UploadReady => '準備完了';

  @override
  String get p20UploadExtractingAudio => '音声を確認し、含まれていれば抽出中';

  @override
  String get p20UploadConvertingVideo => '動画を変換中';

  @override
  String get p20UploadUploadingAudio => '音声をアップロード中';

  @override
  String get p20UploadUploadingVideo => '動画をアップロード中';

  @override
  String get p20UploadRefreshing => 'プレイリストを更新中';

  @override
  String get p20UploadComplete => 'アップロード完了';

  @override
  String get p20UploadIncomplete => 'アップロード未完了';

  @override
  String get p20UploadCancelled => 'キャンセル済み';

  @override
  String get p20SingleOnce => '1回再生';

  @override
  String p20UploadFailureStage(String stage) {
    return '失敗した段階：$stage';
  }

  @override
  String p20UploadTransferDetails(String phase, int acknowledged, int total) {
    return '$phase・$totalバイト中$acknowledgedバイト確認済み';
  }

  @override
  String get creatorMediaOpenFailed => 'この動画を開けません。投稿を更新して再試行してください。';

  @override
  String creatorMediaPreviewLabel(String title) {
    return '動画をプレビュー：$title';
  }

  @override
  String get creatorMediaThumbnailPending => 'サムネイルは準備中です。タップするとプレビューできます。';

  @override
  String get creatorMediaPreview => '動画をプレビュー';

  @override
  String get p20SingleList => 'デバイスの動画';

  @override
  String get p20SingleValidationPending => 'このデバイスへの動画アップロードは、実機での検証待ちです。';

  @override
  String get p20SingleTransferComplete => '転送が確認されました。再生は実機での検証待ちです。';

  @override
  String get p20DeviceType => 'デバイスの種類';

  @override
  String get p20DeviceAuto => '自動検出';

  @override
  String get p20DeviceSingle => 'P20（単一リスト・音声なし）';

  @override
  String get p20DeviceDual => 'P20 PORTAL（2つのリスト・Bluetooth）';
}
