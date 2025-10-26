import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/walkthrough_service.dart';
import 'package:frontend/widgets/camera_screen_widget.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/inspection_provider.dart';
import '../utils/ui_helpers.dart';
import 'dashboard_screen.dart';

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
  final ScrollController _scrollController = ScrollController();
  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    notesController.text = widget.inspection['notes'] ?? '';
    fuelNotesController.text = widget.inspection['fuel_notes'] ?? '';
    startMileageController = TextEditingController(
      text: widget.inspection['start_mileage']?.toString() ?? '',
    );

    _initCameras();
    Future.microtask(() => _initInspection());
  }

  Future<void> _initInspection() async {
    final inspectionProvider = context.read<InspectionProvider>();
    final isEdit = widget.editMode && widget.inspection.containsKey('id');

    if (isEdit) {
      await inspectionProvider.startInspection(
        vehicleId: widget.inspection['vehicle_id'],
        type: widget.inspection['type'] ?? 'pre-trip',
        initialData: widget.inspection,
        template: widget.inspection['template'],
      );
    } else {
      await inspectionProvider.startInspection(
        vehicleId: widget.vehicleId!,
        type: widget.inspectionType ?? 'pre-trip',
        templateId: widget.inspection['template_id'],
        template: widget.inspection,
      );
    }
  }

  Future<void> _initCameras() async {
    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      setState(() {
        _cameras = cameras;
      });
    } catch (e) {
      debugPrint('⚠️ Failed to get cameras: $e');
    }
  }

  Future<void> _pickAndUploadPhoto({required String inspectionItemId}) async {
    if (_cameras.isEmpty) {
      UIHelpers.showError(context, "No camera found on this device");
      return;
    }

    final file = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScreen(cameras: _cameras, onPictureTaken: (file) {}),
      ),
    );

    if (file == null) return;

    final itemId = int.tryParse(inspectionItemId);
    if (itemId == null) {
      UIHelpers.showError(context, "Invalid inspection item ID");
      return;
    }

    try {
      final inspectionProvider = context.read<InspectionProvider>();
      await inspectionProvider.uploadPhoto(file, inspectionItemId: itemId);

      if (!mounted) return;

      if (inspectionProvider.error.isEmpty) {
        UIHelpers.showSuccess(context, "Photo uploaded successfully");
      } else {
        UIHelpers.showError(context, inspectionProvider.error);
      }
    } catch (e, st) {
      debugPrint('⚠️ Error during upload: $e\n$st');
      if (mounted) UIHelpers.showError(context, e.toString());
    }
  }

  Future<void> _submitInspection() async {
    final inspectionProvider = context.read<InspectionProvider>();

    inspectionProvider.updateField(
      'start_mileage',
      int.tryParse(startMileageController.text),
    );
    inspectionProvider.updateField('notes', notesController.text.trim());
    inspectionProvider.updateField(
      'fuel_notes',
      fuelNotesController.text.trim(),
    );

    final success = widget.editMode && widget.inspection.containsKey('id')
        ? await inspectionProvider.updateInspection(widget.inspection['id'])
        : await inspectionProvider.submitInspection();

    if (!mounted) return;

    if (success) {
      UIHelpers.showSuccess(
        context,
        widget.editMode ? "Inspection updated" : "Inspection submitted",
      );
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
  void dispose() {
    notesController.dispose();
    fuelNotesController.dispose();
    startMileageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inspectionProvider = Provider.of<InspectionProvider>(context);
    final current = inspectionProvider.currentInspection;
    final answers = current['results'] ?? {};
    final items = current['template_items'] ?? [];
    final inspectionPhotos = inspectionProvider.inspectionPhotos;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.editMode ? 'Edit Inspection' : 'Vehicle Inspection'),
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
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              ...items.map((item) {
                final idStr = item['id'].toString();
                final answer = answers[idStr] ?? 'no';
                final itemPhotos = inspectionPhotos
                    .where((p) =>
                        p['inspection_item_id']?.toString() == idStr &&
                        p['photo_url'] != null)
                    .toList();

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] ?? '',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['question'] ?? '',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: answer == "yes",
                              onChanged: (val) {
                                HapticFeedback.selectionClick();
                                final updatedResults =
                                    Map<String, String>.from(answers);
                                updatedResults[idStr] = val ? "yes" : "no";
                                inspectionProvider.updateField(
                                  'results',
                                  updatedResults,
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...itemPhotos.map((photo) {
                              final url = photo['photo_url'] ?? '';
                              return url.isEmpty
                                  ? Container(
                                      width: 80,
                                      height: 80,
                                      color: theme.dividerColor.withOpacity(0.2),
                                      child: const Icon(Icons.broken_image),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        url,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                            }),
                            GestureDetector(
                              onTap: () =>
                                  _pickAndUploadPhoto(inspectionItemId: idStr),
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceVariant
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.colorScheme.outline
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Icon(
                                  Icons.add_a_photo_rounded,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              _buildTextField(
                context,
                controller: notesController,
                label: "Additional Notes",
                maxLines: 4,
                icon: Icons.note_alt_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                context,
                controller: startMileageController,
                label: "Start Mileage",
                keyboardType: TextInputType.number,
                icon: Icons.speed_rounded,
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
              const SizedBox(height: 12),
              Text(
                "Fuel Level",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              Slider(
                value: (current['fuel_level'] ?? 0.0) as double,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label:
                    "${((current['fuel_level'] ?? 0.0) * 100).round()}%",
                onChanged: (val) =>
                    inspectionProvider.updateField('fuel_level', val),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _submitInspection,
                icon: Icon(widget.editMode
                    ? Icons.save_alt_rounded
                    : Icons.check_circle_outline),
                label: Text(
                  widget.editMode
                      ? "Update Inspection"
                      : "Submit Inspection",
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
