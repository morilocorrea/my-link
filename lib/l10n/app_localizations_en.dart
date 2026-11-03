// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MyLink';

  @override
  String get appSlogan => 'Your links, always at hand';

  @override
  String get startupError =>
      'Unable to read saved data. No data was overwritten. Close the app and verify storage before trying again.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get saving => 'Saving…';

  @override
  String get add => 'Add';

  @override
  String get close => 'Close';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get generate => 'Generate';

  @override
  String get tryAgain => 'Try again';

  @override
  String get unexpectedError => 'Unable to complete. Please try again.';

  @override
  String get welcomeTitle => 'Your links, organized';

  @override
  String get welcomeSubtitle =>
      'Save URLs, create categories, mark favorites, and take your CSV backup with you.';

  @override
  String get welcomeGetStarted => 'Get Started';

  @override
  String get welcomeFooter => 'Designed to simplify the way you save the web.';

  @override
  String get welcomeSaveError => 'Could not save. Please try again.';

  @override
  String get drawerAddLink => 'Add link';

  @override
  String get drawerScanQr => 'Scan QR Code';

  @override
  String get drawerGenerateQr => 'Generate QR Code';

  @override
  String get drawerExportCsv => 'Export CSV';

  @override
  String get drawerImportCsv => 'Import CSV';

  @override
  String get drawerImportingCsv => 'Importing…';

  @override
  String get drawerGoogleDrive => 'Google Drive';

  @override
  String get drawerGoogleDriveSubtitle => 'Backup and restore';

  @override
  String get drawerSettings => 'Settings';

  @override
  String get tabHome => 'Home';

  @override
  String get tabCategory => 'Category';

  @override
  String get tabTimeLine => 'TimeLine';

  @override
  String get tabFavorite => 'Favorite';

  @override
  String get sortNewest => 'New First';

  @override
  String get sortOldest => 'Old First';

  @override
  String get sortAz => 'A to Z';

  @override
  String get sortZa => 'Z to A';

  @override
  String get sortTooltip => 'Sort links';

  @override
  String get searchHint => 'Search title, URL, or category…';

  @override
  String get emptyNoResults => 'No results found.';

  @override
  String get emptyFavorites => 'No favorite links.';

  @override
  String get emptyHome => 'You haven\'t added any URLs here yet.';

  @override
  String get emptyCategories => 'No categories found.';

  @override
  String get createCategory => 'Create category';

  @override
  String get addUrl => 'Add URL';

  @override
  String linksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count links',
      one: '1 link',
    );
    return '$_temp0';
  }

  @override
  String get backToCategories => 'Back to categories';

  @override
  String get linkOptionsTooltip => 'Link options';

  @override
  String get markFavoriteTooltip => 'Mark as favorite';

  @override
  String get removeFavoriteTooltip => 'Remove from favorites';

  @override
  String get copyUrl => 'Copy URL';

  @override
  String get shareUrl => 'Share URL';

  @override
  String get openInExternalBrowser => 'Open in external browser';

  @override
  String get deleteLinkConfirmTitle => 'Delete link?';

  @override
  String get deleteLinkConfirmMessage => 'This action cannot be undone.';

  @override
  String get linkCopied => 'Link copied.';

  @override
  String get dialogAddUrlTitle => 'Add URL';

  @override
  String get dialogEditUrlTitle => 'Edit link';

  @override
  String get inputTitle => 'Title';

  @override
  String get inputUrl => 'URL';

  @override
  String get inputCategory => 'Category';

  @override
  String get pasteLinkTooltip => 'Paste link';

  @override
  String get newCategory => 'New category';

  @override
  String get selectCategoryError => 'Create or select a category.';

  @override
  String get saveDataError => 'Failed to save data.';

  @override
  String get dialogNewCategoryTitle => 'New category';

  @override
  String get inputName => 'Name';

  @override
  String deleteCategoryConfirmTitle(String category) {
    return 'Delete $category?';
  }

  @override
  String deleteCategoryConfirmMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count links in this category will also be deleted.',
      one: '1 link in this category will also be deleted.',
    );
    return '$_temp0';
  }

  @override
  String get deleteCategoryTooltip => 'Delete category';

  @override
  String get shareReceiveError => 'Could not receive shared item.';

  @override
  String get shareReadError => 'Could not read shared link.';

  @override
  String get noValidUrlFound => 'No HTTP/HTTPS URL found.';

  @override
  String get qrNoHttpUrl => 'The QR Code does not contain an HTTP/HTTPS URL.';

  @override
  String get qrCode => 'QR Code';

  @override
  String get generateQrCode => 'Generate QR Code';

  @override
  String get noLinksToExport => 'No links available to export.';

  @override
  String get exportLinksDialogTitle => 'Export links';

  @override
  String get csvExported => 'CSV exported.';

  @override
  String get importCsvConfirmTitle => 'Import CSV?';

  @override
  String get importCsvConfirmMessage =>
      'Links will be added to your library. Importing the same file again may create duplicates.';

  @override
  String get importSuccess => 'Import completed.';

  @override
  String get fileReadError => 'Unable to read file.';

  @override
  String csvSizeLimitError(int maxSizeMb) {
    return 'The CSV must be at most $maxSizeMb MB.';
  }

  @override
  String get openBrowserError => 'Unable to open browser.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get themeAppTitle => 'App Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get sectionInformation => 'Information';

  @override
  String get aboutAppTitle => 'About the App';

  @override
  String get aboutAppSubtitle => 'Version, developer, and useful links.';

  @override
  String get aboutTitle => 'About';

  @override
  String get sectionTechnicalDetails => 'Technical Details';

  @override
  String get labelVersion => 'Version';

  @override
  String get labelBuild => 'Build';

  @override
  String get labelDeveloper => 'Developer';

  @override
  String get sectionUsefulLinks => 'Useful Links';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicyError => 'Unable to open privacy policy.';

  @override
  String get scanQrTitle => 'Scan QR Code';

  @override
  String get cameraPermissionError =>
      'Grant camera permission in device settings and try again.';

  @override
  String get cameraUnavailableError =>
      'Camera unavailable. You can add the link manually.';

  @override
  String get reloadTooltip => 'Reload';

  @override
  String get openExternalTooltip => 'Open externally';

  @override
  String get pageLoadError => 'Unable to load page.';

  @override
  String get googleDriveTitle => 'Google Drive';

  @override
  String get driveConfigMissingTitle => 'Missing OAuth Configuration';

  @override
  String get driveConfigMissingMessage =>
      'The GOOGLE_SERVER_CLIENT_ID variable was not provided in the .env file. Create the file from .env.example to enable the connection.';

  @override
  String get closeMessageTooltip => 'Close message';

  @override
  String get connectDriveTitle => 'Connect to Google Drive';

  @override
  String get connectDriveMessage =>
      'Connect your Google account to authorize access to Google Drive files managed by MyLink. Your local data remains saved on the device.';

  @override
  String get connectGoogleAccount => 'Connect Google Account';

  @override
  String get connecting => 'Connecting…';

  @override
  String get driveAuthorized => 'Drive Authorized';

  @override
  String get driveNotAuthorized => 'Drive Not Authorized';

  @override
  String get sectionAuthAndAccess => 'Authorization and Access';

  @override
  String get driveAuthorizedScopeInfo =>
      'The application is authorized to manage only files created or opened by it (drive.file scope).';

  @override
  String get driveNotAuthorizedScopeInfo =>
      'For the application to access files in Drive, you need to authorize the drive.file permission.';

  @override
  String get authorizeDrive => 'Authorize Drive';

  @override
  String get authorizing => 'Authorizing…';

  @override
  String get verifyApiAccess => 'Verify API Access';

  @override
  String get verifying => 'Verifying…';

  @override
  String get sectionDriveBackup => 'Backup on Google Drive';

  @override
  String get refreshInfoTooltip => 'Refresh information';

  @override
  String get backupDescription =>
      'Save all your links and categories to Google Drive or restore your data on this device.';

  @override
  String get checkingBackup => 'Checking backup on Google Drive…';

  @override
  String get backupAvailableCloud => 'Backup available in the cloud';

  @override
  String lastUploaded(String date) {
    return 'Last upload: $date';
  }

  @override
  String get noBackupFound => 'No backup found on Google Drive.';

  @override
  String get noLinksToBackup => 'No links available for backup.';

  @override
  String get backupNow => 'Back Up Now';

  @override
  String get backingUp => 'Uploading…';

  @override
  String get restoreBackup => 'Restore Backup';

  @override
  String get restoring => 'Restoring…';

  @override
  String get restoreBackupConfirmTitle => 'Restore Backup?';

  @override
  String get restoreBackupConfirmMessage =>
      'Links and categories saved in Google Drive will be added to your library on this device.';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutSubtitle =>
      'Disconnects your Google account from this app.';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutConfirmMessage =>
      'Your Google account will be disconnected from the application. Your locally saved links will not be modified.';

  @override
  String get revokeAccess => 'Revoke Google access';

  @override
  String get revokeAccessSubtitle =>
      'Revokes permissions granted by your Google account to this application.';

  @override
  String get revokeAccessConfirmTitle => 'Revoke access?';

  @override
  String get revokeAccessConfirmMessage =>
      'This action revokes all application authorizations in your Google account. No local links or Drive files will be deleted.';

  @override
  String get driveVerifiedStatus => 'Verified';
}
