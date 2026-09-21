import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @accountGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest account'**
  String get accountGuest;

  /// No description provided for @accountNone.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get accountNone;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out on all devices'**
  String get accountSignOut;

  /// No description provided for @accountSignOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'This signs out your account on every device. It does not delete your account or local videos. Cloud content may require you to sign in again.'**
  String get accountSignOutConfirm;

  /// No description provided for @accountGuestWarning.
  ///
  /// In en, this message translates to:
  /// **'This guest account has no verified email. Signing out may prevent you from recovering its cloud content. Verify an email before signing out.'**
  String get accountGuestWarning;

  /// No description provided for @accountSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out on all devices.'**
  String get accountSignedOut;

  /// No description provided for @accountCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get accountCancel;

  /// No description provided for @applicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Creator verification'**
  String get applicationTitle;

  /// No description provided for @applicationRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh review status'**
  String get applicationRefresh;

  /// No description provided for @applicationRetry.
  ///
  /// In en, this message translates to:
  /// **'Refresh and retry'**
  String get applicationRetry;

  /// No description provided for @applicationLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your application. Refresh to continue.'**
  String get applicationLoadFailed;

  /// No description provided for @applicationNoTags.
  ///
  /// In en, this message translates to:
  /// **'Character categories are not available yet. Please try again later.'**
  String get applicationNoTags;

  /// No description provided for @applicationApproved.
  ///
  /// In en, this message translates to:
  /// **'Verified creator'**
  String get applicationApproved;

  /// No description provided for @applicationOpenStudio.
  ///
  /// In en, this message translates to:
  /// **'Open creator studio'**
  String get applicationOpenStudio;

  /// No description provided for @applicationPending.
  ///
  /// In en, this message translates to:
  /// **'Application under review'**
  String get applicationPending;

  /// No description provided for @applicationSuspended.
  ///
  /// In en, this message translates to:
  /// **'Creator access suspended'**
  String get applicationSuspended;

  /// No description provided for @applicationReviewNote.
  ///
  /// In en, this message translates to:
  /// **'The team reviews applications manually. Refresh to check your status.'**
  String get applicationReviewNote;

  /// No description provided for @applicationRejected.
  ///
  /// In en, this message translates to:
  /// **'Update your application using the review feedback, then resubmit.'**
  String get applicationRejected;

  /// No description provided for @applicationRoles.
  ///
  /// In en, this message translates to:
  /// **'Character specialties'**
  String get applicationRoles;

  /// No description provided for @applicationDirections.
  ///
  /// In en, this message translates to:
  /// **'Content specialties'**
  String get applicationDirections;

  /// No description provided for @applicationName.
  ///
  /// In en, this message translates to:
  /// **'Creator display name'**
  String get applicationName;

  /// No description provided for @applicationNameHint.
  ///
  /// In en, this message translates to:
  /// **'For example, NovaStudio or Nova2026'**
  String get applicationNameHint;

  /// No description provided for @applicationNameRule.
  ///
  /// In en, this message translates to:
  /// **'Use letters and numbers, including at least one letter. Maximum 80 characters.'**
  String get applicationNameRule;

  /// No description provided for @applicationEmail.
  ///
  /// In en, this message translates to:
  /// **'Email (creator identifier)'**
  String get applicationEmail;

  /// No description provided for @applicationRegion.
  ///
  /// In en, this message translates to:
  /// **'Creator location'**
  String get applicationRegion;

  /// No description provided for @applicationChina.
  ///
  /// In en, this message translates to:
  /// **'Mainland China'**
  String get applicationChina;

  /// No description provided for @applicationUs.
  ///
  /// In en, this message translates to:
  /// **'United States'**
  String get applicationUs;

  /// No description provided for @applicationEea.
  ///
  /// In en, this message translates to:
  /// **'European Economic Area'**
  String get applicationEea;

  /// No description provided for @applicationUk.
  ///
  /// In en, this message translates to:
  /// **'United Kingdom'**
  String get applicationUk;

  /// No description provided for @applicationJapan.
  ///
  /// In en, this message translates to:
  /// **'Japan'**
  String get applicationJapan;

  /// No description provided for @applicationHk.
  ///
  /// In en, this message translates to:
  /// **'Hong Kong'**
  String get applicationHk;

  /// No description provided for @applicationMo.
  ///
  /// In en, this message translates to:
  /// **'Macao'**
  String get applicationMo;

  /// No description provided for @applicationTw.
  ///
  /// In en, this message translates to:
  /// **'Taiwan'**
  String get applicationTw;

  /// No description provided for @applicationAsia.
  ///
  /// In en, this message translates to:
  /// **'Other Asian region'**
  String get applicationAsia;

  /// No description provided for @applicationOther.
  ///
  /// In en, this message translates to:
  /// **'Other region'**
  String get applicationOther;

  /// No description provided for @applicationAdult.
  ///
  /// In en, this message translates to:
  /// **'I am at least 18 years old'**
  String get applicationAdult;

  /// No description provided for @applicationAgreement.
  ///
  /// In en, this message translates to:
  /// **'I agree to the creator rules, confidentiality requirements and rules against off-platform transactions'**
  String get applicationAgreement;

  /// No description provided for @applicationWorks.
  ///
  /// In en, this message translates to:
  /// **'Videos I created'**
  String get applicationWorks;

  /// No description provided for @applicationWorkNote.
  ///
  /// In en, this message translates to:
  /// **'Upload 1–10 MP4 videos you created, up to 15 MB each. These samples are private and used only for verification. The team assesses their quantity, quality and creativity.'**
  String get applicationWorkNote;

  /// No description provided for @applicationUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload my work'**
  String get applicationUpload;

  /// No description provided for @applicationUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. The video was not added.'**
  String get applicationUploadFailed;

  /// No description provided for @applicationRetryUpload.
  ///
  /// In en, this message translates to:
  /// **'Retry upload'**
  String get applicationRetryUpload;

  /// No description provided for @applicationRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Remove failed upload'**
  String get applicationRemoveFailed;

  /// No description provided for @applicationSample.
  ///
  /// In en, this message translates to:
  /// **'Verification sample'**
  String get applicationSample;

  /// No description provided for @applicationPrivate.
  ///
  /// In en, this message translates to:
  /// **'Uploaded · Private sample'**
  String get applicationPrivate;

  /// No description provided for @applicationPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview sample'**
  String get applicationPreview;

  /// No description provided for @applicationRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove sample'**
  String get applicationRemove;

  /// No description provided for @applicationSave.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get applicationSave;

  /// No description provided for @applicationSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit application'**
  String get applicationSubmit;

  /// No description provided for @applicationPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification sample preview'**
  String get applicationPreviewTitle;

  /// No description provided for @applicationInvalidName.
  ///
  /// In en, this message translates to:
  /// **'Use up to 80 letters and numbers, including at least one letter.'**
  String get applicationInvalidName;

  /// No description provided for @applicationInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email before uploading.'**
  String get applicationInvalidEmail;

  /// No description provided for @applicationRoleRequired.
  ///
  /// In en, this message translates to:
  /// **'Select at least one character specialty.'**
  String get applicationRoleRequired;

  /// No description provided for @applicationDirectionRequired.
  ///
  /// In en, this message translates to:
  /// **'Select at least one content specialty.'**
  String get applicationDirectionRequired;

  /// No description provided for @applicationAdultRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm that you are at least 18.'**
  String get applicationAdultRequired;

  /// No description provided for @applicationAgreementRequired.
  ///
  /// In en, this message translates to:
  /// **'Read and accept the creator rules.'**
  String get applicationAgreementRequired;

  /// No description provided for @applicationMp4.
  ///
  /// In en, this message translates to:
  /// **'Select an MP4 video.'**
  String get applicationMp4;

  /// No description provided for @applicationTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Each video must be no larger than 15 MB. Compress it and try again.'**
  String get applicationTooLarge;

  /// No description provided for @applicationLimit.
  ///
  /// In en, this message translates to:
  /// **'Upload no more than 10 samples.'**
  String get applicationLimit;

  /// No description provided for @applicationEmailUsed.
  ///
  /// In en, this message translates to:
  /// **'This email is already used by another creator. Use a different email.'**
  String get applicationEmailUsed;

  /// No description provided for @applicationInvalidFields.
  ///
  /// In en, this message translates to:
  /// **'Check your name, specialties, email and agreement selections.'**
  String get applicationInvalidFields;

  /// No description provided for @applicationProcessorBusy.
  ///
  /// In en, this message translates to:
  /// **'Video checks are busy. Please try again later.'**
  String get applicationProcessorBusy;

  /// No description provided for @applicationLocked.
  ///
  /// In en, this message translates to:
  /// **'This application is locked. Refresh to check its review status.'**
  String get applicationLocked;

  /// No description provided for @applicationVideoLimit.
  ///
  /// In en, this message translates to:
  /// **'Remove a sample before adding another. The limit is 10.'**
  String get applicationVideoLimit;

  /// No description provided for @applicationVideoInvalid.
  ///
  /// In en, this message translates to:
  /// **'The video did not pass validation. Select a playable MP4 and try again.'**
  String get applicationVideoInvalid;

  /// No description provided for @applicationVideoRequired.
  ///
  /// In en, this message translates to:
  /// **'Upload at least one video that passes validation.'**
  String get applicationVideoRequired;

  /// No description provided for @applicationConflict.
  ///
  /// In en, this message translates to:
  /// **'The application changed. Refresh and try again.'**
  String get applicationConflict;

  /// No description provided for @applicationPreviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Preview failed. Go back and try again.'**
  String get applicationPreviewFailed;

  /// No description provided for @applicationGrade.
  ///
  /// In en, this message translates to:
  /// **'Creator grade: {grade}'**
  String applicationGrade(String grade);

  /// No description provided for @applicationUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading and checking: {name}'**
  String applicationUploading(String name);

  /// No description provided for @applicationDirectionAction.
  ///
  /// In en, this message translates to:
  /// **'Simple actions'**
  String get applicationDirectionAction;

  /// No description provided for @applicationDirectionDance.
  ///
  /// In en, this message translates to:
  /// **'Music and dance'**
  String get applicationDirectionDance;

  /// No description provided for @applicationDirectionEffects.
  ///
  /// In en, this message translates to:
  /// **'Visual effects'**
  String get applicationDirectionEffects;

  /// No description provided for @applicationDirectionGrowth.
  ///
  /// In en, this message translates to:
  /// **'Character development'**
  String get applicationDirectionGrowth;

  /// No description provided for @applicationGradeSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get applicationGradeSilver;

  /// No description provided for @applicationGradeGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get applicationGradeGold;

  /// No description provided for @applicationGradeDiamond.
  ///
  /// In en, this message translates to:
  /// **'Diamond'**
  String get applicationGradeDiamond;

  /// No description provided for @applicationGradeMaster.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get applicationGradeMaster;

  /// No description provided for @applicationGradeLegend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get applicationGradeLegend;

  /// No description provided for @authTitle.
  ///
  /// In en, this message translates to:
  /// **'Email sign-in'**
  String get authTitle;

  /// No description provided for @authExplanation.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your email to access your account on another device and receive service notifications. Signing in switches accounts; it does not merge their data. If an older account has no verified email, contact support for recovery.'**
  String get authExplanation;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authSend.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get authSend;

  /// No description provided for @authResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authResend;

  /// No description provided for @authSent.
  ///
  /// In en, this message translates to:
  /// **'Code sent. It expires in 10 minutes.'**
  String get authSent;

  /// No description provided for @authCode.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get authCode;

  /// No description provided for @authChange.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get authChange;

  /// No description provided for @authVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify and sign in'**
  String get authVerify;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authInvalidEmail;

  /// No description provided for @authInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code.'**
  String get authInvalidCode;

  /// No description provided for @authResendSeconds.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String authResendSeconds(int seconds);

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Hildors'**
  String get appName;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get languageChinese;

  /// No description provided for @languageFallback.
  ///
  /// In en, this message translates to:
  /// **'Chinese variants use Simplified Chinese. Other unsupported languages use English.'**
  String get languageFallback;

  /// No description provided for @languageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your language. Please try again.'**
  String get languageSaveFailed;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect. Check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorSession.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to continue.'**
  String get errorSession;

  /// No description provided for @errorPermission.
  ///
  /// In en, this message translates to:
  /// **'This content is not available to your account.'**
  String get errorPermission;

  /// No description provided for @errorConflict.
  ///
  /// In en, this message translates to:
  /// **'This item has changed. Refresh it and try again.'**
  String get errorConflict;

  /// No description provided for @errorTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This file is too large. Choose a smaller file.'**
  String get errorTooLarge;

  /// No description provided for @errorRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again later.'**
  String get errorRateLimit;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorEmailCode.
  ///
  /// In en, this message translates to:
  /// **'Check your email and verification code. The code may have expired.'**
  String get errorEmailCode;

  /// No description provided for @errorServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This service is temporarily unavailable. Please try again later.'**
  String get errorServiceUnavailable;

  /// No description provided for @fileBytes.
  ///
  /// In en, this message translates to:
  /// **'{value} B'**
  String fileBytes(String value);

  /// No description provided for @fileKilobytes.
  ///
  /// In en, this message translates to:
  /// **'{value} KB'**
  String fileKilobytes(String value);

  /// No description provided for @fileMegabytes.
  ///
  /// In en, this message translates to:
  /// **'{value} MB'**
  String fileMegabytes(String value);

  /// No description provided for @catalogCollection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get catalogCollection;

  /// No description provided for @catalogLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get catalogLibrary;

  /// No description provided for @catalogMyCharacters.
  ///
  /// In en, this message translates to:
  /// **'My characters'**
  String get catalogMyCharacters;

  /// No description provided for @catalogLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the library'**
  String get catalogLoadFailed;

  /// No description provided for @catalogCheckNetwork.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get catalogCheckNetwork;

  /// No description provided for @catalogSearch.
  ///
  /// In en, this message translates to:
  /// **'Search characters, videos or genres'**
  String get catalogSearch;

  /// No description provided for @catalogRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh library'**
  String get catalogRefresh;

  /// No description provided for @catalogSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get catalogSource;

  /// No description provided for @catalogFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get catalogFormat;

  /// No description provided for @catalogGenre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get catalogGenre;

  /// No description provided for @catalogAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get catalogAll;

  /// No description provided for @catalogOfficial.
  ///
  /// In en, this message translates to:
  /// **'By Hildors'**
  String get catalogOfficial;

  /// No description provided for @catalogCreatorWorks.
  ///
  /// In en, this message translates to:
  /// **'Creator content'**
  String get catalogCreatorWorks;

  /// No description provided for @catalogAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous creator'**
  String get catalogAnonymous;

  /// No description provided for @catalogSingle.
  ///
  /// In en, this message translates to:
  /// **'Single video'**
  String get catalogSingle;

  /// No description provided for @catalogPackage.
  ///
  /// In en, this message translates to:
  /// **'Character pack'**
  String get catalogPackage;

  /// No description provided for @catalogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching content'**
  String get catalogEmpty;

  /// No description provided for @catalogClear.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get catalogClear;

  /// No description provided for @catalogResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get catalogResults;

  /// No description provided for @catalogDescriptionMissing.
  ///
  /// In en, this message translates to:
  /// **'Character description not yet available'**
  String get catalogDescriptionMissing;

  /// No description provided for @catalogPackVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos in this pack'**
  String get catalogPackVideos;

  /// No description provided for @catalogVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get catalogVideo;

  /// No description provided for @catalogNoPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview is currently unavailable'**
  String get catalogNoPreview;

  /// No description provided for @catalogDurationUnknown.
  ///
  /// In en, this message translates to:
  /// **'Duration unavailable'**
  String get catalogDurationUnknown;

  /// No description provided for @catalogStoryMissing.
  ///
  /// In en, this message translates to:
  /// **'No background story yet'**
  String get catalogStoryMissing;

  /// No description provided for @catalogStory.
  ///
  /// In en, this message translates to:
  /// **'Background story'**
  String get catalogStory;

  /// No description provided for @catalogStoryCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse story'**
  String get catalogStoryCollapse;

  /// No description provided for @catalogStoryExpand.
  ///
  /// In en, this message translates to:
  /// **'Read full story'**
  String get catalogStoryExpand;

  /// No description provided for @catalogImageLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading image'**
  String get catalogImageLoading;

  /// No description provided for @catalogImageRetry.
  ///
  /// In en, this message translates to:
  /// **'Image failed to load. Tap to retry'**
  String get catalogImageRetry;

  /// No description provided for @playerNoSource.
  ///
  /// In en, this message translates to:
  /// **'No video available'**
  String get playerNoSource;

  /// No description provided for @playerBuffering.
  ///
  /// In en, this message translates to:
  /// **'Buffering video…'**
  String get playerBuffering;

  /// No description provided for @playerLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading video…'**
  String get playerLoading;

  /// No description provided for @playerSlow.
  ///
  /// In en, this message translates to:
  /// **'Taking longer than expected. Check your connection or retry.'**
  String get playerSlow;

  /// No description provided for @playerPause.
  ///
  /// In en, this message translates to:
  /// **'Pause preview'**
  String get playerPause;

  /// No description provided for @playerPlay.
  ///
  /// In en, this message translates to:
  /// **'Play preview'**
  String get playerPlay;

  /// No description provided for @playerZoom.
  ///
  /// In en, this message translates to:
  /// **'Pinch to zoom · Double-tap to reset'**
  String get playerZoom;

  /// No description provided for @playerFailed.
  ///
  /// In en, this message translates to:
  /// **'Playback failed. Please retry.'**
  String get playerFailed;

  /// No description provided for @playerTimeout.
  ///
  /// In en, this message translates to:
  /// **'Video loading timed out. Please retry.'**
  String get playerTimeout;

  /// No description provided for @playerLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Video could not load. Please retry.'**
  String get playerLoadFailed;

  /// No description provided for @playerAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Access could not be refreshed. Return to your submissions and try again.'**
  String get playerAuthFailed;

  /// No description provided for @downloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Save to my characters'**
  String get downloadTitle;

  /// No description provided for @downloadUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Purchases are not available'**
  String get downloadUnavailable;

  /// No description provided for @downloadFree.
  ///
  /// In en, this message translates to:
  /// **'Download free'**
  String get downloadFree;

  /// No description provided for @downloadInfo.
  ///
  /// In en, this message translates to:
  /// **'Free videos can be downloaded and viewed offline in My characters. Purchases are not available.'**
  String get downloadInfo;

  /// No description provided for @downloadCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel download'**
  String get downloadCancel;

  /// No description provided for @downloadAvailable.
  ///
  /// In en, this message translates to:
  /// **'Download available videos'**
  String get downloadAvailable;

  /// No description provided for @downloadDone.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloadDone;

  /// No description provided for @downloadRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh access'**
  String get downloadRefresh;

  /// No description provided for @downloadView.
  ///
  /// In en, this message translates to:
  /// **'View my characters'**
  String get downloadView;

  /// No description provided for @downloadDisabled.
  ///
  /// In en, this message translates to:
  /// **'Downloads are temporarily unavailable. Try again later.'**
  String get downloadDisabled;

  /// No description provided for @downloadSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to download.'**
  String get downloadSignIn;

  /// No description provided for @downloadDenied.
  ///
  /// In en, this message translates to:
  /// **'This video is unavailable for download. Refresh access and try again.'**
  String get downloadDenied;

  /// No description provided for @downloadAccessFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not verify download access. Check your connection and account, then retry.'**
  String get downloadAccessFailed;

  /// No description provided for @downloadFinished.
  ///
  /// In en, this message translates to:
  /// **'Download complete. Saved to My characters.'**
  String get downloadFinished;

  /// No description provided for @downloadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Download cancelled. Completed videos remain in My characters.'**
  String get downloadCancelled;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download incomplete. Check your connection, storage and account access, then retry.'**
  String get downloadFailed;

  /// No description provided for @catalogSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} items · {creators} creator items'**
  String catalogSummary(int count, int creators);

  /// No description provided for @catalogRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Library refreshed: {count} items, including {creators} creator items'**
  String catalogRefreshed(int count, int creators);

  /// No description provided for @catalogCount.
  ///
  /// In en, this message translates to:
  /// **'{format} · {count} videos'**
  String catalogCount(String format, int count);

  /// No description provided for @catalogSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String catalogSeconds(String seconds);

  /// No description provided for @catalogCreatorSpace.
  ///
  /// In en, this message translates to:
  /// **'{name}’s work'**
  String catalogCreatorSpace(String name);

  /// No description provided for @catalogPublished.
  ///
  /// In en, this message translates to:
  /// **'Published works · {count}'**
  String catalogPublished(int count);

  /// No description provided for @downloadProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloaded {count}/{total}'**
  String downloadProgress(int count, int total);

  /// No description provided for @downloadActive.
  ///
  /// In en, this message translates to:
  /// **'Downloading: {name}'**
  String downloadActive(String name);

  /// No description provided for @downloadPrice.
  ///
  /// In en, this message translates to:
  /// **'US\$ {price} · Buy to download'**
  String downloadPrice(String price);

  /// No description provided for @controlsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete local downloads?'**
  String get controlsDeleteTitle;

  /// No description provided for @controlsDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'Remove this collection\'s downloaded files from the app. Your cloud access is retained so you can download again.'**
  String get controlsDeleteNote;

  /// No description provided for @controlsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get controlsCancel;

  /// No description provided for @controlsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get controlsDelete;

  /// No description provided for @controlsDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete. Please try again.'**
  String get controlsDeleteFailed;

  /// No description provided for @controlsDeleteLocal.
  ///
  /// In en, this message translates to:
  /// **'Delete local downloads'**
  String get controlsDeleteLocal;

  /// No description provided for @controlsNoVideos.
  ///
  /// In en, this message translates to:
  /// **'No videos are available for this character yet.'**
  String get controlsNoVideos;

  /// No description provided for @controlsPreviewLocal.
  ///
  /// In en, this message translates to:
  /// **'Preview downloaded video'**
  String get controlsPreviewLocal;

  /// No description provided for @controlsExamples.
  ///
  /// In en, this message translates to:
  /// **'Official sample collections · Select videos'**
  String get controlsExamples;

  /// No description provided for @controlsChooseList.
  ///
  /// In en, this message translates to:
  /// **'Choose a playlist'**
  String get controlsChooseList;

  /// No description provided for @controlsPendingNote.
  ///
  /// In en, this message translates to:
  /// **'Videos are added to pending items first. They are not yet uploaded to the device.'**
  String get controlsPendingNote;

  /// No description provided for @controlsStartup.
  ///
  /// In en, this message translates to:
  /// **'Daily display'**
  String get controlsStartup;

  /// No description provided for @controlsBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Music mode'**
  String get controlsBluetooth;

  /// No description provided for @controlsAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not add videos. Please try again.'**
  String get controlsAddFailed;

  /// No description provided for @controlsMyCharacters.
  ///
  /// In en, this message translates to:
  /// **'My characters'**
  String get controlsMyCharacters;

  /// No description provided for @controlsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your characters. Tap to retry.'**
  String get controlsLoadFailed;

  /// No description provided for @controlsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No characters available yet'**
  String get controlsEmpty;

  /// No description provided for @controlsEmptyNote.
  ///
  /// In en, this message translates to:
  /// **'Download a character from the content library, then choose its videos.'**
  String get controlsEmptyNote;

  /// No description provided for @controlsLibrary.
  ///
  /// In en, this message translates to:
  /// **'Content library'**
  String get controlsLibrary;

  /// No description provided for @controlsBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse content library'**
  String get controlsBrowse;

  /// No description provided for @controlsPickNote.
  ///
  /// In en, this message translates to:
  /// **'Choose a character, then select videos for this playlist.'**
  String get controlsPickNote;

  /// No description provided for @controlsListNote.
  ///
  /// In en, this message translates to:
  /// **'Add character videos to Daily display or Music mode.'**
  String get controlsListNote;

  /// No description provided for @controlsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No videos available'**
  String get controlsUnavailable;

  /// No description provided for @controlsSelect.
  ///
  /// In en, this message translates to:
  /// **'Select videos'**
  String get controlsSelect;

  /// No description provided for @controlsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get controlsAdd;

  /// No description provided for @controlsControlTitle.
  ///
  /// In en, this message translates to:
  /// **'Device controls'**
  String get controlsControlTitle;

  /// No description provided for @controlsBrightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get controlsBrightness;

  /// No description provided for @controlsAngle.
  ///
  /// In en, this message translates to:
  /// **'Angle (device units and range unconfirmed)'**
  String get controlsAngle;

  /// No description provided for @controlsSpeakerTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Bluetooth speaker name'**
  String get controlsSpeakerTitle;

  /// No description provided for @controlsSpeakerName.
  ///
  /// In en, this message translates to:
  /// **'Speaker name'**
  String get controlsSpeakerName;

  /// No description provided for @controlsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get controlsSave;

  /// No description provided for @controlsSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth speaker'**
  String get controlsSpeaker;

  /// No description provided for @controlsConnectSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Connect the device to read its speaker name.'**
  String get controlsConnectSpeaker;

  /// No description provided for @controlsReading.
  ///
  /// In en, this message translates to:
  /// **'Reading…'**
  String get controlsReading;

  /// No description provided for @controlsNameUnknown.
  ///
  /// In en, this message translates to:
  /// **'Name not loaded'**
  String get controlsNameUnknown;

  /// No description provided for @controlsRefreshName.
  ///
  /// In en, this message translates to:
  /// **'Refresh name'**
  String get controlsRefreshName;

  /// No description provided for @controlsEditName.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get controlsEditName;

  /// No description provided for @controlsDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get controlsDisconnected;

  /// No description provided for @controlsConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get controlsConnecting;

  /// No description provided for @controlsReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get controlsReconnecting;

  /// No description provided for @controlsConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get controlsConnected;

  /// No description provided for @controlsIp.
  ///
  /// In en, this message translates to:
  /// **'Device IP'**
  String get controlsIp;

  /// No description provided for @controlsPort.
  ///
  /// In en, this message translates to:
  /// **'Default port: 8900'**
  String get controlsPort;

  /// No description provided for @controlsStopReconnect.
  ///
  /// In en, this message translates to:
  /// **'Stop reconnecting'**
  String get controlsStopReconnect;

  /// No description provided for @controlsDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get controlsDisconnect;

  /// No description provided for @controlsConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get controlsConnect;

  /// No description provided for @controlsQuick.
  ///
  /// In en, this message translates to:
  /// **'Quick controls'**
  String get controlsQuick;

  /// No description provided for @controlsPowerOn.
  ///
  /// In en, this message translates to:
  /// **'Power on'**
  String get controlsPowerOn;

  /// No description provided for @controlsPowerOff.
  ///
  /// In en, this message translates to:
  /// **'Power off'**
  String get controlsPowerOff;

  /// No description provided for @controlsPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get controlsPrevious;

  /// No description provided for @controlsPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get controlsPause;

  /// No description provided for @controlsPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get controlsPlay;

  /// No description provided for @controlsNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get controlsNext;

  /// No description provided for @controlsRefreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get controlsRefreshStatus;

  /// No description provided for @controlsStatus.
  ///
  /// In en, this message translates to:
  /// **'Device status'**
  String get controlsStatus;

  /// No description provided for @controlsLan.
  ///
  /// In en, this message translates to:
  /// **'Local network control'**
  String get controlsLan;

  /// No description provided for @controlsMode.
  ///
  /// In en, this message translates to:
  /// **'Operating mode'**
  String get controlsMode;

  /// No description provided for @controlsAudioSource.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth audio source'**
  String get controlsAudioSource;

  /// No description provided for @controlsProtocol.
  ///
  /// In en, this message translates to:
  /// **'Awaiting protocol support'**
  String get controlsProtocol;

  /// No description provided for @controlsLocalPlayback.
  ///
  /// In en, this message translates to:
  /// **'Device playback'**
  String get controlsLocalPlayback;

  /// No description provided for @controlsBluetoothWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Bluetooth'**
  String get controlsBluetoothWaiting;

  /// No description provided for @controlsBluetoothAudio.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth audio'**
  String get controlsBluetoothAudio;

  /// No description provided for @controlsWaitingSource.
  ///
  /// In en, this message translates to:
  /// **'Waiting for an audio source'**
  String get controlsWaitingSource;

  /// No description provided for @controlsAudioPlaying.
  ///
  /// In en, this message translates to:
  /// **'Audio playing'**
  String get controlsAudioPlaying;

  /// No description provided for @controlsAudioPaused.
  ///
  /// In en, this message translates to:
  /// **'Audio paused'**
  String get controlsAudioPaused;

  /// No description provided for @controlsWasDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get controlsWasDisconnected;

  /// No description provided for @controlsBatteryFull.
  ///
  /// In en, this message translates to:
  /// **'Fully charged'**
  String get controlsBatteryFull;

  /// No description provided for @controlsBattery.
  ///
  /// In en, this message translates to:
  /// **'Device battery'**
  String get controlsBattery;

  /// No description provided for @controlsProtocolNote.
  ///
  /// In en, this message translates to:
  /// **'The current protocol does not report operating mode or Bluetooth status. These indicators require updated device protocol support.'**
  String get controlsProtocolNote;

  /// No description provided for @controlsPackageCount.
  ///
  /// In en, this message translates to:
  /// **'Character collection · {count} videos'**
  String controlsPackageCount(int count);

  /// No description provided for @controlsDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded {count}/{total} videos'**
  String controlsDownloaded(int count, int total);

  /// No description provided for @controlsSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String controlsSeconds(int seconds);

  /// No description provided for @controlsAddCount.
  ///
  /// In en, this message translates to:
  /// **'Add {count} videos to pending items'**
  String controlsAddCount(int count);

  /// No description provided for @controlsVideoCount.
  ///
  /// In en, this message translates to:
  /// **'{count} videos'**
  String controlsVideoCount(int count);

  /// No description provided for @controlsAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to {list} pending items. Not yet uploaded to the device.'**
  String controlsAdded(String list);

  /// No description provided for @controlsNamedPlaying.
  ///
  /// In en, this message translates to:
  /// **'{name} · Playing'**
  String controlsNamedPlaying(String name);

  /// No description provided for @controlsNamedPaused.
  ///
  /// In en, this message translates to:
  /// **'{name} · Paused'**
  String controlsNamedPaused(String name);

  /// No description provided for @controlsCharging.
  ///
  /// In en, this message translates to:
  /// **'{percent}% · Charging'**
  String controlsCharging(int percent);

  /// No description provided for @coreHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get coreHome;

  /// No description provided for @coreCollection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get coreCollection;

  /// No description provided for @coreExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get coreExplore;

  /// No description provided for @coreProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get coreProfile;

  /// No description provided for @coreDeviceControl.
  ///
  /// In en, this message translates to:
  /// **'Device controls'**
  String get coreDeviceControl;

  /// No description provided for @coreCustomCharacter.
  ///
  /// In en, this message translates to:
  /// **'Customize your holographic character'**
  String get coreCustomCharacter;

  /// No description provided for @corePlaylists.
  ///
  /// In en, this message translates to:
  /// **'Device playlists'**
  String get corePlaylists;

  /// No description provided for @corePlaylistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display and music modes'**
  String get corePlaylistSubtitle;

  /// No description provided for @coreDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display mode'**
  String get coreDisplay;

  /// No description provided for @coreStartupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage content played at startup'**
  String get coreStartupSubtitle;

  /// No description provided for @coreMusic.
  ///
  /// In en, this message translates to:
  /// **'Music mode'**
  String get coreMusic;

  /// No description provided for @coreBluetoothSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage content played with Bluetooth audio'**
  String get coreBluetoothSubtitle;

  /// No description provided for @coreOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get coreOnline;

  /// No description provided for @coreDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get coreDisconnected;

  /// No description provided for @coreDeviceConnected.
  ///
  /// In en, this message translates to:
  /// **'Device connected'**
  String get coreDeviceConnected;

  /// No description provided for @coreConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get coreConnecting;

  /// No description provided for @coreReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get coreReconnecting;

  /// No description provided for @coreDeviceDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Device disconnected'**
  String get coreDeviceDisconnected;

  /// No description provided for @coreLanControl.
  ///
  /// In en, this message translates to:
  /// **'Local network control · P20 / P11'**
  String get coreLanControl;

  /// No description provided for @coreConnectP20.
  ///
  /// In en, this message translates to:
  /// **'Connect P20'**
  String get coreConnectP20;

  /// No description provided for @coreConnectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Connection settings'**
  String get coreConnectionSettings;

  /// No description provided for @coreDeviceManagement.
  ///
  /// In en, this message translates to:
  /// **'Device management'**
  String get coreDeviceManagement;

  /// No description provided for @coreDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get coreDevices;

  /// No description provided for @corePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get corePlaylist;

  /// No description provided for @coreDeviceContent.
  ///
  /// In en, this message translates to:
  /// **'Device content'**
  String get coreDeviceContent;

  /// No description provided for @coreCharacterAssets.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get coreCharacterAssets;

  /// No description provided for @coreCustomOrders.
  ///
  /// In en, this message translates to:
  /// **'Custom orders'**
  String get coreCustomOrders;

  /// No description provided for @coreOrdersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track production and delivery. Find claimed characters in Collection.'**
  String get coreOrdersSubtitle;

  /// No description provided for @coreCreatorCenter.
  ///
  /// In en, this message translates to:
  /// **'Creator center'**
  String get coreCreatorCenter;

  /// No description provided for @coreCreatorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Applications, production tasks and earnings'**
  String get coreCreatorSubtitle;

  /// No description provided for @coreSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get coreSupport;

  /// No description provided for @corePlaybackGuide.
  ///
  /// In en, this message translates to:
  /// **'Playback modes'**
  String get corePlaybackGuide;

  /// No description provided for @corePlaybackGuideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn how display and music modes switch'**
  String get corePlaybackGuideSubtitle;

  /// No description provided for @coreLanHelp.
  ///
  /// In en, this message translates to:
  /// **'Local network help'**
  String get coreLanHelp;

  /// No description provided for @coreLanHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to a P20/P11 hotspot and troubleshoot'**
  String get coreLanHelpSubtitle;

  /// No description provided for @coreAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Device and app settings'**
  String get coreAppSettings;

  /// No description provided for @coreAppSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Device options, playback preferences and version'**
  String get coreAppSettingsSubtitle;

  /// No description provided for @coreAbout.
  ///
  /// In en, this message translates to:
  /// **'About HILDORS'**
  String get coreAbout;

  /// No description provided for @coreAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Character Portal · P20/P11 support'**
  String get coreAboutSubtitle;

  /// No description provided for @corePlayerProfile.
  ///
  /// In en, this message translates to:
  /// **'Player profile'**
  String get corePlayerProfile;

  /// No description provided for @coreLocalAccount.
  ///
  /// In en, this message translates to:
  /// **'Local device profile · Stored on this device'**
  String get coreLocalAccount;

  /// No description provided for @coreDeviceSettings.
  ///
  /// In en, this message translates to:
  /// **'Device settings'**
  String get coreDeviceSettings;

  /// No description provided for @coreReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read device status. Connect to the device Wi-Fi and try again.'**
  String get coreReadFailed;

  /// No description provided for @coreSettingFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not apply the setting. Check the device connection and try again.'**
  String get coreSettingFailed;

  /// No description provided for @corePlaybackBehavior.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get corePlaybackBehavior;

  /// No description provided for @coreLoopMode.
  ///
  /// In en, this message translates to:
  /// **'Repeat mode'**
  String get coreLoopMode;

  /// No description provided for @coreLoopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how the device repeats its current playlist'**
  String get coreLoopSubtitle;

  /// No description provided for @coreConnectToChange.
  ///
  /// In en, this message translates to:
  /// **'Connect to read and change settings'**
  String get coreConnectToChange;

  /// No description provided for @coreDeviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Device information'**
  String get coreDeviceInfo;

  /// No description provided for @coreLanCockpit.
  ///
  /// In en, this message translates to:
  /// **'Local network device'**
  String get coreLanCockpit;

  /// No description provided for @coreNotRead.
  ///
  /// In en, this message translates to:
  /// **'Not read yet'**
  String get coreNotRead;

  /// No description provided for @coreReadInfo.
  ///
  /// In en, this message translates to:
  /// **'Read device information'**
  String get coreReadInfo;

  /// No description provided for @coreHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get coreHelp;

  /// No description provided for @coreModesHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic switching between display and music modes'**
  String get coreModesHelpSubtitle;

  /// No description provided for @coreHotspotHelp.
  ///
  /// In en, this message translates to:
  /// **'Device hotspot connection and troubleshooting'**
  String get coreHotspotHelp;

  /// No description provided for @coreDeviceConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to device'**
  String get coreDeviceConnecting;

  /// No description provided for @coreDeviceReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Restoring connection'**
  String get coreDeviceReconnecting;

  /// No description provided for @coreCockpitOnline.
  ///
  /// In en, this message translates to:
  /// **'Device online'**
  String get coreCockpitOnline;

  /// No description provided for @coreGoHomeConnect.
  ///
  /// In en, this message translates to:
  /// **'Go to Home to connect your P20 / P11'**
  String get coreGoHomeConnect;

  /// No description provided for @coreOpeningLan.
  ///
  /// In en, this message translates to:
  /// **'Establishing local network control'**
  String get coreOpeningLan;

  /// No description provided for @coreRetryingLan.
  ///
  /// In en, this message translates to:
  /// **'Connection interrupted. Retrying automatically'**
  String get coreRetryingLan;

  /// No description provided for @coreLanReady.
  ///
  /// In en, this message translates to:
  /// **'Local network control connected'**
  String get coreLanReady;

  /// No description provided for @coreSync.
  ///
  /// In en, this message translates to:
  /// **'Sync device status'**
  String get coreSync;

  /// No description provided for @coreSingleLoop.
  ///
  /// In en, this message translates to:
  /// **'Repeat one'**
  String get coreSingleLoop;

  /// No description provided for @coreSequenceLoop.
  ///
  /// In en, this message translates to:
  /// **'Repeat all'**
  String get coreSequenceLoop;

  /// No description provided for @coreRandomLoop.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get coreRandomLoop;

  /// No description provided for @coreSingleOnce.
  ///
  /// In en, this message translates to:
  /// **'Play once'**
  String get coreSingleOnce;

  /// No description provided for @coreCheckWifi.
  ///
  /// In en, this message translates to:
  /// **'Check your phone Wi-Fi'**
  String get coreCheckWifi;

  /// No description provided for @coreCheckWifiBody.
  ///
  /// In en, this message translates to:
  /// **'Connect your phone to the P20 hotspot or the same router as your P20.'**
  String get coreCheckWifiBody;

  /// No description provided for @coreCheckAddress.
  ///
  /// In en, this message translates to:
  /// **'Check the control address'**
  String get coreCheckAddress;

  /// No description provided for @coreCheckAddressBody.
  ///
  /// In en, this message translates to:
  /// **'In hotspot mode, the default address is 192.168.4.1 and the TCP port is 8900.'**
  String get coreCheckAddressBody;

  /// No description provided for @coreLanPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow local network access'**
  String get coreLanPermission;

  /// No description provided for @coreLanPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'On iOS, allow Local Network access. On Android, allow the requested nearby-device and network permissions.'**
  String get coreLanPermissionBody;

  /// No description provided for @coreReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get coreReconnect;

  /// No description provided for @coreReconnectBody.
  ///
  /// In en, this message translates to:
  /// **'Return to device controls and tap Connect. After an unexpected disconnection, the app retries after 1, 2, 4, 8, 15 and 30 seconds.'**
  String get coreReconnectBody;

  /// No description provided for @coreOfflineWifiHelp.
  ///
  /// In en, this message translates to:
  /// **'A “No internet” message does not necessarily mean device control failed. Control can continue while your phone stays on the P20 local network.'**
  String get coreOfflineWifiHelp;

  /// No description provided for @coreLocalPlayback.
  ///
  /// In en, this message translates to:
  /// **'Device playback'**
  String get coreLocalPlayback;

  /// No description provided for @coreLocalPlaybackBody.
  ///
  /// In en, this message translates to:
  /// **'P20 plays videos stored on the device, including their audio. Use this mode for startup playback, looping displays and fixed content.'**
  String get coreLocalPlaybackBody;

  /// No description provided for @coreBluetoothSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth speaker'**
  String get coreBluetoothSpeaker;

  /// No description provided for @coreBluetoothSpeakerBody.
  ///
  /// In en, this message translates to:
  /// **'A phone or computer sends audio to P20 over Bluetooth while P20 plays the video configured for Bluetooth mode.'**
  String get coreBluetoothSpeakerBody;

  /// No description provided for @coreSeparateConnections.
  ///
  /// In en, this message translates to:
  /// **'Hildors controls P20 over local Wi-Fi. Local network control and Bluetooth audio are separate connections.'**
  String get coreSeparateConnections;

  /// No description provided for @coreCharacterPortal.
  ///
  /// In en, this message translates to:
  /// **'Character Portal'**
  String get coreCharacterPortal;

  /// No description provided for @coreExploreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize characters, share wishes and create.'**
  String get coreExploreSubtitle;

  /// No description provided for @coreWishSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share wishes and follow licensing updates'**
  String get coreWishSubtitle;

  /// No description provided for @coreCreatorExploreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Applications, tasks and earnings'**
  String get coreCreatorExploreSubtitle;

  /// No description provided for @coreWish.
  ///
  /// In en, this message translates to:
  /// **'Character wishes'**
  String get coreWish;

  /// No description provided for @coreCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize your character'**
  String get coreCustomize;

  /// No description provided for @coreEnter.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get coreEnter;

  /// No description provided for @coreCreatorFreeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Apply for creator certification and publish free content'**
  String get coreCreatorFreeSubtitle;

  /// No description provided for @coreExploreFreeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore opportunities to create and share free content.'**
  String get coreExploreFreeSubtitle;

  /// No description provided for @coreConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Check the device Wi-Fi and connection settings, then try again.'**
  String get coreConnectionFailed;

  /// No description provided for @coreSystemLabel.
  ///
  /// In en, this message translates to:
  /// **'DEVICE SYSTEM'**
  String get coreSystemLabel;

  /// No description provided for @coreProfileLabel.
  ///
  /// In en, this message translates to:
  /// **'PLAYER PROFILE'**
  String get coreProfileLabel;

  /// No description provided for @coreLocalLabel.
  ///
  /// In en, this message translates to:
  /// **'LOCAL'**
  String get coreLocalLabel;

  /// No description provided for @corePilotLabel.
  ///
  /// In en, this message translates to:
  /// **'HILDORS PILOT'**
  String get corePilotLabel;

  /// No description provided for @coreServiceLabel.
  ///
  /// In en, this message translates to:
  /// **'CORE SERVICE'**
  String get coreServiceLabel;

  /// No description provided for @coreCreatorLabel.
  ///
  /// In en, this message translates to:
  /// **'CREATOR'**
  String get coreCreatorLabel;

  /// No description provided for @coreOnlineLabel.
  ///
  /// In en, this message translates to:
  /// **'ONLINE'**
  String get coreOnlineLabel;

  /// No description provided for @coreConnectingLabel.
  ///
  /// In en, this message translates to:
  /// **'CONNECTING'**
  String get coreConnectingLabel;

  /// No description provided for @coreReconnectingLabel.
  ///
  /// In en, this message translates to:
  /// **'RECONNECTING'**
  String get coreReconnectingLabel;

  /// No description provided for @coreOfflineLabel.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE'**
  String get coreOfflineLabel;

  /// No description provided for @creatorWorkbench.
  ///
  /// In en, this message translates to:
  /// **'Creator studio'**
  String get creatorWorkbench;

  /// No description provided for @creatorOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original content'**
  String get creatorOriginal;

  /// No description provided for @creatorFreeNote.
  ///
  /// In en, this message translates to:
  /// **'Upload a video or character collection for review. This version supports free submissions only. Content is published after approval.'**
  String get creatorFreeNote;

  /// No description provided for @creatorPublishingNote.
  ///
  /// In en, this message translates to:
  /// **'Upload videos or character collections for review. Standard and verified creators publish free content; partners may set prices.'**
  String get creatorPublishingNote;

  /// No description provided for @creatorSubmissions.
  ///
  /// In en, this message translates to:
  /// **'Upload / My submissions'**
  String get creatorSubmissions;

  /// No description provided for @creatorTasks.
  ///
  /// In en, this message translates to:
  /// **'Custom projects'**
  String get creatorTasks;

  /// No description provided for @creatorTasksNote.
  ///
  /// In en, this message translates to:
  /// **'View available projects and ongoing custom orders'**
  String get creatorTasksNote;

  /// No description provided for @customPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom videos'**
  String get customPlansTitle;

  /// No description provided for @customOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'My custom orders'**
  String get customOrdersTitle;

  /// No description provided for @customUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Store payments are not connected yet. No payment can be taken.'**
  String get customUnavailable;

  /// No description provided for @customBase.
  ///
  /// In en, this message translates to:
  /// **'USD base reference: {price}. Checkout uses the store price.'**
  String customBase(String price);

  /// No description provided for @customSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}-second video'**
  String customSeconds(int seconds);

  /// No description provided for @customRequest.
  ///
  /// In en, this message translates to:
  /// **'Send requirements for review'**
  String get customRequest;

  /// No description provided for @customName.
  ///
  /// In en, this message translates to:
  /// **'Character / project name'**
  String get customName;

  /// No description provided for @customRequirements.
  ///
  /// In en, this message translates to:
  /// **'Your requirements'**
  String get customRequirements;

  /// No description provided for @customMaterials.
  ///
  /// In en, this message translates to:
  /// **'Add reference images'**
  String get customMaterials;

  /// No description provided for @customMaterialCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reference images'**
  String customMaterialCount(int count);

  /// No description provided for @customPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Reference materials are used to assess and produce this private order. Public display requires separate consent.'**
  String get customPrivacy;

  /// No description provided for @customConsent.
  ///
  /// In en, this message translates to:
  /// **'I agree to use these materials for this order.'**
  String get customConsent;

  /// No description provided for @customValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter a project name and requirements, and confirm the material-use notice.'**
  String get customValidation;

  /// No description provided for @customImageError.
  ///
  /// In en, this message translates to:
  /// **'Choose up to 8 JPG/PNG images, each no larger than 8 MB.'**
  String get customImageError;

  /// No description provided for @customSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Request submitted for review. No payment has been taken.'**
  String get customSubmitted;

  /// No description provided for @customTerms.
  ///
  /// In en, this message translates to:
  /// **'Review the confirmed scope before payment'**
  String get customTerms;

  /// No description provided for @customContent.
  ///
  /// In en, this message translates to:
  /// **'Deliverables'**
  String get customContent;

  /// No description provided for @customPeriod.
  ///
  /// In en, this message translates to:
  /// **'Delivery period'**
  String get customPeriod;

  /// No description provided for @customRevisions.
  ///
  /// In en, this message translates to:
  /// **'Revision scope'**
  String get customRevisions;

  /// No description provided for @customRights.
  ///
  /// In en, this message translates to:
  /// **'Usage rights'**
  String get customRights;

  /// No description provided for @customAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'I accept this confirmed scope and its terms.'**
  String get customAcceptTerms;

  /// No description provided for @customPay.
  ///
  /// In en, this message translates to:
  /// **'Pay {price}'**
  String customPay(String price);

  /// No description provided for @customRestore.
  ///
  /// In en, this message translates to:
  /// **'Check unfinished purchases'**
  String get customRestore;

  /// No description provided for @customTestMode.
  ///
  /// In en, this message translates to:
  /// **'TEST PAYMENT — no real charge'**
  String get customTestMode;

  /// No description provided for @customAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept delivery'**
  String get customAccept;

  /// No description provided for @customRevise.
  ///
  /// In en, this message translates to:
  /// **'Request revision'**
  String get customRevise;

  /// No description provided for @customRevisionNote.
  ///
  /// In en, this message translates to:
  /// **'Describe the requested revision'**
  String get customRevisionNote;

  /// No description provided for @customStatusReview.
  ///
  /// In en, this message translates to:
  /// **'Requirements under review'**
  String get customStatusReview;

  /// No description provided for @customStatusInfo.
  ///
  /// In en, this message translates to:
  /// **'More information needed'**
  String get customStatusInfo;

  /// No description provided for @customStatusQuote.
  ///
  /// In en, this message translates to:
  /// **'Scope confirmed; awaiting payment'**
  String get customStatusQuote;

  /// No description provided for @customStatusMaking.
  ///
  /// In en, this message translates to:
  /// **'In production'**
  String get customStatusMaking;

  /// No description provided for @customStatusQc.
  ///
  /// In en, this message translates to:
  /// **'Quality review'**
  String get customStatusQc;

  /// No description provided for @customStatusAccept.
  ///
  /// In en, this message translates to:
  /// **'Ready for your review'**
  String get customStatusAccept;

  /// No description provided for @customStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get customStatusDelivered;

  /// No description provided for @customStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Request declined'**
  String get customStatusRejected;

  /// No description provided for @customStatusWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn / refunded'**
  String get customStatusWithdrawn;

  /// No description provided for @customPending.
  ///
  /// In en, this message translates to:
  /// **'Payment is pending. Production starts only after server verification.'**
  String get customPending;

  /// No description provided for @customEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items available yet.'**
  String get customEmpty;

  /// No description provided for @customAudioNone.
  ///
  /// In en, this message translates to:
  /// **'No audio — base package'**
  String get customAudioNone;

  /// No description provided for @customAudioMatched.
  ///
  /// In en, this message translates to:
  /// **'Platform-matched audio'**
  String get customAudioMatched;

  /// No description provided for @customAudioHelp.
  ///
  /// In en, this message translates to:
  /// **'We match background music or simple sound effects to your video. No specific songs, voice-over or uploaded audio.'**
  String get customAudioHelp;

  /// No description provided for @customAudioTotal.
  ///
  /// In en, this message translates to:
  /// **'USD reference total: {price}'**
  String customAudioTotal(String price);

  /// No description provided for @customAudioRate.
  ///
  /// In en, this message translates to:
  /// **'Audio matching surcharge: {percent}%'**
  String customAudioRate(int percent);

  /// No description provided for @customSupplement.
  ///
  /// In en, this message translates to:
  /// **'Update requirements and resubmit'**
  String get customSupplement;

  /// No description provided for @customSupplementSaved.
  ///
  /// In en, this message translates to:
  /// **'Updated requirements submitted for review.'**
  String get customSupplementSaved;

  /// No description provided for @customSaveDelivery.
  ///
  /// In en, this message translates to:
  /// **'Save delivery to My characters'**
  String get customSaveDelivery;

  /// No description provided for @customSavedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Saved to My characters for offline use.'**
  String get customSavedDelivery;

  /// No description provided for @customSavingDelivery.
  ///
  /// In en, this message translates to:
  /// **'Downloading private delivery…'**
  String get customSavingDelivery;

  /// No description provided for @customConfirmDelivery.
  ///
  /// In en, this message translates to:
  /// **'Accept this version as the final delivery?'**
  String get customConfirmDelivery;

  /// No description provided for @customRevisionLimit.
  ///
  /// In en, this message translates to:
  /// **'Revision requests: {used} of {limit}'**
  String customRevisionLimit(int used, int limit);

  /// No description provided for @customProgress.
  ///
  /// In en, this message translates to:
  /// **'Production updates'**
  String get customProgress;

  /// No description provided for @deletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deletionTitle;

  /// No description provided for @deletionExplanation.
  ///
  /// In en, this message translates to:
  /// **'Request deletion of your Hildors account and associated data. This submits a request for review; it does not delete data immediately or sign you out. You can check its status here or cancel while it is pending.'**
  String get deletionExplanation;

  /// No description provided for @deletionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Request account deletion'**
  String get deletionSubmit;

  /// No description provided for @deletionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Submit this deletion request? Your account remains active while the request is being reviewed.'**
  String get deletionConfirm;

  /// No description provided for @deletionNone.
  ///
  /// In en, this message translates to:
  /// **'No pending deletion request.'**
  String get deletionNone;

  /// No description provided for @deletionReceived.
  ///
  /// In en, this message translates to:
  /// **'Request received'**
  String get deletionReceived;

  /// No description provided for @deletionReview.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get deletionReview;

  /// No description provided for @deletionInformation.
  ///
  /// In en, this message translates to:
  /// **'More information needed'**
  String get deletionInformation;

  /// No description provided for @deletionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get deletionCancelled;

  /// No description provided for @deletionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel deletion request'**
  String get deletionCancel;

  /// No description provided for @deletionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get deletionRefresh;

  /// No description provided for @deletionReference.
  ///
  /// In en, this message translates to:
  /// **'Request ID: {id}'**
  String deletionReference(String id);

  /// No description provided for @devicePlayingDelete.
  ///
  /// In en, this message translates to:
  /// **'Play a different video before deleting this one.'**
  String get devicePlayingDelete;

  /// No description provided for @deviceDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete this device file?'**
  String get deviceDeleteTitle;

  /// No description provided for @deviceDeleteIntro.
  ///
  /// In en, this message translates to:
  /// **'This video will be permanently deleted from the holographic device:'**
  String get deviceDeleteIntro;

  /// No description provided for @deviceDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. Downloaded copies on your phone and purchase records will remain.'**
  String get deviceDeleteNote;

  /// No description provided for @deviceCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deviceCancel;

  /// No description provided for @deviceDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deviceDelete;

  /// No description provided for @deviceVideoLibrary.
  ///
  /// In en, this message translates to:
  /// **'Device videos'**
  String get deviceVideoLibrary;

  /// No description provided for @deviceRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get deviceRefresh;

  /// No description provided for @deviceConnectFirst.
  ///
  /// In en, this message translates to:
  /// **'Connect your device in Controls first.'**
  String get deviceConnectFirst;

  /// No description provided for @deviceReadVideos.
  ///
  /// In en, this message translates to:
  /// **'Load device videos'**
  String get deviceReadVideos;

  /// No description provided for @devicePlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get devicePlaying;

  /// No description provided for @devicePlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get devicePlay;

  /// No description provided for @deviceMore.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get deviceMore;

  /// No description provided for @deviceDeleteFrom.
  ///
  /// In en, this message translates to:
  /// **'Delete from device'**
  String get deviceDeleteFrom;

  /// No description provided for @frameSaved.
  ///
  /// In en, this message translates to:
  /// **'Framing saved. The original video is unchanged; it has not been converted or uploaded.'**
  String get frameSaved;

  /// No description provided for @frameSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Please try again.'**
  String get frameSaveFailed;

  /// No description provided for @frameTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust circular framing'**
  String get frameTitle;

  /// No description provided for @frameCircle.
  ///
  /// In en, this message translates to:
  /// **'The circle marks the device display area.'**
  String get frameCircle;

  /// No description provided for @frameInstructions.
  ///
  /// In en, this message translates to:
  /// **'Pinch to zoom and drag to reposition. Play the full video to check that the character and movements stay inside the circle.'**
  String get frameInstructions;

  /// No description provided for @framePause.
  ///
  /// In en, this message translates to:
  /// **'Pause preview'**
  String get framePause;

  /// No description provided for @framePlay.
  ///
  /// In en, this message translates to:
  /// **'Play preview'**
  String get framePlay;

  /// No description provided for @framePlaybackFailed.
  ///
  /// In en, this message translates to:
  /// **'Playback failed. Go back and try again.'**
  String get framePlaybackFailed;

  /// No description provided for @frameZoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get frameZoom;

  /// No description provided for @frameFit.
  ///
  /// In en, this message translates to:
  /// **'Fit whole frame'**
  String get frameFit;

  /// No description provided for @frameFill.
  ///
  /// In en, this message translates to:
  /// **'Fill circle'**
  String get frameFill;

  /// No description provided for @frameReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get frameReset;

  /// No description provided for @frameFitNote.
  ///
  /// In en, this message translates to:
  /// **'Fit keeps the entire frame. Fill crops the edges.'**
  String get frameFitNote;

  /// No description provided for @frameRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Saved framing could not be loaded. Adjust and save it again.'**
  String get frameRestoreFailed;

  /// No description provided for @frameSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get frameSaving;

  /// No description provided for @frameSave.
  ///
  /// In en, this message translates to:
  /// **'Save framing'**
  String get frameSave;

  /// No description provided for @frameUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Convert and upload · Unavailable'**
  String get frameUnavailable;

  /// No description provided for @framePending.
  ///
  /// In en, this message translates to:
  /// **'Only framing is saved for now. Device video conversion is not yet available.'**
  String get framePending;

  /// No description provided for @framePreviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Preview could not load. Go back and try again.'**
  String get framePreviewFailed;

  /// No description provided for @deviceDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted {name} from the device.'**
  String deviceDeleted(String name);

  /// No description provided for @frameTime.
  ///
  /// In en, this message translates to:
  /// **'{position} / {duration} seconds'**
  String frameTime(int position, int duration);

  /// No description provided for @governanceReport.
  ///
  /// In en, this message translates to:
  /// **'Report content'**
  String get governanceReport;

  /// No description provided for @governanceBlock.
  ///
  /// In en, this message translates to:
  /// **'Block creator'**
  String get governanceBlock;

  /// No description provided for @governanceCopyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright infringement'**
  String get governanceCopyright;

  /// No description provided for @governanceAbuse.
  ///
  /// In en, this message translates to:
  /// **'Harassment or abuse'**
  String get governanceAbuse;

  /// No description provided for @governanceSexual.
  ///
  /// In en, this message translates to:
  /// **'Sexual content'**
  String get governanceSexual;

  /// No description provided for @governanceViolence.
  ///
  /// In en, this message translates to:
  /// **'Violence'**
  String get governanceViolence;

  /// No description provided for @governanceSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get governanceSpam;

  /// No description provided for @governanceOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get governanceOther;

  /// No description provided for @governanceDetails.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get governanceDetails;

  /// No description provided for @governanceReportNote.
  ///
  /// In en, this message translates to:
  /// **'Your report will be sent to our review team. For copyright concerns, describe the original work and where it appears. Do not include sensitive personal information.'**
  String get governanceReportNote;

  /// No description provided for @governanceCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get governanceCancel;

  /// No description provided for @governanceSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get governanceSubmit;

  /// No description provided for @governanceReceived.
  ///
  /// In en, this message translates to:
  /// **'Report received. Reference: {reference}'**
  String governanceReceived(String reference);

  /// No description provided for @governanceBlockNote.
  ///
  /// In en, this message translates to:
  /// **'Hide this creator’s content from your catalog for this account. You can unblock them in Reports and blocked creators.'**
  String get governanceBlockNote;

  /// No description provided for @governanceBlocked.
  ///
  /// In en, this message translates to:
  /// **'Creator blocked.'**
  String get governanceBlocked;

  /// No description provided for @governanceAuthError.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Sign in again.'**
  String get governanceAuthError;

  /// No description provided for @governanceUnavailableError.
  ///
  /// In en, this message translates to:
  /// **'This content is no longer available.'**
  String get governanceUnavailableError;

  /// No description provided for @governanceInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Check your report and try again.'**
  String get governanceInvalidError;

  /// No description provided for @governanceConflictError.
  ///
  /// In en, this message translates to:
  /// **'This action is unavailable. Refresh and try again.'**
  String get governanceConflictError;

  /// No description provided for @governanceNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Please try again.'**
  String get governanceNetworkError;

  /// No description provided for @governanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports and blocked creators'**
  String get governanceTitle;

  /// No description provided for @governanceRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get governanceRefresh;

  /// No description provided for @governanceReports.
  ///
  /// In en, this message translates to:
  /// **'My reports'**
  String get governanceReports;

  /// No description provided for @governanceBlocks.
  ///
  /// In en, this message translates to:
  /// **'Blocked creators'**
  String get governanceBlocks;

  /// No description provided for @governanceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items yet.'**
  String get governanceEmpty;

  /// No description provided for @governanceUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get governanceUnblock;

  /// No description provided for @governanceStatusReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get governanceStatusReceived;

  /// No description provided for @governanceStatusReview.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get governanceStatusReview;

  /// No description provided for @governanceStatusAction.
  ///
  /// In en, this message translates to:
  /// **'Action taken'**
  String get governanceStatusAction;

  /// No description provided for @governanceStatusNoViolation.
  ///
  /// In en, this message translates to:
  /// **'No violation found'**
  String get governanceStatusNoViolation;

  /// No description provided for @playlistFromCharacters.
  ///
  /// In en, this message translates to:
  /// **'Choose from My characters'**
  String get playlistFromCharacters;

  /// No description provided for @playlistChooseCharacter.
  ///
  /// In en, this message translates to:
  /// **'Choose videos from your characters'**
  String get playlistChooseCharacter;

  /// No description provided for @playlistFromPhone.
  ///
  /// In en, this message translates to:
  /// **'Import from phone'**
  String get playlistFromPhone;

  /// No description provided for @playlistFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Add existing device videos'**
  String get playlistFromDevice;

  /// No description provided for @playlistPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not select a video. Please try again.'**
  String get playlistPickFailed;

  /// No description provided for @playlistPendingSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Pending items could not be saved and may be lost when you leave. Please retry.'**
  String get playlistPendingSaveFailed;

  /// No description provided for @playlistRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get playlistRetry;

  /// No description provided for @playlistReselectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select the source video again'**
  String get playlistReselectTitle;

  /// No description provided for @playlistReselectNote.
  ///
  /// In en, this message translates to:
  /// **'The file moved or its temporary cache was cleared. The playlist entry remains. Select the source again and confirm its framing.'**
  String get playlistReselectNote;

  /// No description provided for @playlistCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get playlistCancel;

  /// No description provided for @playlistReselect.
  ///
  /// In en, this message translates to:
  /// **'Select again'**
  String get playlistReselect;

  /// No description provided for @playlistReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the video. Please try again.'**
  String get playlistReadFailed;

  /// No description provided for @playlistOriginalTitle.
  ///
  /// In en, this message translates to:
  /// **'Original video required'**
  String get playlistOriginalTitle;

  /// No description provided for @playlistOriginalNote.
  ///
  /// In en, this message translates to:
  /// **'Only the filename is available on the device. Choose the original video from your phone to adjust its framing. Saving records only the framing; converting and uploading adds a new device file and keeps the original.'**
  String get playlistOriginalNote;

  /// No description provided for @playlistChooseOriginal.
  ///
  /// In en, this message translates to:
  /// **'Choose original video'**
  String get playlistChooseOriginal;

  /// No description provided for @playlistOriginalFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the original video. Please try again.'**
  String get playlistOriginalFailed;

  /// No description provided for @playlistRemovePending.
  ///
  /// In en, this message translates to:
  /// **'Remove pending video?'**
  String get playlistRemovePending;

  /// No description provided for @playlistRemovePendingNote.
  ///
  /// In en, this message translates to:
  /// **'Only this playlist entry will be removed. Phone and device videos are retained.'**
  String get playlistRemovePendingNote;

  /// No description provided for @playlistRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get playlistRemove;

  /// No description provided for @playlistReadLocalFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the local playlist. Please retry.'**
  String get playlistReadLocalFailed;

  /// No description provided for @playlistSaveLocalFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the local playlist. Please retry.'**
  String get playlistSaveLocalFailed;

  /// No description provided for @playlistAddDevice.
  ///
  /// In en, this message translates to:
  /// **'Add from device library'**
  String get playlistAddDevice;

  /// No description provided for @playlistAllAdded.
  ///
  /// In en, this message translates to:
  /// **'All device videos are already in this draft.'**
  String get playlistAllAdded;

  /// No description provided for @playlistConnectFirst.
  ///
  /// In en, this message translates to:
  /// **'Connect the device before playing.'**
  String get playlistConnectFirst;

  /// No description provided for @playlistNotUploaded.
  ///
  /// In en, this message translates to:
  /// **'This video is not on the device. Conversion and upload are required before playback.'**
  String get playlistNotUploaded;

  /// No description provided for @playlistRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from playlist?'**
  String get playlistRemoveTitle;

  /// No description provided for @playlistRemoveList.
  ///
  /// In en, this message translates to:
  /// **'Remove from playlist'**
  String get playlistRemoveList;

  /// No description provided for @playlistUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get playlistUndo;

  /// No description provided for @playlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Device playlists'**
  String get playlistTitle;

  /// No description provided for @playlistReadDevice.
  ///
  /// In en, this message translates to:
  /// **'Read device videos'**
  String get playlistReadDevice;

  /// No description provided for @playlistStartup.
  ///
  /// In en, this message translates to:
  /// **'Startup'**
  String get playlistStartup;

  /// No description provided for @playlistBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get playlistBluetooth;

  /// No description provided for @playlistStartupNote.
  ///
  /// In en, this message translates to:
  /// **'The device plays this playlist at startup.'**
  String get playlistStartupNote;

  /// No description provided for @playlistBluetoothNote.
  ///
  /// In en, this message translates to:
  /// **'The device switches to this playlist when Bluetooth connects.'**
  String get playlistBluetoothNote;

  /// No description provided for @playlistLoop.
  ///
  /// In en, this message translates to:
  /// **'Repeat mode'**
  String get playlistLoop;

  /// No description provided for @playlistListLoop.
  ///
  /// In en, this message translates to:
  /// **'Repeat playlist'**
  String get playlistListLoop;

  /// No description provided for @playlistSingleLoop.
  ///
  /// In en, this message translates to:
  /// **'Repeat one'**
  String get playlistSingleLoop;

  /// No description provided for @playlistOnce.
  ///
  /// In en, this message translates to:
  /// **'Play once'**
  String get playlistOnce;

  /// No description provided for @playlistOrder.
  ///
  /// In en, this message translates to:
  /// **'Playback order'**
  String get playlistOrder;

  /// No description provided for @playlistAddVideo.
  ///
  /// In en, this message translates to:
  /// **'Add video'**
  String get playlistAddVideo;

  /// No description provided for @playlistPendingLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load pending items. Tap to retry.'**
  String get playlistPendingLoadFailed;

  /// No description provided for @playlistPending.
  ///
  /// In en, this message translates to:
  /// **'Pending videos · Not uploaded to device'**
  String get playlistPending;

  /// No description provided for @playlistPendingNote.
  ///
  /// In en, this message translates to:
  /// **'Pending entries reference the original files. Conversion is not yet available. Keep source files in place after framing.'**
  String get playlistPendingNote;

  /// No description provided for @playlistConvertPending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting conversion · Not uploaded'**
  String get playlistConvertPending;

  /// No description provided for @playlistFrame.
  ///
  /// In en, this message translates to:
  /// **'Adjust framing'**
  String get playlistFrame;

  /// No description provided for @playlistRemovePendingAction.
  ///
  /// In en, this message translates to:
  /// **'Remove pending video'**
  String get playlistRemovePendingAction;

  /// No description provided for @playlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'This playlist is empty'**
  String get playlistEmpty;

  /// No description provided for @playlistFirst.
  ///
  /// In en, this message translates to:
  /// **'Default first video'**
  String get playlistFirst;

  /// No description provided for @playlistUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get playlistUp;

  /// No description provided for @playlistDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get playlistDown;

  /// No description provided for @playlistRemoveDraft.
  ///
  /// In en, this message translates to:
  /// **'Remove from draft'**
  String get playlistRemoveDraft;

  /// No description provided for @playlistSaveDevice.
  ///
  /// In en, this message translates to:
  /// **'Save to device · Awaiting protocol support'**
  String get playlistSaveDevice;

  /// No description provided for @playlistRecovery.
  ///
  /// In en, this message translates to:
  /// **'After Bluetooth disconnects'**
  String get playlistRecovery;

  /// No description provided for @playlistRecoveryNote.
  ///
  /// In en, this message translates to:
  /// **'Resume the previous device video when supported. Awaiting protocol confirmation.'**
  String get playlistRecoveryNote;

  /// No description provided for @playlistDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Device disconnected'**
  String get playlistDisconnected;

  /// No description provided for @playlistReadDeviceFailed.
  ///
  /// In en, this message translates to:
  /// **'Network connected · Could not read device'**
  String get playlistReadDeviceFailed;

  /// No description provided for @playlistReadDeviceReady.
  ///
  /// In en, this message translates to:
  /// **'Network connected · Tap to read'**
  String get playlistReadDeviceReady;

  /// No description provided for @playlistReadNote.
  ///
  /// In en, this message translates to:
  /// **'Read device content to verify the control connection.'**
  String get playlistReadNote;

  /// No description provided for @playlistConnectNote.
  ///
  /// In en, this message translates to:
  /// **'Connect to device Wi-Fi, then read its playlist.'**
  String get playlistConnectNote;

  /// No description provided for @playlistRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get playlistRead;

  /// No description provided for @playlistSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} · Original framing'**
  String playlistSourceTitle(String name);

  /// No description provided for @playlistSent.
  ///
  /// In en, this message translates to:
  /// **'Sent to device: {name}'**
  String playlistSent(String name);

  /// No description provided for @playlistRemoveNote.
  ///
  /// In en, this message translates to:
  /// **'Remove “{name}” from this playlist only. Phone and device files are retained.'**
  String playlistRemoveNote(String name);

  /// No description provided for @playlistRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed {name} from the playlist'**
  String playlistRemoved(String name);

  /// No description provided for @playlistCount.
  ///
  /// In en, this message translates to:
  /// **'{count} videos'**
  String playlistCount(int count);

  /// No description provided for @playlistDeviceCount.
  ///
  /// In en, this message translates to:
  /// **'Device responding · {count} videos'**
  String playlistDeviceCount(int count);

  /// No description provided for @submissionDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved. Upload your videos, then submit for review.'**
  String get submissionDraftSaved;

  /// No description provided for @submissionTitle.
  ///
  /// In en, this message translates to:
  /// **'My submissions'**
  String get submissionTitle;

  /// No description provided for @submissionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh submissions'**
  String get submissionRefresh;

  /// No description provided for @submissionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create submission'**
  String get submissionCreate;

  /// No description provided for @submissionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No submissions yet. Create a draft, upload your videos and submit after validation.'**
  String get submissionEmpty;

  /// No description provided for @submissionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Submission updated.'**
  String get submissionUpdated;

  /// No description provided for @submissionFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get submissionFree;

  /// No description provided for @submissionPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get submissionPaid;

  /// No description provided for @submissionPrice.
  ///
  /// In en, this message translates to:
  /// **'Price (USD)'**
  String get submissionPrice;

  /// No description provided for @submissionDecimals.
  ///
  /// In en, this message translates to:
  /// **'Up to two decimal places'**
  String get submissionDecimals;

  /// No description provided for @submissionInvalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive USD price with up to two decimal places.'**
  String get submissionInvalidPrice;

  /// No description provided for @submissionReviewNote.
  ///
  /// In en, this message translates to:
  /// **'All videos require review before publication.'**
  String get submissionReviewNote;

  /// No description provided for @submissionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get submissionCancel;

  /// No description provided for @submissionSavePrice.
  ///
  /// In en, this message translates to:
  /// **'Save price'**
  String get submissionSavePrice;

  /// No description provided for @submissionSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted for review. Editing is locked while under review.'**
  String get submissionSubmitted;

  /// No description provided for @submissionPartnerNote.
  ///
  /// In en, this message translates to:
  /// **'Partners may publish free or paid videos. All content requires review.'**
  String get submissionPartnerNote;

  /// No description provided for @submissionFreeNote.
  ///
  /// In en, this message translates to:
  /// **'Submit free videos or character collections for review.'**
  String get submissionFreeNote;

  /// No description provided for @submissionCharacterPackage.
  ///
  /// In en, this message translates to:
  /// **'Character collection'**
  String get submissionCharacterPackage;

  /// No description provided for @submissionSingleVideo.
  ///
  /// In en, this message translates to:
  /// **'Single video'**
  String get submissionSingleVideo;

  /// No description provided for @submissionRejectedReason.
  ///
  /// In en, this message translates to:
  /// **'Changes requested'**
  String get submissionRejectedReason;

  /// No description provided for @submissionReviewFeedback.
  ///
  /// In en, this message translates to:
  /// **'Review feedback'**
  String get submissionReviewFeedback;

  /// No description provided for @submissionName.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get submissionName;

  /// No description provided for @submissionNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a title.'**
  String get submissionNameRequired;

  /// No description provided for @submissionFormat.
  ///
  /// In en, this message translates to:
  /// **'Content format'**
  String get submissionFormat;

  /// No description provided for @submissionSingle.
  ///
  /// In en, this message translates to:
  /// **'Single video'**
  String get submissionSingle;

  /// No description provided for @submissionPackage.
  ///
  /// In en, this message translates to:
  /// **'Video collection'**
  String get submissionPackage;

  /// No description provided for @submissionTags.
  ///
  /// In en, this message translates to:
  /// **'Content tags'**
  String get submissionTags;

  /// No description provided for @submissionNoTags.
  ///
  /// In en, this message translates to:
  /// **'Content tags are not available yet.'**
  String get submissionNoTags;

  /// No description provided for @submissionStory.
  ///
  /// In en, this message translates to:
  /// **'Background story'**
  String get submissionStory;

  /// No description provided for @submissionStoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a background story.'**
  String get submissionStoryRequired;

  /// No description provided for @submissionVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get submissionVideos;

  /// No description provided for @submissionAddVideo.
  ///
  /// In en, this message translates to:
  /// **'Add video'**
  String get submissionAddVideo;

  /// No description provided for @submissionRemoveVideo.
  ///
  /// In en, this message translates to:
  /// **'Remove video'**
  String get submissionRemoveVideo;

  /// No description provided for @submissionVideoNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a video title.'**
  String get submissionVideoNameRequired;

  /// No description provided for @submissionSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get submissionSaveDraft;

  /// No description provided for @submissionSaveInfo.
  ///
  /// In en, this message translates to:
  /// **'Save details'**
  String get submissionSaveInfo;

  /// No description provided for @submissionCoverUploaded.
  ///
  /// In en, this message translates to:
  /// **'Cover uploaded'**
  String get submissionCoverUploaded;

  /// No description provided for @submissionCover.
  ///
  /// In en, this message translates to:
  /// **'Collection cover'**
  String get submissionCover;

  /// No description provided for @submissionCoverTypes.
  ///
  /// In en, this message translates to:
  /// **'JPG or PNG'**
  String get submissionCoverTypes;

  /// No description provided for @submissionReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get submissionReplace;

  /// No description provided for @submissionUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get submissionUpload;

  /// No description provided for @submissionSetPrice.
  ///
  /// In en, this message translates to:
  /// **'Set price'**
  String get submissionSetPrice;

  /// No description provided for @submissionMakeFree.
  ///
  /// In en, this message translates to:
  /// **'Make free'**
  String get submissionMakeFree;

  /// No description provided for @submissionReplaceMp4.
  ///
  /// In en, this message translates to:
  /// **'Replace MP4'**
  String get submissionReplaceMp4;

  /// No description provided for @submissionUploadMp4.
  ///
  /// In en, this message translates to:
  /// **'Upload MP4'**
  String get submissionUploadMp4;

  /// No description provided for @submissionCheckVideo.
  ///
  /// In en, this message translates to:
  /// **'Validate video'**
  String get submissionCheckVideo;

  /// No description provided for @submissionResubmit.
  ///
  /// In en, this message translates to:
  /// **'Resubmit for review'**
  String get submissionResubmit;

  /// No description provided for @submissionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get submissionSubmit;

  /// No description provided for @submissionRequirements.
  ///
  /// In en, this message translates to:
  /// **'Validate every video before submitting. Collections also require a cover.'**
  String get submissionRequirements;

  /// No description provided for @submissionInfo.
  ///
  /// In en, this message translates to:
  /// **'Content details'**
  String get submissionInfo;

  /// No description provided for @submissionNoStory.
  ///
  /// In en, this message translates to:
  /// **'No background story yet.'**
  String get submissionNoStory;

  /// No description provided for @submissionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get submissionRetry;

  /// No description provided for @submissionPending.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get submissionPending;

  /// No description provided for @submissionPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get submissionPublished;

  /// No description provided for @submissionApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved, awaiting publication'**
  String get submissionApproved;

  /// No description provided for @submissionRejected.
  ///
  /// In en, this message translates to:
  /// **'Changes requested'**
  String get submissionRejected;

  /// No description provided for @submissionDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get submissionDraft;

  /// No description provided for @submissionNoMedia.
  ///
  /// In en, this message translates to:
  /// **'No video uploaded'**
  String get submissionNoMedia;

  /// No description provided for @submissionChecked.
  ///
  /// In en, this message translates to:
  /// **'Validation passed'**
  String get submissionChecked;

  /// No description provided for @submissionProcessing.
  ///
  /// In en, this message translates to:
  /// **'Validating video'**
  String get submissionProcessing;

  /// No description provided for @submissionFailed.
  ///
  /// In en, this message translates to:
  /// **'Validation failed. Replace the video and try again.'**
  String get submissionFailed;

  /// No description provided for @submissionWaiting.
  ///
  /// In en, this message translates to:
  /// **'Uploaded, awaiting validation'**
  String get submissionWaiting;

  /// No description provided for @submissionApprovalError.
  ///
  /// In en, this message translates to:
  /// **'Creator access is not approved or is suspended. Check the verification page.'**
  String get submissionApprovalError;

  /// No description provided for @submissionDataError.
  ///
  /// In en, this message translates to:
  /// **'The submission data could not be read. Refresh and try again.'**
  String get submissionDataError;

  /// No description provided for @submissionLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load submissions. Please try again later.'**
  String get submissionLoadError;

  /// No description provided for @submissionSessionError.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Sign in again.'**
  String get submissionSessionError;

  /// No description provided for @submissionAccessError.
  ///
  /// In en, this message translates to:
  /// **'An active verified creator account is required.'**
  String get submissionAccessError;

  /// No description provided for @submissionPaidError.
  ///
  /// In en, this message translates to:
  /// **'Paid pricing is unavailable for this account. Make the video free before submitting.'**
  String get submissionPaidError;

  /// No description provided for @submissionPriceError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid USD price with up to two decimal places.'**
  String get submissionPriceError;

  /// No description provided for @submissionConflictError.
  ///
  /// In en, this message translates to:
  /// **'The submission changed. Refresh and try again.'**
  String get submissionConflictError;

  /// No description provided for @submissionMediaError.
  ///
  /// In en, this message translates to:
  /// **'Upload and validate every video first.'**
  String get submissionMediaError;

  /// No description provided for @submissionCoverError.
  ///
  /// In en, this message translates to:
  /// **'Upload a collection cover first.'**
  String get submissionCoverError;

  /// No description provided for @submissionTagError.
  ///
  /// In en, this message translates to:
  /// **'Some tags are no longer available. Refresh and select again.'**
  String get submissionTagError;

  /// No description provided for @submissionServerError.
  ///
  /// In en, this message translates to:
  /// **'The service is unavailable. Please try again later.'**
  String get submissionServerError;

  /// No description provided for @submissionRequestError.
  ///
  /// In en, this message translates to:
  /// **'The action could not finish. Check your content and try again.'**
  String get submissionRequestError;

  /// No description provided for @submissionAccountChanged.
  ///
  /// In en, this message translates to:
  /// **'Your account changed. Refresh submissions.'**
  String get submissionAccountChanged;

  /// No description provided for @submissionPreviewError.
  ///
  /// In en, this message translates to:
  /// **'The video is not uploaded or preview is unavailable.'**
  String get submissionPreviewError;

  /// No description provided for @submissionVideoPrice.
  ///
  /// In en, this message translates to:
  /// **'Video price · {name}'**
  String submissionVideoPrice(String name);

  /// No description provided for @submissionVideoName.
  ///
  /// In en, this message translates to:
  /// **'Video {index} title'**
  String submissionVideoName(int index);

  /// No description provided for @submissionLegacyTag.
  ///
  /// In en, this message translates to:
  /// **'{name} (legacy)'**
  String submissionLegacyTag(String name);

  /// No description provided for @p20Refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh device playlist'**
  String get p20Refresh;

  /// No description provided for @p20Daily.
  ///
  /// In en, this message translates to:
  /// **'A Daily'**
  String get p20Daily;

  /// No description provided for @p20Bluetooth.
  ///
  /// In en, this message translates to:
  /// **'B Bluetooth'**
  String get p20Bluetooth;

  /// No description provided for @p20ConnectNote.
  ///
  /// In en, this message translates to:
  /// **'Connect to see the playlist stored on your device'**
  String get p20ConnectNote;

  /// No description provided for @p20ConnectWifi.
  ///
  /// In en, this message translates to:
  /// **'Join the device Wi-Fi on your phone, then tap Connect device.'**
  String get p20ConnectWifi;

  /// No description provided for @p20Connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get p20Connecting;

  /// No description provided for @p20Connect.
  ///
  /// In en, this message translates to:
  /// **'Connect device'**
  String get p20Connect;

  /// No description provided for @p20Reading.
  ///
  /// In en, this message translates to:
  /// **'Reading device playlist…'**
  String get p20Reading;

  /// No description provided for @p20ReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the device playlist'**
  String get p20ReadFailed;

  /// No description provided for @p20Mode.
  ///
  /// In en, this message translates to:
  /// **'Playback mode (shared by A/B)'**
  String get p20Mode;

  /// No description provided for @p20OrderNote.
  ///
  /// In en, this message translates to:
  /// **'The order comes from your device. Moving a video updates the device and reads back the confirmed order.'**
  String get p20OrderNote;

  /// No description provided for @p20Empty.
  ///
  /// In en, this message translates to:
  /// **'This device playlist is empty'**
  String get p20Empty;

  /// No description provided for @p20Pending.
  ///
  /// In en, this message translates to:
  /// **'Videos ready to upload'**
  String get p20Pending;

  /// No description provided for @p20PendingNote.
  ///
  /// In en, this message translates to:
  /// **'These videos are waiting on your phone and have not been uploaded to the device.'**
  String get p20PendingNote;

  /// No description provided for @p20Unconfirmed.
  ///
  /// In en, this message translates to:
  /// **'The device did not confirm the change. Its current state has been refreshed. Check it and try again.'**
  String get p20Unconfirmed;

  /// No description provided for @p20UploadEntry.
  ///
  /// In en, this message translates to:
  /// **'Open from a device playlist to upload'**
  String get p20UploadEntry;

  /// No description provided for @p20UploadAction.
  ///
  /// In en, this message translates to:
  /// **'Convert and upload'**
  String get p20UploadAction;

  /// No description provided for @p20FramingNote.
  ///
  /// In en, this message translates to:
  /// **'Saving records only the framing. Tap Convert and upload to prepare and transfer the device files.'**
  String get p20FramingNote;

  /// No description provided for @p20ConnectedCount.
  ///
  /// In en, this message translates to:
  /// **'Device connected · {count} videos'**
  String p20ConnectedCount(int count);

  /// No description provided for @p20UploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload to device'**
  String get p20UploadTitle;

  /// No description provided for @p20UploadStart.
  ///
  /// In en, this message translates to:
  /// **'Prepare and upload'**
  String get p20UploadStart;

  /// No description provided for @p20UploadCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel upload'**
  String get p20UploadCancel;

  /// No description provided for @p20UploadClose.
  ///
  /// In en, this message translates to:
  /// **'Back to playlist'**
  String get p20UploadClose;

  /// No description provided for @p20UploadDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Connect to the device from Home before uploading.'**
  String get p20UploadDisconnected;

  /// No description provided for @p20UploadDaily.
  ///
  /// In en, this message translates to:
  /// **'A daily playlist accepts videos with or without sound. With audio: extract MP3, convert, upload audio then video. Without audio: convert and upload video only.'**
  String get p20UploadDaily;

  /// No description provided for @p20UploadBluetooth.
  ///
  /// In en, this message translates to:
  /// **'B Bluetooth playlist accepts videos with or without sound. Convert and upload video only; source audio is ignored.'**
  String get p20UploadBluetooth;

  /// No description provided for @p20UploadSettings.
  ///
  /// In en, this message translates to:
  /// **'298 × 298 · 20 fps · Current framing'**
  String get p20UploadSettings;

  /// No description provided for @p20UploadDownloadFirst.
  ///
  /// In en, this message translates to:
  /// **'Download this video to My Characters before uploading to the device.'**
  String get p20UploadDownloadFirst;

  /// No description provided for @p20UploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Preparation or upload failed. Check the video, device connection and storage, then try again.'**
  String get p20UploadFailed;

  /// No description provided for @p20UploadConfirmedProgress.
  ///
  /// In en, this message translates to:
  /// **'Confirmed by the device'**
  String get p20UploadConfirmedProgress;

  /// No description provided for @p20UploadFailureStageLabel.
  ///
  /// In en, this message translates to:
  /// **'Failed during'**
  String get p20UploadFailureStageLabel;

  /// No description provided for @p20UploadConfirmedLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get p20UploadConfirmedLabel;

  /// No description provided for @p20UploadBytesLabel.
  ///
  /// In en, this message translates to:
  /// **'bytes'**
  String get p20UploadBytesLabel;

  /// No description provided for @p20UploadBusy.
  ///
  /// In en, this message translates to:
  /// **'Device is busy. Try again shortly.'**
  String get p20UploadBusy;

  /// No description provided for @p20UploadWriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Device could not write the file. Check its storage card.'**
  String get p20UploadWriteFailed;

  /// No description provided for @p20UploadAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'The file already exists on the device.'**
  String get p20UploadAlreadyExists;

  /// No description provided for @p20UploadStorageFull.
  ///
  /// In en, this message translates to:
  /// **'Device storage or playlist is full.'**
  String get p20UploadStorageFull;

  /// No description provided for @p20UploadBatteryLow.
  ///
  /// In en, this message translates to:
  /// **'Device battery is too low. Charge it and retry.'**
  String get p20UploadBatteryLow;

  /// No description provided for @p20UploadRejected.
  ///
  /// In en, this message translates to:
  /// **'Device rejected the file.'**
  String get p20UploadRejected;

  /// No description provided for @p20UploadConfirmationTimeout.
  ///
  /// In en, this message translates to:
  /// **'Device confirmation timed out. Note the stage and progress below, then reconnect.'**
  String get p20UploadConfirmationTimeout;

  /// No description provided for @p20UploadProcessingTimeout.
  ///
  /// In en, this message translates to:
  /// **'Media processing timed out. Try a shorter video.'**
  String get p20UploadProcessingTimeout;

  /// No description provided for @p20UploadConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'Device connection was lost. Reconnect and retry.'**
  String get p20UploadConnectionLost;

  /// No description provided for @p20UploadLocalFileError.
  ///
  /// In en, this message translates to:
  /// **'Cannot read or write local files. Check the source and available phone storage.'**
  String get p20UploadLocalFileError;

  /// No description provided for @p20UploadInvalidReply.
  ///
  /// In en, this message translates to:
  /// **'Device reply or progress sequence did not match. Check the firmware protocol.'**
  String get p20UploadInvalidReply;

  /// No description provided for @p20UploadPartial.
  ///
  /// In en, this message translates to:
  /// **'Audio was uploaded but video did not finish. No device files have been deleted or automatically retried.'**
  String get p20UploadPartial;

  /// No description provided for @p20UploadRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'The device confirmed the upload, but the playlist could not be refreshed. Reconnect and refresh; do not upload again.'**
  String get p20UploadRefreshFailed;

  /// No description provided for @p20UploadCleanupPending.
  ///
  /// In en, this message translates to:
  /// **'Temporary files are still in use and have been retained.'**
  String get p20UploadCleanupPending;

  /// No description provided for @p20UploadWaitingAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Waiting for upload acceptance'**
  String get p20UploadWaitingAcceptance;

  /// No description provided for @p20UploadTransferring.
  ///
  /// In en, this message translates to:
  /// **'Transferring file'**
  String get p20UploadTransferring;

  /// No description provided for @p20UploadWaitingCompletion.
  ///
  /// In en, this message translates to:
  /// **'Waiting for completion confirmation'**
  String get p20UploadWaitingCompletion;

  /// No description provided for @p20UploadConfirmedCompletion.
  ///
  /// In en, this message translates to:
  /// **'Device confirmed completion'**
  String get p20UploadConfirmedCompletion;

  /// No description provided for @p20UploadReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get p20UploadReady;

  /// No description provided for @p20UploadExtractingAudio.
  ///
  /// In en, this message translates to:
  /// **'Checking and extracting audio if present'**
  String get p20UploadExtractingAudio;

  /// No description provided for @p20UploadConvertingVideo.
  ///
  /// In en, this message translates to:
  /// **'Converting video'**
  String get p20UploadConvertingVideo;

  /// No description provided for @p20UploadUploadingAudio.
  ///
  /// In en, this message translates to:
  /// **'Uploading audio'**
  String get p20UploadUploadingAudio;

  /// No description provided for @p20UploadUploadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Uploading video'**
  String get p20UploadUploadingVideo;

  /// No description provided for @p20UploadRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing playlist'**
  String get p20UploadRefreshing;

  /// No description provided for @p20UploadComplete.
  ///
  /// In en, this message translates to:
  /// **'Upload complete'**
  String get p20UploadComplete;

  /// No description provided for @p20UploadIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Upload incomplete'**
  String get p20UploadIncomplete;

  /// No description provided for @p20UploadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get p20UploadCancelled;

  /// No description provided for @p20SingleOnce.
  ///
  /// In en, this message translates to:
  /// **'Play once'**
  String get p20SingleOnce;

  /// No description provided for @p20UploadFailureStage.
  ///
  /// In en, this message translates to:
  /// **'Failed during: {stage}'**
  String p20UploadFailureStage(String stage);

  /// No description provided for @p20UploadTransferDetails.
  ///
  /// In en, this message translates to:
  /// **'{phase} · Confirmed {acknowledged} / {total} bytes'**
  String p20UploadTransferDetails(String phase, int acknowledged, int total);

  /// No description provided for @creatorMediaOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open this video. Refresh your submissions and try again.'**
  String get creatorMediaOpenFailed;

  /// No description provided for @creatorMediaPreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview video: {title}'**
  String creatorMediaPreviewLabel(String title);

  /// No description provided for @creatorMediaThumbnailPending.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail not ready. Tap to preview.'**
  String get creatorMediaThumbnailPending;

  /// No description provided for @creatorMediaPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview video'**
  String get creatorMediaPreview;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
