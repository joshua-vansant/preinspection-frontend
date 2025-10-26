import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/providers/inspection_provider.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vehicle_provider.dart';
import '../services/vehicle_service.dart';
import 'template_selection_screen.dart';
import '../services/inspection_service.dart';
import 'add_vehicle_screen.dart';
import 'package:frontend/utils/ui_helpers.dart';

class VehicleSelectionScreen extends StatefulWidget {
  const VehicleSelectionScreen({super.key});

  @override
  _VehicleSelectionScreenState createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
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
      UIHelpers.showError(context, "Failed to load vehicles: $e");
      setState(() {
        error = "Failed to load vehicles";
        isLoading = false;
      });
    }
  }

  Future<void> selectVehicle(Map<String, dynamic> vehicle) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      UIHelpers.showError(context, "Not authenticated");
      return;
    }

    HapticFeedback.mediumImpact();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateSelectionScreen(
          vehicle: vehicle,
          inspectionType: 'pre',
          lastInspection: null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicles = context.watch<VehicleProvider>().vehicles;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Select Vehicle"),
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error.isNotEmpty
                    ? Center(child: Text(error))
                    : vehicles.isEmpty
                        ? _buildEmptyState(context)
                        : RefreshIndicator(
                            onRefresh: fetchVehicles,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              itemCount: vehicles.length,
                              itemBuilder: (_, index) {
                                final vehicle = vehicles[index];
                                final licensePlate =
                                    vehicle['license_plate'] ?? 'Unknown';
                                final makeModel =
                                    "${vehicle['make'] ?? ''} ${vehicle['model'] ?? ''}"
                                        .trim();

                                return _buildVehicleCard(
                                  context,
                                  licensePlate: licensePlate,
                                  makeModel: makeModel,
                                  onTap: () => selectVehicle(vehicle),
                                );
                              },
                            ),
                          ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          HapticFeedback.mediumImpact();

          final Map<String, dynamic>? newVehicle =
              await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
          );

          if (newVehicle != null) {
            final token = context.read<AuthProvider>().token;
            if (token != null) {
              await context.read<VehicleProvider>().addVehicle(
                    token,
                    licensePlate: newVehicle["license_plate"],
                  );
              UIHelpers.showSuccess(context, "Vehicle added successfully!");
            }
          }
        },
        label: const Text("Add Vehicle"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildVehicleCard(
    BuildContext context, {
    required String licensePlate,
    required String makeModel,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        splashColor: theme.colorScheme.primary.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.directions_car_rounded,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      licensePlate,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (makeModel.isNotEmpty)
                      Text(
                        makeModel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.8),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_outlined,
              size: 72, color: Theme.of(context).disabledColor),
          const SizedBox(height: 12),
          Text(
            'No vehicles yet',
            style: TextStyle(color: Theme.of(context).disabledColor),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Add Vehicle"),
            onPressed: () async {
              HapticFeedback.lightImpact();
              final Map<String, dynamic>? newVehicle =
                  await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
              );

              if (newVehicle != null) {
                final token = context.read<AuthProvider>().token;
                if (token != null) {
                  await context.read<VehicleProvider>().addVehicle(
                        token,
                        licensePlate: newVehicle["license_plate"],
                      );
                  UIHelpers.showSuccess(context, "Vehicle added successfully!");
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
