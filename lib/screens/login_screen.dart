import 'package:flutter/material.dart';
import 'package:frontend/providers/inspection_history_provider.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../utils/ui_helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();

  bool isRegistering = false;
  bool _rememberMe = false;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadLastEmail();
  }

  Future<void> _loadLastEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final lastEmail = prefs.getString('last_email');
    final remember = prefs.getBool('remember_me') ?? false;

    if (lastEmail != null) {
      emailController.text = lastEmail;
    }

    setState(() {
      _rememberMe = remember;
    });
  }

  Future<void> _handleLogin() async {
    setState(() => _loading = true);
    final authProvider = context.read<AuthProvider>();

    try {
      final result = await AuthService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      final token = result['access_token'];
      final userData = result['user'];

      if (token != null && userData != null) {
        authProvider.setToken(token, userData['role'], userData: userData);

        // After login succeeds
        final inspectionHistoryProvider = context
            .read<InspectionHistoryProvider>();
        await inspectionHistoryProvider.fetchHistory();

        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setString('last_email', emailController.text.trim());
          await prefs.setBool('remember_me', true);
        } else {
          await prefs.remove('last_email');
          await prefs.setBool('remember_me', false);
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        UIHelpers.showError(context, "Login failed: Invalid server response");
      }
    } catch (e) {
      if (!mounted) return;
      UIHelpers.showError(context, "Login failed: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleRegister() async {
    setState(() => _loading = true);
    final authProvider = context.read<AuthProvider>();

    try {
      final result = await AuthService.register(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        phoneNumber: phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
      );

      final token = result['access_token'];
      final userData = result['user'];

      if (token != null && userData != null) {
        authProvider.setToken(token, userData['role'], userData: userData);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        UIHelpers.showError(
          context,
          "Registration failed: Invalid server response",
        );
      }
    } catch (e) {
      if (!mounted) return;
      UIHelpers.showError(context, "Registration failed: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    TextInputAction action = TextInputAction.next,
    TextInputType type = TextInputType.text,
  }) {
    final isPasswordField = obscure;

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: isPasswordField
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
      ),
      obscureText: isPasswordField ? _obscurePassword : false,
      textInputAction: action,
      keyboardType: type,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isRegistering ? "Register" : "Login")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (isRegistering) ...[
              buildTextField(
                controller: firstNameController,
                label: "First Name",
              ),
              const SizedBox(height: 8),
              buildTextField(
                controller: lastNameController,
                label: "Last Name",
              ),
              const SizedBox(height: 8),
              buildTextField(
                controller: phoneController,
                label: "Phone Number (optional)",
                type: TextInputType.phone,
              ),
              const SizedBox(height: 8),
            ],
            buildTextField(
              controller: emailController,
              label: "Email",
              type: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            buildTextField(
              controller: passwordController,
              label: "Password",
              obscure: true,
              action: TextInputAction.done,
            ),
            const SizedBox(height: 12),
            _loading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: isRegistering
                            ? _handleRegister
                            : _handleLogin,
                        child: Text(isRegistering ? "Register" : "Login"),
                      ),
                      CheckboxListTile(
                        title: const Text("Remember me"),
                        value: _rememberMe,
                        onChanged: (val) =>
                            setState(() => _rememberMe = val ?? false),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => isRegistering = !isRegistering);
                        },
                        child: Text(
                          isRegistering
                              ? "Already have an account? Login"
                              : "Don't have an account? Register",
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
