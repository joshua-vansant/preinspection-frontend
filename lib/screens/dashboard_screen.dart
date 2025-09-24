import 'package:flutter/material.dart';
import 'package:frontend/screens/vehicle_selection_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/inspection_service.dart';
import 'inspection_detail_screen.dart';
import 'inspection_form_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final role = authProvider.role ?? 'driver'; // default to driver if null

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
      body: SafeArea(
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: role == 'admin'
            ? _AdminDashboard()
            : _DriverDashboard(),
      ),
    ),
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
    final token = context.read<AuthProvider>().token!;
    historyFuture = InspectionService.getInspectionHistory(token);
  }

  @override
  Widget build(BuildContext context) {
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
              // Sort newest first
              history.sort((a, b) => b['created_at'].compareTo(a['created_at']));

              return ListView.builder(
                itemCount: history.length,
                itemBuilder: (_, index) {
                  final item = history[index];
                  final createdAt = DateTime.parse(item['created_at']);
                  final editable = DateTime.now().difference(createdAt).inMinutes <= 30;

                  return ListTile(
                    title: Text('Inspection #${item['id']}'),
                    subtitle: Text('Date: ${item['created_at']}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InspectionDetailScreen(inspection: item),
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
