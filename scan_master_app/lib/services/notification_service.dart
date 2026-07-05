import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';
import '../main.dart';
import '../screens/viewer_screen.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null && response.payload!.isNotEmpty) {
          final String path = response.payload!;
          if (path.toLowerCase().endsWith('.pdf')) {
            // Open in internal ViewerScreen
            final context = navigatorKey.currentContext;
            if (context != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ViewerScreen(file: File(path))),
              );
            } else {
              // Fallback if context is not ready
              await OpenFilex.open(path);
            }
          } else {
            // Open with external viewer for other file types
            await OpenFilex.open(path);
          }
        }
      },
    );
    
    await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  static Future<void> showNotification({required int id, required String title, required String body, String? payload}) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'scan_master_channel', 'Scan Master Notifications',
      channelDescription: 'Notifications for background tasks',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }
}
