import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';
import 'screens/viewer_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/ad_service.dart';
import 'services/file_manager_service.dart';
import 'services/notification_service.dart';

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

// Global key for Scafford Messenger
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// Global key for Navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
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
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                kDebugMode ? details.exceptionAsString() : 'An unexpected error occurred. Please try restarting the app.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // 2. Uncaught Asynchronous Errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Async error caught globally: $error');
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('An unexpected error occurred. We are looking into it.'),
        backgroundColor: Colors.redAccent,
      ),
    );
    return true;
  };

  // 3. Standard Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
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
    
    final prefs = await SharedPreferences.getInstance();
    
    // Load and apply saved theme
    final savedThemeIndex = prefs.getInt('theme_mode') ?? 0;
    themeNotifier.value = ThemeMode.values[savedThemeIndex];
    
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
        String path = media.path;
        if (path.startsWith('file://')) {
          path = Uri.parse(path).toFilePath();
        }
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => ViewerScreen(file: File(path))),
        );
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
        return MaterialApp(
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          title: 'Scan Master',
          debugShowCheckedModeBanner: false,
          scrollBehavior: const SmoothScrollBehavior(),
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
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
                String path = media.first.path;
                if (path.startsWith('file://')) {
                  path = Uri.parse(path).toFilePath();
                }
                return ViewerScreen(file: File(path));
              }
              // No intent — show HomeScreen normally
              return const HomeScreen();
            },
          ),
        );
      },
    );
  }
}
