import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/inspection_service.dart';
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
  late Map<String, bool> answers;
  final notesController = TextEditingController();
  bool isSubmitting = false;

  late Map<String, dynamic> template;
  late List<dynamic> items;
  late Map<String, dynamic> results;
  late String? vehicleId;
  late String inspectionType;

  @override
  void initState() {
    super.initState();

    // Determine if editing or new
    if (widget.inspection.containsKey('template')) {
      // Editing an existing inspection
      template = widget.inspection['template'] ?? {};
      results = widget.inspection['results'] ?? {};
      vehicleId = widget.inspection['vehicle_id']?.toString();
      inspectionType = widget.inspection['type'] ?? 'pre'; // fallback if missing
      notesController.text = widget.inspection['notes'] ?? '';
    } else {
      // Creating a new inspection
      template = widget.inspection;
      results = {};
      vehicleId = template['vehicle_id']?.toString();
      inspectionType = 'pre'; // default type for new inspections
    }

    items = template['items'] as List<dynamic>? ?? [];

    // Initialize all answers to false
    answers = {for (var item in items) item['id'].toString(): false};

    // Prefill answers if editing
    if (widget.editMode && results.isNotEmpty) {
      for (var item in items) {
        final idStr = item['id'].toString();
        if (results.containsKey(idStr)) {
          answers[idStr] = results[idStr] == "yes";
        }
      }
    }

    // print("Template items: $items");
    // print("Prefill results: $results");
    // print("VehicleId: $vehicleId, Type: $inspectionType");
  }

Future<void> _submitInspection() async {
  final authProvider = context.read<AuthProvider>();
  final isEdit = widget.editMode && widget.inspection.containsKey('id');

  // Determine the correct vehicle ID and inspection type
  final int? vehicleId = isEdit
      ? widget.inspection['vehicle_id'] as int?
      : widget.vehicleId;
  final String? inspectionType = isEdit
      ? widget.inspection['type'] as String?
      : widget.inspectionType;

  // For new inspections, these are required
  if (!isEdit && (vehicleId == null || inspectionType == null)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Missing vehicle or inspection type')),
    );
    return;
  }

  // Build the payload
  final inspectionResult = <String, dynamic>{
    "template_id": template['id'],
    if (!isEdit) "vehicle_id": vehicleId,
    if (!isEdit) "type": inspectionType,
    "results": {
      for (var item in items)
        item['id'].toString(): answers[item['id'].toString()] == true ? "yes" : "no"
    },
    "notes": notesController.text.trim(),
  };

  setState(() => isSubmitting = true);

  try {
    if (isEdit) {
      // Update existing inspection
      await InspectionService.updateInspection(
        widget.inspection['id'],
        authProvider.token!,
        {
          "results": inspectionResult['results'],
          "notes": inspectionResult['notes'],
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inspection updated")),
      );
    } else {
      // Submit new inspection
      await InspectionService.submitInspection(authProvider.token!, inspectionResult);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Inspection submitted ($inspectionType)")),
      );
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  } finally {
    if (mounted) setState(() => isSubmitting = false);
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Inspection: ${template['name'] ?? 'Unknown'}")),
      body: ListView.builder(
        itemCount: items.length + 1,
        itemBuilder: (_, index) {
          if (index < items.length) {
            final item = items[index];
            final idStr = item['id'].toString();
            return ListTile(
              title: Text(item['name']),
              subtitle: Text(item['question']),
              trailing: Switch(
                value: answers[idStr] ?? false,
                onChanged: (value) {
                  setState(() {
                    answers[idStr] = value;
                  });
                },
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Additional Notes",
                  border: OutlineInputBorder(),
                ),
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isSubmitting ? null : _submitInspection,
        tooltip: "Submit Inspection",
        child: isSubmitting
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
  }
}
