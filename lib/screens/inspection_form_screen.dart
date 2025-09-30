import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/inspection_provider.dart';
import 'dashboard_screen.dart';
import 'package:frontend/services/inspection_service.dart';
import '../utils/ui_helpers.dart';

class InspectionFormScreen extends StatefulWidget {
  final Map<String, dynamic> inspection;
  final bool editMode;
  final int? vehicleId;
  final String? inspectionType;

  const InspectionFormScreen({
    super.key,
    required this.inspection,
    this.editMode = false,
    this.vehicleId,
    this.inspectionType,
  });

  @override
  State<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends State<InspectionFormScreen> {
  final TextEditingController notesController = TextEditingController();
  final TextEditingController fuelNotesController = TextEditingController();
  late TextEditingController startMileageController;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    notesController.text = widget.inspection['notes'] ?? '';
    fuelNotesController.text = widget.inspection['fuel_notes'] ?? '';
    startMileageController = TextEditingController(
      text: widget.inspection['start_mileage']?.toString() ?? '',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final inspectionProvider = context.read<InspectionProvider>();
      final isEdit = widget.editMode && widget.inspection.containsKey('id');

      if (isEdit) {
        // Editing existing inspection
        inspectionProvider.startInspection(
          vehicleId: widget.inspection['vehicle_id'],
          type: widget.inspection['type'] ?? 'pre-trip',
          initialData: widget.inspection,
          template: widget.inspection['template'],
        );
      } else {
        // New inspection
        inspectionProvider.startInspection(
          vehicleId: widget.vehicleId!,
          type: widget.inspectionType ?? 'pre-trip',
          template: widget.inspection,
        );
      }

      // Sync controllers with currentInspection
      final current = inspectionProvider.currentInspection;
      startMileageController.text = current['start_mileage']?.toString() ?? '';
    });
  }


  /// Submit inspection with validation
  Future<void> _submitInspection() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final inspectionProvider = context.read<InspectionProvider>();

    // Validate required mileage
    final startMileage = int.tryParse(startMileageController.text);

    inspectionProvider.updateField('start_mileage', startMileage);
    inspectionProvider.updateField('notes', notesController.text.trim());
    inspectionProvider.updateField('fuel_notes', fuelNotesController.text.trim(),
    );

    final success = widget.editMode && widget.inspection.containsKey('id')
        ? await inspectionProvider.updateInspection(
            token,
            widget.inspection['id'],
          )
        : await inspectionProvider.submitInspection(token);

    if (!mounted) return;

    if (success) {
      UIHelpers.showSuccess(context, widget.editMode ? "Inspection updated" : "Inspection submitted");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } else {
      UIHelpers.showError(context, inspectionProvider.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InspectionProvider>(
      builder: (_, inspectionProvider, __) {
        final current = inspectionProvider.currentInspection;
        final templateItems = current['template_items'] as List<dynamic>? ?? [];
        final answers = current['results'] ?? {};

        return Scaffold(
          appBar: AppBar(
            title: Text("Inspection: ${current['template_name'] ?? 'Unknown'}"),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                ...templateItems.map((item) {
                  final idStr = item['id'].toString();
                  final answer = answers[idStr] ?? 'no';
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(item['question'] ?? ''),
                              ],
                            ),
                          ),
                          Switch(
                            value: answer == "yes",
                            onChanged: (val) {
                              final updatedResults = <String, String>{
                                ...answers,
                              };
                              updatedResults[idStr] = val ? "yes" : "no";
                              inspectionProvider.updateField(
                                'results',
                                updatedResults,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: "Additional Notes",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Start Mileage"),
                  controller: startMileageController,
                  onChanged: (val) => inspectionProvider.updateField(
                    'start_mileage',
                    int.tryParse(val),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("Odometer Verified"),
                    Checkbox(
                      value: current['odometer_verified'] ?? false,
                      onChanged: (val) => inspectionProvider.updateField(
                        'odometer_verified',
                        val,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Fuel Level: ${(current['fuel_level'] ?? 0).round()}%"),
                Slider(
                  value: (current['fuel_level'] ?? 0).toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: "${(current['fuel_level'] ?? 0).round()}%",
                  onChanged: (val) =>
                      inspectionProvider.updateField('fuel_level', val),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: fuelNotesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Fuel Notes",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: inspectionProvider.isSubmitting
                ? null
                : _submitInspection,
            tooltip: "Submit Inspection",
            child: inspectionProvider.isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check),
          ),
        );
      },
    );
  }
}
