import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:scan_master_app/core/app_config.dart';

/// ═══════════════════════════════════════════════════════════════════
/// TESTER REMINDER SERVICE — For Play Store Closed Testing Only
/// ═══════════════════════════════════════════════════════════════════
///
/// **Purpose:** Sends periodic notifications (every ~2 hours) to remind
/// testers to open the app, until they open it at least once that day.
///
/// **Controlled by:** Firebase Remote Config → `testing_reminder_enabled`
///
/// **How to remove after testing:**
/// 1. Set `testing_reminder_enabled` = false in Firebase (instant OFF)
/// 2. OR delete this file + remove 2 lines from main.dart + remove
///    `workmanager` from pubspec.yaml + remove getter from app_config.dart
/// ═══════════════════════════════════════════════════════════════════

const String _taskName = 'testerReminderTask';
const String _taskUniqueName = 'com.scanmaster.testerReminder';
const String _prefKey = 'tester_last_opened_date';

/// Top-level callback for WorkManager (MUST be top-level or static)
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == _taskName) {
      await _checkAndNotify();
    }
    return true;
  });
}

/// Check if app was opened today; if not, send a notification
Future<void> _checkAndNotify() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10); // "2026-07-10"
    final lastOpened = prefs.getString(_prefKey) ?? '';

    if (lastOpened == today) {
      // User already opened the app today — no notification needed
      debugPrint('TesterReminder: App already opened today, skipping.');
      return;
    }

    // User has NOT opened the app today — send reminder
    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await plugin.initialize(settings: initSettings);

    const androidDetails = AndroidNotificationDetails(
      'tester_reminder_channel',
      'Testing Reminders',
      channelDescription: 'Reminders for Play Store closed testing',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await plugin.show(
      id: 9999, // Fixed ID so it replaces previous reminder
      title: '📱 Scan Master Testing',
      body: 'Please open the app today for closed testing! Your support helps us launch faster. 🚀',
      notificationDetails: details,
    );

    debugPrint('TesterReminder: Notification sent (user not opened today).');
  } catch (e) {
    debugPrint('TesterReminder: Error in background task: $e');
  }
}

/// Service class with static methods — call from main.dart
class TesterReminderService {
  TesterReminderService._();

  /// Call once during app startup (in _initServicesInBackground).
  /// Only registers the background worker if Remote Config says so.
  static Future<void> initialize() async {
    if (!AppConfig.testingReminderEnabled) {
      // Testing mode is OFF — cancel any existing tasks and return
      await Workmanager().cancelByUniqueName(_taskUniqueName);
      debugPrint('TesterReminder: Disabled via Remote Config.');
      return;
    }

    // Initialize WorkManager
    await Workmanager().initialize(_callbackDispatcher);

    // Register periodic task (minimum interval on Android is 15 min,
    // we set 2 hours as requested)
    await Workmanager().registerPeriodicTask(
      _taskUniqueName,
      _taskName,
      frequency: const Duration(hours: 2),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      initialDelay: const Duration(minutes: 30), // First check after 30 min
    );

    debugPrint('TesterReminder: Enabled — periodic task registered (every ~2h).');
  }

  /// Call every time the app is opened to mark today as "opened".
  static Future<void> markAppOpened() async {
    if (!AppConfig.testingReminderEnabled) return;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(_prefKey, today);

    // Cancel any pending notification for today
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.cancel(id: 9999);

    debugPrint('TesterReminder: App opened today ($today), notification cancelled.');
  }
}
