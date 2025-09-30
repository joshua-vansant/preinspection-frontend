import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vehicle_provider.dart';
import '../services/vehicle_service.dart';
import 'template_selection_screen.dart';
import '../services/inspection_service.dart';
import 'add_vehicle_screen.dart';

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
      setState(() {
        error = 'Failed to load vehicles: $e';
        isLoading = false;
      });
    }
  }

  Future<void> selectVehicle(Map<String, dynamic> vehicle) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not authenticated')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    Map<String, dynamic>? lastInspection;
    try {
      lastInspection = await InspectionService.getLastInspection(
        token,
        vehicle['id'],
      );
    } catch (e) {
      debugPrint('Failed to fetch last inspection: $e');
    } finally {
      Navigator.of(context).pop();
    }

    final computedType = (lastInspection == null)
        ? 'pre'
        : (lastInspection['type'] == 'pre' ? 'post' : 'pre');

    context.read<VehicleProvider>().selectVehicle(vehicle);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateSelectionScreen(
          vehicle: vehicle,
          inspectionType: computedType,
          lastInspection: lastInspection,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = context.watch<VehicleProvider>().vehicles;

    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error.isNotEmpty) return Center(child: Text(error));

    return Scaffold(
      appBar: AppBar(title: const Text("Select Vehicle")),
      body: vehicles.isEmpty
          ? const Center(
              child: Text(
                "No vehicles yet. Add one to continue.",
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: vehicles.length,
              itemBuilder: (_, index) {
                final vehicle = vehicles[index];
                final licensePlate = vehicle['license_plate'] ?? '';
                final makeModel =
                    "${vehicle['make'] ?? ''} ${vehicle['model'] ?? ''}".trim();

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const Icon(
                      Icons.directions_car,
                      color: Colors.blue,
                      size: 36,
                    ),
                    title: Text(
                      licensePlate,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      makeModel,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => selectVehicle(vehicle),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
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
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
