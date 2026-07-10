// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Scan Master: PDF Toolkit';

  @override
  String get viewerSearchHint => 'Search text in PDF...';

  @override
  String get actionShareDocument => 'Share PDF...';

  @override
  String get actionOpenFile => 'Open PDF...';

  @override
  String get actionSaveToDevice => 'Download PDF';

  @override
  String get actionPrintPdf => 'Print PDF';

  @override
  String get actionShareImage => 'Share Image...';

  @override
  String get actionOpenImage => 'Open Image...';

  @override
  String get actionSaveImage => 'Download Image';

  @override
  String get saveSuccess => 'File saved successfully to: ';

  @override
  String get saveFailed => 'Failed to save file: ';

  @override
  String get printPdfOnly => 'Printing is supported for PDF files only.';

  @override
  String get tabRecent => 'Recent Documents';

  @override
  String get tabFolders => 'Client Folders';

  @override
  String get titleFolders => 'Client Directories';

  @override
  String get btnCreateFolder => 'New Client Folder';

  @override
  String get btnShareFolder => 'Share Folder (ZIP)';

  @override
  String get msgNoFolders => 'No client folders available.';

  @override
  String get msgCreateFolderPrompt => 'Create one to organize documents.';

  @override
  String get msgFolderEmpty => 'Folder is empty. Move client documents here.';

  @override
  String get hintFolderName => 'Enter client or project name';

  @override
  String get actionMoveToFolder => 'Move to Folder';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get btnCreate => 'Create';

  @override
  String get btnRename => 'Rename';

  @override
  String get btnClose => 'Close';

  @override
  String get btnOk => 'OK';

  @override
  String get actionRenameFolder => 'Rename Folder';

  @override
  String get msgFolderRenamed => 'Folder renamed successfully';

  @override
  String get errorCreateFolder => 'Failed to create folder';

  @override
  String get errorRenameFolder => 'Failed to rename folder';

  @override
  String get titleTrashBin => 'Recycle Bin';

  @override
  String get actionTrash => 'Move to Trash';

  @override
  String get actionRestore => 'Restore File';

  @override
  String get actionDeletePermanently => 'Delete Permanently';

  @override
  String get actionUndo => 'Undo';

  @override
  String get actionEmptyTrash => 'Empty Recycle Bin';

  @override
  String get msgTrashEmpty => 'No items in the Recycle Bin.';

  @override
  String get msgFileRestored => 'File restored successfully.';

  @override
  String get msgFileDeleted => 'File deleted permanently.';

  @override
  String get msgMovedToTrash => 'Moved to Trash';

  @override
  String get msgFolderMovedToTrash => 'Folder moved to Trash';

  @override
  String get settingTrashRetention => 'Trash Retention Period';

  @override
  String get settingTrashRetentionDesc =>
      'Automatically delete files from trash';

  @override
  String get msgTrashCleanup => 'Cleaning up old files...';

  @override
  String get settingTheme => 'App Theme';

  @override
  String get settingThemeDesc => 'Change application theme';

  @override
  String get themeSystem => 'System Default';

  @override
  String get themeLight => 'Light Theme';

  @override
  String get themeDark => 'Dark Theme';

  @override
  String get badgePrivacy => '100% Offline • Safe & Secure • No Tracking';

  @override
  String get processingBackground =>
      'Processing large file in background.\nYou can safely go back; we will notify you when it\'s done.';

  @override
  String get loading => 'Processing...';

  @override
  String get splitPdf => 'Split PDF';

  @override
  String get mergePdf => 'Merge with another PDF';

  @override
  String get protectPdf => 'Add Password (Protect)';

  @override
  String get splitSuccess => 'PDF Split Successfully!';

  @override
  String get mergeSuccess => 'PDFs Merged Successfully!';

  @override
  String get protectSuccess => 'PDF Protected Successfully!';

  @override
  String get notificationTitle => 'Task Completed';

  @override
  String get pdfToolsTitle => 'PDF Tools';

  @override
  String get selectAnAction => 'Select an Action';

  @override
  String get whatWouldYouLikeToDo => 'What would you like to do?';

  @override
  String get descSplitPdf => 'Extract pages or split a PDF into multiple files';

  @override
  String get descMergePdf => 'Combine multiple PDFs into a single file';

  @override
  String get descProtectPdf => 'Add AES encryption password to a PDF';

  @override
  String get selectedPdf => 'Selected PDF';

  @override
  String get splittingPdf => 'Splitting PDF...';

  @override
  String get mergingPdfs => 'Merging PDFs natively...';

  @override
  String get protectPdfTitle => 'Protect PDF';

  @override
  String get compressPdf => 'Compress PDF';

  @override
  String get compressPdfTitle => 'Compress PDF';

  @override
  String get descCompressPdf => 'Reduce PDF file size for easier sharing';

  @override
  String get compressOptionsTitle => 'Compress PDF';

  @override
  String get compressCurrentSize => 'Current size:';

  @override
  String get compressQuickPresets => 'Quick Presets';

  @override
  String get compressLowLabel => 'Low (smallest file)';

  @override
  String get compressMediumLabel => 'Medium (balanced)';

  @override
  String get compressHighLabel => 'High Quality';

  @override
  String get compressTargetSizeLabel => 'Set target size (MB)';

  @override
  String get compressTargetSizeHint => 'e.g. 1.5';

  @override
  String get compressReduceByLabel => 'Reduce by %';

  @override
  String get compressButtonLabel => 'Compress';

  @override
  String get compressInvalidTarget => 'Invalid target size';

  @override
  String get compressInvalidTargetMsg =>
      'Please enter a valid target size in MB';

  @override
  String get compressNotNeeded => 'No compression needed';

  @override
  String get compressFailed => 'Compression Failed';

  @override
  String get compressAlreadyOptimized =>
      'This PDF is already optimized — no further size reduction possible';

  @override
  String get compressingPdf => 'Compressing PDF...';

  @override
  String get addPassword => 'Add Password';

  @override
  String get exportImagesTitle => 'Export to Images';

  @override
  String get descExportImages => 'Convert all PDF pages into JPEG/PNG images';

  @override
  String get exportTextTitle => 'Extract Text (TXT)';

  @override
  String get descExportText =>
      'Run OCR to extract all text from the PDF into a .txt file';

  @override
  String get watermarkPdfTitle => 'Add Watermark';

  @override
  String get descWatermarkPdf => 'Overlay custom text on all pages of the PDF';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingThumbnailSize => 'Thumbnail Size';

  @override
  String get settingThumbnailSizeDesc =>
      'Adjust the size of recent files preview';

  @override
  String get sizeSmall => 'Small';

  @override
  String get sizeMedium => 'Medium';

  @override
  String get sizeLarge => 'Large';

  @override
  String get settingLanguage => 'Language';

  @override
  String get settingLanguageDesc => 'App interface language';

  @override
  String get settingAppVersion => 'App Version';

  @override
  String get settingRateUs => 'Rate Us';

  @override
  String get settingRateUsDesc => 'Love the app? Rate us!';

  @override
  String get settingMoreApps => 'Discover Other Apps';

  @override
  String get settingMoreAppsDesc => 'More apps from Nitesh';

  @override
  String get settingTerms => 'Terms of Service';

  @override
  String get settingPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingAnalytics => 'Usage Analytics';

  @override
  String get settingAnalyticsDesc =>
      'Help improve this app by sharing anonymous usage data';

  @override
  String get days7 => '7 Days';

  @override
  String get days15 => '15 Days';

  @override
  String get days30 => '30 Days';

  @override
  String get days60 => '60 Days';

  @override
  String get never => 'Never';

  @override
  String get searchDocuments => 'Search documents...';

  @override
  String get recentFiles => 'Recent Files';

  @override
  String get searchResults => 'Search Results';

  @override
  String get noFilesFound => 'No files found';

  @override
  String get scanError => 'Scan Error';

  @override
  String savedFiles(int count) {
    return 'Saved $count file(s)';
  }

  @override
  String get importFromGallery => 'Import from Gallery';

  @override
  String get secureVault => 'Secure Vault';

  @override
  String get scanDocument => 'Scan Document';

  @override
  String get homeTitle => 'Scan Master';

  @override
  String get tabHome => 'Home';

  @override
  String get tabFoldersNav => 'Folders';

  @override
  String get quickActionSignature => 'Signature';

  @override
  String get quickActionSignatureDesc => 'Draw & Save';

  @override
  String get quickActionQr => 'QR Toolkit';

  @override
  String get quickActionQrDesc => 'Scan & Gen';

  @override
  String get quickActionOcr => 'OCR Text';

  @override
  String get quickActionOcrDesc => 'Extract Text';

  @override
  String get quickActionPdfTools => 'PDF Tools';

  @override
  String get quickActionPdfToolsDesc => 'Merge & Split';
}
