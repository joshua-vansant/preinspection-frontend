import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: role == 'admin'
            ? _AdminDashboard()
            : _DriverDashboard(),
      ),
    );
  }
}

class _DriverDashboard extends StatelessWidget {
  const _DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            // TODO: Navigate to New Inspection screen
          },
          child: const Text("Start a New Inspection"),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            color: Colors.grey[200],
            child: const Center(
              child: Text("Inspection history will appear here."),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: "Enter Invite Code",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                // TODO: Join org via invite code
              },
              child: const Text("Join"),
            ),
          ],
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
