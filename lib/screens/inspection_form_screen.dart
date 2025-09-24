import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/inspection_service.dart';
import 'dashboard_screen.dart';

class InspectionFormScreen extends StatefulWidget {
  final Map<String, dynamic> template;
  final bool editMode;

  const InspectionFormScreen({super.key, required this.template, this.editMode = false});

  @override
  State<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends State<InspectionFormScreen> {
  late Map<String, bool> answers; // Keyed by item ID as string
  final notesController = TextEditingController();
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final items = widget.template['items'] as List<dynamic>? ?? [];

    // Initialize all answers to false
    answers = {
      for (var item in items) item['id'].toString(): false,
    };

    // Prefill answers if editing a post-inspection
    final inspectionType = widget.template['inspection_type'] as String? ?? 'pre';
    final lastResults = widget.editMode
        ? (widget.template['results'] as Map<String, dynamic>? ?? {})
        : (widget.template['last_inspection']?['results'] as Map<String, dynamic>? ?? {});

    if (inspectionType == 'post' || widget.editMode) {
      for (int i = 0; i < items.length; i++) {
        final key = i.toString(); // match JSON keys from API
        if (lastResults.containsKey(key)) {
          answers[key] = lastResults[key] == "yes";
        }
      }
    }

    // Prefill notes if editing
    if (widget.editMode) {
      notesController.text = widget.template['notes'] ?? '';
    }
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> _submitInspection() async {
    final items = widget.template['items'] as List<dynamic>? ?? [];
    final authProvider = context.read<AuthProvider>();

    final vehicleId = widget.template['vehicle_id'];
    final inspectionType = widget.template['inspection_type'];

    if (vehicleId == null || inspectionType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing vehicle or inspection type')),
      );
      return;
    }

    final inspectionResult = {
      "template_id": widget.template['id'],
      "vehicle_id": vehicleId,
      "type": inspectionType,
      "results": {
        for (var item in items)
          item['id'].toString(): answers[item['id'].toString()] == true ? "yes" : "no"
      },
      "notes": notesController.text.trim(),
    };

    setState(() => isSubmitting = true);

    try {
      await InspectionService.submitInspection(authProvider.token!, inspectionResult);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Inspection submitted ($inspectionType)")),
      );

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
    final items = widget.template['items'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(title: Text("Inspection: ${widget.template['name']}")),
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
