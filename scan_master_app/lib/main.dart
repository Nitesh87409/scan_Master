import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:scan_master_app/l10n/app_localizations.dart';
import 'package:scan_master_app/core/theme.dart';
import 'package:scan_master_app/features/home/screens/home_screen.dart';
import 'package:scan_master_app/features/viewer/screens/viewer_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scan_master_app/services/ad_service.dart';
import 'package:scan_master_app/services/file_manager_service.dart';
import 'package:scan_master_app/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:scan_master_app/firebase_options.dart';
import 'package:scan_master_app/services/remote_config_service.dart';
import 'package:scan_master_app/core/app_config.dart';
import 'package:scan_master_app/services/tester_reminder_service.dart'; // Remove after testing

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

// Global smooth scrolling behavior
class SmoothScrollBehavior extends ScrollBehavior {
  const SmoothScrollBehavior();
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

// Global notifier for Theme
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

// Global notifier for Locale
final ValueNotifier<Locale?> localeNotifier = ValueNotifier(null);

// Global key for Scafford Messenger
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// Global key for Navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // --- Global Industry-Level Error Handling (lightweight, no awaits) ---
  _setupErrorHandlers();

  // Run app IMMEDIATELY — zero blocking, zero awaits
  runApp(const ScanMasterApp());
}

void _setupErrorHandlers() {
  // 1. UI Build Errors (Replaces the Red Screen of Death)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 64),
              SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                kDebugMode ? details.exceptionAsString() : 'An unexpected error occurred. Please try restarting the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // 2. Uncaught Asynchronous Errors
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    debugPrint('Async error caught globally: $error');
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('An unexpected error occurred. We are looking into it.'),
        backgroundColor: Colors.redAccent,
      ),
    );
    return true;
  };

  // 3. Standard Flutter framework errors
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    FirebaseCrashlytics.instance.recordFlutterError(details);
    if (originalOnError != null) {
      originalOnError(details);
    } else {
      FlutterError.presentError(details);
    }
    debugPrint('Flutter error caught: ${details.exception}');
  };
}

class ScanMasterApp extends StatefulWidget {
  const ScanMasterApp({super.key});

  @override
  State<ScanMasterApp> createState() => _ScanMasterAppState();
}

class _ScanMasterAppState extends State<ScanMasterApp> {
  late Future<List<SharedMediaFile>> _initialMediaFuture;
  late StreamSubscription _intentDataStreamSubscription;
  bool _servicesInitialized = false;

  @override
  void initState() {
    super.initState();
    // Start fetching intent data immediately (non-blocking, runs in parallel with UI)
    _initialMediaFuture = _getInitialMedia();
    _initIntentListener();
    
    // Lazy-initialize all heavy services AFTER the first frame is drawn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServicesInBackground();
    });
  }

  /// Fetch initial shared media (intent data) — lightweight, fast
  Future<List<SharedMediaFile>> _getInitialMedia() async {
    try {
      final media = await ReceiveSharingIntent.instance.getInitialMedia();
      if (media.isNotEmpty) {
        ReceiveSharingIntent.instance.reset();
      }
      return media;
    } catch (e) {
      debugPrint("Failed to get initial media: $e");
      return [];
    }
  }

  /// Initialize heavy services in background — does NOT block app startup
  Future<void> _initServicesInBackground() async {
    if (_servicesInitialized) return;
    _servicesInitialized = true;
    
    // These run AFTER the first frame, so user already sees the UI
    await AdService.initialize();
    await NotificationService.initialize();
    await AppConfig.initialize(); // Load Firebase Remote Config values
    await RemoteConfigService.initialize(); // Check for updates
    
    // Tester Reminder — remove after closed testing
    await TesterReminderService.initialize();
    TesterReminderService.markAppOpened();
    
    // Request FCM permission
    await FirebaseMessaging.instance.requestPermission();
    
    final prefs = await SharedPreferences.getInstance();
    
    // Load and apply saved theme
    final savedThemeIndex = prefs.getInt('theme_mode') ?? 0;
    themeNotifier.value = ThemeMode.values[savedThemeIndex];

    // Load and apply saved language
    final savedLanguage = prefs.getString('app_language');
    if (savedLanguage != null && savedLanguage.isNotEmpty) {
      localeNotifier.value = Locale(savedLanguage);
    }
    
    // Run trash cleanup
    final retentionDays = prefs.getInt('trash_retention_days') ?? 30;
    if (retentionDays > 0) {
      FileManagerService().cleanupTrash(retentionDays);
    }
  }

  void _initIntentListener() {
    // For sharing files coming from outside the app while the app is in memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isEmpty) return;
      for (final media in value) {
        try {
          String path = media.path;
          if (path.startsWith('file://')) {
            path = Uri.parse(path).toFilePath();
          }
          if (File(path).existsSync()) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (_) => ViewerScreen(file: File(path))),
            );
          }
        } catch (e) {
          debugPrint("Malformed intent path: $e");
        }
        break;
      }
    }, onError: (err) {
      debugPrint("getIntentDataStream error: $err");
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return ValueListenableBuilder<Locale?>(
          valueListenable: localeNotifier,
          builder: (_, Locale? currentLocale, __) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              scaffoldMessengerKey: rootScaffoldMessengerKey,
              onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: currentLocale,
              localeResolutionCallback: (deviceLocale, supportedLocales) {
                if (currentLocale != null) return currentLocale;
                if (deviceLocale != null) {
                  for (var locale in supportedLocales) {
                    if (locale.languageCode == deviceLocale.languageCode) {
                      return deviceLocale;
                    }
                  }
                }
                return const Locale('en', ''); // Default fallback
              },
              debugShowCheckedModeBanner: false,
              scrollBehavior: const SmoothScrollBehavior(),
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: currentMode,
              navigatorObservers: [
                FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
              ],
              home: FutureBuilder<List<SharedMediaFile>>(
                future: _initialMediaFuture,
                builder: (context, snapshot) {
                  // While intent data is loading, show a minimal loading screen
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Scaffold(
                      backgroundColor: currentMode == ThemeMode.dark ? Colors.black : Colors.white,
                      body: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  // If intent has media, render ViewerScreen DIRECTLY (no HomeScreen flash)
                  final media = snapshot.data;
                  if (media != null && media.isNotEmpty) {
                    try {
                      String path = media.first.path;
                      if (path.startsWith('file://')) {
                        path = Uri.parse(path).toFilePath();
                      }
                      if (File(path).existsSync()) {
                        return ViewerScreen(file: File(path));
                      }
                    } catch (e) {
                      debugPrint("Malformed initial intent path: $e");
                    }
                  }
                  // No intent — show HomeScreen normally
                  return const HomeScreen();
                },
              ),
            );
          },
        );
      },
    );
  }
}
