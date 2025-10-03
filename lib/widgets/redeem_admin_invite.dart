import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/organization_service.dart';
import '../utils/ui_helpers.dart';

class RedeemAdminInviteWidget extends StatefulWidget {
  const RedeemAdminInviteWidget({super.key});

  @override
  State<RedeemAdminInviteWidget> createState() =>
      _RedeemAdminInviteWidgetState();
}

class _RedeemAdminInviteWidgetState extends State<RedeemAdminInviteWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _message;

  Future<void> _redeemAdminCode() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    final authProvider = context.read<AuthProvider>();
    final code = _controller.text.trim();
    final token = authProvider.token;

    if (token == null) {
      setState(() {
        _message = "Not authenticated";
        _loading = false;
      });
      return;
    }

    try {
      final result = await OrganizationService.redeemAdminInvite(token, code);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        authProvider.setUser({
          ...?authProvider.user,
          'role': 'admin',
          'org_id': result['org_id'],
        });
      });
      await authProvider.org;

      setState(() {
        _message = "Success! You are now an admin.";
      });
    } catch (e) {
      setState(() {
        _message = "Invalid code. Please try again.";
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Enter admin invite code:"),
        const SizedBox(height: 4),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(labelText: "Admin Code"),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _loading ? null : _redeemAdminCode,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Redeem"),
        ),
        if (_message != null) ...[
          const SizedBox(height: 8),
          Text(
            _message!,
            style: TextStyle(
              color: _message!.startsWith("Success") ? Colors.green : Colors.red,
            ),
          ),
        ],
      ],
    );
  }
}
