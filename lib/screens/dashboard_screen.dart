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
import '../widgets/invite_driver_widget.dart';
import '../config/api_config.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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
          : AdminDrawerWidget(
              onOrgCreated: () {
                // Find the AdminDashboardState and refresh users
                final adminDashboardState = context.findAncestorStateOfType<_AdminDashboardState>();
                adminDashboardState?._fetchUsers(); // refresh user list
                // Join socket room again
                final orgId = context.read<AuthProvider>().org?['id'];
                if (orgId != null) {
                  adminDashboardState?._socket?.emit('join_org', {'org_id': orgId});
                }
              },
            ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: role == 'admin' ? AdminDashboard() : _DriverDashboard(),
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
        if (authProvider.user != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Welcome, ${authProvider.user!['first_name']} ${authProvider.user!['last_name']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
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
          child: authProvider.token == null
              ? const Center(child: Text('Please log in to view inspections.'))
              : FutureBuilder<List<Map<String, dynamic>>>(
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



class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _users = [];
  IO.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _setupSocket();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final token = context.read<AuthProvider>().token!;
    try {
      final users = await OrganizationService.getAllUsers(token);
      setState(() => _users = users);
    } catch (e) {
      setState(() => _error = "Error loading users: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _setupSocket() async {
    final auth = context.read<AuthProvider>();

    // Ensure org is loaded
    if (auth.org == null) {
      await auth.loadOrg();
    }

    final orgId = auth.org?['id'];
    if (orgId == null) {
      debugPrint('No org ID available for socket join.');
      return;
    }

    // Initialize socket connection
    _socket = IO.io(
      ApiConfig.baseUrl, 
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _socket!.connect();
    _socket!.on('driver_joined', (data) {
    debugPrint('Driver joined: $data');
    setState(() {
      _users.add(Map<String, dynamic>.from(data));
    });
  });

    _socket!.onConnect((_) {
      debugPrint('Socket connected');
      // Join organization room
      _socket!.emit('join_org', {'org_id': orgId});
    });

    _socket!.onDisconnect((_) => debugPrint('Socket disconnected'));
    _socket!.onError((data) => debugPrint('Socket error: $data'));
  }

  @override
  void dispose() {
    _socket?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminTemplatesScreen()),
            );
          },
          child: const Text("Manage Templates"),
        ),
        const SizedBox(height: 12),
        const InviteDriverWidget(),
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _users.isEmpty
                        ? const Center(child: Text("No drivers in your org yet."))
                        : ListView.builder(
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              return ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(user["first_name"] != null && user["last_name"] != null
                                    ? "${user["first_name"]} ${user["last_name"]}"
                                    : "Unnamed"),
                                subtitle: Text(user["email"] ?? ""),
                                trailing: Text(user["role"] ?? ""),
                              );
                            },
                          ),
          ),
        ),
      ],
    );
  }
}
