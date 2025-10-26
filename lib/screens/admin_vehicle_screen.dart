import 'package:flutter/material.dart';
import 'package:frontend/utils/ui_helpers.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vehicle_provider.dart';
import '../services/vehicle_service.dart';
import 'add_vehicle_screen.dart';

class AdminVehiclesScreen extends StatefulWidget {
  const AdminVehiclesScreen({super.key});

  @override
  _AdminVehiclesScreenState createState() => _AdminVehiclesScreenState();
}

class _AdminVehiclesScreenState extends State<AdminVehiclesScreen> {
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchVehicles();
  }

  Future<void> fetchVehicles() async {
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception("No token found");

      final vehicles = await VehicleService.getVehicles(token);
      context.read<VehicleProvider>().setVehicles(vehicles);

      setState(() => isLoading = false);
    } catch (e) {
      if (!mounted) return;
      UIHelpers.showError(context, e.toString());
      setState(() => isLoading = false);
    }
  }

  Future<void> editVehicle(Map<String, dynamic> vehicle) async {
    final updatedVehicle = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddVehicleScreen(existingVehicle: vehicle),
      ),
    );

    if (updatedVehicle != null) {
      final token = context.read<AuthProvider>().token!;
      await context.read<VehicleProvider>().updateVehicle(
        token,
        vehicle['id'],
        updatedVehicle,
      );
      fetchVehicles();
    }
  }

  Color _statusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return theme.disabledColor;
      case 'maintenance':
        return Colors.orange;
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicles = context.watch<VehicleProvider>().vehicles;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Manage Vehicles"),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withOpacity(0.05),
              colorScheme.secondary.withOpacity(0.03),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error.isNotEmpty
                    ? Center(child: Text(error))
                    : vehicles.isEmpty
                        ? _buildEmptyState(theme)
                        : RefreshIndicator(
                            onRefresh: fetchVehicles,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: vehicles.length,
                              itemBuilder: (_, index) {
                                final vehicle = vehicles[index];
                                final licensePlate =
                                    vehicle['license_plate'] ?? '';
                                final makeModel =
                                    "${vehicle['make'] ?? ''} ${vehicle['model'] ?? ''}"
                                        .trim();
                                final status =
                                    (vehicle['status'] ?? 'active').toString();

                                return Card(
                                  elevation: 3,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => editVehicle(vehicle),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          // Vehicle icon and status
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor: _statusColor(
                                                    status, theme)
                                                .withOpacity(0.1),
                                            child: Icon(
                                              Icons.directions_car_rounded,
                                              color: _statusColor(
                                                  status, theme),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          // Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  licensePlate.isNotEmpty
                                                      ? licensePlate
                                                      : 'Unknown Vehicle',
                                                  style: theme
                                                      .textTheme.titleMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (makeModel.isNotEmpty)
                                                  Text(
                                                    makeModel,
                                                    style: theme
                                                        .textTheme.bodySmall
                                                        ?.copyWith(
                                                      color: theme.textTheme
                                                          .bodySmall?.color
                                                          ?.withOpacity(0.8),
                                                    ),
                                                  ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "Status: ${status[0].toUpperCase()}${status.substring(1)}",
                                                  style: TextStyle(
                                                    color: _statusColor(
                                                        status, theme),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ),
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final org = authProvider.org;

          if (org == null || org["id"] == null) {
            return FloatingActionButton(
              onPressed: null,
              backgroundColor: Colors.grey,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
          }

          return FloatingActionButton.extended(
            onPressed: () async {
              final Map<String, dynamic>? newVehicle =
                  await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
              );

              if (newVehicle != null) {
                final token = authProvider.token;
                if (token != null) {
                  await context.read<VehicleProvider>().addVehicle(
                        token,
                        licensePlate: newVehicle["license_plate"],
                        number: newVehicle["number"],
                        make: newVehicle["make"],
                        model: newVehicle["model"],
                        year: newVehicle["year"],
                        vin: newVehicle["vin"],
                        mileage: newVehicle["mileage"],
                        status: newVehicle["status"],
                        orgId: org["id"],
                      );
                  fetchVehicles();
                }
              }
            },
            label: const Text("Add Vehicle"),
            icon: const Icon(Icons.add_rounded),
            backgroundColor: colorScheme.primary,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_filled_outlined,
                size: 80, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(
              "No vehicles found",
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.disabledColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Add a vehicle to start tracking inspections and status.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
