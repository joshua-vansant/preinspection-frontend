import 'package:flutter/material.dart';
import 'package:frontend/screens/vehicle_selection_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/inspection_service.dart';
import '../services/organization_service.dart';
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
  final inviteController = TextEditingController();
  bool isJoining = false;
  
  @override
  void initState() {
    super.initState();
    final token = context.read<AuthProvider>().token!;
    historyFuture = InspectionService.getInspectionHistory(token);
  }

  @override
    void dispose() {
      inviteController.dispose();
      super.dispose();
    }

    Future<void> _joinOrganization() async {
      final token = context.read<AuthProvider>().token!;
      final code = inviteController.text.trim();
      if (code.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an invite code')),
        );
        return;
      }

      setState(() => isJoining = true);

      try {
        final result = await OrganizationService.joinOrganization(token, code);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Joined organization successfully')),
        );
        inviteController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining organization: $e')),
        );
      } finally {
        setState(() => isJoining = false);
      }
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
            history.sort((a, b) => b['created_at'].compareTo(a['created_at']));

            return ListView.builder(
              itemCount: history.length,
              itemBuilder: (_, index) {
                final item = history[index];
                final createdAt = parseUtcToLocal(item['created_at']);
                final formattedDate = DateFormat('MMM d, yyyy - h:mm a').format(createdAt);

                return ListTile(
                  title: Text('Inspection #${item['id']}'),
                  subtitle: Text('Date: $formattedDate'),
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

      // Join Organization section at the bottom
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: inviteController,
                decoration: const InputDecoration(
                  labelText: 'Enter Invite Code',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: isJoining ? null : _joinOrganization,
              child: isJoining
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Join'),
            ),
          ],
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
