import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:frontend/screens/reset_password_screen.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import '../../main.dart'; // 👈 for navigatorKey

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AppLinks _appLinks;
  bool _navigated = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _fadeController.forward(); // fade in the splash
    _init();
  }

  Future<void> _init() async {
  _appLinks = AppLinks();

  await Future.delayed(const Duration(milliseconds: 900));

  final initialUri = await _appLinks.getInitialLink();
  if (initialUri != null) {
    _handleUri(initialUri);
  } else {
    _goToDefault();
  }
}


  void _handleUri(Uri uri) {
    print('🚀 [Splash DeepLink] $uri');

    String? token;
    if (uri.scheme == 'https' &&
        uri.host == 'preinspection-api.onrender.com' &&
        (uri.path == '/auth/deep-reset' || uri.path == '/auth/reset-password')) {
      token = uri.queryParameters['token'];
      print('🧩 Token (https): $token');
    } else if (uri.scheme == 'drivecheck' && uri.host == 'reset-password') {
      token = uri.queryParameters['token'];
      print('🧭 Token (custom): $token');
    }

    if (token != null && !_navigated) {
      _fadeOutAndNavigate(
        ResetPasswordScreen(token: token!),
      );
    } else {
      _goToDefault();
    }
  }

  void _goToDefault() {
    if (_navigated) return;
    final authProvider = context.read<AuthProvider>();
    final Widget nextScreen = authProvider.isLoggedIn
        ? const DashboardScreen()
        : const LoginScreen();
    _fadeOutAndNavigate(nextScreen);
  }

  void _fadeOutAndNavigate(Widget screen) async {
    if (_navigated) return;
    _navigated = true;

    await _fadeController.reverse(); // fade out splash

    navigatorKey.currentState?.pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_car_rounded,
                size: 96,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'DriveCheck',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
