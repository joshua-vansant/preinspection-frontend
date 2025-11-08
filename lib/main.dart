import 'package:flutter/material.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:frontend/services/walkthrough_service.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'themes/themes.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'package:frontend/providers/socket_provider.dart';
import 'package:frontend/providers/inspection_history_provider.dart';
import 'package:frontend/providers/vehicle_provider.dart';
import 'package:frontend/providers/inspection_provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'screens/reset_password_screen.dart';
import 'screens/splash_screen.dart';

// Global camera list
late final List<CameraDescription> cameras;
late final SharedPreferences sharedPreferences;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sharedPreferences = await SharedPreferences.getInstance();

  // Initialize cameras
  cameras = await availableCameras();
  await WalkthroughService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (context) =>
              SocketProvider(authProvider: context.read<AuthProvider>()),
        ),
        ChangeNotifierProvider(
          create: (context) => InspectionHistoryProvider(
            authProvider: context.read<AuthProvider>(),
            socketProvider: context.read<SocketProvider>(),
          ),
        ),
        ChangeNotifierProvider(create: (context) => VehicleProvider()),
        ChangeNotifierProvider(
          create: (context) =>
              InspectionProvider(authProvider: context.read<AuthProvider>()),
        ),
      ],
      child: const RootApp(),
    ),
  );
}

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Listen for links while app is running (foreground or background)
    _sub = _appLinks.uriLinkStream.listen(
      (Uri uri) => _handleUri(uri),
      onError: (err) => print('Error handling URI: $err'),
    );

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      print('Failed to get initial link: $e');
    }
  }

  void _handleUri(Uri uri) {
    print('🔗 [DeepLink Detected]');
    print('   Scheme: ${uri.scheme}');
    print('   Host: ${uri.host}');
    print('   Path: ${uri.path}');
    print('   Query: ${uri.query}');
    print('   Full URI: $uri');

    String? token;

    // Match both your HTTPS and custom schemes
    if (uri.scheme == 'https' &&
        uri.host == 'preinspection-api.onrender.com' &&
        (uri.path == '/auth/deep-reset' || uri.path == '/auth/reset-password')) {
      token = uri.queryParameters['token'];
      print('🧩 Extracted token from HTTPS: $token');
    } else if (uri.scheme == 'drivecheck' && uri.host == 'reset-password') {
      token = uri.queryParameters['token'];
      print('🧭 Extracted token from custom scheme: $token');
    } else {
      print('⚠️ URI did not match any expected pattern.');
      return;
    }

    if (token != null) {
      // Use navigatorKey safely here
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => ResetPasswordScreen(token: token!)),
          (route) => false,
        );
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'DriveCheck',
      navigatorKey: navigatorKey,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode:
          themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,

      /// 🟩 Start at the splash screen — it'll decide if we go to login, dashboard, or deep link.
      home: const SplashScreen(),
    );
  }
}
