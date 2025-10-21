import 'package:flutter/material.dart';
import 'package:frontend/config/api_config.dart';
import 'package:frontend/providers/inspection_history_provider.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:frontend/services/walkthrough_service.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import '../providers/auth_provider.dart';
import '../services/inspection_service.dart';
import '../services/organization_service.dart';
import '../widgets/driver_drawer_widget.dart';
import '../widgets/admin_drawer_widget.dart';
import '../widgets/invite_driver_widget.dart';
import '../utils/ui_helpers.dart';
import '../utils/date_time_utils.dart';
import 'inspection_detail_screen.dart';
import 'vehicle_selection_screen.dart';
import 'admin_inspections_screen.dart';
import 'manage_organization_screen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:frontend/screens/login_screen.dart';

//////////////////////////
// DASHBOARD SCREEN
//////////////////////////
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.user == null ||
        (auth.user?['org_id'] != null && auth.org == null)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final role = auth.role ?? 'driver';

    return role == 'admin' ? const AdminDashboard() : const DriverDashboard();
  }
}

//////////////////////////
// DRIVER DASHBOARD
//////////////////////////
class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  IO.Socket? _socket;

  // Walkthrough keys
  final GlobalKey<ShowCaseWidgetState> _showcaseKey =
      GlobalKey<ShowCaseWidgetState>();
  final GlobalKey _startInspectionKey = GlobalKey();
  final GlobalKey _historyListKey = GlobalKey();
  final GlobalKey _drawerKey = GlobalKey();
  final GlobalKey _themeKey = GlobalKey();
  final GlobalKey _logoutKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeDashboard();

      if (!WalkthroughService.hasSeenDriverWalkthrough()) {
        _showcaseKey.currentState?.startShowCase([
          _startInspectionKey,
          _historyListKey,
          _drawerKey,
          _themeKey,
          _logoutKey,
        ]);
        await WalkthroughService.markDriverWalkthroughSeen();
      }
    });
  }

  Future<void> _initializeDashboard() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    await context.read<InspectionHistoryProvider>().refresh();
    _setupSocket(auth);
  }

  void _setupSocket(AuthProvider auth) {
    final driverId = auth.user?['id'];
    if (driverId == null) return;

    final socket = IO.io(
      ApiConfig.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      debugPrint('DEBUG: Driver socket connected');
      socket.emit('join_driver', {'id': driverId});
    });

    socket.on('inspection_created', (data) {
      final inspection = Map<String, dynamic>.from(data);
      if (inspection['driver']?['id'] == driverId) {
        debugPrint(
          'DEBUG: Socket inspection_created received: ${inspection['id']}',
        );
        context.read<InspectionHistoryProvider>().addInspection(inspection);
      }
    });

    socket.onDisconnect((_) => debugPrint('DEBUG: Driver socket disconnected'));
    socket.onError((data) => debugPrint('DEBUG: Driver socket error: $data'));

    _socket = socket;
  }

  @override
  void dispose() {
    _socket?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final org = auth.org;
    final historyProvider = context.watch<InspectionHistoryProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    // Filter out drafts before building the ListView
    final visibleInspections = historyProvider.history
        .where((item) => item['is_draft'] == false)
        .toList();

    return ShowCaseWidget(
      key: _showcaseKey,
      builder: (context) => Scaffold(
        drawer: DriverDrawerWidget(
          onResetWalkthrough: () {
            _showcaseKey.currentState?.startShowCase([
              _startInspectionKey,
              _historyListKey,
              _drawerKey,
              _themeKey,
              _logoutKey,
            ]);
            WalkthroughService.markDriverWalkthroughSeen();
          },
        ),

        appBar: AppBar(
          leading: Showcase(
            key: _drawerKey,
            description: 'Open the drawer to access additional options',
            child: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
          title: const Text('Driver Dashboard'),
          actions: [
            Showcase(
              key: _themeKey,
              description: 'Toggle light/dark mode here',
              child: IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
                onPressed: () =>
                    themeProvider.toggleTheme(!themeProvider.isDarkMode),
              ),
            ),
            Showcase(
              key: _logoutKey,
              description: 'Tap here to log out',
              child: IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await auth.logout();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      "Welcome, ${user['first_name']} ${user['last_name']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
              if (org != null)
                Center(
                  child: Text(
                    "Organization: ${org['name']}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Center(
                child: Showcase(
                  key: _startInspectionKey,
                  description: 'Tap here to start a new inspection!',
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
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Showcase(
                  key: _historyListKey,
                  description: 'Your inspection history appears here',
                  child: historyProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : historyProvider.error.isNotEmpty
                      ? Center(child: Text('Error: ${historyProvider.error}'))
                      : historyProvider.history.isEmpty
                      ? const Center(child: Text('No inspections yet.'))
                      : RefreshIndicator(
                          onRefresh: historyProvider.refresh,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: visibleInspections.length,
                            itemBuilder: (_, index) {
                              final item =
                                  visibleInspections[index]; // this is now guaranteed to be non-draft
                              final formattedDate = parseUtcToLocal(
                                item['updated_at'],
                              );
                              final driverName =
                                  item['driver']?['full_name'] ?? 'N/A';
                              final inspectionType = (item['type'] ?? 'N/A')
                                  .toUpperCase();

                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  title: Text(
                                    'Inspection #${item['id']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        builder: (_) => InspectionDetailScreen(
                                          inspectionId: item['id'],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//////////////////////////
// ADMIN DASHBOARD
//////////////////////////
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

  // Walkthrough keys
  final GlobalKey<ShowCaseWidgetState> _showcaseKey =
      GlobalKey<ShowCaseWidgetState>();
  final GlobalKey _drawerKey = GlobalKey();
  final GlobalKey _themeKey = GlobalKey();
  final GlobalKey _logoutKey = GlobalKey();
  final GlobalKey _inviteDriverKey = GlobalKey();
  final GlobalKey _viewInspectionsKey = GlobalKey();
  final GlobalKey _dismissUserKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeAdmin();
      if (!WalkthroughService.hasSeenAdminWalkthrough()) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        Scaffold.of(context).closeDrawer();
        // start showcase with delay
        await Future.delayed(const Duration(milliseconds: 250));
        _showcaseKey.currentState?.startShowCase([
          _drawerKey,
          _themeKey,
          _logoutKey,
          _inviteDriverKey,
          _viewInspectionsKey,
          _dismissUserKey,
        ]);
        await WalkthroughService.markAdminWalkthroughSeen();
      }
    });
  }

  Future<void> _initializeAdmin() async {
    final auth = context.read<AuthProvider>();
    if (auth.user?['org_id'] != null && auth.org == null) {
      auth.setOrg(auth.user?['org']);
    }
    await _fetchUsers(auth);
    _setupSocket(auth);
  }

  Future<void> _fetchUsers(AuthProvider auth) async {
    if (auth.org == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await OrganizationService.getAllUsers(auth.token!);
      users.sort((a, b) {
        if (a['role'] == 'admin' && b['role'] != 'admin') return -1;
        if (a['role'] != 'admin' && b['role'] == 'admin') return 1;
        return 0;
      });
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

  void _setupSocket(AuthProvider auth) {
    if (auth.org == null) return;

    final orgId = auth.org?['id'];
    if (orgId == null) return;

    final socket = IO.io(
      ApiConfig.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    socket.connect();
    socket.onConnect((_) {
      socket.emit('join_org', {'org_id': orgId});
    });

    socket.on('driver_joined', (data) {
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

    socket.on('driver_left', (data) {
      if (!mounted) return;
      final driverId = data['id'];
      if (driverId == null) return;
      setState(() {
        _users.removeWhere((u) => u['id'] == driverId);
      });
    });

    socket.on('user_updated', (data) {
      try {
        final id = data['id'];
        if (id == null) {
          return;
        }

        final index = _users.indexWhere((u) => u['id'] == id);
        if (index != -1) {
          final updatedUser = Map<String, dynamic>.from(_users[index]);
          updatedUser.addAll(data); // merge incoming data
          if (mounted) {
            setState(() {
              _users[index] = updatedUser;
            });
          }
        }
      } catch (e, st) {
        print('DEBUG: user_updated listener crash: $e\n$st');
      }
    });

    socket.onDisconnect((_) => debugPrint('DEBUG: Admin socket disconnected'));
    socket.onError((data) => debugPrint('DEBUG: Admin socket error: $data'));

    _socket = socket;
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
    final userHasOrg = auth.user?['org_id'] != null;

    if (auth.user == null || (auth.user?['org'] != null && auth.org == null)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!userHasOrg) {
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
                  MaterialPageRoute(
                    builder: (_) => const ManageOrganizationScreen(),
                  ),
                );
              },
              child: const Text('Create or Join Organization'),
            ),
          ],
        ),
      );
    }

    return ShowCaseWidget(
      key: _showcaseKey,
      builder: (context) => Scaffold(
        drawer: AdminDrawerWidget(
          onResetWalkthrough: () {
            _showcaseKey.currentState?.startShowCase([
              _drawerKey,
              _themeKey,
              _logoutKey,
              _inviteDriverKey,
              _viewInspectionsKey,
              _dismissUserKey,
            ]);
          },
        ),
        appBar: AppBar(
          leading: Showcase(
            key: _drawerKey,
            description: 'Open the drawer to manage your organization',
            child: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
          title: const Text('Admin Dashboard'),
          actions: [
            Showcase(
              key: _themeKey,
              description: 'Toggle light/dark mode here',
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) => IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  onPressed: () =>
                      themeProvider.toggleTheme(!themeProvider.isDarkMode),
                ),
              ),
            ),
            Showcase(
              key: _logoutKey,
              description: 'Tap here to log out',
              child: IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await auth.logout();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (org != null)
                Card(
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          org['name'] ?? 'Organization',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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
              InviteDriverWidget(showcaseKey: _inviteDriverKey),
              const SizedBox(height: 12),
              Showcase(
                key: _viewInspectionsKey,
                description: 'View all inspections for your organization',
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminInspectionsScreen(),
                      ),
                    );
                  },
                  child: const Text("View Inspections"),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final isAdmin = user['role'] == 'admin';
                    final card = _buildUserCard(context, user);

                    if (isAdmin) return card;

                    return Showcase(
                      key: _dismissUserKey,
                      description: "Swipe left to remove a driver",
                      disposeOnTap: true,
                      onTargetClick: () {},
                      child: Dismissible(
                        key: ValueKey(user['id']),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Remove driver?"),
                              content: Text(
                                "Are you sure you want to remove ${user['first_name']} ${user['last_name']} from your org?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text("Remove"),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) async {
                          final removedUser = _users[index];
                          try {
                            final auth = context.read<AuthProvider>();
                            await OrganizationService.removeDriver(
                              auth.token!,
                              removedUser['id'],
                            );
                            if (!mounted) return;
                            setState(
                              () => _users.removeWhere(
                                (u) => u['id'] == removedUser['id'],
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "${removedUser['first_name']} removed from org",
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Failed to remove ${removedUser['first_name']}: $e",
                                ),
                              ),
                            );
                          }
                        },
                        child: card,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildUserCard(BuildContext context, Map<String, dynamic> user) {
  final isAdmin = user['role'] == 'admin';
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  final cardColor = isAdmin
      ? (isDark ? Colors.amber.shade700 : Colors.amber.shade50)
      : theme.cardColor;

  final textColor = isAdmin
      ? (isDark ? Colors.black : Colors.black87)
      : theme.textTheme.bodyMedium?.color;

  return Card(
    color: cardColor,
    elevation: 2,
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: ListTile(
      leading: Icon(
        isAdmin ? Icons.admin_panel_settings : Icons.person,
        color: isAdmin
            ? (isDark ? Colors.black : Colors.amber)
            : theme.iconTheme.color,
      ),
      title: Text(
        '${user["first_name"]} ${user["last_name"]}${isAdmin ? " (Admin)" : ""}',
        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
      ),
      subtitle: Text(user["email"] ?? "", style: TextStyle(color: textColor)),
    ),
  );
}
