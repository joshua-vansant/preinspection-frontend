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

  /// Called when user picks a vehicle.
  /// Fetches last inspection, decides pre/post, then navigates to template screen.
  Future<void> selectVehicle(Map<String, dynamic> vehicle) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not authenticated')));
      return;
    }

    // show a blocking progress dialog while we fetch last inspection
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    Map<String, dynamic>? lastInspection;
    try {
      lastInspection = await InspectionService.getLastInspection(token, vehicle['id']);
    } catch (e) {
      // log, but allow continuing — default to no previous inspection
      debugPrint('Failed to fetch last inspection: $e');
    } finally {
      Navigator.of(context).pop(); // close progress dialog
    }

    // compute the opposite inspection type:
    final computedType = (lastInspection == null)
        ? 'pre'
        : ((lastInspection['type'] == 'pre') ? 'post' : 'pre');

    // set selected vehicle in provider (optional but useful)
    context.read<VehicleProvider>().selectVehicle(vehicle);

    // navigate to template selection, passing vehicle + inspection metadata
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
