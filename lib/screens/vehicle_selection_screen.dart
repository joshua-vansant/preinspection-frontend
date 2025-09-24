import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vehicle_provider.dart';
import '../services/vehicle_service.dart';
import 'template_selection_screen.dart';

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

  void selectVehicle(Map<String, dynamic> vehicle) {
    context.read<VehicleProvider>().selectVehicle(vehicle);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TemplateSelectionScreen()),
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
          return ListTile(
            title: Text(vehicle['number']),
            subtitle: Text(vehicle['id']?.toString() ?? ''),
            onTap: () => selectVehicle(vehicle),
          );
        },
      ),
    );
  }
}
