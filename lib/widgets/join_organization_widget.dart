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

      UIHelpers.showSuccess(
        context,
        result['message'] ?? "Joined organization successfully",
      );
      inviteController.clear();
    } catch (e) {
      UIHelpers.showError(context, "Error joining organization: $e");
    } finally {
      if (mounted) setState(() => isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.group_add_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "Join an Organization",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: inviteController,
              decoration: InputDecoration(
                labelText: 'Invite Code',
                hintText: 'Enter code provided by admin',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.key_rounded),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                icon: isJoining
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login_rounded, size: 20),
                label: Text(
                  isJoining ? "Joining..." : "Join Organization",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: isJoining ? null : _joinOrganization,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
