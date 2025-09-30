import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/organization_service.dart';
import 'join_organization_widget.dart';
import 'package:frontend/utils/ui_helpers.dart';


class DriverDrawerWidget extends StatelessWidget {
  const DriverDrawerWidget({super.key});

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
              "Organization",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          if (authProvider.org == null)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: JoinOrganizationWidget(),
            ),
          if (authProvider.org != null)
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text("Leave Organization"),
              onTap: () async {
                final token = authProvider.token;
                if (token == null) {
                  UIHelpers.showError(context, "Not authenticated");
                  return;
                }

                try {
                  await OrganizationService.leaveOrg(token);
                  authProvider.clearOrg();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  UIHelpers.showError(context, "You left the organization");
                } catch (e) {
                  if (!context.mounted) return;
                  UIHelpers.showError(context, "Error leaving org: $e");
                }
              },
            ),
        ],
      ),
    );
  }
}
