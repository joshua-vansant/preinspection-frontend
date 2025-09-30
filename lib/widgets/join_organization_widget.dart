import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/organization_service.dart';
import 'package:frontend/utils/ui_helpers.dart';


class JoinOrganizationWidget extends StatefulWidget {
  const JoinOrganizationWidget({super.key});

  @override
  State<JoinOrganizationWidget> createState() => _JoinOrganizationWidgetState();
}

class _JoinOrganizationWidgetState extends State<JoinOrganizationWidget> {
  final inviteController = TextEditingController();
  bool isJoining = false;

  @override
  void dispose() {
    inviteController.dispose();
    super.dispose();
  }

  Future<void> _joinOrganization() async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;
    final code = inviteController.text.trim();

    if (token == null) {
      UIHelpers.showError(context, "Not authenticated");
      return;
    }

    if (code.isEmpty) {
      UIHelpers.showError(context, "Please enter an invite code");
      return;
    }

    setState(() => isJoining = true);

    try {
      final result = await OrganizationService.joinOrg(token, code);

      if (result['organization'] != null) {
        authProvider.setOrg(result['organization']);
      }

      UIHelpers.showSuccess(context, result['message'] ?? "Joined organization successfully");
      inviteController.clear();
    } catch (e) {
      UIHelpers.showError(context, "Error joining organization: $e");
    } finally {
      if (mounted) setState(() => isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: inviteController,
              decoration: const InputDecoration(
                labelText: 'Enter Invite Code',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: isJoining ? null : _joinOrganization,
            child: isJoining
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Join'),
          ),
        ],
      ),
    );
  }
}
