import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../services/organization_service.dart';

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

  String error = "";
  bool loading = false;
  bool isRegistering = false; // <-- toggle flag

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
      final userData = result['user'];
      final expiresIn = result['expires_in'];
      final role = userData['role'] as String;

      if (token != null && role != null) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.setToken(token, role, userData: userData, expiresIn: expiresIn);
      }

      // Fetch org data if available
      if (token != null) {
        final orgData = await OrganizationService.getMyOrg(token);
        if (orgData != null) {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          authProvider.setOrg(orgData);
        }
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      if (!mounted) return;
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
      final role = userData['role'] as String;

      if (token != null && role != null) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.setToken(token, role, userData: userData);
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    TextInputAction action = TextInputAction.next,
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      obscureText: obscure,
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
            if (error.isNotEmpty)
              Text(error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            loading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: isRegistering ? handleRegister : handleLogin,
                        child: Text(isRegistering ? "Register" : "Login"),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isRegistering = !isRegistering;
                            error = "";
                          });
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
