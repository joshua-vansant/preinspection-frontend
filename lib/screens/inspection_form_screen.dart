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
  final TextEditingController notesController = TextEditingController();
  bool isSubmitting = false;

  late Map<String, dynamic> template;
  late List<dynamic> items;
  late Map<String, dynamic> results;
  late int? vehicleId;
  late String inspectionType;

  @override
  void initState() {
    super.initState();

    final isEdit = widget.editMode && widget.inspection.containsKey('id');

    if (isEdit) {
      // Editing existing inspection
      template = widget.inspection['template'] ?? {};
      results = widget.inspection['results'] ?? {};
      vehicleId = widget.inspection['vehicle_id'] as int?;
      inspectionType = widget.inspection['type'] ?? 'pre';
      notesController.text = widget.inspection['notes'] ?? '';
    } else {
      // Creating new inspection
      template = widget.inspection;
      results = {};
      vehicleId = widget.vehicleId;
      inspectionType = widget.inspectionType ?? 'pre';
    }

    items = template['items'] as List<dynamic>? ?? [];

    // Initialize answers
    answers = {
      for (var item in items) item['id'].toString(): results[item['id'].toString()] == "yes"
    };
  }

  Future<void> _submitInspection() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final isEdit = widget.editMode && widget.inspection.containsKey('id');

    if (!isEdit && (vehicleId == null || inspectionType.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing vehicle or inspection type')),
      );
      return;
    }

    final inspectionPayload = <String, dynamic>{
      "template_id": template['id'],
      if (!isEdit) "vehicle_id": vehicleId,
      if (!isEdit) "type": inspectionType,
      "results": {for (var item in items) item['id'].toString(): answers[item['id'].toString()]! ? "yes" : "no"},
      "notes": notesController.text.trim(),
    };

    setState(() => isSubmitting = true);

    try {
      if (isEdit) {
        await InspectionService.updateInspection(
          widget.inspection['id'],
          token,
          {
            "results": inspectionPayload['results'],
            "notes": inspectionPayload['notes'],
          },
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Inspection updated")),
        );
      } else {
        await InspectionService.submitInspection(token, inspectionPayload);
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
        SnackBar(content: Text("Error submitting inspection: $e")),
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
              title: Text(item['name'] ?? ''),
              subtitle: Text(item['question'] ?? ''),
              trailing: Switch(
                value: answers[idStr] ?? false,
                onChanged: (val) => setState(() => answers[idStr] = val),
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
