import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/ui_helpers.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _handlePasswordReset() async {
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      UIHelpers.showError(context, "Please fill out all fields");
      return;
    }

    if (newPassword != confirmPassword) {
      UIHelpers.showError(context, "Passwords do not match");
      return;
    }

    if (newPassword.length < 8) {
      UIHelpers.showError(context, "Password must be at least 8 characters");
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await AuthService.resetPassword(
        token: widget.token,
        newPassword: newPassword,
      );

      if (response['message'] != null) {
        if (!mounted) return;
        UIHelpers.showSuccess(context, response['message']);
        Navigator.pop(context); // Go back to login
      } else {
        UIHelpers.showError(context, response['error'] ?? "Reset failed");
      }
    } catch (e) {
      UIHelpers.showError(context, "Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reset Password"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: newPasswordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: "New Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _handlePasswordReset,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text("Reset Password"),
            ),
          ],
        ),
      ),
    );
  }
}
