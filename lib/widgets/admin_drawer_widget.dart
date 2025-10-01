import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/organization_service.dart';
import 'create_organization_widget.dart';
import 'package:frontend/screens/admin_templates_screen.dart';
import 'package:frontend/screens/admin_vehicle_screen.dart';
import 'package:frontend/screens/manage_organization_screen.dart';
import 'package:frontend/utils/ui_helpers.dart';


class AdminDrawerWidget extends StatefulWidget {
  final VoidCallback? onOrgCreated; // callback to refresh dashboard

  const AdminDrawerWidget({super.key, this.onOrgCreated});

  @override
  State<AdminDrawerWidget> createState() => _AdminDrawerWidgetState();
}

class _AdminDrawerWidgetState extends State<AdminDrawerWidget> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Drawer(
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
                  if (widget.onOrgCreated != null) {
                    widget.onOrgCreated!(); // refresh dashboard users
                  }
                  Navigator.pop(context); // close drawer
                  if (!mounted) return;
                  UIHelpers.showSuccess(context, "Organization created!");
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
                      builder: (_) => const ManageOrganizationScreen()),
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
                MaterialPageRoute(builder: (_) => const AdminTemplatesScreen()),
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
                MaterialPageRoute(builder: (_) => const AdminVehiclesScreen()),
              );
            },
          ),

          const Divider(),

          // Leave Organization
          if (authProvider.org != null)
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text("Leave Organization"),
              onTap: () async {
                final token = authProvider.token!;
                try {
                  await OrganizationService.leaveOrg(token);
                  authProvider.clearOrg();
                  if (!context.mounted) return;

                  Navigator.pop(context);
                  if (!mounted) return;
                  UIHelpers.showSuccess(context, "You left the organization");
                } catch (e) {
                  UIHelpers.showError(context, "Error leaving org: $e");
                }
              },
            ),

            // Delete Organization (only visible if admin has org)
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
              "This will delete your organization and all related templates, vehicles, and inspections. This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
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
            await OrganizationService.deleteOrg(token); // <-- backend call
            authProvider.clearOrg(); // remove org from provider
            if (!context.mounted) return;
            Navigator.pop(context); // close drawer
            UIHelpers.showSuccess(context, "Organization deleted successfully!");
          } catch (e) {
            if (!context.mounted) return;
            UIHelpers.showError(context, "Error deleting org: $e");
          }
        },
      ),

        ],
      ),
    );
  }
}
