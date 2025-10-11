import 'package:flutter/material.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/organization_service.dart';
import 'join_organization_widget.dart';
import 'create_organization_widget.dart';
import 'package:frontend/utils/ui_helpers.dart';
import 'package:frontend/screens/edit_account_screen.dart';

class DriverDrawerWidget extends StatelessWidget {
  const DriverDrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final hasOrg = authProvider.org != null;

    return SafeArea(
      child: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Colors.blue,
              child: const Text(
                "Organization",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
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

                          authProvider.setUser({
                            ...?authProvider.user,
                            'role': 'admin',
                            'org_id': org['id'],
                          });

                          authProvider.setOrg(org);

                          UIHelpers.showSuccess(
                            context,
                            "Organization created!",
                          );
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DashboardScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.orange),
                      title: const Text("Leave Organization"),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Leave Organization?"),
                            content: const Text(
                              "Are you sure you want to leave this organization?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  "Leave",
                                  style: TextStyle(color: Colors.orange),
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
                          await OrganizationService.leaveOrg(token);
                          authProvider.clearOrg(); // ✅ Clears org info locally
                          if (!context.mounted) return;
                          UIHelpers.showSuccess(
                            context,
                            "You left the organization.",
                          );
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DashboardScreen(),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          UIHelpers.showError(context, "Error: $e");
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text("Edit My Account"),
                  onTap: () {
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditAccountScreen()),
                    );
                  },
                ),
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
                      authProvider.clearToken();
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                      UIHelpers.showSuccess(
                        context,
                        "Account deleted successfully",
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      UIHelpers.showError(
                        context,
                        "Error deleting account: $e",
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
