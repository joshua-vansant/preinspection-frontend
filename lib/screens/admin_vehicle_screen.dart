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
      if(!mounted) return;
      UIHelpers.showError(context, e.toString());
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = context.watch<VehicleProvider>().vehicles;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Vehicles"),
        backgroundColor: Colors.blue.shade600,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(child: Text(error))
          : vehicles.isEmpty
          ? const Center(
              child: Text(
                "No vehicles yet. Add one to continue.",
                style: TextStyle(fontSize: 16),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView.builder(
                itemCount: vehicles.length,
                itemBuilder: (_, index) {
                  final vehicle = vehicles[index];
                  final licensePlate = vehicle['license_plate'] ?? '';
                  final makeModel =
                      "${vehicle['make'] ?? ''} ${vehicle['model'] ?? ''}"
                          .trim();
                  final status = (vehicle['status'] ?? 'active').toString();

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          // Status indicator
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _statusColor(status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Vehicle info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$licensePlate${makeModel.isNotEmpty ? ' ($makeModel)' : ''}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Status: ${status[0].toUpperCase()}${status.substring(1)}",
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Edit button
                          IconButton(
                            icon: const Icon(Icons.edit),
                            color: Colors.blue.shade700,
                            onPressed: () => editVehicle(vehicle),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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

          return FloatingActionButton(
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
            backgroundColor: Colors.blue.shade600,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
