import 'package:flutter/material.dart';
import 'package:frontend/screens/vehicle_selection_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/inspection_service.dart';
import '../services/organization_service.dart';
import 'inspection_detail_screen.dart';
import '../widgets/join_organization_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final role = authProvider.role ?? 'driver';

    return Scaffold(
      appBar: AppBar(
        title: Text(role == 'admin' ? "Admin Dashboard" : "Driver Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.clearToken();
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      drawer: role == 'driver'
          ? _DriverDrawer(
              onOrgChanged: () {},
            )
          : _AdminDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: role == 'admin' ? _AdminDashboard() : _DriverDashboard(),
        ),
      ),
    );
  }
}


class _DriverDrawer extends StatelessWidget {
  final VoidCallback onOrgChanged;
  const _DriverDrawer({required this.onOrgChanged});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text("Organization", style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
          if(authProvider.org == null)
          Padding(padding: const EdgeInsets.all(12.0),
          child: JoinOrganizationWidget(onJoined: onOrgChanged),),

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

                  Navigator.pop(context); // close drawer
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("You left the organization")),
                  );
                  onOrgChanged();
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



class _AdminDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Drawer(
      child: Center(child: Text("Admin drawer (coming soon)")),
    );
  }
}


class _DriverDashboard extends StatefulWidget {
  const _DriverDashboard({super.key});

  @override
  State<_DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<_DriverDashboard> {
  late Future<List<Map<String, dynamic>>> historyFuture;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token!;
    historyFuture = InspectionService.getInspectionHistory(token);

    if (authProvider.org == null) {
      OrganizationService.getMyOrg(token).then((orgData) {
        if (orgData != null) {
          authProvider.setOrg(orgData);
        }
      }).catchError((e) {
        debugPrint("Error fetching org info: $e");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final org = authProvider.org;

    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VehicleSelectionScreen()),
            );
          },
          child: const Text("Start New Inspection"),
        ),
        const SizedBox(height: 16),

        // Show org info only if driver is in an org
        if (org != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Organization: ${org['name']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

        const SizedBox(height: 16),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: historyFuture,
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No inspections yet.'));
              }

              final history = snapshot.data!;
              history.sort((a, b) => b['created_at'].compareTo(a['created_at']));

              return ListView.builder(
                itemCount: history.length,
                itemBuilder: (_, index) {
                  final item = history[index];
                  final createdAt = parseUtcToLocal(item['created_at']);
                  final formattedDate =
                      DateFormat('MMM d, yyyy - h:mm a').format(createdAt);

                  return ListTile(
                    title: Text('Inspection #${item['id']}'),
                    subtitle: Text('Date: $formattedDate'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              InspectionDetailScreen(inspection: item),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}


class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            // TODO: Navigate to Manage Templates
          },
          child: const Text("Manage Templates"),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            // TODO: Navigate to Invite Drivers
          },
          child: const Text("Invite Drivers"),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            // TODO: Navigate to View Inspections
          },
          child: const Text("View Inspections"),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            color: Colors.grey[200],
            child: const Center(
              child: Text("List of drivers in your org will appear here."),
            ),
          ),
        ),
      ],
    );
  }
}
