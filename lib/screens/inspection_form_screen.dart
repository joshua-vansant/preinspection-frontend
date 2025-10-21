import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Inspection')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          controller: _scrollController,
          children: [
            ...items.map((item) {
              final idStr = item['id'].toString();
              final answer = answers[idStr] ?? 'no';
              final itemPhotos = inspectionPhotos
                  .where((p) =>
                      p['inspection_item_id']?.toString() == idStr &&
                      p['photo_url'] != null)
                  .toList();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
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
                        const SizedBox(height: 8),
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
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                      ),
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
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey[400]!,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add_a_photo,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
              onChanged: (val) => inspectionProvider.updateField('notes', val),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: startMileageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Start Mileage"),
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
                  onChanged: (val) =>
                      inspectionProvider.updateField('odometer_verified', val),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Fuel Level"),
                Slider(
                  value: (current['fuel_level'] ?? 0.0) as double,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label: "${((current['fuel_level'] ?? 0.0) * 100).round()}%",
                  onChanged: (val) =>
                      inspectionProvider.updateField('fuel_level', val),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitInspection,
              child: Text(
                widget.editMode ? "Update Inspection" : "Submit Inspection",
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
