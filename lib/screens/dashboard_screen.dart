import 'package:flutter/material.dart';
import 'package:frontend/screens/admin_templates_screen.dart';
import 'package:frontend/screens/vehicle_selection_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/inspection_service.dart';
import '../services/organization_service.dart';
import 'inspection_detail_screen.dart';
import '../widgets/driver_drawer_widget.dart';
import '../widgets/admin_drawer_widget.dart';

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
          ? DriverDrawerWidget()
          : AdminDrawerWidget(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: role == 'admin' ? _AdminDashboard() : _DriverDashboard(),
        ),
      ),
    );
  }
}


class _DriverDashboard extends StatelessWidget {
  const _DriverDashboard({super.key});

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
            future: InspectionService.getInspectionHistory(authProvider.token!),
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
            Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminTemplatesScreen()),
                );          },
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
