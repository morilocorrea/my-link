import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MyLink'**
  String get appTitle;

  /// No description provided for @appSlogan.
  ///
  /// In en, this message translates to:
  /// **'Your links, always at hand'**
  String get appSlogan;

  /// No description provided for @startupError.
  ///
  /// In en, this message translates to:
  /// **'Unable to read saved data. No data was overwritten. Close the app and verify storage before trying again.'**
  String get startupError;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unable to complete. Please try again.'**
  String get unexpectedError;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your links, organized'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save URLs, create categories, mark favorites, and take your CSV backup with you.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get welcomeGetStarted;

  /// No description provided for @welcomeFooter.
  ///
  /// In en, this message translates to:
  /// **'Designed to simplify the way you save the web.'**
  String get welcomeFooter;

  /// No description provided for @welcomeSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Please try again.'**
  String get welcomeSaveError;

  /// No description provided for @drawerAddLink.
  ///
  /// In en, this message translates to:
  /// **'Add link'**
  String get drawerAddLink;

  /// No description provided for @drawerScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get drawerScanQr;

  /// No description provided for @drawerGenerateQr.
  ///
  /// In en, this message translates to:
  /// **'Generate QR Code'**
  String get drawerGenerateQr;

  /// No description provided for @drawerExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get drawerExportCsv;

  /// No description provided for @drawerImportCsv.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get drawerImportCsv;

  /// No description provided for @drawerImportingCsv.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get drawerImportingCsv;

  /// No description provided for @drawerGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get drawerGoogleDrive;

  /// No description provided for @drawerGoogleDriveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Backup and restore'**
  String get drawerGoogleDriveSubtitle;

  /// No description provided for @drawerSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get drawerSettings;

  /// No description provided for @drawerRateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate us'**
  String get drawerRateUs;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get tabCategory;

  /// No description provided for @tabTimeLine.
  ///
  /// In en, this message translates to:
  /// **'TimeLine'**
  String get tabTimeLine;

  /// No description provided for @tabFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get tabFavorite;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'New First'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Old First'**
  String get sortOldest;

  /// No description provided for @sortAz.
  ///
  /// In en, this message translates to:
  /// **'A to Z'**
  String get sortAz;

  /// No description provided for @sortZa.
  ///
  /// In en, this message translates to:
  /// **'Z to A'**
  String get sortZa;

  /// No description provided for @sortTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort links'**
  String get sortTooltip;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search title, URL, or category…'**
  String get searchHint;

  /// No description provided for @emptyNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get emptyNoResults;

  /// No description provided for @emptyFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorite links.'**
  String get emptyFavorites;

  /// No description provided for @emptyHome.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any URLs here yet.'**
  String get emptyHome;

  /// No description provided for @emptyCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories found.'**
  String get emptyCategories;

  /// No description provided for @createCategory.
  ///
  /// In en, this message translates to:
  /// **'Create category'**
  String get createCategory;

  /// No description provided for @addUrl.
  ///
  /// In en, this message translates to:
  /// **'Add URL'**
  String get addUrl;

  /// No description provided for @linksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 link} other{{count} links}}'**
  String linksCount(int count);

  /// No description provided for @backToCategories.
  ///
  /// In en, this message translates to:
  /// **'Back to categories'**
  String get backToCategories;

  /// No description provided for @linkOptionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Link options'**
  String get linkOptionsTooltip;

  /// No description provided for @markFavoriteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mark as favorite'**
  String get markFavoriteTooltip;

  /// No description provided for @removeFavoriteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFavoriteTooltip;

  /// No description provided for @copyUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy URL'**
  String get copyUrl;

  /// No description provided for @shareUrl.
  ///
  /// In en, this message translates to:
  /// **'Share URL'**
  String get shareUrl;

  /// No description provided for @openInExternalBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in external browser'**
  String get openInExternalBrowser;

  /// No description provided for @deleteLinkConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete link?'**
  String get deleteLinkConfirmTitle;

  /// No description provided for @deleteLinkConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteLinkConfirmMessage;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied.'**
  String get linkCopied;

  /// No description provided for @dialogAddUrlTitle.
  ///
  /// In en, this message translates to:
  /// **'Add URL'**
  String get dialogAddUrlTitle;

  /// No description provided for @dialogEditUrlTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit link'**
  String get dialogEditUrlTitle;

  /// No description provided for @inputTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get inputTitle;

  /// No description provided for @inputUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get inputUrl;

  /// No description provided for @inputCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get inputCategory;

  /// No description provided for @pasteLinkTooltip.
  ///
  /// In en, this message translates to:
  /// **'Paste link'**
  String get pasteLinkTooltip;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @selectCategoryError.
  ///
  /// In en, this message translates to:
  /// **'Create or select a category.'**
  String get selectCategoryError;

  /// No description provided for @saveDataError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save data.'**
  String get saveDataError;

  /// No description provided for @dialogNewCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get dialogNewCategoryTitle;

  /// No description provided for @inputName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get inputName;

  /// No description provided for @deleteCategoryConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {category}?'**
  String deleteCategoryConfirmTitle(String category);

  /// No description provided for @deleteCategoryConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 link in this category will also be deleted.} other{{count} links in this category will also be deleted.}}'**
  String deleteCategoryConfirmMessage(int count);

  /// No description provided for @deleteCategoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get deleteCategoryTooltip;

  /// No description provided for @shareReceiveError.
  ///
  /// In en, this message translates to:
  /// **'Could not receive shared item.'**
  String get shareReceiveError;

  /// No description provided for @shareReadError.
  ///
  /// In en, this message translates to:
  /// **'Could not read shared link.'**
  String get shareReadError;

  /// No description provided for @noValidUrlFound.
  ///
  /// In en, this message translates to:
  /// **'No HTTP/HTTPS URL found.'**
  String get noValidUrlFound;

  /// No description provided for @qrNoHttpUrl.
  ///
  /// In en, this message translates to:
  /// **'The QR Code does not contain an HTTP/HTTPS URL.'**
  String get qrNoHttpUrl;

  /// No description provided for @qrCode.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qrCode;

  /// No description provided for @generateQrCode.
  ///
  /// In en, this message translates to:
  /// **'Generate QR Code'**
  String get generateQrCode;

  /// No description provided for @noLinksToExport.
  ///
  /// In en, this message translates to:
  /// **'No links available to export.'**
  String get noLinksToExport;

  /// No description provided for @exportLinksDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Export links'**
  String get exportLinksDialogTitle;

  /// No description provided for @csvExported.
  ///
  /// In en, this message translates to:
  /// **'CSV exported.'**
  String get csvExported;

  /// No description provided for @importCsvConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Import CSV?'**
  String get importCsvConfirmTitle;

  /// No description provided for @importCsvConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Links will be added to your library. Importing the same file again may create duplicates.'**
  String get importCsvConfirmMessage;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import completed.'**
  String get importSuccess;

  /// No description provided for @fileReadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to read file.'**
  String get fileReadError;

  /// No description provided for @csvSizeLimitError.
  ///
  /// In en, this message translates to:
  /// **'The CSV must be at most {maxSizeMb} MB.'**
  String csvSizeLimitError(int maxSizeMb);

  /// No description provided for @openBrowserError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open browser.'**
  String get openBrowserError;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// No description provided for @themeAppTitle.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get themeAppTitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @sectionInformation.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get sectionInformation;

  /// No description provided for @aboutAppTitle.
  ///
  /// In en, this message translates to:
  /// **'About the App'**
  String get aboutAppTitle;

  /// No description provided for @aboutAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Version, developer, and useful links.'**
  String get aboutAppSubtitle;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @sectionTechnicalDetails.
  ///
  /// In en, this message translates to:
  /// **'Technical Details'**
  String get sectionTechnicalDetails;

  /// No description provided for @labelVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get labelVersion;

  /// No description provided for @labelBuild.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get labelBuild;

  /// No description provided for @labelDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get labelDeveloper;

  /// No description provided for @sectionUsefulLinks.
  ///
  /// In en, this message translates to:
  /// **'Useful Links'**
  String get sectionUsefulLinks;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicyError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open privacy policy.'**
  String get privacyPolicyError;

  /// No description provided for @scanQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrTitle;

  /// No description provided for @cameraPermissionRationaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera Access'**
  String get cameraPermissionRationaleTitle;

  /// No description provided for @cameraPermissionRationaleMessage.
  ///
  /// In en, this message translates to:
  /// **'To scan QR codes and automatically add links to your library, MyLink needs access to your device camera.'**
  String get cameraPermissionRationaleMessage;

  /// No description provided for @cameraPermissionError.
  ///
  /// In en, this message translates to:
  /// **'Grant camera permission in device settings and try again.'**
  String get cameraPermissionError;

  /// No description provided for @cameraUnavailableError.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable. You can add the link manually.'**
  String get cameraUnavailableError;

  /// No description provided for @reloadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reloadTooltip;

  /// No description provided for @openExternalTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open externally'**
  String get openExternalTooltip;

  /// No description provided for @pageLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load page.'**
  String get pageLoadError;

  /// No description provided for @googleDriveTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get googleDriveTitle;

  /// No description provided for @driveConfigMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Missing OAuth Configuration'**
  String get driveConfigMissingTitle;

  /// No description provided for @driveConfigMissingMessage.
  ///
  /// In en, this message translates to:
  /// **'The GOOGLE_SERVER_CLIENT_ID variable was not provided in the .env file. Create the file from .env.example to enable the connection.'**
  String get driveConfigMissingMessage;

  /// No description provided for @closeMessageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close message'**
  String get closeMessageTooltip;

  /// No description provided for @connectDriveTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to Google Drive'**
  String get connectDriveTitle;

  /// No description provided for @connectDriveMessage.
  ///
  /// In en, this message translates to:
  /// **'Connect your Google account to authorize access to Google Drive files managed by MyLink. Your local data remains saved on the device.'**
  String get connectDriveMessage;

  /// No description provided for @connectGoogleAccount.
  ///
  /// In en, this message translates to:
  /// **'Connect Google Account'**
  String get connectGoogleAccount;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @driveAuthorized.
  ///
  /// In en, this message translates to:
  /// **'Drive Authorized'**
  String get driveAuthorized;

  /// No description provided for @driveNotAuthorized.
  ///
  /// In en, this message translates to:
  /// **'Drive Not Authorized'**
  String get driveNotAuthorized;

  /// No description provided for @sectionAuthAndAccess.
  ///
  /// In en, this message translates to:
  /// **'Authorization and Access'**
  String get sectionAuthAndAccess;

  /// No description provided for @driveAuthorizedScopeInfo.
  ///
  /// In en, this message translates to:
  /// **'The application is authorized to manage only files created or opened by it (drive.file scope).'**
  String get driveAuthorizedScopeInfo;

  /// No description provided for @driveNotAuthorizedScopeInfo.
  ///
  /// In en, this message translates to:
  /// **'For the application to access files in Drive, you need to authorize the drive.file permission.'**
  String get driveNotAuthorizedScopeInfo;

  /// No description provided for @authorizeDrive.
  ///
  /// In en, this message translates to:
  /// **'Authorize Drive'**
  String get authorizeDrive;

  /// No description provided for @authorizing.
  ///
  /// In en, this message translates to:
  /// **'Authorizing…'**
  String get authorizing;

  /// No description provided for @verifyApiAccess.
  ///
  /// In en, this message translates to:
  /// **'Verify API Access'**
  String get verifyApiAccess;

  /// No description provided for @verifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying…'**
  String get verifying;

  /// No description provided for @sectionDriveBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup on Google Drive'**
  String get sectionDriveBackup;

  /// No description provided for @refreshInfoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh information'**
  String get refreshInfoTooltip;

  /// No description provided for @backupDescription.
  ///
  /// In en, this message translates to:
  /// **'Save all your links and categories to Google Drive or restore your data on this device.'**
  String get backupDescription;

  /// No description provided for @checkingBackup.
  ///
  /// In en, this message translates to:
  /// **'Checking backup on Google Drive…'**
  String get checkingBackup;

  /// No description provided for @backupAvailableCloud.
  ///
  /// In en, this message translates to:
  /// **'Backup available in the cloud'**
  String get backupAvailableCloud;

  /// No description provided for @lastUploaded.
  ///
  /// In en, this message translates to:
  /// **'Last upload: {date}'**
  String lastUploaded(String date);

  /// No description provided for @noBackupFound.
  ///
  /// In en, this message translates to:
  /// **'No backup found on Google Drive.'**
  String get noBackupFound;

  /// No description provided for @noLinksToBackup.
  ///
  /// In en, this message translates to:
  /// **'No links available for backup.'**
  String get noLinksToBackup;

  /// No description provided for @backupNow.
  ///
  /// In en, this message translates to:
  /// **'Back Up Now'**
  String get backupNow;

  /// No description provided for @backingUp.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get backingUp;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get restoreBackup;

  /// No description provided for @restoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring…'**
  String get restoring;

  /// No description provided for @restoreBackupConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup?'**
  String get restoreBackupConfirmTitle;

  /// No description provided for @restoreBackupConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Links and categories saved in Google Drive will be added to your library on this device.'**
  String get restoreBackupConfirmMessage;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnects your Google account from this app.'**
  String get signOutSubtitle;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Your Google account will be disconnected from the application. Your locally saved links will not be modified.'**
  String get signOutConfirmMessage;

  /// No description provided for @revokeAccess.
  ///
  /// In en, this message translates to:
  /// **'Revoke Google access'**
  String get revokeAccess;

  /// No description provided for @revokeAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Revokes permissions granted by your Google account to this application.'**
  String get revokeAccessSubtitle;

  /// No description provided for @revokeAccessConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke access?'**
  String get revokeAccessConfirmTitle;

  /// No description provided for @revokeAccessConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This action revokes all application authorizations in your Google account. No local links or Drive files will be deleted.'**
  String get revokeAccessConfirmMessage;

  /// No description provided for @driveVerifiedStatus.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get driveVerifiedStatus;
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
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
