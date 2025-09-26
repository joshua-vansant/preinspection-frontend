import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vehicle_provider.dart';
import '../services/vehicle_service.dart';
import 'template_selection_screen.dart';
import '../services/inspection_service.dart';

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

    // show loading dialog
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
      body: ListView.builder(
        itemCount: vehicles.length,
        itemBuilder: (_, index) {
          final vehicle = vehicles[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: ListTile(
              title: Text(
                "${vehicle['number']} (${vehicle['make'] ?? ''} ${vehicle['model'] ?? ''})",
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Year: ${vehicle['year'] ?? '-'}"),
                  if (vehicle['license_plate'] != null)
                    Text("Plate: ${vehicle['license_plate']}"),
                  if (vehicle['vin'] != null) Text("VIN: ${vehicle['vin']}"),
                  if (vehicle['mileage'] != null)
                    Text("Mileage: ${vehicle['mileage']}"),
                  Text("Status: ${vehicle['status'] ?? 'unknown'}"),
                ],
              ),
              onTap: () => selectVehicle(vehicle),
            ),
          );
        },
      ),
    );
  }
}
