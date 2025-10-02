import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/organization_service.dart';
import 'join_organization_widget.dart';
import 'create_organization_widget.dart';
import 'package:frontend/utils/ui_helpers.dart';

class DriverDrawerWidget extends StatelessWidget {
  const DriverDrawerWidget({super.key});

  @override
Widget build(BuildContext context) {
  // Watching authProvider so drawer rebuilds on changes
  final authProvider = context.watch<AuthProvider>();
  final isAdmin = authProvider.role == 'admin';
  final hasOrg = authProvider.org != null;

  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        const DrawerHeader(
          decoration: BoxDecoration(color: Colors.blue),
          child: Text(
            "Organization",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),

        // If user has no org, show Join or Create widgets
        if (!hasOrg) ...[
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: JoinOrganizationWidget(),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: CreateOrganizationWidget(
              onCreated: (org) {
                if (!context.mounted) return;

                // Update user role and org_id
                authProvider.setUser({
                  ...?authProvider.user,
                  'role': 'admin',
                  'org_id': org['id'],
                });

                // Update org in provider
                authProvider.setOrg(org);

                // Show success message
                UIHelpers.showSuccess(context, "Organization created!");

                // Navigate to dashboard to refresh UI
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
            ),
          ),
        ],

        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text(
            "Delete My Account",
            style: TextStyle(color: Colors.red),
          ),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Delete Account?"),
                content: const Text(
                  "This will permanently delete your account. Are you sure?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      "Delete",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );

            if (confirm != true) return;

            final token = authProvider.token;
            if (token == null) {
              UIHelpers.showError(context, "Not authenticated");
              return;
            }

            try {
              await OrganizationService.deleteDriver(token);

              // Clear auth state and navigate to login
              authProvider.clearToken();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
              UIHelpers.showSuccess(context, "Account deleted successfully");
            } catch (e) {
              if (!context.mounted) return;
              UIHelpers.showError(context, "Error deleting account: $e");
            }
          },
        ),
      ],
    ),
  );
}
}