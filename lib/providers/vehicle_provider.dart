import 'package:flutter/material.dart';
import '../services/vehicle_service.dart';
import '../utils/ui_helpers.dart';

class VehicleProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _vehicles = [];
  Map<String, dynamic>? _selectedVehicle;

  List<Map<String, dynamic>> get vehicles => _vehicles;
  Map<String, dynamic>? get selectedVehicle => _selectedVehicle;

  // Replace the current vehicle list
  void setVehicles(List<Map<String, dynamic>> vehicles) {
    _vehicles = vehicles;
    notifyListeners();
  }

  // Select a vehicle
  void selectVehicle(Map<String, dynamic> vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  // Clear all vehicles
  void clearVehicles() {
    _vehicles = [];
    _selectedVehicle = null;
    notifyListeners();
  }

  // Fetch vehicles from the backend and update provider
  Future<void> fetchVehicles(String token, {BuildContext? context}) async {
    try {
      final result = await VehicleService.getVehicles(token);

      // Fetch last inspection for each vehicle
      final List<Map<String, dynamic>>
      vehiclesWithInspections = await Future.wait(
        result.map((vehicle) async {
          try {
            final lastInspection =
                await VehicleService.getLastInspectionForVehicle(
                  token,
                  vehicle['id'],
                );
            return {...vehicle, 'lastInspection': lastInspection};
          } catch (e) {
            debugPrint(
              "DEBUG: Failed to fetch last inspection for vehicle ${vehicle['id']}: $e",
            );
            return {...vehicle, 'lastInspection': null};
          }
        }),
      );

      _vehicles = vehiclesWithInspections;
      notifyListeners();
    } catch (e) {
      final errorMessage = UIHelpers.parseError(e.toString());
      if (context != null) UIHelpers.showError(context, errorMessage);
      debugPrint("DEBUG: VehicleProvider fetchVehicles error: $errorMessage");
    }
  }

  // Add a new vehicle
  Future<void> addVehicle(
    String token, {
    required String licensePlate,
    String? number,
    String? make,
    String? model,
    int? year,
    String? vin,
    int? mileage,
    String? status,
    int? orgId,
    BuildContext? context,
  }) async {
    try {
      final vehicle = await VehicleService.addVehicle(
        token: token,
        licensePlate: licensePlate,
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
    } catch (e) {
      final errorMessage = UIHelpers.parseError(e.toString());
      if (context != null) UIHelpers.showError(context, errorMessage);
      debugPrint("DEBUG: VehicleProvider addVehicle error: $errorMessage");
    }
  }

  // Update an existing vehicle
  Future<void> updateVehicle(
    String token,
    int vehicleId,
    Map<String, dynamic> updatedData, {
    BuildContext? context,
  }) async {
    try {
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
    } catch (e) {
      final errorMessage = UIHelpers.parseError(e.toString());
      if (context != null) UIHelpers.showError(context, errorMessage);
      debugPrint("DEBUG: VehicleProvider updateVehicle error: $errorMessage");
    }
  }

  // Delete a vehicle
  Future<void> deleteVehicle(
    String token,
    int vehicleId, {
    BuildContext? context,
  }) async {
    try {
      await VehicleService.deleteVehicle(token, vehicleId);
      _vehicles.removeWhere((v) => v['id'] == vehicleId);
      if (_selectedVehicle?['id'] == vehicleId) _selectedVehicle = null;
      notifyListeners();
    } catch (e) {
      final errorMessage = UIHelpers.parseError(e.toString());
      if (context != null) UIHelpers.showError(context, errorMessage);
      debugPrint("DEBUG: VehicleProvider deleteVehicle error: $errorMessage");
    }
  }

  // Returns all vehicles within the org
  List<Map<String, dynamic>> vehiclesForOrg(int orgId) {
    return _vehicles.where((v) => v['org_id'] == orgId).toList();
  }
}
