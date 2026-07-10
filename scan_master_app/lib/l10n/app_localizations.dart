import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

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
    Locale('bn'),
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Scan Master: PDF Toolkit'**
  String get appName;

  /// No description provided for @viewerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search text in PDF...'**
  String get viewerSearchHint;

  /// No description provided for @actionShareDocument.
  ///
  /// In en, this message translates to:
  /// **'Share PDF...'**
  String get actionShareDocument;

  /// No description provided for @actionOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Open PDF...'**
  String get actionOpenFile;

  /// No description provided for @actionSaveToDevice.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get actionSaveToDevice;

  /// No description provided for @actionPrintPdf.
  ///
  /// In en, this message translates to:
  /// **'Print PDF'**
  String get actionPrintPdf;

  /// No description provided for @actionShareImage.
  ///
  /// In en, this message translates to:
  /// **'Share Image...'**
  String get actionShareImage;

  /// No description provided for @actionOpenImage.
  ///
  /// In en, this message translates to:
  /// **'Open Image...'**
  String get actionOpenImage;

  /// No description provided for @actionSaveImage.
  ///
  /// In en, this message translates to:
  /// **'Download Image'**
  String get actionSaveImage;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'File saved successfully to: '**
  String get saveSuccess;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save file: '**
  String get saveFailed;

  /// No description provided for @printPdfOnly.
  ///
  /// In en, this message translates to:
  /// **'Printing is supported for PDF files only.'**
  String get printPdfOnly;

  /// No description provided for @tabRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent Documents'**
  String get tabRecent;

  /// No description provided for @tabFolders.
  ///
  /// In en, this message translates to:
  /// **'Client Folders'**
  String get tabFolders;

  /// No description provided for @titleFolders.
  ///
  /// In en, this message translates to:
  /// **'Client Directories'**
  String get titleFolders;

  /// No description provided for @btnCreateFolder.
  ///
  /// In en, this message translates to:
  /// **'New Client Folder'**
  String get btnCreateFolder;

  /// No description provided for @btnShareFolder.
  ///
  /// In en, this message translates to:
  /// **'Share Folder (ZIP)'**
  String get btnShareFolder;

  /// No description provided for @msgNoFolders.
  ///
  /// In en, this message translates to:
  /// **'No client folders available.'**
  String get msgNoFolders;

  /// No description provided for @msgCreateFolderPrompt.
  ///
  /// In en, this message translates to:
  /// **'Create one to organize documents.'**
  String get msgCreateFolderPrompt;

  /// No description provided for @msgFolderEmpty.
  ///
  /// In en, this message translates to:
  /// **'Folder is empty. Move client documents here.'**
  String get msgFolderEmpty;

  /// No description provided for @hintFolderName.
  ///
  /// In en, this message translates to:
  /// **'Enter client or project name'**
  String get hintFolderName;

  /// No description provided for @actionMoveToFolder.
  ///
  /// In en, this message translates to:
  /// **'Move to Folder'**
  String get actionMoveToFolder;

  /// No description provided for @btnCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btnCancel;

  /// No description provided for @btnCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get btnCreate;

  /// No description provided for @btnRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get btnRename;

  /// No description provided for @btnClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get btnClose;

  /// No description provided for @btnOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get btnOk;

  /// No description provided for @actionRenameFolder.
  ///
  /// In en, this message translates to:
  /// **'Rename Folder'**
  String get actionRenameFolder;

  /// No description provided for @msgFolderRenamed.
  ///
  /// In en, this message translates to:
  /// **'Folder renamed successfully'**
  String get msgFolderRenamed;

  /// No description provided for @errorCreateFolder.
  ///
  /// In en, this message translates to:
  /// **'Failed to create folder'**
  String get errorCreateFolder;

  /// No description provided for @errorRenameFolder.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename folder'**
  String get errorRenameFolder;

  /// No description provided for @titleTrashBin.
  ///
  /// In en, this message translates to:
  /// **'Recycle Bin'**
  String get titleTrashBin;

  /// No description provided for @actionTrash.
  ///
  /// In en, this message translates to:
  /// **'Move to Trash'**
  String get actionTrash;

  /// No description provided for @actionRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore File'**
  String get actionRestore;

  /// No description provided for @actionDeletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get actionDeletePermanently;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// No description provided for @actionEmptyTrash.
  ///
  /// In en, this message translates to:
  /// **'Empty Recycle Bin'**
  String get actionEmptyTrash;

  /// No description provided for @msgTrashEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items in the Recycle Bin.'**
  String get msgTrashEmpty;

  /// No description provided for @msgFileRestored.
  ///
  /// In en, this message translates to:
  /// **'File restored successfully.'**
  String get msgFileRestored;

  /// No description provided for @msgFileDeleted.
  ///
  /// In en, this message translates to:
  /// **'File deleted permanently.'**
  String get msgFileDeleted;

  /// No description provided for @msgMovedToTrash.
  ///
  /// In en, this message translates to:
  /// **'Moved to Trash'**
  String get msgMovedToTrash;

  /// No description provided for @msgFolderMovedToTrash.
  ///
  /// In en, this message translates to:
  /// **'Folder moved to Trash'**
  String get msgFolderMovedToTrash;

  /// No description provided for @settingTrashRetention.
  ///
  /// In en, this message translates to:
  /// **'Trash Retention Period'**
  String get settingTrashRetention;

  /// No description provided for @settingTrashRetentionDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically delete files from trash'**
  String get settingTrashRetentionDesc;

  /// No description provided for @msgTrashCleanup.
  ///
  /// In en, this message translates to:
  /// **'Cleaning up old files...'**
  String get msgTrashCleanup;

  /// No description provided for @settingTheme.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get settingTheme;

  /// No description provided for @settingThemeDesc.
  ///
  /// In en, this message translates to:
  /// **'Change application theme'**
  String get settingThemeDesc;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get themeDark;

  /// No description provided for @badgePrivacy.
  ///
  /// In en, this message translates to:
  /// **'100% Offline • Safe & Secure • No Tracking'**
  String get badgePrivacy;

  /// No description provided for @processingBackground.
  ///
  /// In en, this message translates to:
  /// **'Processing large file in background.\nYou can safely go back; we will notify you when it\'s done.'**
  String get processingBackground;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get loading;

  /// No description provided for @splitPdf.
  ///
  /// In en, this message translates to:
  /// **'Split PDF'**
  String get splitPdf;

  /// No description provided for @mergePdf.
  ///
  /// In en, this message translates to:
  /// **'Merge with another PDF'**
  String get mergePdf;

  /// No description provided for @protectPdf.
  ///
  /// In en, this message translates to:
  /// **'Add Password (Protect)'**
  String get protectPdf;

  /// No description provided for @splitSuccess.
  ///
  /// In en, this message translates to:
  /// **'PDF Split Successfully!'**
  String get splitSuccess;

  /// No description provided for @mergeSuccess.
  ///
  /// In en, this message translates to:
  /// **'PDFs Merged Successfully!'**
  String get mergeSuccess;

  /// No description provided for @protectSuccess.
  ///
  /// In en, this message translates to:
  /// **'PDF Protected Successfully!'**
  String get protectSuccess;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Completed'**
  String get notificationTitle;

  /// No description provided for @pdfToolsTitle.
  ///
  /// In en, this message translates to:
  /// **'PDF Tools'**
  String get pdfToolsTitle;

  /// No description provided for @selectAnAction.
  ///
  /// In en, this message translates to:
  /// **'Select an Action'**
  String get selectAnAction;

  /// No description provided for @whatWouldYouLikeToDo.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get whatWouldYouLikeToDo;

  /// No description provided for @descSplitPdf.
  ///
  /// In en, this message translates to:
  /// **'Extract pages or split a PDF into multiple files'**
  String get descSplitPdf;

  /// No description provided for @descMergePdf.
  ///
  /// In en, this message translates to:
  /// **'Combine multiple PDFs into a single file'**
  String get descMergePdf;

  /// No description provided for @descProtectPdf.
  ///
  /// In en, this message translates to:
  /// **'Add AES encryption password to a PDF'**
  String get descProtectPdf;

  /// No description provided for @selectedPdf.
  ///
  /// In en, this message translates to:
  /// **'Selected PDF'**
  String get selectedPdf;

  /// No description provided for @splittingPdf.
  ///
  /// In en, this message translates to:
  /// **'Splitting PDF...'**
  String get splittingPdf;

  /// No description provided for @mergingPdfs.
  ///
  /// In en, this message translates to:
  /// **'Merging PDFs natively...'**
  String get mergingPdfs;

  /// No description provided for @protectPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Protect PDF'**
  String get protectPdfTitle;

  /// No description provided for @compressPdf.
  ///
  /// In en, this message translates to:
  /// **'Compress PDF'**
  String get compressPdf;

  /// No description provided for @compressPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Compress PDF'**
  String get compressPdfTitle;

  /// No description provided for @descCompressPdf.
  ///
  /// In en, this message translates to:
  /// **'Reduce PDF file size for easier sharing'**
  String get descCompressPdf;

  /// No description provided for @compressOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Compress PDF'**
  String get compressOptionsTitle;

  /// No description provided for @compressCurrentSize.
  ///
  /// In en, this message translates to:
  /// **'Current size:'**
  String get compressCurrentSize;

  /// No description provided for @compressQuickPresets.
  ///
  /// In en, this message translates to:
  /// **'Quick Presets'**
  String get compressQuickPresets;

  /// No description provided for @compressLowLabel.
  ///
  /// In en, this message translates to:
  /// **'Low (smallest file)'**
  String get compressLowLabel;

  /// No description provided for @compressMediumLabel.
  ///
  /// In en, this message translates to:
  /// **'Medium (balanced)'**
  String get compressMediumLabel;

  /// No description provided for @compressHighLabel.
  ///
  /// In en, this message translates to:
  /// **'High Quality'**
  String get compressHighLabel;

  /// No description provided for @compressTargetSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Set target size (MB)'**
  String get compressTargetSizeLabel;

  /// No description provided for @compressTargetSizeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1.5'**
  String get compressTargetSizeHint;

  /// No description provided for @compressReduceByLabel.
  ///
  /// In en, this message translates to:
  /// **'Reduce by %'**
  String get compressReduceByLabel;

  /// No description provided for @compressButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Compress'**
  String get compressButtonLabel;

  /// No description provided for @compressInvalidTarget.
  ///
  /// In en, this message translates to:
  /// **'Invalid target size'**
  String get compressInvalidTarget;

  /// No description provided for @compressInvalidTargetMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid target size in MB'**
  String get compressInvalidTargetMsg;

  /// No description provided for @compressNotNeeded.
  ///
  /// In en, this message translates to:
  /// **'No compression needed'**
  String get compressNotNeeded;

  /// No description provided for @compressFailed.
  ///
  /// In en, this message translates to:
  /// **'Compression Failed'**
  String get compressFailed;

  /// No description provided for @compressAlreadyOptimized.
  ///
  /// In en, this message translates to:
  /// **'This PDF is already optimized — no further size reduction possible'**
  String get compressAlreadyOptimized;

  /// No description provided for @compressingPdf.
  ///
  /// In en, this message translates to:
  /// **'Compressing PDF...'**
  String get compressingPdf;

  /// No description provided for @addPassword.
  ///
  /// In en, this message translates to:
  /// **'Add Password'**
  String get addPassword;

  /// No description provided for @exportImagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Export to Images'**
  String get exportImagesTitle;

  /// No description provided for @descExportImages.
  ///
  /// In en, this message translates to:
  /// **'Convert all PDF pages into JPEG/PNG images'**
  String get descExportImages;

  /// No description provided for @exportTextTitle.
  ///
  /// In en, this message translates to:
  /// **'Extract Text (TXT)'**
  String get exportTextTitle;

  /// No description provided for @descExportText.
  ///
  /// In en, this message translates to:
  /// **'Run OCR to extract all text from the PDF into a .txt file'**
  String get descExportText;

  /// No description provided for @watermarkPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Watermark'**
  String get watermarkPdfTitle;

  /// No description provided for @descWatermarkPdf.
  ///
  /// In en, this message translates to:
  /// **'Overlay custom text on all pages of the PDF'**
  String get descWatermarkPdf;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingThumbnailSize.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail Size'**
  String get settingThumbnailSize;

  /// No description provided for @settingThumbnailSizeDesc.
  ///
  /// In en, this message translates to:
  /// **'Adjust the size of recent files preview'**
  String get settingThumbnailSizeDesc;

  /// No description provided for @sizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get sizeSmall;

  /// No description provided for @sizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get sizeMedium;

  /// No description provided for @sizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get sizeLarge;

  /// No description provided for @settingLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingLanguage;

  /// No description provided for @settingLanguageDesc.
  ///
  /// In en, this message translates to:
  /// **'App interface language'**
  String get settingLanguageDesc;

  /// No description provided for @settingAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get settingAppVersion;

  /// No description provided for @settingRateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get settingRateUs;

  /// No description provided for @settingRateUsDesc.
  ///
  /// In en, this message translates to:
  /// **'Love the app? Rate us!'**
  String get settingRateUsDesc;

  /// No description provided for @settingMoreApps.
  ///
  /// In en, this message translates to:
  /// **'Discover Other Apps'**
  String get settingMoreApps;

  /// No description provided for @settingMoreAppsDesc.
  ///
  /// In en, this message translates to:
  /// **'More apps from Nitesh'**
  String get settingMoreAppsDesc;

  /// No description provided for @settingTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingTerms;

  /// No description provided for @settingPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingPrivacyPolicy;

  /// No description provided for @settingAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Usage Analytics'**
  String get settingAnalytics;

  /// No description provided for @settingAnalyticsDesc.
  ///
  /// In en, this message translates to:
  /// **'Help improve this app by sharing anonymous usage data'**
  String get settingAnalyticsDesc;

  /// No description provided for @days7.
  ///
  /// In en, this message translates to:
  /// **'7 Days'**
  String get days7;

  /// No description provided for @days15.
  ///
  /// In en, this message translates to:
  /// **'15 Days'**
  String get days15;

  /// No description provided for @days30.
  ///
  /// In en, this message translates to:
  /// **'30 Days'**
  String get days30;

  /// No description provided for @days60.
  ///
  /// In en, this message translates to:
  /// **'60 Days'**
  String get days60;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @searchDocuments.
  ///
  /// In en, this message translates to:
  /// **'Search documents...'**
  String get searchDocuments;

  /// No description provided for @recentFiles.
  ///
  /// In en, this message translates to:
  /// **'Recent Files'**
  String get recentFiles;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResults;

  /// No description provided for @noFilesFound.
  ///
  /// In en, this message translates to:
  /// **'No files found'**
  String get noFilesFound;

  /// No description provided for @scanError.
  ///
  /// In en, this message translates to:
  /// **'Scan Error'**
  String get scanError;

  /// No description provided for @savedFiles.
  ///
  /// In en, this message translates to:
  /// **'Saved {count} file(s)'**
  String savedFiles(int count);

  /// No description provided for @importFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Import from Gallery'**
  String get importFromGallery;

  /// No description provided for @secureVault.
  ///
  /// In en, this message translates to:
  /// **'Secure Vault'**
  String get secureVault;

  /// No description provided for @scanDocument.
  ///
  /// In en, this message translates to:
  /// **'Scan Document'**
  String get scanDocument;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Master'**
  String get homeTitle;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabFoldersNav.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get tabFoldersNav;

  /// No description provided for @quickActionSignature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get quickActionSignature;

  /// No description provided for @quickActionSignatureDesc.
  ///
  /// In en, this message translates to:
  /// **'Draw & Save'**
  String get quickActionSignatureDesc;

  /// No description provided for @quickActionQr.
  ///
  /// In en, this message translates to:
  /// **'QR Toolkit'**
  String get quickActionQr;

  /// No description provided for @quickActionQrDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan & Gen'**
  String get quickActionQrDesc;

  /// No description provided for @quickActionOcr.
  ///
  /// In en, this message translates to:
  /// **'OCR Text'**
  String get quickActionOcr;

  /// No description provided for @quickActionOcrDesc.
  ///
  /// In en, this message translates to:
  /// **'Extract Text'**
  String get quickActionOcrDesc;

  /// No description provided for @quickActionPdfTools.
  ///
  /// In en, this message translates to:
  /// **'PDF Tools'**
  String get quickActionPdfTools;

  /// No description provided for @quickActionPdfToolsDesc.
  ///
  /// In en, this message translates to:
  /// **'Merge & Split'**
  String get quickActionPdfToolsDesc;
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
      <String>['bn', 'en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
