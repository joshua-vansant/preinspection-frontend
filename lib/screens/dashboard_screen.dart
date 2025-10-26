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
import 'package:flutter/services.dart';

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
      IO.OptionBuilder().setTransports(['websocket']).enableAutoConnect().build(),
    );

    socket.connect();

    socket.onConnect((_) {
      debugPrint('Driver socket connected');
      socket.emit('join_driver', {'id': driverId});
    });

    socket.on('inspection_created', (data) {
      final inspection = Map<String, dynamic>.from(data);
      if (inspection['driver']?['id'] == driverId) {
        context.read<InspectionHistoryProvider>().addInspection(inspection);
      }
    });

    socket.onDisconnect((_) => debugPrint('Driver socket disconnected'));
    socket.onError((data) => debugPrint('Driver socket error: $data'));
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
          centerTitle: true,
          title: const Text('Driver Dashboard'),
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
          actions: [
            Showcase(
              key: _themeKey,
              description: 'Toggle light/dark mode here',
              child: IconButton(
                icon: Icon(
                  themeProvider.isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  themeProvider.toggleTheme(!themeProvider.isDarkMode);
                },
              ),
            ),
            Showcase(
              key: _logoutKey,
              description: 'Tap here to log out',
              child: IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await auth.logout();
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.05),
                Theme.of(context).colorScheme.secondary.withOpacity(0.03),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    children: [
                      Icon(Icons.directions_car_filled,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 6),
                      if (user != null)
                        Text(
                          "Welcome, ${user['first_name']} ${user['last_name']}",
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      if (org != null)
                        Text(
                          org['name'],
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                    ],
                  ),
                ),

                // Start New Inspection button
                Showcase(
                  key: _startInspectionKey,
                  description: 'Tap here to start a new inspection!',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text("Start New Inspection"),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VehicleSelectionScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Inspection history list
                Expanded(
                  child: Showcase(
                    key: _historyListKey,
                    description: 'Your inspection history appears here',
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: historyProvider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : historyProvider.error.isNotEmpty
                              ? Center(
                                  child: Text('Error: ${historyProvider.error}'),
                                )
                              : visibleInspections.isEmpty
                                  ? _buildEmptyState(context)
                                  : RefreshIndicator(
                                      onRefresh: historyProvider.refresh,
                                      child: ListView.builder(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        itemCount: visibleInspections.length,
                                        itemBuilder: (_, index) {
                                          final item =
                                              visibleInspections[index];
                                          final formattedDate =
                                              item['updated_at'] != null
                                                  ? parseUtcToLocal(
                                                      item['updated_at'])
                                                  : 'Unknown';
                                          final driverName = item['driver']
                                                  ?['full_name'] ??
                                              'N/A';
                                          final inspectionType =
                                              (item['type']
                                                      ?.toString()
                                                      .toUpperCase()) ??
                                                  'N/A';

                                          return _buildInspectionCard(
                                            context,
                                            id: item['id'],
                                            type: inspectionType,
                                            driverName: driverName,
                                            date: formattedDate,
                                          );
                                        },
                                      ),
                                    ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInspectionCard(
    BuildContext context, {
    required int id,
    required String type,
    required String driverName,
    required String date,
  }) {
    final isPreTrip = type == 'PRE';
    final color = isPreTrip
        ? Colors.green.shade100
        : Theme.of(context).colorScheme.primaryContainer;
    final iconColor = isPreTrip
        ? Colors.green.shade800
        : Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(
            isPreTrip ? Icons.check_circle_outline : Icons.assignment_outlined,
            color: iconColor,
          ),
        ),
        title: Text(
          'Inspection #$id',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Driver: $driverName'),
            Text('Date: $date'),
          ],
        ),
        trailing: Text(
          type,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: iconColor,
          ),
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InspectionDetailScreen(inspectionId: id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 72, color: Theme.of(context).disabledColor),
          const SizedBox(height: 12),
          Text(
            'No inspections yet',
            style: TextStyle(color: Theme.of(context).disabledColor),
          ),
        ],
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
      IO.OptionBuilder().setTransports(['websocket']).enableAutoConnect().build(),
    );

    socket.connect();
    socket.onConnect((_) => socket.emit('join_org', {'org_id': orgId}));

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
      setState(() => _users.removeWhere((u) => u['id'] == driverId));
    });

    socket.on('user_updated', (data) {
      try {
        final id = data['id'];
        if (id == null) return;
        final index = _users.indexWhere((u) => u['id'] == id);
        if (index != -1) {
          final updatedUser = Map<String, dynamic>.from(_users[index]);
          updatedUser.addAll(data);
          if (mounted) {
            setState(() => _users[index] = updatedUser);
          }
        }
      } catch (e, st) {
        debugPrint('user_updated listener crash: $e\n$st');
      }
    });

    socket.onDisconnect((_) => debugPrint('Admin socket disconnected'));
    socket.onError((data) => debugPrint('Admin socket error: $data'));

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
    final theme = Theme.of(context);

    if (auth.user == null || (auth.user?['org'] != null && auth.org == null)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!userHasOrg) {
      return Scaffold(
        body: _buildEmptyOrgState(context),
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
          centerTitle: true,
          title: const Text('Admin Dashboard'),
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
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    themeProvider.toggleTheme(!themeProvider.isDarkMode);
                  },
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
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.05),
                theme.colorScheme.secondary.withOpacity(0.03),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, org),
                const SizedBox(height: 8),
                InviteDriverWidget(showcaseKey: _inviteDriverKey),
                const SizedBox(height: 12),
                Showcase(
                  key: _viewInspectionsKey,
                  description: 'View all inspections for your organization',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.assignment_turned_in_outlined),
                        label: const Text("View Inspections"),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminInspectionsScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _users.isEmpty
                            ? _buildEmptyUsers(context)
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: _users.length,
                                itemBuilder: (context, index) {
                                  final user = _users[index];
                                  final isAdmin = user['role'] == 'admin';
                                  final card = _buildUserCard(context, user);

                                  if (isAdmin) return card;

                                  return Showcase(
                                    key: _dismissUserKey,
                                    description:
                                        "Swipe left to remove a driver",
                                    disposeOnTap: true,
                                    onTargetClick: () {},
                                    child: Dismissible(
                                      key: ValueKey(user['id']),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        color: Colors.red,
                                        child: const Icon(Icons.delete,
                                            color: Colors.white),
                                      ),
                                      confirmDismiss: (_) async {
                                        return await showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title:
                                                const Text("Remove driver?"),
                                            content: Text(
                                              "Are you sure you want to remove ${user['first_name']} ${user['last_name']} from your org?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false),
                                                child: const Text("Cancel"),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(true),
                                                child: const Text("Remove"),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      onDismissed: (_) =>
                                          _removeUser(context, user),
                                      child: card,
                                    ),
                                  );
                                },
                              ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic>? org) {
    if (org == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Icon(Icons.business_center_outlined,
              size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            org['name'] ?? 'Organization',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (org['address']?.isNotEmpty ?? false)
            Text(org['address'],
                style: Theme.of(context).textTheme.bodyMedium),
          if (org['contact_name']?.isNotEmpty ?? false)
            Text('Contact: ${org['contact_name']}',
                style: Theme.of(context).textTheme.bodyMedium),
          if (org['phone_number']?.isNotEmpty ?? false)
            Text('Phone: ${org['phone_number']}',
                style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user) {
    final isAdmin = user['role'] == 'admin';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isAdmin
        ? (isDark ? Colors.amber.shade700 : Colors.amber.shade50)
        : theme.colorScheme.surfaceVariant;
    final textColor = isAdmin
        ? (isDark ? Colors.black : Colors.black87)
        : theme.textTheme.bodyMedium?.color;

    return Card(
      color: cardColor,
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          isAdmin ? Icons.admin_panel_settings : Icons.person,
          color: isAdmin
              ? (isDark ? Colors.black : Colors.amber)
              : theme.colorScheme.primary,
        ),
        title: Text(
          '${user["first_name"]} ${user["last_name"]}${isAdmin ? " (Admin)" : ""}',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        subtitle: Text(
          user["email"] ?? "",
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }

  Widget _buildEmptyUsers(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline,
              size: 72, color: Theme.of(context).disabledColor),
          const SizedBox(height: 12),
          Text(
            'No drivers yet',
            style: TextStyle(color: Theme.of(context).disabledColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrgState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.apartment_outlined,
              size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
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

  Future<void> _removeUser(BuildContext context, Map<String, dynamic> user) async {
    final removedUser = user;
    try {
      final auth = context.read<AuthProvider>();
      await OrganizationService.removeDriver(auth.token!, removedUser['id']);
      if (!mounted) return;
      setState(() => _users.removeWhere((u) => u['id'] == removedUser['id']));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${removedUser['first_name']} removed from org")),
      );
      HapticFeedback.lightImpact();
    } catch (e) {
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to remove ${removedUser['first_name']}: $e")),
      );
    }
  }
}