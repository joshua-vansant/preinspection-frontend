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
      'status': 'active',
    };

    Navigator.pop(context, vehicleData);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingVehicle != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? "Edit Vehicle" : "Add Vehicle")),
      body: SafeArea(
        child: Container(
        color: Colors.grey[100],
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Vehicle Details",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _licensePlateController,
                        decoration: const InputDecoration(
                          labelText: 'License Plate *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'License Plate is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Optional Info",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _numberController,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _makeController,
                        decoration: const InputDecoration(
                          labelText: 'Make',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                          labelText: 'Model',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _yearController,
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _vinController,
                        decoration: const InputDecoration(
                          labelText: 'VIN',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _mileageController,
                        decoration: const InputDecoration(
                          labelText: 'Mileage',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            backgroundColor: Colors.blue.shade600,
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          child: Text(isEditing ? 'Update Vehicle' : 'Save Vehicle'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

