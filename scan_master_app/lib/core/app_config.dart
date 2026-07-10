import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Centralized configuration for the entire app.
///
/// **How it works:**
/// 1. App starts → hardcoded defaults load instantly (zero delay).
/// 2. Firebase Remote Config fetches in background.
/// 3. Remote values override defaults — app auto-updates without new APK.
///
/// **Firebase Console → Remote Config Parameters:**
/// Just create a parameter with the EXACT same key name (e.g. `ads_enabled`)
/// and set its value. The app will pick it up automatically.
class AppConfig {
  AppConfig._();

  // ── Internal Remote Config instance ──
  static final FirebaseRemoteConfig _rc = FirebaseRemoteConfig.instance;

  // ══════════════════════════════════════════════════════════════════
  // ── HARDCODED DEFAULTS (these work even without internet) ──
  // ══════════════════════════════════════════════════════════════════

  static const String _defaultDeveloperName = 'Nitesh';
  static const String _defaultAppPackageName = 'com.scanmaster.scan_master_app';

  // ══════════════════════════════════════════════════════════════════
  // ── DYNAMIC VALUES (read from Firebase, fallback to defaults) ──
  // ══════════════════════════════════════════════════════════════════

  // ── App Identity (not remote-controlled, stays constant) ──
  static const String appPackageName = _defaultAppPackageName;
  static const String amazonInstallerPackage = 'com.amazon.venezia';

  // ── Feature Flags ──
  static bool get adsEnabled => _rc.getBool('ads_enabled');
  static bool get adsHomeScreenEnabled => _rc.getBool('ads_home_screen_enabled');
  static bool get adsPdfToolsScreenEnabled => _rc.getBool('ads_pdf_tools_screen_enabled');
  static bool get adsViewerScreenEnabled => _rc.getBool('ads_viewer_screen_enabled');
  static bool get adsSettingsScreenEnabled => _rc.getBool('ads_settings_screen_enabled');
  static bool get analyticsEnabled => _rc.getBool('analytics_enabled');
  static bool get ocrFeatureEnabled => _rc.getBool('ocr_feature_enabled');
  static bool get qrFeatureEnabled => _rc.getBool('qr_feature_enabled');
  static bool get signatureFeatureEnabled => _rc.getBool('signature_feature_enabled');
  static bool get vaultFeatureEnabled => _rc.getBool('vault_feature_enabled');
  static bool get compressFeatureEnabled => _rc.getBool('compress_feature_enabled');
  static bool get watermarkFeatureEnabled => _rc.getBool('watermark_feature_enabled');
  static bool get exportImagesEnabled => _rc.getBool('export_images_enabled');
  static bool get exportTextEnabled => _rc.getBool('export_text_enabled');
  static bool get protectPdfEnabled => _rc.getBool('protect_pdf_enabled');

  // ── Testing (remove after closed testing) ──
  static bool get testingReminderEnabled => _rc.getBool('testing_reminder_enabled');

  // ── Maintenance Mode ──
  static bool get maintenanceMode => _rc.getBool('maintenance_mode');
  static String get maintenanceMessage => _rc.getString('maintenance_message');

  // ── AdMob IDs ──
  static String get admobBannerAndroid => _rc.getString('admob_banner_android');
  static String get admobBannerIos => _rc.getString('admob_banner_ios');
  static String get admobInterstitialAndroid => _rc.getString('admob_interstitial_android');
  static String get admobInterstitialIos => _rc.getString('admob_interstitial_ios');

  // ── Store Links ──
  static String get playStoreUrl => _rc.getString('play_store_url');
  static String get amazonStoreUrl => _rc.getString('amazon_store_url');
  static String get playStoreDeveloperPage => _rc.getString('play_store_developer_page');
  static String get amazonDeveloperPage => _rc.getString('amazon_developer_page');

  // ── Update System ──
  static String get latestAppVersion => _rc.getString('latest_app_version');
  static String get updateUrl => _rc.getString('update_url');
  static bool get forceUpdateRequired => _rc.getBool('force_update_required');

  // ── Privacy & Legal ──
  static String get privacyPolicyUrl => _rc.getString('privacy_policy_url');
  static String get termsOfServiceUrl => _rc.getString('terms_of_service_url');
  static String get privacyPolicyText => _rc.getString('privacy_policy_text');

  // ── Developer Name (for "More Apps" feature) ──
  static String get developerName => _rc.getString('developer_name');

  // ── Custom Announcement / Promo Banner ──
  static bool get showAnnouncement => _rc.getBool('show_announcement');
  static String get announcementTitle => _rc.getString('announcement_title');
  static String get announcementMessage => _rc.getString('announcement_message');
  static String get announcementActionUrl => _rc.getString('announcement_action_url');

  // ── Default Settings ──
  static const String defaultThumbnailSize = 'Small';
  static const int defaultTrashRetentionDays = 30;
  static const int defaultThemeMode = 0;

  // ══════════════════════════════════════════════════════════════════
  // ── INITIALIZATION ──
  // ══════════════════════════════════════════════════════════════════

  /// Call this ONCE at app startup (in main.dart).
  /// Sets hardcoded defaults first (instant), then fetches remote values.
  static Future<void> initialize() async {
    try {
      await _rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // All defaults — these work even if Firebase fails or user is offline
      await _rc.setDefaults({
        // Feature Flags
        'ads_enabled': true,
        'ads_home_screen_enabled': true,
        'ads_pdf_tools_screen_enabled': true,
        'ads_viewer_screen_enabled': true,
        'ads_settings_screen_enabled': true,
        'analytics_enabled': true,
        'ocr_feature_enabled': true,
        'qr_feature_enabled': true,
        'signature_feature_enabled': true,
        'vault_feature_enabled': true,
        'compress_feature_enabled': true,
        'watermark_feature_enabled': true,
        'export_images_enabled': true,
        'export_text_enabled': true,
        'protect_pdf_enabled': true,

        // Testing (remove after closed testing)
        'testing_reminder_enabled': false,

        // Maintenance
        'maintenance_mode': false,
        'maintenance_message': 'App is under maintenance. Please try again later.',

        // AdMob IDs (Test IDs)
        'admob_banner_android': 'ca-app-pub-3940256099942544/6300978111',
        'admob_banner_ios': 'ca-app-pub-3940256099942544/2934735716',
        'admob_interstitial_android': 'ca-app-pub-3940256099942544/1033173712',
        'admob_interstitial_ios': 'ca-app-pub-3940256099942544/4411468910',

        // Store Links
        'play_store_url': 'https://play.google.com/store/apps/details?id=$_defaultAppPackageName',
        'amazon_store_url': 'https://www.amazon.com/gp/mas/dl/android?p=$_defaultAppPackageName',
        'play_store_developer_page': 'https://play.google.com/store/apps/developer?id=$_defaultDeveloperName',
        'amazon_developer_page': 'https://www.amazon.com/s?rh=p_4:$_defaultDeveloperName',

        // Update System
        'latest_app_version': '1.0.0',
        'update_url': 'https://play.google.com/store/apps/details?id=$_defaultAppPackageName',
        'force_update_required': false,

        // Privacy & Legal
        'privacy_policy_url': 'https://docs.google.com/document/d/1GhSOcrpymsv1XZvCXgzW1YQWlrrCpNiBy2dc2eBW8hU/edit?usp=sharing',
        'terms_of_service_url': '',
        'privacy_policy_text':
            'Scan Master automatically sends anonymous crash and error reports '
            '(device model, OS version, app version, and technical error details) '
            'to help us fix bugs. No document content, file names, or personal '
            'files are ever included in these reports.\n\n'
            'All your scanned documents and files remain private and are '
            'processed locally on your device.',

        // Developer
        'developer_name': _defaultDeveloperName,

        // Announcement
        'show_announcement': false,
        'announcement_title': '',
        'announcement_message': '',
        'announcement_action_url': '',
      });

      await _rc.fetchAndActivate();
      debugPrint('AppConfig: Remote Config loaded successfully.');
    } catch (e) {
      debugPrint('AppConfig: Remote Config fetch failed, using defaults. Error: $e');
    }
  }
}
