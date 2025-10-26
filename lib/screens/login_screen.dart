import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    if (lastEmail != null) emailController.text = lastEmail;
    setState(() => _rememberMe = remember);
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
        HapticFeedback.lightImpact();
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
        HapticFeedback.lightImpact();
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    TextInputAction action = TextInputAction.next,
    TextInputType type = TextInputType.text,
    Iterable<String>? autofillHints,
  }) {
    final isPasswordField = obscure;
    return TextField(
      controller: controller,
      autofillHints: autofillHints,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceVariant.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: isPasswordField
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
      ),
      obscureText: isPasswordField ? _obscurePassword : false,
      textInputAction: action,
      keyboardType: type,
    );
  }

  Widget _buildLoginFields() => Column(
    key: const ValueKey('login_fields'),
    children: [
      _buildTextField(
        controller: emailController,
        label: "Email",
        type: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: passwordController,
        label: "Password",
        obscure: true,
        action: TextInputAction.done,
        autofillHints: const [AutofillHints.password],
      ),
    ],
  );

  Widget _buildRegisterFields() => Column(
    key: const ValueKey('register_fields'),
    children: [
      _buildTextField(controller: firstNameController, label: "First Name"),
      const SizedBox(height: 12),
      _buildTextField(controller: lastNameController, label: "Last Name"),
      const SizedBox(height: 12),
      _buildTextField(
        controller: phoneController,
        label: "Phone Number (optional)",
        type: TextInputType.phone,
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: emailController,
        label: "Email",
        type: TextInputType.emailAddress,
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: passwordController,
        label: "Password",
        obscure: true,
        action: TextInputAction.done,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Column(
            children: [
              Icon(
                Icons.directions_car_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'DriveCheck',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 28,
                  ),
                  child: Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: isRegistering
                            ? _buildRegisterFields()
                            : _buildLoginFields(),
                      ),
                      const SizedBox(height: 20),
                      _loading
                          ? const CircularProgressIndicator()
                          : Column(
                              children: [
                                AnimatedScale(
                                  scale: _loading ? 0.95 : 1,
                                  duration: const Duration(milliseconds: 150),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: isRegistering
                                          ? _handleRegister
                                          : _handleLogin,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        child: Text(
                                          isRegistering ? "Register" : "Login",
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: CheckboxListTile(
                                        title: const Text("Remember me"),
                                        value: _rememberMe,
                                        contentPadding: EdgeInsets.zero,
                                        dense: true,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        onChanged: (val) => setState(
                                          () => _rememberMe = val ?? false,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(
                                      () => isRegistering = !isRegistering,
                                    );
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
