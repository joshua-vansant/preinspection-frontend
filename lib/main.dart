import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/vehicle_provider.dart';
import 'providers/inspection_history_provider.dart';
import 'providers/socket_provider.dart';
import 'widgets/app_lifecycle_handler.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Sentry
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://6e997a495ed33316994592e01cce24f3@o4510095188688896.ingest.us.sentry.io/4510095241510912';
      options.tracesSampleRate = 1.0;
    },
    appRunner: () {
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),

            // Socket depends on Auth
            ChangeNotifierProxyProvider<AuthProvider, SocketProvider>(
              create: (context) =>
                  SocketProvider(authProvider: context.read<AuthProvider>()),
              update: (context, authProvider, socketProvider) {
                socketProvider ??= SocketProvider(authProvider: authProvider);
                return socketProvider;
              },
            ),

            ChangeNotifierProvider(create: (_) => VehicleProvider()),

            // InspectionHistory depends on SocketProvider
            ChangeNotifierProxyProvider<SocketProvider, InspectionHistoryProvider>(
              create: (context) =>
                  InspectionHistoryProvider(socketProvider: context.read<SocketProvider>()),
              update: (context, socketProvider, inspectionHistoryProvider) {
                inspectionHistoryProvider ??=
                    InspectionHistoryProvider(socketProvider: socketProvider);
                return inspectionHistoryProvider;
              },
            ),
          ],
          child: AppLifeCycleHandler(child: const MyApp()),
        ),
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PreInspection',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
      },
    );
  }
}
