import 'package:flutter/material.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:frontend/services/walkthrough_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/organization_service.dart';
import 'create_organization_widget.dart';
import 'package:frontend/screens/admin_templates_screen.dart';
import 'package:frontend/screens/admin_vehicle_screen.dart';
import 'package:frontend/screens/manage_organization_screen.dart';
import 'package:frontend/screens/edit_account_screen.dart';
import 'package:frontend/utils/ui_helpers.dart';

class AdminDrawerWidget extends StatefulWidget {
  final VoidCallback? onOrgCreated;
  final VoidCallback? onResetWalkthrough;

  const AdminDrawerWidget({
    super.key,
    this.onOrgCreated,
    this.onResetWalkthrough,
  });

  @override
  State<AdminDrawerWidget> createState() => _AdminDrawerWidgetState();
}

class _AdminDrawerWidgetState extends State<AdminDrawerWidget> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final org = authProvider.org;

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.surfaceVariant.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Drawer header with org/user info
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
                  authProvider.user?['full_name'] ?? 'Admin User',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(
                  org != null ? org['name'] ?? 'No Organization' : 'No Organization',
                  style: const TextStyle(fontSize: 14),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: colorScheme.onPrimary,
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                ),
              ),

              // Main scrollable section
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (authProvider.org == null)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: CreateOrganizationWidget(
                          onCreated: (organization) {
                            authProvider.setOrg(organization);
                            widget.onOrgCreated?.call();
                            Navigator.pop(context);
                            if (!mounted) return;
                            UIHelpers.showSuccess(context, "Organization created!");
                          },
                        ),
                      ),
                    if (authProvider.org != null)
                      _buildDrawerTile(
                        context,
                        icon: Icons.business,
                        label: "Manage Organization",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManageOrganizationScreen(),
                            ),
                          );
                        },
                      ),
                    _buildDrawerTile(
                      context,
                      icon: Icons.article_outlined,
                      label: "Manage Templates",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminTemplatesScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerTile(
                      context,
                      icon: Icons.directions_car_filled_outlined,
                      label: "Manage Vehicles",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminVehiclesScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    _buildDrawerTile(
                      context,
                      icon: Icons.refresh_rounded,
                      label: "Reset Walkthrough",
                      color: Colors.green,
                      onTap: () async {
                        WalkthroughService.resetAdminWalkthrough();
                        Navigator.pop(context);
                        await Future.delayed(const Duration(milliseconds: 250));
                        widget.onResetWalkthrough?.call();
                        if (context.mounted) {
                          UIHelpers.showSuccess(
                            context,
                            "Walkthrough reset. Restarting from the dashboard.",
                          );
                        }
                      },
                    ),
                    _buildDrawerTile(
                      context,
                      icon: Icons.person_outline,
                      label: "Edit My Account",
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EditAccountScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const Divider(),
              if (authProvider.org != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                        icon: Icons.exit_to_app_rounded,
                        label: "Leave Organization",
                        color: Colors.orange,
                        onTap: () async {
                          final token = authProvider.token!;
                          try {
                            await OrganizationService.leaveOrg(token);
                            authProvider.clearOrg();
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            UIHelpers.showSuccess(context, "You left the organization");
                          } catch (e) {
                            UIHelpers.showError(context, "Error leaving org: $e");
                          }
                        },
                      ),
                      _buildDrawerTile(
                        context,
                        icon: Icons.delete_forever_rounded,
                        label: "Delete Organization",
                        color: Colors.redAccent,
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Delete Organization?"),
                              content: const Text(
                                "This will permanently delete your organization, including all related templates, vehicles, and inspections. This action cannot be undone.",
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
                            await OrganizationService.deleteOrg(token);
                            authProvider.clearOrg();
                            authProvider.setRole("driver");
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DashboardScreen(),
                              ),
                            );
                            UIHelpers.showSuccess(
                              context,
                              "Organization deleted successfully!",
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            UIHelpers.showError(context, "Error deleting org: $e");
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
