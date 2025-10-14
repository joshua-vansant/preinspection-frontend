import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';

import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'package:frontend/providers/socket_provider.dart';
import 'package:frontend/providers/inspection_history_provider.dart';
import 'package:frontend/providers/vehicle_provider.dart';
import 'package:frontend/providers/inspection_provider.dart';

// Global camera list
late final List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize cameras
  cameras = await availableCameras();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return MaterialApp(
      title: 'PreInspection',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: authProvider.isLoggedIn
          ? const DashboardScreen()
          : const LoginScreen(),
    );
  }
}
