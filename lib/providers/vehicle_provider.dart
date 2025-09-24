import 'package:flutter/material.dart';

class VehicleProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _vehicles = [];
  Map<String, dynamic>? _selectedVehicle;

  List<Map<String, dynamic>> get vehicles => _vehicles;
  Map<String, dynamic>? get selectedVehicle => _selectedVehicle;

  void setVehicles(List<Map<String, dynamic>> vehicles) {
    _vehicles = vehicles;
    notifyListeners();
  }

  void selectVehicle(Map<String, dynamic> vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  void clearVehicles() {
    _vehicles = [];
    _selectedVehicle = null;
    notifyListeners();
  }
}
