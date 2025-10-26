import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddVehicleScreen extends StatefulWidget {
  final Map<String, dynamic>? existingVehicle;

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
    HapticFeedback.mediumImpact();

    final vehicleData = <String, dynamic>{
      'number': _numberController.text.isNotEmpty ? _numberController.text : null,
      'license_plate': _licensePlateController.text,
      'make': _makeController.text.isNotEmpty ? _makeController.text : null,
      'model': _modelController.text.isNotEmpty ? _modelController.text : null,
      'year': _yearController.text.isNotEmpty
          ? int.tryParse(_yearController.text)
          : null,
      'vin': _vinController.text.isNotEmpty ? _vinController.text : null,
      'mileage': _mileageController.text.isNotEmpty
          ? int.tryParse(_mileageController.text)
          : null,
      'status': 'active',
    };

    Navigator.pop(context, vehicleData);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingVehicle != null;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(isEditing ? "Edit Vehicle" : "Add Vehicle"),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.secondary.withOpacity(0.03),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.directions_car_rounded,
                                size: 64,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Vehicle Details",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Required Field
                        TextFormField(
                          controller: _licensePlateController,
                          decoration: InputDecoration(
                            labelText: 'License Plate *',
                            filled: true,
                            fillColor:
                                theme.colorScheme.surfaceVariant.withOpacity(0.2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'License Plate is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        Text(
                          "Optional Information",
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),

                        _buildField(
                          controller: _numberController,
                          label: 'Vehicle Number',
                          theme: theme,
                        ),
                        _buildField(
                          controller: _makeController,
                          label: 'Make',
                          theme: theme,
                        ),
                        _buildField(
                          controller: _modelController,
                          label: 'Model',
                          theme: theme,
                        ),
                        _buildField(
                          controller: _yearController,
                          label: 'Year',
                          theme: theme,
                          keyboardType: TextInputType.number,
                        ),
                        _buildField(
                          controller: _vinController,
                          label: 'VIN',
                          theme: theme,
                        ),
                        _buildField(
                          controller: _mileageController,
                          label: 'Mileage',
                          theme: theme,
                          keyboardType: TextInputType.number,
                        ),

                        const SizedBox(height: 24),

                        ElevatedButton.icon(
                          onPressed: _submit,
                          icon: Icon(
                            isEditing ? Icons.save_outlined : Icons.add_rounded,
                            size: 22,
                          ),
                          label: Text(
                            isEditing ? 'Update Vehicle' : 'Save Vehicle',
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required ThemeData theme,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
