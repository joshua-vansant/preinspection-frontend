import 'package:flutter/material.dart';
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
      setState(() {
        error = 'Failed to load vehicles: $e';
        isLoading = false;
      });
    }
  }

  Future<void> editVehicle(Map<String, dynamic> vehicle) async {
    // Navigate to the same AddVehicleScreen but pre-fill with vehicle data
    final updatedVehicle = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddVehicleScreen(existingVehicle: vehicle),
      ),
    );

    if (updatedVehicle != null) {
      final token = context.read<AuthProvider>().token!;
      await context.read<VehicleProvider>().updateVehicle(token, vehicle['id'], updatedVehicle);
      fetchVehicles(); // Refresh list
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = context.watch<VehicleProvider>().vehicles;

    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error.isNotEmpty) return Center(child: Text(error));

    return Scaffold(
      appBar: AppBar(title: const Text("Manage Vehicles")),
      body: vehicles.isEmpty
          ? const Center(child: Text("No vehicles yet. Add one to continue."))
          : ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (_, index) {
                final vehicle = vehicles[index];
                final licensePlate = vehicle['license_plate'] ?? '';
                final makeModel =
                    "${vehicle['make'] ?? ''} ${vehicle['model'] ?? ''}".trim();

                return Card(
                  child: ListTile(
                    title: Text("$licensePlate ${makeModel.isNotEmpty ? '($makeModel)' : ''}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => editVehicle(vehicle),
                    ),
                  ),
                );
              },
            ),
  floatingActionButton: Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    final org = authProvider.org;

    // If org not loaded yet → show disabled button with spinner
    if (org == null || org["id"] == null) {
      return FloatingActionButton(
        onPressed: null, // disabled
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

    // Otherwise show normal button
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
              orgId: org["id"], // pass admin’s org_id safely
            );
          }
        }
      },
      child: const Icon(Icons.add),
    );
  },
),


    );
  }
}
