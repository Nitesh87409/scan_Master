import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scan_master_app/main.dart';
import 'package:scan_master_app/core/app_config.dart';

/// Handles the in-app update check and dialog.
/// All config values are read from AppConfig (which reads from Firebase).
class RemoteConfigService {
  static Future<void> initialize() async {
    // AppConfig.initialize() is called separately in main.dart
    // This just triggers the update check
    _checkForUpdate();
  }

  static Future<void> _checkForUpdate() async {
    final String latestVersionString = AppConfig.latestAppVersion;
    final String updateUrl = AppConfig.updateUrl;
    final bool forceUpdate = AppConfig.forceUpdateRequired;

    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String currentVersionString = packageInfo.version;

    if (_isUpdateRequired(currentVersionString, latestVersionString)) {
      _showUpdateDialog(updateUrl, forceUpdate);
    }
  }

  static bool _isUpdateRequired(String currentVersion, String minVersion) {
    try {
      List<int> current = currentVersion.split('.').map(int.parse).toList();
      List<int> min = minVersion.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        if (current.length > i && min.length > i) {
          if (current[i] < min[i]) return true;
          if (current[i] > min[i]) return false;
        }
      }
    } catch (e) {
      debugPrint("Version parsing error: $e");
    }
    return false;
  }

  static void _showUpdateDialog(String updateUrl, bool forceUpdate) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) {
        return PopScope(
          canPop: !forceUpdate,
          child: AlertDialog(
            title: Text('Update Available'),
            content: Text(forceUpdate
                ? 'A new mandatory update is available. Please update the app to continue using Scan Master.'
                : 'A new version of Scan Master is available. Would you like to update now?'),
            actions: [
              if (!forceUpdate)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Later'),
                ),
              ElevatedButton(
                onPressed: () async {
                  final uri = Uri.parse(updateUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Text('Update Now'),
              ),
            ],
          ),
        );
      },
    );
  }
}
