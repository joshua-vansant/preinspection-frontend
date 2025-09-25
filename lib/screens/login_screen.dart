import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
// import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String error = "";
  bool loading = false;

  Future<void> handleLogin() async {
    setState(() {
      loading = true;
      error = "";
    });

    try {
      final result = await AuthService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      final token = result['access_token'];
      final role = result['role'];
      // debugPrint("Login result: $result");
      // debugPrint("Saving token: $token, role: $role");

      // Save token and role in provider
      final authProvider = context.read<AuthProvider>();
      authProvider.setToken(token, role);

      // Navigate to dashboard
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/dashboard'
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint("Login error: $e");
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> handleRegister() async {
    setState(() {
      loading = true;
      error = "";
    });

    try {
      final result = await AuthService.register(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      final token = result['access_token'];
      final role = result['role'];

      final authProvider = context.read<AuthProvider>();
      authProvider.setToken(token, role);
      authProvider.loadOrg();

      // Navigate to dashboard
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/dashboard',
      );
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 12),
            if (error.isNotEmpty)
              Text(error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            loading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: handleLogin,
                        child: const Text("Login"),
                      ),
                      TextButton(
                        onPressed: handleRegister,
                        child: const Text("Don't have an account? Register"),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
