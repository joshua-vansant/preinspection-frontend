import 'package:flutter/material.dart';

class AddVehicleScreen extends StatefulWidget {
  final Map<String, dynamic>? existingVehicle; // optional for editing

  const AddVehicleScreen({super.key, this.existingVehicle});

  @override
  _AddVehicleScreenState createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _vinController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _statusController = TextEditingController(text: 'active');

  @override
  void initState() {
    super.initState();
    final vehicle = widget.existingVehicle;
    if (vehicle != null) {
      _licensePlateController.text = vehicle['license_plate'] ?? '';
      _numberController.text = vehicle['number'] ?? '';
      _makeController.text = vehicle['make'] ?? '';
      _modelController.text = vehicle['model'] ?? '';
      _yearController.text = vehicle['year']?.toString() ?? '';
      _vinController.text = vehicle['vin'] ?? '';
      _mileageController.text = vehicle['mileage']?.toString() ?? '';
      _statusController.text = vehicle['status'] ?? 'active';
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _licensePlateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _vinController.dispose();
    _mileageController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final vehicleData = <String, dynamic>{
      'number': _numberController.text.isNotEmpty ? _numberController.text : null,
      'license_plate': _licensePlateController.text,
      'make': _makeController.text.isNotEmpty ? _makeController.text : null,
      'model': _modelController.text.isNotEmpty ? _modelController.text : null,
      'year': _yearController.text.isNotEmpty ? int.tryParse(_yearController.text) : null,
      'vin': _vinController.text.isNotEmpty ? _vinController.text : null,
      'mileage': _mileageController.text.isNotEmpty ? int.tryParse(_mileageController.text) : null,
      'status': _statusController.text.isNotEmpty ? _statusController.text : 'active',
    };

    Navigator.pop(context, vehicleData);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingVehicle != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? "Edit Vehicle" : "Add Vehicle")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _licensePlateController,
                decoration: const InputDecoration(labelText: 'License Plate *'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'License Plate is required';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(labelText: 'Vehicle Number'),
              ),
              TextFormField(
                controller: _makeController,
                decoration: const InputDecoration(labelText: 'Make'),
              ),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Model'),
              ),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Year'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _vinController,
                decoration: const InputDecoration(labelText: 'VIN'),
              ),
              TextFormField(
                controller: _mileageController,
                decoration: const InputDecoration(labelText: 'Mileage'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _statusController,
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: Text(isEditing ? 'Update Vehicle' : 'Save Vehicle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
