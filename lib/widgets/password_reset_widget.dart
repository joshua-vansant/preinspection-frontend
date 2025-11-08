import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class PasswordResetWidget extends StatefulWidget {
  final VoidCallback onBack;

  const PasswordResetWidget({super.key, required this.onBack});

  @override
  State<PasswordResetWidget> createState() => _PasswordResetWidgetState();
}

class _PasswordResetWidgetState extends State<PasswordResetWidget> {
  final emailController = TextEditingController();
  bool _loading = false;
  String? _message;

  Future<void> _handlePasswordResetRequest() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final response = await AuthService.requestPasswordReset(
        emailController.text.trim(),
      );

      if (response['error'] != null) {
        _message = response['error'];
      } else {
        _message = "If an account exists, a reset link has been sent.";
      }
    } catch (e) {
      _message = "Failed to request password reset: $e";
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('reset_password_fields'),
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(
            labelText: "Enter your account email",
            filled: true,
            fillColor: Theme.of(context)
                .colorScheme
                .surfaceVariant
                .withOpacity(0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_loading)
          const CircularProgressIndicator()
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handlePasswordResetRequest,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text("Send Reset Link", style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(
            _message!,
            style: TextStyle(
              color: _message!.contains('sent') ? Colors.green : Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 16),
        TextButton(
          onPressed: widget.onBack,
          child: const Text("Back to Login"),
        ),
      ],
    );
  }
}
