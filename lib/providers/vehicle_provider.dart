import 'package:flutter/material.dart';
import '../services/vehicle_service.dart';

class VehicleProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _vehicles = [];
  Map<String, dynamic>? _selectedVehicle;

  List<Map<String, dynamic>> get vehicles => _vehicles;
  Map<String, dynamic>? get selectedVehicle => _selectedVehicle;

  /// Replace the current vehicle list
  void setVehicles(List<Map<String, dynamic>> vehicles) {
    _vehicles = vehicles;
    notifyListeners();
  }

  /// Select a vehicle
  void selectVehicle(Map<String, dynamic> vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  /// Clear all vehicles
  void clearVehicles() {
    _vehicles = [];
    _selectedVehicle = null;
    notifyListeners();
  }

  /// Fetch vehicles from the backend and update provider
  Future<void> fetchVehicles(String token) async {
    try {
      final result = await VehicleService.getVehicles(token);
      _vehicles = result;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

Future<void> addVehicle(
  String token,
  {required String licensePlate, // ← required
   String? number,
   String? make,
   String? model,
   int? year,
   String? vin,
   int? mileage,
   String? status,
   int? orgId,}
) async {
  final vehicle = await VehicleService.addVehicle(
    token: token,
    licensePlate: licensePlate, // always pass
    number: number,
    make: make,
    model: model,
    year: year,
    vin: vin,
    mileage: mileage,
    status: status,
    orgId: orgId,
  );

  _vehicles.add(vehicle);
  notifyListeners();
}


  /// Update an existing vehicle
  Future<void> updateVehicle(
    String token,
    int vehicleId,
    Map<String, dynamic> updatedData,
  ) async {
    final updatedVehicle = await VehicleService.updateVehicle(
      token: token,
      vehicleId: vehicleId,
      number: updatedData['number'],
      make: updatedData['make'],
      model: updatedData['model'],
      year: updatedData['year'],
      vin: updatedData['vin'],
      licensePlate: updatedData['license_plate'],
      mileage: updatedData['mileage'],
      status: updatedData['status'],
      orgId: updatedData['org_id'],
    );
    final index = _vehicles.indexWhere((v) => v['id'] == vehicleId);
    if (index != -1) _vehicles[index] = updatedVehicle;
    notifyListeners();
  }

  /// Delete a vehicle
  Future<void> deleteVehicle(String token, int vehicleId) async {
    await VehicleService.deleteVehicle(token, vehicleId);
    _vehicles.removeWhere((v) => v['id'] == vehicleId);
    if (_selectedVehicle?['id'] == vehicleId) _selectedVehicle = null;
    notifyListeners();
  }
}
