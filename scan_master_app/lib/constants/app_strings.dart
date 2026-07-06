class AppStrings {
  // App General
  static const String appName = 'Scan Master: PDF Toolkit';
  
  // Viewer Screen ASO Strings
  static const String viewerSearchHint = 'Search text in PDF...';
  static const String actionShareDocument = 'Share PDF...';
  static const String actionOpenFile = 'Open PDF...';
  static const String actionSaveToDevice = 'Download PDF';
  static const String actionPrintPdf = 'Print PDF';
  static const String actionShareImage = 'Share Image...';
  static const String actionOpenImage = 'Open Image...';
  static const String actionSaveImage = 'Download Image';
  
  // Dialogs & Messages
  static const String saveSuccess = 'File saved successfully to: ';
  static const String saveFailed = 'Failed to save file: ';
  static const String printPdfOnly = 'Printing is supported for PDF files only.';

  // Folder Management & E-Mitra Client ASO Strings
  static const String tabRecent = 'Recent Documents';
  static const String tabFolders = 'Client Folders';
  static const String titleFolders = 'Client Directories';
  static const String btnCreateFolder = 'New Client Folder';
  static const String btnShareFolder = 'Share Folder (ZIP)';
  static const String msgNoFolders = 'No client folders available.';
  static const String msgCreateFolderPrompt = 'Create one to organize documents.';
  static const String msgFolderEmpty = 'Folder is empty. Move client documents here.';
  static const String hintFolderName = 'Enter client or project name';
  static const String actionMoveToFolder = 'Move to Folder';
  static const String btnCancel = 'Cancel';
  static const String btnCreate = 'Create';
  static const String btnRename = 'Rename';
  static const String actionRenameFolder = 'Rename Folder';
  static const String msgFolderRenamed = 'Folder renamed successfully';
  static const String errorCreateFolder = 'Failed to create folder';
  static const String errorRenameFolder = 'Failed to rename folder';

  // Trash Bin & Retention ASO Strings
  static const String titleTrashBin = 'Recycle Bin';
  static const String actionTrash = 'Move to Trash';
  static const String actionRestore = 'Restore File';
  static const String actionDeletePermanently = 'Delete Permanently';
  static const String actionUndo = 'Undo';
  static const String actionEmptyTrash = 'Empty Recycle Bin';
  static const String msgTrashEmpty = 'No items in the Recycle Bin.';
  static const String msgFileRestored = 'File restored successfully.';
  static const String msgFileDeleted = 'File deleted permanently.';
  static const String msgMovedToTrash = 'Moved to Trash';
  static const String msgFolderMovedToTrash = 'Folder moved to Trash';
  static const String settingTrashRetention = 'Trash Retention Period';
  static const String msgTrashCleanup = 'Cleaning up old files...';

  // Theme ASO Strings
  static const String settingTheme = 'App Theme';
  static const String themeSystem = 'System Default';
  static const String themeLight = 'Light Theme';
  static const String themeDark = 'Dark Theme';

  // Privacy & Security Badges
  static const String badgePrivacy = '100% Offline • Safe & Secure • No Tracking';
  
  // Background Processing & PDF Tools
  static const String processingBackground = 'Processing large file in background.\nYou can safely go back; we will notify you when it\'s done.';
  static const String loading = 'Processing...';
  
  static const String splitPdf = 'Split PDF';
  static const String mergePdf = 'Merge with another PDF';
  static const String protectPdf = 'Add Password (Protect)';
  static const String splitSuccess = 'PDF Split Successfully!';
  static const String mergeSuccess = 'PDFs Merged Successfully!';
  static const String protectSuccess = 'PDF Protected Successfully!';
  static const String notificationTitle = 'Task Completed';
  static const String pdfToolsTitle = 'PDF Tools';
  
  // Dynamic UI Strings
  static const String selectAnAction = 'Select an Action';
  static const String whatWouldYouLikeToDo = 'What would you like to do?';
  static const String descSplitPdf = 'Extract pages or split a PDF into multiple files';
  static const String descMergePdf = 'Combine multiple PDFs into a single file';
  static const String descProtectPdf = 'Add AES encryption password to a PDF';
  static const String selectedPdf = 'Selected PDF';
  static const String splittingPdf = 'Splitting PDF...';
  static const String mergingPdfs = 'Merging PDFs natively...';
  static const String protectPdfTitle = 'Protect PDF';
  static const String compressPdf = 'Compress PDF';
  static const String compressPdfTitle = 'Compress PDF';
  static const String descCompressPdf = 'Reduce PDF file size for easier sharing';
  static const String compressOptionsTitle = 'Compress PDF';
  static const String compressCurrentSize = 'Current size:';
  static const String compressQuickPresets = 'Quick Presets';
  static const String compressLowLabel = 'Low (smallest file)';
  static const String compressMediumLabel = 'Medium (balanced)';
  static const String compressHighLabel = 'High Quality';
  static const String compressTargetSizeLabel = 'Set target size (MB)';
  static const String compressTargetSizeHint = 'e.g. 1.5';
  static const String compressReduceByLabel = 'Reduce by %';
  static const String compressButtonLabel = 'Compress';
  static const String compressInvalidTarget = 'Invalid target size';
  static const String compressInvalidTargetMsg = 'Please enter a valid target size in MB';
  static const String compressNotNeeded = 'No compression needed';
  static const String compressFailed = 'Compression Failed';
  static const String compressAlreadyOptimized = 'This PDF is already optimized — no further size reduction possible';
  static const String compressingPdf = 'Compressing PDF...';
  static const String addPassword = 'Add Password';
  
  static const String exportImagesTitle = 'Export to Images';
  static const String descExportImages = 'Convert all PDF pages into JPEG/PNG images';
  static const String exportTextTitle = 'Extract Text (TXT)';
  static const String descExportText = 'Run OCR to extract all text from the PDF into a .txt file';
  static const String watermarkPdfTitle = 'Add Watermark';
  static const String descWatermarkPdf = 'Overlay custom text on all pages of the PDF';
}
