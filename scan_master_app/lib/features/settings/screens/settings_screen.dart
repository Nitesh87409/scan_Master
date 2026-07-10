import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scan_master_app/main.dart';
import 'package:scan_master_app/l10n/app_localizations.dart';
import 'package:scan_master_app/core/app_config.dart';
import 'package:scan_master_app/core/analytics_events.dart';
import 'package:scan_master_app/services/ad_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = 'Loading...';
  String _thumbnailSize = AppConfig.defaultThumbnailSize;
  int _trashRetention = AppConfig.defaultTrashRetentionDays;
  int _themeMode = AppConfig.defaultThemeMode;
  String _appLanguage = 'system';
  bool _analyticsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadPreferences();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = '${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _thumbnailSize = prefs.getString('thumbnail_size') ?? AppConfig.defaultThumbnailSize;
      _trashRetention = prefs.getInt('trash_retention_days') ?? AppConfig.defaultTrashRetentionDays;
      _themeMode = prefs.getInt('theme_mode') ?? AppConfig.defaultThemeMode;
      _appLanguage = prefs.getString('app_language') ?? 'system';
      _analyticsEnabled = prefs.getBool('analytics_enabled') ?? true;
    });
  }

  Future<void> _saveThumbnailSize(String? size) async {
    if (size == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('thumbnail_size', size);
    if (!mounted) return;
    setState(() {
      _thumbnailSize = size;
    });
  }

  Future<void> _saveTrashRetention(int? days) async {
    if (days == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('trash_retention_days', days);
    if (!mounted) return;
    setState(() {
      _trashRetention = days;
    });
  }

  Future<void> _saveThemeMode(int? modeIndex) async {
    if (modeIndex == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', modeIndex);
    if (!mounted) return;
    setState(() {
      _themeMode = modeIndex;
    });
    themeNotifier.value = ThemeMode.values[modeIndex];
    final themeNames = ['system', 'light', 'dark'];
    AnalyticsEvents.logThemeChanged(theme: themeNames[modeIndex]);
  }

  Future<void> _saveAppLanguage(String? lang) async {
    if (lang == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (lang == 'system') {
      await prefs.remove('app_language');
      localeNotifier.value = null;
    } else {
      await prefs.setString('app_language', lang);
      localeNotifier.value = Locale(lang);
    }
    if (!mounted) return;
    setState(() {
      _appLanguage = lang;
    });
    AnalyticsEvents.logLanguageChanged(language: lang);
  }

  Future<void> _toggleAnalytics(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('analytics_enabled', value);
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(value);
    if (!mounted) return;
    setState(() {
      _analyticsEnabled = value;
    });
  }

  Future<void> _launchRateUs() async {
    final info = await PackageInfo.fromPlatform();
    final installer = info.installerStore;

    String url;
    if (installer == AppConfig.amazonInstallerPackage) {
      url = AppConfig.amazonStoreUrl;
    } else {
      url = AppConfig.playStoreUrl;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    AnalyticsEvents.logRateUs();
  }

  Future<void> _launchMoreApps() async {
    final info = await PackageInfo.fromPlatform();
    final installer = info.installerStore;

    String url;
    if (installer == AppConfig.amazonInstallerPackage) {
      url = AppConfig.amazonDeveloperPage;
    } else {
      url = AppConfig.playStoreDeveloperPage;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    AnalyticsEvents.logMoreApps();
  }

  Future<void> _launchPrivacyPolicy() async {
    final url = AppConfig.privacyPolicyUrl;
    if (url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    
    // Fallback if URL is empty or cannot be launched
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.settingPrivacyPolicy),
        content: Text(AppConfig.privacyPolicyText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.btnClose),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
          ListTile(
            title: Text(l10n.settingsGeneral, style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: Icon(Icons.image),
            title: Text(l10n.settingThumbnailSize),
            subtitle: Text(l10n.settingThumbnailSizeDesc),
            trailing: DropdownButton<String>(
              value: _thumbnailSize,
              underline: SizedBox(),
              items: [
                DropdownMenuItem(value: 'Small', child: Text(l10n.sizeSmall)),
                DropdownMenuItem(value: 'Medium', child: Text(l10n.sizeMedium)),
                DropdownMenuItem(value: 'Large', child: Text(l10n.sizeLarge)),
              ],
              onChanged: _saveThumbnailSize,
            ),
          ),
          ListTile(
            leading: Icon(Icons.palette),
            title: Text(l10n.settingTheme),
            subtitle: Text(l10n.settingThemeDesc),
            trailing: DropdownButton<int>(
              value: _themeMode,
              underline: SizedBox(),
              items: [
                DropdownMenuItem(value: 0, child: Text(l10n.themeSystem)),
                DropdownMenuItem(value: 1, child: Text(l10n.themeLight)),
                DropdownMenuItem(value: 2, child: Text(l10n.themeDark)),
              ],
              onChanged: _saveThemeMode,
            ),
          ),
          ListTile(
            leading: Icon(Icons.language),
            title: Text(l10n.settingLanguage),
            subtitle: Text(l10n.settingLanguageDesc),
            trailing: DropdownButton<String>(
              value: _appLanguage,
              underline: SizedBox(),
              items: [
                DropdownMenuItem(value: 'system', child: Text(l10n.themeSystem)),
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'hi', child: Text('हिंदी')),
                DropdownMenuItem(value: 'bn', child: Text('বাংলা')),
              ],
              onChanged: _saveAppLanguage,
            ),
          ),
          ListTile(
            leading: Icon(Icons.delete_sweep),
            title: Text(l10n.settingTrashRetention),
            subtitle: Text(l10n.settingTrashRetentionDesc),
            trailing: DropdownButton<int>(
              value: _trashRetention,
              underline: SizedBox(),
              items: [
                DropdownMenuItem(value: 7, child: Text(l10n.days7)),
                DropdownMenuItem(value: 15, child: Text(l10n.days15)),
                DropdownMenuItem(value: 30, child: Text(l10n.days30)),
                DropdownMenuItem(value: 60, child: Text(l10n.days60)),
                DropdownMenuItem(value: -1, child: Text(l10n.never)),
              ],
              onChanged: _saveTrashRetention,
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.settingsPrivacy, style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            secondary: Icon(Icons.analytics_outlined),
            title: Text(l10n.settingAnalytics),
            subtitle: Text(l10n.settingAnalyticsDesc),
            value: _analyticsEnabled,
            onChanged: _toggleAnalytics,
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.settingsAbout, style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text(l10n.settingAppVersion),
            subtitle: Text(_version),
          ),
          ListTile(
            leading: Icon(Icons.star_rate, color: Colors.amber),
            title: Text(l10n.settingRateUs),
            subtitle: Text(l10n.settingRateUsDesc),
            onTap: _launchRateUs,
          ),
          ListTile(
            leading: Icon(Icons.apps, color: Colors.blue),
            title: Text(l10n.settingMoreApps),
            subtitle: Text(l10n.settingMoreAppsDesc),
            onTap: _launchMoreApps,
          ),
          ListTile(
            leading: Icon(Icons.description),
            title: Text(l10n.settingTerms),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text(l10n.settingPrivacyPolicy),
            onTap: _launchPrivacyPolicy,
          ),
        ],
      ),
    ),
      BannerAdWidget(isEnabled: AppConfig.adsSettingsScreenEnabled),
    ],
  ),
);
  }
}
