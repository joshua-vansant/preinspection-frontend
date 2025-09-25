import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/organization_service.dart';
import 'join_organization_widget.dart';

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
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: JoinOrganizationWidget(), // no callback needed
            ),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("You left the organization")),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error leaving org: $e")),
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}
