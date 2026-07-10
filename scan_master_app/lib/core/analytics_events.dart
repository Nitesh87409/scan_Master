import 'package:firebase_analytics/firebase_analytics.dart';

/// Centralized analytics helper — every trackable user action is defined here.
/// To add a new event, just add a new static method.
class AnalyticsEvents {
  AnalyticsEvents._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// User scanned a document using the camera
  static Future<void> logScanDocument() =>
      _analytics.logEvent(name: 'scan_document');

  /// User imported from gallery
  static Future<void> logGalleryImport() =>
      _analytics.logEvent(name: 'gallery_import');

  /// User merged PDFs
  static Future<void> logMergePdf() =>
      _analytics.logEvent(name: 'merge_pdf');

  /// User split a PDF
  static Future<void> logSplitPdf() =>
      _analytics.logEvent(name: 'split_pdf');

  /// User compressed a PDF
  static Future<void> logCompressPdf() =>
      _analytics.logEvent(name: 'compress_pdf');

  /// User protected a PDF with password
  static Future<void> logProtectPdf() =>
      _analytics.logEvent(name: 'protect_pdf');

  /// User used OCR text extraction
  static Future<void> logOcrUsed() =>
      _analytics.logEvent(name: 'ocr_used');

  /// User scanned or generated a QR code
  static Future<void> logQrToolkitUsed() =>
      _analytics.logEvent(name: 'qr_toolkit_used');

  /// User drew a signature
  static Future<void> logSignatureCreated() =>
      _analytics.logEvent(name: 'signature_created');

  /// User tapped Rate Us
  static Future<void> logRateUs() =>
      _analytics.logEvent(name: 'rate_us_tapped');

  /// User tapped Discover Other Apps
  static Future<void> logMoreApps() =>
      _analytics.logEvent(name: 'more_apps_tapped');

  /// User exported PDF to images
  static Future<void> logExportImages() =>
      _analytics.logEvent(name: 'export_images');

  /// User extracted text from PDF
  static Future<void> logExportText() =>
      _analytics.logEvent(name: 'export_text');

  /// User added watermark to PDF
  static Future<void> logWatermarkPdf() =>
      _analytics.logEvent(name: 'watermark_pdf');

  /// User moved a file to the secure vault
  static Future<void> logVaultUsed() =>
      _analytics.logEvent(name: 'vault_used');

  /// User changed app language
  static Future<void> logLanguageChanged({required String language}) =>
      _analytics.logEvent(
        name: 'language_changed',
        parameters: {'language': language},
      );

  /// User changed app theme
  static Future<void> logThemeChanged({required String theme}) =>
      _analytics.logEvent(
        name: 'theme_changed',
        parameters: {'theme': theme},
      );
}
