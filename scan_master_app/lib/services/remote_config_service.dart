import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';

class RemoteConfigService {
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  static Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1), // Checks for updates every hour max
      ));
      
      // Default values
      await _remoteConfig.setDefaults(const {
        "min_version": "1.0.0"
      });

      await _remoteConfig.fetchAndActivate();
      
      _checkForUpdate();
    } catch (e) {
      debugPrint("Remote Config init error: $e");
    }
  }

  static Future<void> _checkForUpdate() async {
    final String minVersionString = _remoteConfig.getString("min_version");
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String currentVersionString = packageInfo.version;

    if (_isUpdateRequired(currentVersionString, minVersionString)) {
      _showUpdateDialog();
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

  static void _showUpdateDialog() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false, // Force update
      builder: (context) {
        return PopScope(
          canPop: false, // Prevent back button
          child: AlertDialog(
            title: const Text('Update Required'),
            content: const Text(
                'A new mandatory update is available. Please update the app to continue using Scan Master.'),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  // Replace with your app's actual Play Store link
                  const url = 'https://play.google.com/store/apps/details?id=com.scanmaster.scan_master_app';
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text('Update Now'),
              ),
            ],
          ),
        );
      },
    );
  }
}
