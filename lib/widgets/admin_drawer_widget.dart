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

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Scrollable section
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(color: Colors.blue),
                    child: Text(
                      "Admin",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  // Show create org widget if admin has no org
                  if (authProvider.org == null)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: CreateOrganizationWidget(
                        onCreated: (organization) {
                          authProvider.setOrg(organization);
                          widget.onOrgCreated?.call();
                          Navigator.pop(context);
                          if (!mounted) return;
                          UIHelpers.showSuccess(
                            context,
                            "Organization created!",
                          );
                        },
                      ),
                    ),
                  // Manage Organization (only if admin has org)
                  if (authProvider.org != null)
                    ListTile(
                      leading: const Icon(Icons.business),
                      title: const Text("Manage Organization"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManageOrganizationScreen(),
                          ),
                        );
                      },
                    ),
                  // Manage Templates
                  ListTile(
                    leading: const Icon(Icons.article),
                    title: const Text("Manage Templates"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminTemplatesScreen(),
                        ),
                      );
                    },
                  ),
                  // Manage Vehicles
                  ListTile(
                    leading: const Icon(Icons.directions_car),
                    title: const Text("Manage Vehicles"),
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
            const Divider(),
            // Reset walkthrough
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.green),
              title: const Text(
                "Reset Walkthrough",
                style: TextStyle(color: Colors.green),
              ),
              onTap: () async {
                WalkthroughService.resetAdminWalkthrough();
                Navigator.pop(context);
                // Wait for drawer to close
                await Future.delayed(const Duration(milliseconds: 250));

                if (widget.onResetWalkthrough != null && context.mounted) {
                  widget.onResetWalkthrough!();
                }

                if (context.mounted) {
                  UIHelpers.showSuccess(
                    context,
                    "Walkthrough reset. Restarting from the dashboard.",
                  );
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text(
                "Edit My Account",
                style: TextStyle(color: Colors.blue),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditAccountScreen()),
                );
              },
            ),
            if (authProvider.org != null)
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.orange),
                title: const Text(
                  "Leave Organization",
                  style: TextStyle(color: Colors.orange),
                ),
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
            if (authProvider.org != null)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  "Delete Organization",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Delete Organization?"),
                      content: const Text(
                        "This will delete your organization and all related templates, vehicles, and inspections. This action cannot be undone.",
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
    );
  }
}
