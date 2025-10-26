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
import '../services/walkthrough_service.dart';

class DriverDrawerWidget extends StatelessWidget {
  final VoidCallback? onResetWalkthrough;
  const DriverDrawerWidget({super.key, this.onResetWalkthrough});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasOrg = authProvider.org != null;

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withOpacity(0.08),
              colorScheme.surfaceVariant.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.primary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                accountName: Text(
                  authProvider.user?['full_name'] ?? 'Driver',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(
  hasOrg
      ? (authProvider.org?['name']?.toString() ?? 'Organization')
      : 'No Organization',
  style: const TextStyle(fontSize: 14),
),

                currentAccountPicture: CircleAvatar(
                  backgroundColor: colorScheme.onPrimary,
                  child: Icon(
                    Icons.person_outline,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                ),
              ),

              // Main section
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
                      _buildDrawerTile(
                        context,
                        icon: Icons.logout_rounded,
                        label: "Leave Organization",
                        color: Colors.orange,
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
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
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
                            authProvider.clearOrg();
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
                    const Divider(),
                    _buildDrawerTile(
                      context,
                      icon: Icons.refresh_rounded,
                      label: "Reset Walkthrough",
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        if (onResetWalkthrough != null) {
                          onResetWalkthrough!();
                        }
                      },
                    ),
                  ],
                ),
              ),

              const Divider(),
              // Bottom section
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDrawerTile(
                      context,
                      icon: Icons.edit_outlined,
                      label: "Edit My Account",
                      color: colorScheme.primary,
                      onTap: () {
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EditAccountScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "Danger Zone",
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildDrawerTile(
                      context,
                      icon: Icons.delete_forever_rounded,
                      label: "Delete My Account",
                      color: Colors.redAccent,
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
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor = color ?? colorScheme.primary;

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        label,
        style: TextStyle(
          color: iconColor,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: onTap,
      hoverColor: colorScheme.surfaceVariant.withOpacity(0.2),
      splashColor: colorScheme.primary.withOpacity(0.1),
    );
  }
}
