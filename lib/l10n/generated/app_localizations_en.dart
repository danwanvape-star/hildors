// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get deviceDeleteAudioNote =>
      'The paired audio file will also be deleted.';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountGuest => 'Guest account';

  @override
  String get accountNone => 'Not signed in';

  @override
  String get accountSignOut => 'Sign out on all devices';

  @override
  String get accountSignOutConfirm =>
      'This signs out your account on every device. It does not delete your account or local videos. Cloud content may require you to sign in again.';

  @override
  String get accountGuestWarning =>
      'This guest account has no verified email. Signing out may prevent you from recovering its cloud content. Verify an email before signing out.';

  @override
  String get accountSignedOut => 'Signed out on all devices.';

  @override
  String get accountCancel => 'Cancel';

  @override
  String get applicationTitle => 'Creator verification';

  @override
  String get applicationRefresh => 'Refresh review status';

  @override
  String get applicationRetry => 'Refresh and retry';

  @override
  String get applicationLoadFailed =>
      'Could not load your application. Refresh to continue.';

  @override
  String get applicationNoTags =>
      'Character categories are not available yet. Please try again later.';

  @override
  String get applicationApproved => 'Verified creator';

  @override
  String get applicationOpenStudio => 'Open creator studio';

  @override
  String get applicationPending => 'Application under review';

  @override
  String get applicationSuspended => 'Creator access suspended';

  @override
  String get applicationReviewNote =>
      'The team reviews applications manually. Refresh to check your status.';

  @override
  String get applicationRejected =>
      'Update your application using the review feedback, then resubmit.';

  @override
  String get applicationRoles => 'Character specialties';

  @override
  String get applicationDirections => 'Content specialties';

  @override
  String get applicationName => 'Creator display name';

  @override
  String get applicationNameHint => 'For example, NovaStudio or Nova2026';

  @override
  String get applicationNameRule =>
      'Use letters and numbers, including at least one letter. Maximum 80 characters.';

  @override
  String get applicationEmail => 'Email (creator identifier)';

  @override
  String get applicationRegion => 'Creator location';

  @override
  String get applicationChina => 'Mainland China';

  @override
  String get applicationUs => 'United States';

  @override
  String get applicationEea => 'European Economic Area';

  @override
  String get applicationUk => 'United Kingdom';

  @override
  String get applicationJapan => 'Japan';

  @override
  String get applicationHk => 'Hong Kong';

  @override
  String get applicationMo => 'Macao';

  @override
  String get applicationTw => 'Taiwan';

  @override
  String get applicationAsia => 'Other Asian region';

  @override
  String get applicationOther => 'Other region';

  @override
  String get applicationAdult => 'I am at least 18 years old';

  @override
  String get applicationAgreement =>
      'I agree to the creator rules, confidentiality requirements and rules against off-platform transactions';

  @override
  String get applicationWorks => 'Videos I created';

  @override
  String get applicationWorkNote =>
      'Upload 1–10 MP4 videos you created, up to 15 MB each. These samples are private and used only for verification. The team assesses their quantity, quality and creativity.';

  @override
  String get applicationUpload => 'Upload my work';

  @override
  String get applicationUploadFailed =>
      'Upload failed. The video was not added.';

  @override
  String get applicationRetryUpload => 'Retry upload';

  @override
  String get applicationRemoveFailed => 'Remove failed upload';

  @override
  String get applicationSample => 'Verification sample';

  @override
  String get applicationPrivate => 'Uploaded · Private sample';

  @override
  String get applicationPreview => 'Preview sample';

  @override
  String get applicationRemove => 'Remove sample';

  @override
  String get applicationSave => 'Save draft';

  @override
  String get applicationSubmit => 'Submit application';

  @override
  String get applicationPreviewTitle => 'Verification sample preview';

  @override
  String get applicationInvalidName =>
      'Use up to 80 letters and numbers, including at least one letter.';

  @override
  String get applicationInvalidEmail => 'Enter a valid email before uploading.';

  @override
  String get applicationRoleRequired =>
      'Select at least one character specialty.';

  @override
  String get applicationDirectionRequired =>
      'Select at least one content specialty.';

  @override
  String get applicationAdultRequired => 'Confirm that you are at least 18.';

  @override
  String get applicationAgreementRequired =>
      'Read and accept the creator rules.';

  @override
  String get applicationMp4 => 'Select an MP4 video.';

  @override
  String get applicationTooLarge =>
      'Each video must be no larger than 15 MB. Compress it and try again.';

  @override
  String get applicationLimit => 'Upload no more than 10 samples.';

  @override
  String get applicationEmailUsed =>
      'This email is already used by another creator. Use a different email.';

  @override
  String get applicationInvalidFields =>
      'Check your name, specialties, email and agreement selections.';

  @override
  String get applicationProcessorBusy =>
      'Video checks are busy. Please try again later.';

  @override
  String get applicationLocked =>
      'This application is locked. Refresh to check its review status.';

  @override
  String get applicationVideoLimit =>
      'Remove a sample before adding another. The limit is 10.';

  @override
  String get applicationVideoInvalid =>
      'The video did not pass validation. Select a playable MP4 and try again.';

  @override
  String get applicationVideoRequired =>
      'Upload at least one video that passes validation.';

  @override
  String get applicationConflict =>
      'The application changed. Refresh and try again.';

  @override
  String get applicationPreviewFailed =>
      'Preview failed. Go back and try again.';

  @override
  String applicationGrade(String grade) {
    return 'Creator grade: $grade';
  }

  @override
  String applicationUploading(String name) {
    return 'Uploading and checking: $name';
  }

  @override
  String get applicationDirectionAction => 'Simple actions';

  @override
  String get applicationDirectionDance => 'Music and dance';

  @override
  String get applicationDirectionEffects => 'Visual effects';

  @override
  String get applicationDirectionGrowth => 'Character development';

  @override
  String get applicationGradeSilver => 'Silver';

  @override
  String get applicationGradeGold => 'Gold';

  @override
  String get applicationGradeDiamond => 'Diamond';

  @override
  String get applicationGradeMaster => 'Master';

  @override
  String get applicationGradeLegend => 'Legend';

  @override
  String get authTitle => 'Email sign-in';

  @override
  String get authExplanation =>
      'Sign in with your email to access your account on another device and receive service notifications. Signing in switches accounts; it does not merge their data. If an older account has no verified email, contact support for recovery.';

  @override
  String get authEmail => 'Email';

  @override
  String get authSend => 'Send code';

  @override
  String get authResend => 'Resend code';

  @override
  String get authSent => 'Code sent. It expires in 10 minutes.';

  @override
  String get authCode => '6-digit code';

  @override
  String get authChange => 'Change email';

  @override
  String get authVerify => 'Verify and sign in';

  @override
  String get authInvalidEmail => 'Enter a valid email address.';

  @override
  String get authInvalidCode => 'Enter the 6-digit code.';

  @override
  String authResendSeconds(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get appName => 'Hildors';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSystem => 'Follow system';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageFallback =>
      'Chinese variants use Simplified Chinese. Other unsupported languages use English.';

  @override
  String get languageSaveFailed =>
      'Could not save your language. Please try again.';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonSave => 'Save';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get errorNetwork =>
      'Unable to connect. Check your connection and try again.';

  @override
  String get errorSession => 'Please sign in again to continue.';

  @override
  String get errorPermission =>
      'This content is not available to your account.';

  @override
  String get errorConflict =>
      'This item has changed. Refresh it and try again.';

  @override
  String get errorTooLarge => 'This file is too large. Choose a smaller file.';

  @override
  String get errorRateLimit => 'Too many requests. Please try again later.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorEmailCode =>
      'Check your email and verification code. The code may have expired.';

  @override
  String get errorServiceUnavailable =>
      'This service is temporarily unavailable. Please try again later.';

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
  String get catalogCollection => 'Collection';

  @override
  String get catalogLibrary => 'Library';

  @override
  String get catalogMyCharacters => 'My characters';

  @override
  String get catalogLoadFailed => 'Unable to load the library';

  @override
  String get catalogCheckNetwork => 'Check your connection and try again.';

  @override
  String get catalogSearch => 'Search characters, videos or genres';

  @override
  String get catalogRefresh => 'Refresh library';

  @override
  String get catalogSource => 'Source';

  @override
  String get catalogFormat => 'Format';

  @override
  String get catalogGenre => 'Genre';

  @override
  String get catalogAll => 'All';

  @override
  String get catalogOfficial => 'By Hildors';

  @override
  String get catalogCreatorWorks => 'Creator content';

  @override
  String get catalogAnonymous => 'Anonymous creator';

  @override
  String get catalogSingle => 'Single video';

  @override
  String get catalogPackage => 'Character pack';

  @override
  String get catalogEmpty => 'No matching content';

  @override
  String get catalogClear => 'Clear filters';

  @override
  String get catalogResults => 'Results';

  @override
  String get catalogDescriptionMissing =>
      'Character description not yet available';

  @override
  String get catalogPackVideos => 'Videos in this pack';

  @override
  String get catalogVideo => 'Video';

  @override
  String get catalogNoPreview => 'Preview is currently unavailable';

  @override
  String get catalogDurationUnknown => 'Duration unavailable';

  @override
  String get catalogStoryMissing => 'No background story yet';

  @override
  String get catalogStory => 'Background story';

  @override
  String get catalogStoryCollapse => 'Collapse story';

  @override
  String get catalogStoryExpand => 'Read full story';

  @override
  String get catalogImageLoading => 'Loading image';

  @override
  String get catalogImageRetry => 'Image failed to load. Tap to retry';

  @override
  String get playerNoSource => 'No video available';

  @override
  String get playerBuffering => 'Buffering video…';

  @override
  String get playerLoading => 'Loading video…';

  @override
  String get playerSlow =>
      'Taking longer than expected. Check your connection or retry.';

  @override
  String get playerPause => 'Pause preview';

  @override
  String get playerPlay => 'Play preview';

  @override
  String get playerZoom => 'Pinch to zoom · Double-tap to reset';

  @override
  String get playerFailed => 'Playback failed. Please retry.';

  @override
  String get playerTimeout => 'Video loading timed out. Please retry.';

  @override
  String get playerLoadFailed => 'Video could not load. Please retry.';

  @override
  String get playerAuthFailed =>
      'Access could not be refreshed. Return to your submissions and try again.';

  @override
  String get downloadTitle => 'Save to my characters';

  @override
  String get downloadUnavailable => 'Purchases are not available';

  @override
  String get downloadFree => 'Download free';

  @override
  String get downloadInfo =>
      'Free videos can be downloaded and viewed offline in My characters. Purchases are not available.';

  @override
  String get downloadCancel => 'Cancel download';

  @override
  String get downloadAvailable => 'Download available videos';

  @override
  String get downloadDone => 'Downloaded';

  @override
  String get downloadRefresh => 'Refresh access';

  @override
  String get downloadView => 'View my characters';

  @override
  String get downloadDisabled =>
      'Downloads are temporarily unavailable. Try again later.';

  @override
  String get downloadSignIn => 'Please sign in again to download.';

  @override
  String get downloadDenied =>
      'This video is unavailable for download. Refresh access and try again.';

  @override
  String get downloadAccessFailed =>
      'Could not verify download access. Check your connection and account, then retry.';

  @override
  String get downloadFinished => 'Download complete. Saved to My characters.';

  @override
  String get downloadCancelled =>
      'Download cancelled. Completed videos remain in My characters.';

  @override
  String get downloadFailed =>
      'Download incomplete. Check your connection, storage and account access, then retry.';

  @override
  String catalogSummary(int count, int creators) {
    return '$count items · $creators creator items';
  }

  @override
  String catalogRefreshed(int count, int creators) {
    return 'Library refreshed: $count items, including $creators creator items';
  }

  @override
  String catalogCount(String format, int count) {
    return '$format · $count videos';
  }

  @override
  String catalogSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String catalogCreatorSpace(String name) {
    return '$name’s work';
  }

  @override
  String catalogPublished(int count) {
    return 'Published works · $count';
  }

  @override
  String downloadProgress(int count, int total) {
    return 'Downloaded $count/$total';
  }

  @override
  String downloadActive(String name) {
    return 'Downloading: $name';
  }

  @override
  String downloadPrice(String price) {
    return 'US\$ $price · Buy to download';
  }

  @override
  String get controlsDeleteTitle => 'Delete local downloads?';

  @override
  String get controlsDeleteNote =>
      'Remove this collection\'s downloaded files from the app. Your cloud access is retained so you can download again.';

  @override
  String get controlsCancel => 'Cancel';

  @override
  String get controlsDelete => 'Delete';

  @override
  String get controlsDeleteFailed => 'Could not delete. Please try again.';

  @override
  String get controlsDeleteLocal => 'Delete local downloads';

  @override
  String get controlsNoVideos =>
      'No videos are available for this character yet.';

  @override
  String get controlsPreviewLocal => 'Preview downloaded video';

  @override
  String get controlsExamples => 'Official sample collections · Select videos';

  @override
  String get controlsChooseList => 'Choose a playlist';

  @override
  String get controlsPendingNote =>
      'Videos are added to pending items first. They are not yet uploaded to the device.';

  @override
  String get controlsStartup => 'Daily display';

  @override
  String get controlsBluetooth => 'Music mode';

  @override
  String get controlsAddFailed => 'Could not add videos. Please try again.';

  @override
  String get controlsMyCharacters => 'My characters';

  @override
  String get controlsLoadFailed =>
      'Could not load your characters. Tap to retry.';

  @override
  String get controlsEmpty => 'No characters available yet';

  @override
  String get controlsEmptyNote =>
      'Download a character from the content library, then choose its videos.';

  @override
  String get controlsLibrary => 'Content library';

  @override
  String get controlsBrowse => 'Browse content library';

  @override
  String get controlsPickNote =>
      'Choose a character, then select videos for this playlist.';

  @override
  String get controlsListNote =>
      'Add character videos to Daily display or Music mode.';

  @override
  String get controlsUnavailable => 'No videos available';

  @override
  String get controlsSelect => 'Select videos';

  @override
  String get controlsAdd => 'Add to playlist';

  @override
  String get controlsControlTitle => 'Device controls';

  @override
  String get controlsBrightness => 'Brightness';

  @override
  String get controlsAngle => 'Angle (device units and range unconfirmed)';

  @override
  String get controlsSpeakerTitle => 'Set Bluetooth speaker name';

  @override
  String get controlsSpeakerName => 'Speaker name';

  @override
  String get controlsSave => 'Save';

  @override
  String get controlsSpeaker => 'Bluetooth speaker';

  @override
  String get controlsConnectSpeaker =>
      'Connect the device to read its speaker name.';

  @override
  String get controlsReading => 'Reading…';

  @override
  String get controlsNameUnknown => 'Name not loaded';

  @override
  String get controlsRefreshName => 'Refresh name';

  @override
  String get controlsEditName => 'Edit name';

  @override
  String get controlsDisconnected => 'Disconnected';

  @override
  String get controlsConnecting => 'Connecting…';

  @override
  String get controlsReconnecting => 'Reconnecting…';

  @override
  String get controlsConnected => 'Connected';

  @override
  String get controlsIp => 'Device IP';

  @override
  String get controlsPort => 'Default port: 8900';

  @override
  String get controlsStopReconnect => 'Stop reconnecting';

  @override
  String get controlsDisconnect => 'Disconnect';

  @override
  String get controlsConnect => 'Connect';

  @override
  String get controlsQuick => 'Quick controls';

  @override
  String get controlsPowerOn => 'Power on';

  @override
  String get controlsPowerOff => 'Power off';

  @override
  String get controlsPrevious => 'Previous';

  @override
  String get controlsPause => 'Pause';

  @override
  String get controlsPlay => 'Play';

  @override
  String get controlsNext => 'Next';

  @override
  String get controlsRefreshStatus => 'Refresh status';

  @override
  String get controlsStatus => 'Device status';

  @override
  String get controlsLan => 'Local network control';

  @override
  String get controlsMode => 'Operating mode';

  @override
  String get controlsAudioSource => 'Bluetooth audio source';

  @override
  String get controlsProtocol => 'Awaiting protocol support';

  @override
  String get controlsLocalPlayback => 'Device playback';

  @override
  String get controlsBluetoothWaiting => 'Waiting for Bluetooth';

  @override
  String get controlsBluetoothAudio => 'Bluetooth audio';

  @override
  String get controlsWaitingSource => 'Waiting for an audio source';

  @override
  String get controlsAudioPlaying => 'Audio playing';

  @override
  String get controlsAudioPaused => 'Audio paused';

  @override
  String get controlsWasDisconnected => 'Disconnected';

  @override
  String get controlsBatteryFull => 'Fully charged';

  @override
  String get controlsBattery => 'Device battery';

  @override
  String get controlsProtocolNote =>
      'The current protocol does not report operating mode or Bluetooth status. These indicators require updated device protocol support.';

  @override
  String controlsPackageCount(int count) {
    return 'Character collection · $count videos';
  }

  @override
  String controlsDownloaded(int count, int total) {
    return 'Downloaded $count/$total videos';
  }

  @override
  String controlsSeconds(int seconds) {
    return '$seconds seconds';
  }

  @override
  String controlsAddCount(int count) {
    return 'Add $count videos to pending items';
  }

  @override
  String controlsVideoCount(int count) {
    return '$count videos';
  }

  @override
  String controlsAdded(String list) {
    return 'Added to $list pending items. Not yet uploaded to the device.';
  }

  @override
  String controlsNamedPlaying(String name) {
    return '$name · Playing';
  }

  @override
  String controlsNamedPaused(String name) {
    return '$name · Paused';
  }

  @override
  String controlsCharging(int percent) {
    return '$percent% · Charging';
  }

  @override
  String get coreHome => 'Home';

  @override
  String get coreCollection => 'Collection';

  @override
  String get coreExplore => 'Explore';

  @override
  String get coreProfile => 'Profile';

  @override
  String get coreDeviceControl => 'Device controls';

  @override
  String get coreCustomCharacter => 'Customize your holographic character';

  @override
  String get corePlaylists => 'Device playlists';

  @override
  String get corePlaylistSubtitle => 'Display and music modes';

  @override
  String get coreDisplay => 'Display mode';

  @override
  String get coreStartupSubtitle => 'Manage content played at startup';

  @override
  String get coreMusic => 'Music mode';

  @override
  String get coreBluetoothSubtitle =>
      'Manage content played with Bluetooth audio';

  @override
  String get coreOnline => 'Online';

  @override
  String get coreDisconnected => 'Disconnected';

  @override
  String get coreDeviceConnected => 'Device connected';

  @override
  String get coreConnecting => 'Connecting…';

  @override
  String get coreReconnecting => 'Reconnecting…';

  @override
  String get coreDeviceDisconnected => 'Device disconnected';

  @override
  String get coreLanControl => 'Local network control · P20 / P11';

  @override
  String get coreConnectP20 => 'Connect P20';

  @override
  String get coreConnectionSettings => 'Connection settings';

  @override
  String get coreDeviceManagement => 'Device management';

  @override
  String get coreDevices => 'Devices';

  @override
  String get corePlaylist => 'Playlists';

  @override
  String get coreDeviceContent => 'Device content';

  @override
  String get coreCharacterAssets => 'Characters';

  @override
  String get coreCustomOrders => 'Custom orders';

  @override
  String get coreOrdersSubtitle =>
      'Track production and delivery. Find claimed characters in Collection.';

  @override
  String get coreCreatorCenter => 'Creator center';

  @override
  String get coreCreatorSubtitle =>
      'Applications, production tasks and earnings';

  @override
  String get coreSupport => 'Support';

  @override
  String get corePlaybackGuide => 'Playback modes';

  @override
  String get corePlaybackGuideSubtitle =>
      'Learn how display and music modes switch';

  @override
  String get coreLanHelp => 'Local network help';

  @override
  String get coreLanHelpSubtitle =>
      'Connect to a P20/P11 hotspot and troubleshoot';

  @override
  String get coreAppSettings => 'Device and app settings';

  @override
  String get coreAppSettingsSubtitle =>
      'Device options, playback preferences and version';

  @override
  String get coreAbout => 'About HILDORS';

  @override
  String get coreAboutSubtitle => 'Character Portal · P20/P11 support';

  @override
  String get corePlayerProfile => 'Player profile';

  @override
  String get coreLocalAccount => 'Local device profile · Stored on this device';

  @override
  String get coreDeviceSettings => 'Device settings';

  @override
  String get coreReadFailed =>
      'Could not read device status. Connect to the device Wi-Fi and try again.';

  @override
  String get coreSettingFailed =>
      'Could not apply the setting. Check the device connection and try again.';

  @override
  String get corePlaybackBehavior => 'Playback';

  @override
  String get coreLoopMode => 'Repeat mode';

  @override
  String get coreLoopSubtitle =>
      'Choose how the device repeats its current playlist';

  @override
  String get coreConnectToChange => 'Connect to read and change settings';

  @override
  String get coreDeviceInfo => 'Device information';

  @override
  String get coreLanCockpit => 'Local network device';

  @override
  String get coreNotRead => 'Not read yet';

  @override
  String get coreReadInfo => 'Read device information';

  @override
  String get coreHelp => 'Help';

  @override
  String get coreModesHelpSubtitle =>
      'Automatic switching between display and music modes';

  @override
  String get coreHotspotHelp => 'Device hotspot connection and troubleshooting';

  @override
  String get coreDeviceConnecting => 'Connecting to device';

  @override
  String get coreDeviceReconnecting => 'Restoring connection';

  @override
  String get coreCockpitOnline => 'Device online';

  @override
  String get coreGoHomeConnect => 'Go to Home to connect your P20 / P11';

  @override
  String get coreOpeningLan => 'Establishing local network control';

  @override
  String get coreRetryingLan =>
      'Connection interrupted. Retrying automatically';

  @override
  String get coreLanReady => 'Local network control connected';

  @override
  String get coreSync => 'Sync device status';

  @override
  String get coreSingleLoop => 'Repeat one';

  @override
  String get coreSequenceLoop => 'Repeat all';

  @override
  String get coreRandomLoop => 'Shuffle';

  @override
  String get coreSingleOnce => 'Play once';

  @override
  String get coreCheckWifi => 'Check your phone Wi-Fi';

  @override
  String get coreCheckWifiBody =>
      'Connect your phone to the P20 hotspot or the same router as your P20.';

  @override
  String get coreCheckAddress => 'Check the control address';

  @override
  String get coreCheckAddressBody =>
      'In hotspot mode, the default address is 192.168.4.1 and the TCP port is 8900.';

  @override
  String get coreLanPermission => 'Allow local network access';

  @override
  String get coreLanPermissionBody =>
      'On iOS, allow Local Network access. On Android, allow the requested nearby-device and network permissions.';

  @override
  String get coreReconnect => 'Reconnect';

  @override
  String get coreReconnectBody =>
      'Return to device controls and tap Connect. After an unexpected disconnection, the app retries after 1, 2, 4, 8, 15 and 30 seconds.';

  @override
  String get coreOfflineWifiHelp =>
      'A “No internet” message does not necessarily mean device control failed. Control can continue while your phone stays on the P20 local network.';

  @override
  String get coreLocalPlayback => 'Device playback';

  @override
  String get coreLocalPlaybackBody =>
      'P20 plays videos stored on the device, including their audio. Use this mode for startup playback, looping displays and fixed content.';

  @override
  String get coreBluetoothSpeaker => 'Bluetooth speaker';

  @override
  String get coreBluetoothSpeakerBody =>
      'A phone or computer sends audio to P20 over Bluetooth while P20 plays the video configured for Bluetooth mode.';

  @override
  String get coreSeparateConnections =>
      'Hildors controls P20 over local Wi-Fi. Local network control and Bluetooth audio are separate connections.';

  @override
  String get coreCharacterPortal => 'Character Portal';

  @override
  String get coreExploreSubtitle =>
      'Customize characters, share wishes and create.';

  @override
  String get coreWishSubtitle => 'Share wishes and follow licensing updates';

  @override
  String get coreCreatorExploreSubtitle => 'Applications, tasks and earnings';

  @override
  String get coreWish => 'Character wishes';

  @override
  String get coreCustomize => 'Customize your character';

  @override
  String get coreEnter => 'Open';

  @override
  String get coreCreatorFreeSubtitle =>
      'Apply for creator certification and publish free content';

  @override
  String get coreExploreFreeSubtitle =>
      'Explore opportunities to create and share free content.';

  @override
  String get coreConnectionFailed =>
      'Could not connect. Check the device Wi-Fi and connection settings, then try again.';

  @override
  String get coreSystemLabel => 'DEVICE SYSTEM';

  @override
  String get coreProfileLabel => 'PLAYER PROFILE';

  @override
  String get coreLocalLabel => 'LOCAL';

  @override
  String get corePilotLabel => 'HILDORS PILOT';

  @override
  String get coreServiceLabel => 'CORE SERVICE';

  @override
  String get coreCreatorLabel => 'CREATOR';

  @override
  String get coreOnlineLabel => 'ONLINE';

  @override
  String get coreConnectingLabel => 'CONNECTING';

  @override
  String get coreReconnectingLabel => 'RECONNECTING';

  @override
  String get coreOfflineLabel => 'OFFLINE';

  @override
  String get creatorWorkbench => 'Creator studio';

  @override
  String get creatorOriginal => 'Original content';

  @override
  String get creatorFreeNote =>
      'Upload a video or character collection for review. This version supports free submissions only. Content is published after approval.';

  @override
  String get creatorPublishingNote =>
      'Upload videos or character collections for review. Standard and verified creators publish free content; partners may set prices.';

  @override
  String get creatorSubmissions => 'Upload / My submissions';

  @override
  String get creatorTasks => 'Custom projects';

  @override
  String get creatorTasksNote =>
      'View available projects and ongoing custom orders';

  @override
  String get customPlansTitle => 'Custom videos';

  @override
  String get customOrdersTitle => 'My custom orders';

  @override
  String get customUnavailable =>
      'Store payments are not connected yet. No payment can be taken.';

  @override
  String customBase(String price) {
    return 'USD base reference: $price. Checkout uses the store price.';
  }

  @override
  String customSeconds(int seconds) {
    return '$seconds-second video';
  }

  @override
  String get customRequest => 'Send requirements for review';

  @override
  String get customName => 'Character / project name';

  @override
  String get customRequirements => 'Your requirements';

  @override
  String get customMaterials => 'Add reference images';

  @override
  String customMaterialCount(int count) {
    return '$count reference images';
  }

  @override
  String get customPrivacy =>
      'Reference materials are used to assess and produce this private order. Public display requires separate consent.';

  @override
  String get customConsent => 'I agree to use these materials for this order.';

  @override
  String get customValidation =>
      'Enter a project name and requirements, and confirm the material-use notice.';

  @override
  String get customImageError =>
      'Choose up to 8 JPG/PNG images, each no larger than 8 MB.';

  @override
  String get customSubmitted =>
      'Request submitted for review. No payment has been taken.';

  @override
  String get customTerms => 'Review the confirmed scope before payment';

  @override
  String get customContent => 'Deliverables';

  @override
  String get customPeriod => 'Delivery period';

  @override
  String get customRevisions => 'Revision scope';

  @override
  String get customRights => 'Usage rights';

  @override
  String get customAcceptTerms =>
      'I accept this confirmed scope and its terms.';

  @override
  String customPay(String price) {
    return 'Pay $price';
  }

  @override
  String get customRestore => 'Check unfinished purchases';

  @override
  String get customTestMode => 'TEST PAYMENT — no real charge';

  @override
  String get customAccept => 'Accept delivery';

  @override
  String get customRevise => 'Request revision';

  @override
  String get customRevisionNote => 'Describe the requested revision';

  @override
  String get customStatusReview => 'Requirements under review';

  @override
  String get customStatusInfo => 'More information needed';

  @override
  String get customStatusQuote => 'Scope confirmed; awaiting payment';

  @override
  String get customStatusMaking => 'In production';

  @override
  String get customStatusQc => 'Quality review';

  @override
  String get customStatusAccept => 'Ready for your review';

  @override
  String get customStatusDelivered => 'Delivered';

  @override
  String get customStatusRejected => 'Request declined';

  @override
  String get customStatusWithdrawn => 'Withdrawn / refunded';

  @override
  String get customPending =>
      'Payment is pending. Production starts only after server verification.';

  @override
  String get customEmpty => 'No items available yet.';

  @override
  String get customAudioNone => 'No audio — base package';

  @override
  String get customAudioMatched => 'Platform-matched audio';

  @override
  String get customAudioHelp =>
      'We match background music or simple sound effects to your video. No specific songs, voice-over or uploaded audio.';

  @override
  String customAudioTotal(String price) {
    return 'USD reference total: $price';
  }

  @override
  String customAudioRate(int percent) {
    return 'Audio matching surcharge: $percent%';
  }

  @override
  String get customSupplement => 'Update requirements and resubmit';

  @override
  String get customSupplementSaved =>
      'Updated requirements submitted for review.';

  @override
  String get customSaveDelivery => 'Save delivery to My characters';

  @override
  String get customSavedDelivery => 'Saved to My characters for offline use.';

  @override
  String get customSavingDelivery => 'Downloading private delivery…';

  @override
  String get customConfirmDelivery =>
      'Accept this version as the final delivery?';

  @override
  String customRevisionLimit(int used, int limit) {
    return 'Revision requests: $used of $limit';
  }

  @override
  String get customProgress => 'Production updates';

  @override
  String get deletionTitle => 'Delete account';

  @override
  String get deletionExplanation =>
      'Request deletion of your Hildors account and associated data. This submits a request for review; it does not delete data immediately or sign you out. You can check its status here or cancel while it is pending.';

  @override
  String get deletionSubmit => 'Request account deletion';

  @override
  String get deletionConfirm =>
      'Submit this deletion request? Your account remains active while the request is being reviewed.';

  @override
  String get deletionNone => 'No pending deletion request.';

  @override
  String get deletionReceived => 'Request received';

  @override
  String get deletionReview => 'Under review';

  @override
  String get deletionInformation => 'More information needed';

  @override
  String get deletionCancelled => 'Request cancelled';

  @override
  String get deletionCancel => 'Cancel deletion request';

  @override
  String get deletionRefresh => 'Refresh status';

  @override
  String deletionReference(String id) {
    return 'Request ID: $id';
  }

  @override
  String get devicePlayingDelete =>
      'Play a different video before deleting this one.';

  @override
  String get deviceDeleteTitle => 'Permanently delete this device file?';

  @override
  String get deviceDeleteIntro =>
      'This video will be permanently deleted from the holographic device:';

  @override
  String get deviceDeleteNote =>
      'This cannot be undone. Downloaded copies on your phone and purchase records will remain.';

  @override
  String get deviceCancel => 'Cancel';

  @override
  String get deviceDelete => 'Delete permanently';

  @override
  String get deviceVideoLibrary => 'Device videos';

  @override
  String get deviceRefresh => 'Refresh';

  @override
  String get deviceConnectFirst => 'Connect your device in Controls first.';

  @override
  String get deviceReadVideos => 'Load device videos';

  @override
  String get devicePlaying => 'Playing';

  @override
  String get devicePlay => 'Play';

  @override
  String get deviceMore => 'More actions';

  @override
  String get deviceDeleteFrom => 'Delete from device';

  @override
  String get frameSaved =>
      'Framing saved. The original video is unchanged; it has not been converted or uploaded.';

  @override
  String get frameSaveFailed => 'Could not save. Please try again.';

  @override
  String get frameTitle => 'Adjust circular framing';

  @override
  String get frameCircle => 'The circle marks the device display area.';

  @override
  String get frameInstructions =>
      'Pinch to zoom and drag to reposition. Play the full video to check that the character and movements stay inside the circle.';

  @override
  String get framePause => 'Pause preview';

  @override
  String get framePlay => 'Play preview';

  @override
  String get framePlaybackFailed => 'Playback failed. Go back and try again.';

  @override
  String get frameZoom => 'Zoom';

  @override
  String get frameFit => 'Fit whole frame';

  @override
  String get frameFill => 'Fill circle';

  @override
  String get frameReset => 'Reset';

  @override
  String get frameFitNote =>
      'Fit keeps the entire frame. Fill crops the edges.';

  @override
  String get frameRestoreFailed =>
      'Saved framing could not be loaded. Adjust and save it again.';

  @override
  String get frameSaving => 'Saving…';

  @override
  String get frameSave => 'Save framing';

  @override
  String get frameUnavailable => 'Convert and upload · Unavailable';

  @override
  String get framePending =>
      'Only framing is saved for now. Device video conversion is not yet available.';

  @override
  String get framePreviewFailed =>
      'Preview could not load. Go back and try again.';

  @override
  String deviceDeleted(String name) {
    return 'Deleted $name from the device.';
  }

  @override
  String frameTime(int position, int duration) {
    return '$position / $duration seconds';
  }

  @override
  String get governanceReport => 'Report content';

  @override
  String get governanceBlock => 'Block creator';

  @override
  String get governanceCopyright => 'Copyright infringement';

  @override
  String get governanceAbuse => 'Harassment or abuse';

  @override
  String get governanceSexual => 'Sexual content';

  @override
  String get governanceViolence => 'Violence';

  @override
  String get governanceSpam => 'Spam';

  @override
  String get governanceOther => 'Other';

  @override
  String get governanceDetails => 'Details (optional)';

  @override
  String get governanceReportNote =>
      'Your report will be sent to our review team. For copyright concerns, describe the original work and where it appears. Do not include sensitive personal information.';

  @override
  String get governanceCancel => 'Cancel';

  @override
  String get governanceSubmit => 'Submit report';

  @override
  String governanceReceived(String reference) {
    return 'Report received. Reference: $reference';
  }

  @override
  String get governanceBlockNote =>
      'Hide this creator’s content from your catalog for this account. You can unblock them in Reports and blocked creators.';

  @override
  String get governanceBlocked => 'Creator blocked.';

  @override
  String get governanceAuthError => 'Your session expired. Sign in again.';

  @override
  String get governanceUnavailableError =>
      'This content is no longer available.';

  @override
  String get governanceInvalidError => 'Check your report and try again.';

  @override
  String get governanceConflictError =>
      'This action is unavailable. Refresh and try again.';

  @override
  String get governanceNetworkError => 'Could not connect. Please try again.';

  @override
  String get governanceTitle => 'Reports and blocked creators';

  @override
  String get governanceRefresh => 'Refresh';

  @override
  String get governanceReports => 'My reports';

  @override
  String get governanceBlocks => 'Blocked creators';

  @override
  String get governanceEmpty => 'No items yet.';

  @override
  String get governanceUnblock => 'Unblock';

  @override
  String get governanceStatusReceived => 'Received';

  @override
  String get governanceStatusReview => 'Under review';

  @override
  String get governanceStatusAction => 'Action taken';

  @override
  String get governanceStatusNoViolation => 'No violation found';

  @override
  String get playlistFromCharacters => 'Choose from My characters';

  @override
  String get playlistChooseCharacter => 'Choose videos from your characters';

  @override
  String get playlistFromPhone => 'Import from phone';

  @override
  String get playlistFromDevice => 'Add existing device videos';

  @override
  String get playlistPickFailed =>
      'Could not select a video. Please try again.';

  @override
  String get playlistPendingSaveFailed =>
      'Pending items could not be saved and may be lost when you leave. Please retry.';

  @override
  String get playlistRetry => 'Retry';

  @override
  String get playlistReselectTitle => 'Select the source video again';

  @override
  String get playlistReselectNote =>
      'The file moved or its temporary cache was cleared. The playlist entry remains. Select the source again and confirm its framing.';

  @override
  String get playlistCancel => 'Cancel';

  @override
  String get playlistReselect => 'Select again';

  @override
  String get playlistReadFailed =>
      'Could not read the video. Please try again.';

  @override
  String get playlistOriginalTitle => 'Original video required';

  @override
  String get playlistOriginalNote =>
      'Only the filename is available on the device. Choose the original video from your phone to adjust its framing. Saving records only the framing; converting and uploading adds a new device file and keeps the original.';

  @override
  String get playlistChooseOriginal => 'Choose original video';

  @override
  String get playlistOriginalFailed =>
      'Could not read the original video. Please try again.';

  @override
  String get playlistRemovePending => 'Remove pending video?';

  @override
  String get playlistRemovePendingNote =>
      'Only this playlist entry will be removed. Phone and device videos are retained.';

  @override
  String get playlistRemove => 'Remove';

  @override
  String get playlistReadLocalFailed =>
      'Could not load the local playlist. Please retry.';

  @override
  String get playlistSaveLocalFailed =>
      'Could not save the local playlist. Please retry.';

  @override
  String get playlistAddDevice => 'Add from device library';

  @override
  String get playlistAllAdded => 'All device videos are already in this draft.';

  @override
  String get playlistConnectFirst => 'Connect the device before playing.';

  @override
  String get playlistNotUploaded =>
      'This video is not on the device. Conversion and upload are required before playback.';

  @override
  String get playlistRemoveTitle => 'Remove from playlist?';

  @override
  String get playlistRemoveList => 'Remove from playlist';

  @override
  String get playlistUndo => 'Undo';

  @override
  String get playlistTitle => 'Device playlists';

  @override
  String get playlistReadDevice => 'Read device videos';

  @override
  String get playlistStartup => 'Startup';

  @override
  String get playlistBluetooth => 'Bluetooth';

  @override
  String get playlistStartupNote =>
      'The device plays this playlist at startup.';

  @override
  String get playlistBluetoothNote =>
      'The device switches to this playlist when Bluetooth connects.';

  @override
  String get playlistLoop => 'Repeat mode';

  @override
  String get playlistListLoop => 'Repeat playlist';

  @override
  String get playlistSingleLoop => 'Repeat one';

  @override
  String get playlistOnce => 'Play once';

  @override
  String get playlistOrder => 'Playback order';

  @override
  String get playlistAddVideo => 'Add video';

  @override
  String get playlistPendingLoadFailed =>
      'Could not load pending items. Tap to retry.';

  @override
  String get playlistPending => 'Pending videos · Not uploaded to device';

  @override
  String get playlistPendingNote =>
      'Pending entries reference the original files. Conversion is not yet available. Keep source files in place after framing.';

  @override
  String get playlistConvertPending => 'Awaiting conversion · Not uploaded';

  @override
  String get playlistFrame => 'Adjust framing';

  @override
  String get playlistRemovePendingAction => 'Remove pending video';

  @override
  String get playlistEmpty => 'This playlist is empty';

  @override
  String get playlistFirst => 'Default first video';

  @override
  String get playlistUp => 'Move up';

  @override
  String get playlistDown => 'Move down';

  @override
  String get playlistRemoveDraft => 'Remove from draft';

  @override
  String get playlistSaveDevice => 'Save to device · Awaiting protocol support';

  @override
  String get playlistRecovery => 'After Bluetooth disconnects';

  @override
  String get playlistRecoveryNote =>
      'Resume the previous device video when supported. Awaiting protocol confirmation.';

  @override
  String get playlistDisconnected => 'Device disconnected';

  @override
  String get playlistReadDeviceFailed =>
      'Network connected · Could not read device';

  @override
  String get playlistReadDeviceReady => 'Network connected · Tap to read';

  @override
  String get playlistReadNote =>
      'Read device content to verify the control connection.';

  @override
  String get playlistConnectNote =>
      'Connect to device Wi-Fi, then read its playlist.';

  @override
  String get playlistRead => 'Read';

  @override
  String playlistSourceTitle(String name) {
    return '$name · Original framing';
  }

  @override
  String playlistSent(String name) {
    return 'Sent to device: $name';
  }

  @override
  String playlistRemoveNote(String name) {
    return 'Remove “$name” from this playlist only. Phone and device files are retained.';
  }

  @override
  String playlistRemoved(String name) {
    return 'Removed $name from the playlist';
  }

  @override
  String playlistCount(int count) {
    return '$count videos';
  }

  @override
  String playlistDeviceCount(int count) {
    return 'Device responding · $count videos';
  }

  @override
  String get submissionDraftSaved =>
      'Draft saved. Upload your videos, then submit for review.';

  @override
  String get submissionTitle => 'My submissions';

  @override
  String get submissionRefresh => 'Refresh submissions';

  @override
  String get submissionCreate => 'Create submission';

  @override
  String get submissionEmpty =>
      'No submissions yet. Create a draft, upload your videos and submit after validation.';

  @override
  String get submissionUpdated => 'Submission updated.';

  @override
  String get submissionFree => 'Free';

  @override
  String get submissionPaid => 'Paid';

  @override
  String get submissionPrice => 'Price (USD)';

  @override
  String get submissionDecimals => 'Up to two decimal places';

  @override
  String get submissionInvalidPrice =>
      'Enter a positive USD price with up to two decimal places.';

  @override
  String get submissionReviewNote =>
      'All videos require review before publication.';

  @override
  String get submissionCancel => 'Cancel';

  @override
  String get submissionSavePrice => 'Save price';

  @override
  String get submissionSubmitted =>
      'Submitted for review. Editing is locked while under review.';

  @override
  String get submissionPartnerNote =>
      'Partners may publish free or paid videos. All content requires review.';

  @override
  String get submissionFreeNote =>
      'Submit free videos or character collections for review.';

  @override
  String get submissionCharacterPackage => 'Character collection';

  @override
  String get submissionSingleVideo => 'Single video';

  @override
  String get submissionRejectedReason => 'Changes requested';

  @override
  String get submissionReviewFeedback => 'Review feedback';

  @override
  String get submissionName => 'Title';

  @override
  String get submissionNameRequired => 'Enter a title.';

  @override
  String get submissionFormat => 'Content format';

  @override
  String get submissionSingle => 'Single video';

  @override
  String get submissionPackage => 'Video collection';

  @override
  String get submissionTags => 'Content tags';

  @override
  String get submissionNoTags => 'Content tags are not available yet.';

  @override
  String get submissionStory => 'Background story';

  @override
  String get submissionStoryRequired => 'Enter a background story.';

  @override
  String get submissionVideos => 'Videos';

  @override
  String get submissionAddVideo => 'Add video';

  @override
  String get submissionRemoveVideo => 'Remove video';

  @override
  String get submissionVideoNameRequired => 'Enter a video title.';

  @override
  String get submissionSaveDraft => 'Save draft';

  @override
  String get submissionSaveInfo => 'Save details';

  @override
  String get submissionCoverUploaded => 'Cover uploaded';

  @override
  String get submissionCover => 'Collection cover';

  @override
  String get submissionCoverTypes => 'JPG or PNG';

  @override
  String get submissionReplace => 'Replace';

  @override
  String get submissionUpload => 'Upload';

  @override
  String get submissionSetPrice => 'Set price';

  @override
  String get submissionMakeFree => 'Make free';

  @override
  String get submissionReplaceMp4 => 'Replace MP4';

  @override
  String get submissionUploadMp4 => 'Upload MP4';

  @override
  String get submissionCheckVideo => 'Validate video';

  @override
  String get submissionResubmit => 'Resubmit for review';

  @override
  String get submissionSubmit => 'Submit for review';

  @override
  String get submissionRequirements =>
      'Validate every video before submitting. Collections also require a cover.';

  @override
  String get submissionInfo => 'Content details';

  @override
  String get submissionNoStory => 'No background story yet.';

  @override
  String get submissionRetry => 'Retry';

  @override
  String get submissionPending => 'Under review';

  @override
  String get submissionPublished => 'Published';

  @override
  String get submissionApproved => 'Approved, awaiting publication';

  @override
  String get submissionRejected => 'Changes requested';

  @override
  String get submissionDraft => 'Draft';

  @override
  String get submissionNoMedia => 'No video uploaded';

  @override
  String get submissionChecked => 'Validation passed';

  @override
  String get submissionProcessing => 'Validating video';

  @override
  String get submissionFailed =>
      'Validation failed. Replace the video and try again.';

  @override
  String get submissionWaiting => 'Uploaded, awaiting validation';

  @override
  String get submissionApprovalError =>
      'Creator access is not approved or is suspended. Check the verification page.';

  @override
  String get submissionDataError =>
      'The submission data could not be read. Refresh and try again.';

  @override
  String get submissionLoadError =>
      'Could not load submissions. Please try again later.';

  @override
  String get submissionSessionError => 'Your session expired. Sign in again.';

  @override
  String get submissionAccessError =>
      'An active verified creator account is required.';

  @override
  String get submissionPaidError =>
      'Paid pricing is unavailable for this account. Make the video free before submitting.';

  @override
  String get submissionPriceError =>
      'Enter a valid USD price with up to two decimal places.';

  @override
  String get submissionConflictError =>
      'The submission changed. Refresh and try again.';

  @override
  String get submissionMediaError => 'Upload and validate every video first.';

  @override
  String get submissionCoverError => 'Upload a collection cover first.';

  @override
  String get submissionTagError =>
      'Some tags are no longer available. Refresh and select again.';

  @override
  String get submissionServerError =>
      'The service is unavailable. Please try again later.';

  @override
  String get submissionRequestError =>
      'The action could not finish. Check your content and try again.';

  @override
  String get submissionAccountChanged =>
      'Your account changed. Refresh submissions.';

  @override
  String get submissionPreviewError =>
      'The video is not uploaded or preview is unavailable.';

  @override
  String submissionVideoPrice(String name) {
    return 'Video price · $name';
  }

  @override
  String submissionVideoName(int index) {
    return 'Video $index title';
  }

  @override
  String submissionLegacyTag(String name) {
    return '$name (legacy)';
  }

  @override
  String get p20Refresh => 'Refresh device playlist';

  @override
  String get p20Daily => 'A Daily';

  @override
  String get p20Bluetooth => 'B Bluetooth';

  @override
  String get p20ConnectNote =>
      'Connect to see the playlist stored on your device';

  @override
  String get p20ConnectWifi =>
      'Join the device Wi-Fi on your phone, then tap Connect device.';

  @override
  String get p20Connecting => 'Connecting…';

  @override
  String get p20Connect => 'Connect device';

  @override
  String get p20Reading => 'Reading device playlist…';

  @override
  String get p20ReadFailed => 'Could not read the device playlist';

  @override
  String get p20Mode => 'Playback mode (shared by A/B)';

  @override
  String get p20OrderNote =>
      'The order comes from your device. Moving a video updates the device and reads back the confirmed order.';

  @override
  String get p20Empty => 'This device playlist is empty';

  @override
  String get p20Pending => 'Videos ready to upload';

  @override
  String get p20PendingNote =>
      'These videos are waiting on your phone and have not been uploaded to the device.';

  @override
  String get p20Unconfirmed =>
      'The device did not confirm the change. Its current state has been refreshed. Check it and try again.';

  @override
  String get p20UploadEntry => 'Open from a device playlist to upload';

  @override
  String get p20UploadAction => 'Convert and upload';

  @override
  String get p20FramingNote =>
      'Saving records only the framing. Tap Convert and upload to prepare and transfer the device files.';

  @override
  String p20ConnectedCount(int count) {
    return 'Device connected · $count videos';
  }

  @override
  String get p20UploadTitle => 'Upload to device';

  @override
  String get p20UploadStart => 'Prepare and upload';

  @override
  String get p20UploadCancel => 'Cancel upload';

  @override
  String get p20UploadClose => 'Back to playlist';

  @override
  String get p20UploadDisconnected =>
      'Connect to the device from Home before uploading.';

  @override
  String get p20UploadDaily =>
      'A daily playlist accepts videos with or without sound. With audio: extract MP3, convert, upload audio then video. Without audio: convert and upload video only.';

  @override
  String get p20UploadBluetooth =>
      'B Bluetooth playlist accepts videos with or without sound. Convert and upload video only; source audio is ignored.';

  @override
  String get p20UploadSettings => '298 × 298 · 20 fps · Current framing';

  @override
  String get p20UploadDownloadFirst =>
      'Download this video to My Characters before uploading to the device.';

  @override
  String get p20UploadFailed =>
      'Preparation or upload failed. Check the video, device connection and storage, then try again.';

  @override
  String get p20UploadConfirmedProgress => 'Confirmed by the device';

  @override
  String get p20UploadFailureStageLabel => 'Failed during';

  @override
  String get p20UploadConfirmedLabel => 'Confirmed';

  @override
  String get p20UploadBytesLabel => 'bytes';

  @override
  String get p20UploadBusy => 'Device is busy. Try again shortly.';

  @override
  String get p20UploadWriteFailed =>
      'Device could not write the file. Check its storage card.';

  @override
  String get p20UploadAlreadyExists => 'The file already exists on the device.';

  @override
  String get p20UploadStorageFull => 'Device storage or playlist is full.';

  @override
  String get p20UploadBatteryLow =>
      'Device battery is too low. Charge it and retry.';

  @override
  String get p20UploadRejected => 'Device rejected the file.';

  @override
  String get p20UploadConfirmationTimeout =>
      'Device confirmation timed out. Note the stage and progress below, then reconnect.';

  @override
  String get p20UploadProcessingTimeout =>
      'Media processing timed out. Try a shorter video.';

  @override
  String get p20UploadConnectionLost =>
      'Device connection was lost. Reconnect and retry.';

  @override
  String get p20UploadLocalFileError =>
      'Cannot read or write local files. Check the source and available phone storage.';

  @override
  String get p20UploadInvalidReply =>
      'Device reply or progress sequence did not match. Check the firmware protocol.';

  @override
  String get p20UploadPartial =>
      'Audio was uploaded but video did not finish. No device files have been deleted or automatically retried.';

  @override
  String get p20UploadRefreshFailed =>
      'The device confirmed the upload, but the playlist could not be refreshed. Reconnect and refresh; do not upload again.';

  @override
  String get p20UploadCleanupPending =>
      'Temporary files are still in use and have been retained.';

  @override
  String get p20UploadWaitingAcceptance => 'Waiting for upload acceptance';

  @override
  String get p20UploadTransferring => 'Transferring file';

  @override
  String get p20UploadWaitingCompletion =>
      'Waiting for completion confirmation';

  @override
  String get p20UploadConfirmedCompletion => 'Device confirmed completion';

  @override
  String get p20UploadReady => 'Ready';

  @override
  String get p20UploadExtractingAudio =>
      'Checking and extracting audio if present';

  @override
  String get p20UploadConvertingVideo => 'Converting video';

  @override
  String get p20UploadUploadingAudio => 'Uploading audio';

  @override
  String get p20UploadUploadingVideo => 'Uploading video';

  @override
  String get p20UploadRefreshing => 'Refreshing playlist';

  @override
  String get p20UploadComplete => 'Upload complete';

  @override
  String get p20UploadIncomplete => 'Upload incomplete';

  @override
  String get p20UploadCancelled => 'Cancelled';

  @override
  String get p20SingleOnce => 'Play once';

  @override
  String p20UploadFailureStage(String stage) {
    return 'Failed during: $stage';
  }

  @override
  String p20UploadTransferDetails(String phase, int acknowledged, int total) {
    return '$phase · Confirmed $acknowledged / $total bytes';
  }

  @override
  String get creatorMediaOpenFailed =>
      'Unable to open this video. Refresh your submissions and try again.';

  @override
  String creatorMediaPreviewLabel(String title) {
    return 'Preview video: $title';
  }

  @override
  String get creatorMediaThumbnailPending =>
      'Thumbnail not ready. Tap to preview.';

  @override
  String get creatorMediaPreview => 'Preview video';
}
