// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'स्कैन मास्टर: पीडीएफ टूलकिट';

  @override
  String get viewerSearchHint => 'पीडीएफ में टेक्स्ट खोजें...';

  @override
  String get actionShareDocument => 'पीडीएफ शेयर करें...';

  @override
  String get actionOpenFile => 'पीडीएफ खोलें...';

  @override
  String get actionSaveToDevice => 'पीडीएफ डाउनलोड करें';

  @override
  String get actionPrintPdf => 'पीडीएफ प्रिंट करें';

  @override
  String get actionShareImage => 'इमेज शेयर करें...';

  @override
  String get actionOpenImage => 'इमेज खोलें...';

  @override
  String get actionSaveImage => 'इमेज डाउनलोड करें';

  @override
  String get saveSuccess => 'फ़ाइल सफलतापूर्वक यहाँ सेव की गई: ';

  @override
  String get saveFailed => 'फ़ाइल सेव करने में विफल: ';

  @override
  String get printPdfOnly => 'प्रिंटिंग केवल पीडीएफ फ़ाइलों के लिए समर्थित है।';

  @override
  String get tabRecent => 'हालिया दस्तावेज़';

  @override
  String get tabFolders => 'क्लाइंट फ़ोल्डर्स';

  @override
  String get titleFolders => 'क्लाइंट डायरेक्टरी';

  @override
  String get btnCreateFolder => 'नया क्लाइंट फ़ोल्डर';

  @override
  String get btnShareFolder => 'फ़ोल्डर शेयर करें (ZIP)';

  @override
  String get msgNoFolders => 'कोई क्लाइंट फ़ोल्डर उपलब्ध नहीं है।';

  @override
  String get msgCreateFolderPrompt =>
      'दस्तावेज़ों को व्यवस्थित करने के लिए एक बनाएँ।';

  @override
  String get msgFolderEmpty =>
      'फ़ोल्डर खाली है। क्लाइंट दस्तावेज़ों को यहाँ ले जाएँ।';

  @override
  String get hintFolderName => 'क्लाइंट या प्रोजेक्ट का नाम दर्ज करें';

  @override
  String get actionMoveToFolder => 'फ़ोल्डर में ले जाएँ';

  @override
  String get btnCancel => 'रद्द करें';

  @override
  String get btnCreate => 'बनाएँ';

  @override
  String get btnRename => 'नाम बदलें';

  @override
  String get btnClose => 'बंद करें';

  @override
  String get btnOk => 'ठीक है';

  @override
  String get actionRenameFolder => 'फ़ोल्डर का नाम बदलें';

  @override
  String get msgFolderRenamed => 'फ़ोल्डर का नाम सफलतापूर्वक बदल दिया गया';

  @override
  String get errorCreateFolder => 'फ़ोल्डर बनाने में विफल';

  @override
  String get errorRenameFolder => 'फ़ोल्डर का नाम बदलने में विफल';

  @override
  String get titleTrashBin => 'रीसायकल बिन';

  @override
  String get actionTrash => 'ट्रैश में ले जाएँ';

  @override
  String get actionRestore => 'फ़ाइल रीस्टोर करें';

  @override
  String get actionDeletePermanently => 'स्थायी रूप से हटाएँ';

  @override
  String get actionUndo => 'पूर्ववत करें';

  @override
  String get actionEmptyTrash => 'रीसायकल बिन खाली करें';

  @override
  String get msgTrashEmpty => 'रीसायकल बिन में कोई आइटम नहीं है।';

  @override
  String get msgFileRestored => 'फ़ाइल सफलतापूर्वक रीस्टोर की गई।';

  @override
  String get msgFileDeleted => 'फ़ाइल स्थायी रूप से हटा दी गई।';

  @override
  String get msgMovedToTrash => 'ट्रैश में ले जाया गया';

  @override
  String get msgFolderMovedToTrash => 'फ़ोल्डर ट्रैश में ले जाया गया';

  @override
  String get settingTrashRetention => 'ट्रैश प्रतिधारण अवधि';

  @override
  String get settingTrashRetentionDesc =>
      'ट्रैश से फ़ाइलों को स्वचालित रूप से हटाएँ';

  @override
  String get msgTrashCleanup => 'पुरानी फ़ाइलों की सफाई की जा रही है...';

  @override
  String get settingTheme => 'ऐप थीम';

  @override
  String get settingThemeDesc => 'एप्लिकेशन थीम बदलें';

  @override
  String get themeSystem => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get themeLight => 'लाइट थीम';

  @override
  String get themeDark => 'डार्क थीम';

  @override
  String get badgePrivacy =>
      '100% ऑफ़लाइन • सुरक्षित और संरक्षित • कोई ट्रैकिंग नहीं';

  @override
  String get processingBackground =>
      'बैकग्राउंड में बड़ी फ़ाइल प्रोसेस की जा रही है।\nआप सुरक्षित रूप से वापस जा सकते हैं; कार्य पूरा होने पर हम आपको सूचित करेंगे।';

  @override
  String get loading => 'प्रोसेस हो रहा है...';

  @override
  String get splitPdf => 'पीडीएफ स्प्लिट करें';

  @override
  String get mergePdf => 'दूसरी पीडीएफ के साथ मर्ज करें';

  @override
  String get protectPdf => 'पासवर्ड जोड़ें (सुरक्षित करें)';

  @override
  String get splitSuccess => 'पीडीएफ सफलतापूर्वक स्प्लिट हो गया!';

  @override
  String get mergeSuccess => 'पीडीएफ सफलतापूर्वक मर्ज हो गए!';

  @override
  String get protectSuccess => 'पीडीएफ सफलतापूर्वक सुरक्षित हो गया!';

  @override
  String get notificationTitle => 'कार्य पूरा हुआ';

  @override
  String get pdfToolsTitle => 'पीडीएफ टूल्स';

  @override
  String get selectAnAction => 'कोई क्रिया चुनें';

  @override
  String get whatWouldYouLikeToDo => 'आप क्या करना चाहेंगे?';

  @override
  String get descSplitPdf =>
      'पेज निकालें या पीडीएफ को कई फ़ाइलों में विभाजित करें';

  @override
  String get descMergePdf => 'कई पीडीएफ को एक फ़ाइल में मिलाएँ';

  @override
  String get descProtectPdf => 'पीडीएफ में एईएस एन्क्रिप्शन पासवर्ड जोड़ें';

  @override
  String get selectedPdf => 'चयनित पीडीएफ';

  @override
  String get splittingPdf => 'पीडीएफ स्प्लिट किया जा रहा है...';

  @override
  String get mergingPdfs => 'पीडीएफ मर्ज किए जा रहे हैं...';

  @override
  String get protectPdfTitle => 'पीडीएफ सुरक्षित करें';

  @override
  String get compressPdf => 'पीडीएफ कंप्रेस करें';

  @override
  String get compressPdfTitle => 'पीडीएफ कंप्रेस करें';

  @override
  String get descCompressPdf =>
      'आसानी से शेयर करने के लिए पीडीएफ फ़ाइल का आकार कम करें';

  @override
  String get compressOptionsTitle => 'पीडीएफ कंप्रेस करें';

  @override
  String get compressCurrentSize => 'वर्तमान आकार:';

  @override
  String get compressQuickPresets => 'त्वरित प्रीसेट';

  @override
  String get compressLowLabel => 'निम्न (सबसे छोटी फ़ाइल)';

  @override
  String get compressMediumLabel => 'मध्यम (संतुलित)';

  @override
  String get compressHighLabel => 'उच्च गुणवत्ता';

  @override
  String get compressTargetSizeLabel => 'लक्ष्य आकार निर्धारित करें (MB)';

  @override
  String get compressTargetSizeHint => 'उदा. 1.5';

  @override
  String get compressReduceByLabel => '% कम करें';

  @override
  String get compressButtonLabel => 'कंप्रेस करें';

  @override
  String get compressInvalidTarget => 'अमान्य लक्ष्य आकार';

  @override
  String get compressInvalidTargetMsg =>
      'कृपया MB में एक मान्य लक्ष्य आकार दर्ज करें';

  @override
  String get compressNotNeeded => 'कंप्रेशन की आवश्यकता नहीं है';

  @override
  String get compressFailed => 'कंप्रेशन विफल रहा';

  @override
  String get compressAlreadyOptimized =>
      'यह पीडीएफ पहले से ही ऑप्टिमाइज़ किया गया है — फ़ाइल का आकार और कम करना संभव नहीं है';

  @override
  String get compressingPdf => 'पीडीएफ कंप्रेस किया जा रहा है...';

  @override
  String get addPassword => 'पासवर्ड जोड़ें';

  @override
  String get exportImagesTitle => 'इमेज में एक्सपोर्ट करें';

  @override
  String get descExportImages => 'सभी पीडीएफ पेजों को JPEG/PNG इमेज में बदलें';

  @override
  String get exportTextTitle => 'टेक्स्ट निकालें (TXT)';

  @override
  String get descExportText =>
      'पीडीएफ से .txt फ़ाइल में सभी टेक्स्ट निकालने के लिए OCR चलाएँ';

  @override
  String get watermarkPdfTitle => 'वॉटरमार्क जोड़ें';

  @override
  String get descWatermarkPdf =>
      'पीडीएफ के सभी पेजों पर कस्टम टेक्स्ट ओवरले करें';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsGeneral => 'सामान्य';

  @override
  String get settingsAbout => 'जानकारी';

  @override
  String get settingsPrivacy => 'गोपनीयता';

  @override
  String get settingThumbnailSize => 'थंबनेल आकार';

  @override
  String get settingThumbnailSizeDesc =>
      'हालिया फ़ाइलों के प्रीव्यू का आकार बदलें';

  @override
  String get sizeSmall => 'छोटा';

  @override
  String get sizeMedium => 'मध्यम';

  @override
  String get sizeLarge => 'बड़ा';

  @override
  String get settingLanguage => 'भाषा';

  @override
  String get settingLanguageDesc => 'ऐप इंटरफ़ेस की भाषा';

  @override
  String get settingAppVersion => 'ऐप संस्करण';

  @override
  String get settingRateUs => 'हमें रेट करें';

  @override
  String get settingRateUsDesc => 'ऐप पसंद आया? हमें रेट करें!';

  @override
  String get settingMoreApps => 'अन्य ऐप्स देखें';

  @override
  String get settingMoreAppsDesc => 'Nitesh की और ऐप्स';

  @override
  String get settingTerms => 'सेवा की शर्तें';

  @override
  String get settingPrivacyPolicy => 'गोपनीयता नीति';

  @override
  String get settingAnalytics => 'उपयोग विश्लेषण';

  @override
  String get settingAnalyticsDesc =>
      'अनाम उपयोग डेटा साझा करके इस ऐप को बेहतर बनाने में मदद करें';

  @override
  String get days7 => '7 दिन';

  @override
  String get days15 => '15 दिन';

  @override
  String get days30 => '30 दिन';

  @override
  String get days60 => '60 दिन';

  @override
  String get never => 'कभी नहीं';

  @override
  String get searchDocuments => 'दस्तावेज़ खोजें...';

  @override
  String get recentFiles => 'हालिया फ़ाइलें';

  @override
  String get searchResults => 'खोज परिणाम';

  @override
  String get noFilesFound => 'कोई फ़ाइल नहीं मिली';

  @override
  String get scanError => 'स्कैन त्रुटि';

  @override
  String savedFiles(int count) {
    return '$count फ़ाइल(ों) को सहेजा गया';
  }

  @override
  String get importFromGallery => 'गैलरी से आयात करें';

  @override
  String get secureVault => 'सुरक्षित वॉल्ट';

  @override
  String get scanDocument => 'दस्तावेज़ स्कैन करें';

  @override
  String get homeTitle => 'स्कैन मास्टर';

  @override
  String get tabHome => 'होम';

  @override
  String get tabFoldersNav => 'फ़ोल्डर';

  @override
  String get quickActionSignature => 'हस्ताक्षर';

  @override
  String get quickActionSignatureDesc => 'बनाएँ और सहेजें';

  @override
  String get quickActionQr => 'QR टूलकिट';

  @override
  String get quickActionQrDesc => 'स्कैन और जनरेट';

  @override
  String get quickActionOcr => 'OCR टेक्स्ट';

  @override
  String get quickActionOcrDesc => 'टेक्स्ट निकालें';

  @override
  String get quickActionPdfTools => 'पीडीएफ टूल्स';

  @override
  String get quickActionPdfToolsDesc => 'मर्ज और स्प्लिट';
}
