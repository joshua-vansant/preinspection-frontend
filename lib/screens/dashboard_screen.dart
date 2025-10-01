import 'package:flutter/material.dart';
import 'package:frontend/screens/admin_templates_screen.dart';
import 'package:frontend/screens/vehicle_selection_screen.dart';
import 'package:frontend/utils/ui_helpers.dart';
import 'package:frontend/widgets/invite_admin_widget.dart';
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
import 'package:frontend/screens/admin_inspections_screen.dart';
import 'admin_vehicle_screen.dart';
import '../providers/socket_provider.dart';
import 'package:frontend/utils/date_time_utils.dart';
import 'manage_organization_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final role = authProvider.role ?? 'driver';
    final hasOrg = authProvider.org != null;

    // Determine if admin dashboard should be shown
    final isAdmin = role == 'admin' && hasOrg;
    debugPrint('DriverDrawer build: org=${authProvider.org}, hasOrg=$hasOrg');


    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? "Admin Dashboard" : "Driver Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.clearToken();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      drawer: isAdmin
          ? AdminDrawerWidget(onOrgCreated: () {})
          : DriverDrawerWidget(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isAdmin ? AdminDashboard() : DriverDashboard(),
        ),
      ),
    );
  }
}




class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String? _error;

  AuthProvider? _authProvider;
  SocketProvider? _socketProvider;

  @override
  void initState() {
    super.initState();
    // Delay initialization until context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authProvider = context.read<AuthProvider>();
      _socketProvider = context.read<SocketProvider>();

      // Only fetch if token exists
      if (_authProvider?.token != null) {
        _fetchHistory();
        _subscribeToSocket();
      } else {
        setState(() {
          _error = "Authentication token not available.";
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _fetchHistory() async {
    if (_authProvider?.token == null) {
    setState(() {
      _isLoading = false;
      _history = [];
      _error = "Authentication token not available.";
    });
    return;
  }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final history = await InspectionService.getInspectionHistory(
        _authProvider!.token!,
      );

      // Sort by created_at descending
      history.sort((a, b) {
        final aDate = a['created_at'] != null
            ? DateTime.tryParse(a['created_at'])
            : null;
        final bDate = b['created_at'] != null
            ? DateTime.tryParse(b['created_at'])
            : null;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
        if (!mounted) return;
        UIHelpers.showError(context, e.toString());
        setState(() => _isLoading = false);
      }
  }

  void _subscribeToSocket() {
    final driverId = _authProvider?.user?['id'];
    if (driverId == null) return;

    _socketProvider?.onEvent('inspection_created', (data) {
      final inspection = Map<String, dynamic>.from(data);
      final driverId = _authProvider?.user?['id'];
      if (driverId != null &&
          inspection['driver'] != null &&
          inspection['driver']['id'] == driverId) {
        setState(() {
          _history.insert(0, inspection);
        });
      }
    });
  }

  @override
  void dispose() {
    debugPrint('DEBUG: DriverDashboard disposed');
    _socketProvider?.offEvent('inspection_created');
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final user = _authProvider?.user;
    final org = _authProvider?.org;

    return SafeArea(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (user != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16,
              ),
              child: Text(
                "Welcome, ${user['first_name']} ${user['last_name']}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ),
        if (org != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 4.0,
                horizontal: 16,
              ),
              child: Text(
                "Organization: ${org['name']}",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Colors.blueGrey.shade800,
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VehicleSelectionScreen(),
                ),
              );
            },
            child: const Text("Start New Inspection"),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text('Error: $_error'))
              : _history.isEmpty
              ? const Center(child: Text('No inspections yet.'))
              : RefreshIndicator(
                  onRefresh: _fetchHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _history.length,
                    itemBuilder: (_, index) {
                      final item = _history[index];
                      final formattedDate = parseUtcToLocal(item['created_at']);
                      final driverName = item['driver'] != null
                          ? item['driver']['full_name']
                          : 'N/A';

                      final inspectionType = (item['type'] ?? 'N/A')
                          .toUpperCase();

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          title: Text(
                            'Inspection #${item['id']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Driver: $driverName'),
                              Text('Date: $formattedDate'),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: inspectionType == 'PRE'
                                  ? Colors.green.shade100
                                  : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              inspectionType,
                              style: TextStyle(
                                color: inspectionType == 'PRE'
                                    ? Colors.green.shade800
                                    : Colors.blue.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    InspectionDetailScreen(inspection: item),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
      ),
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
    debugPrint('DEBUG: AdminDashboard initState start');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if(!mounted) return;
      debugPrint('DEBUG: AdminDashboard postFrameCallback');
      final auth = context.read<AuthProvider>();
      await _fetchUsers(auth);
      debugPrint('DEBUG: AdminDashboard fetched users');
      _setupSocket(auth);  // Pass it in!
      debugPrint('DEBUG: AdminDashboard setup socket done');
    });
  }

Future<void> _fetchUsers(AuthProvider auth) async {
  if (!mounted) return;

  setState(() {
    _loading = true;
    _error = null;
  });

  final token = auth.token;
  if (token == null) {
    if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No auth token';
      });
      return;
    }

    try {
      final users = await OrganizationService.getAllUsers(token);
      if (!mounted) return;
      setState(() => _users = users);
    } catch (e) {
      if (!mounted) return;
      UIHelpers.showError(context, e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }
 void _setupSocket(AuthProvider auth) async {
  if (auth.org == null) {
    await auth.loadOrg();
    if (!mounted) return;
  }

  final orgId = auth.org?['id'];
  if (orgId == null) return;

  _socket = IO.io(
    ApiConfig.baseUrl,
    IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .build(),
  );

  _socket!.connect();

  _socket!.on('driver_joined', (data) {
    if (!mounted) return;
    final newDriver = Map<String, dynamic>.from(data);
    setState(() {
      _users.removeWhere((u) => u['id'] == newDriver['id']);
      final adminIndex = _users.indexWhere((u) => u['role'] == 'admin');
      if (adminIndex >= 0) {
        _users.insert(adminIndex + 1, newDriver);
      } else {
        _users.add(newDriver);
      }
    });
  });

  _socket!.on('driver_left', (data) {
    if (!mounted) return;
    final driverId = data['id'];
    if (driverId == null) return;
    setState(() {
      _users.removeWhere((u) => u['id'] == driverId);
    });
  });

  _socket!.onConnect((_) {
    if (!mounted) return;
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
    final auth = context.watch<AuthProvider>();
    final org = auth.org;

    if (auth.org == null) {
      if (_users.isNotEmpty || _socket != null) {
        setState(() {
          _users = [];
          _socket?.disconnect();
          _socket = null;
        });
      }
    }


    if (org == null) {
      // Admin has no org — show a friendly message
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You are not part of any organization.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageOrganizationScreen()),
                );
              },
              child: const Text('Create or Join Organization'),
            ),
          ],
        ),
      );
    }


    return SafeArea(
      child: Column(
      children: [
        // Organization Info Card
        if (org != null)
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SafeArea(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        org['name'] ?? 'Organization',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (org['address'] != null && org['address'].isNotEmpty)
                    Text('Address: ${org['address']}'),
                  if (org['contact_name'] != null &&
                      org['contact_name'].isNotEmpty)
                    Text('Contact: ${org['contact_name']}'),
                  if (org['phone_number'] != null &&
                      org['phone_number'].isNotEmpty)
                    Text('Phone: ${org['phone_number']}'),
                ],
                ),
              ),
            ),
          ),

        // Buttons
        const InviteDriverWidget(),
        const SizedBox(height: 12),
        // const InviteAdminWidget(),
        // const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminInspectionsScreen()),
            );
          },
          child: const Text("View Inspections"),
        ),
        const SizedBox(height: 12),

        // User List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : _users.isEmpty
              ? const Center(child: Text("No users in your org yet."))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    // Admin Card
                    if (_users.any((u) => u['role'] == 'admin'))
                      Card(
                        color: Colors.amber.shade50,
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.amber,
                          ),
                          title: Text(
                            '${_users.firstWhere((u) => u['role'] == 'admin')["first_name"]} '
                            '${_users.firstWhere((u) => u['role'] == 'admin')["last_name"]} (Admin)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            _users.firstWhere(
                                  (u) => u['role'] == 'admin',
                                )["email"] ??
                                "",
                          ),
                        ),
                      ),

                    // Drivers Cards
                    ..._users.where((u) => u['role'] != 'admin').map((user) {
                      return Dismissible(
                        key: ValueKey(user['id']),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Remove driver?"),
                              content: Text(
                                "Are you sure you want to remove ${user['first_name']}?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Remove"),
                                ),
                              ],
                            ),
                          );
                          return confirm ?? false;
                        },
                        onDismissed: (_) async {
                          try {
                            final token = context.read<AuthProvider>().token!;
                            await OrganizationService.removeDriver(
                              token,
                              user['id'],
                            );
                            setState(
                              () => _users.removeWhere(
                                (u) => u['id'] == user['id'],
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("${user['first_name']} removed"),
                              ),
                            );
                          }catch (e) {
                            if (!mounted) return;
                            UIHelpers.showError(context, e.toString());
                          }

                        },
                        child: Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(
                              '${user["first_name"]} ${user["last_name"]}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(user["email"] ?? ""),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user["role"] ?? "",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    // No drivers message
                    if (_users.where((u) => u['role'] != 'admin').isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text("No drivers in your org yet."),
                        ),
                      ),
                  ],
                ),
        ),
      ],
      ),
    );
  }
}
