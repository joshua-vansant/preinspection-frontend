import 'package:flutter/material.dart';
import 'package:frontend/providers/inspection_provider.dart';
import 'package:frontend/utils/ui_helpers.dart';
import 'package:provider/provider.dart';
import '../services/template_service.dart';
import '../providers/auth_provider.dart';
import 'inspection_form_screen.dart';

class TemplateSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  final String inspectionType;
  final Map<String, dynamic>? lastInspection;

  const TemplateSelectionScreen({
    super.key,
    required this.vehicle,
    required this.inspectionType,
    this.lastInspection,
  });

  @override
  State<TemplateSelectionScreen> createState() =>
      _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState extends State<TemplateSelectionScreen> {
  List<Map<String, dynamic>> templates = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchTemplates();
  }

  Future<void> fetchTemplates() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception("No token found");

      final result = await TemplateService.getTemplates(token);

      if (!mounted) return;
      setState(() {
        templates = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      UIHelpers.showError(context, "Failed to load templates: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> selectTemplate(Map<String, dynamic> template) async {
    final inspectionProvider = context.read<InspectionProvider>();
    final vehicleId = widget.vehicle['id'];
    final inspectionType = widget.inspectionType;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Create the draft inspection here
      await inspectionProvider.startInspection(
        vehicleId: vehicleId,
        templateId: template['id'],
        type: inspectionType,
        selectedVehicle: widget.vehicle,
      );

      Navigator.of(context).pop(); // close spinner

      // Now move to form
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InspectionFormScreen(
            inspection: template,
            vehicleId: vehicleId,
            inspectionType: inspectionType,
          ),
        ),
      );

      if (!mounted) return;
      if (result == true) {
        debugPrint(
          "DEBUG: Inspection completed for vehicle ${widget.vehicle['name']} (${widget.vehicle['id']})",
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      Navigator.of(context).pop();
      UIHelpers.showError(context, "Failed to start inspection: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text(error!));

    return Scaffold(
      appBar: AppBar(title: const Text("Select Template")),
      body: Column(
        children: [
          // Vehicle header card
          Card(
            color: Colors.blue.shade50,
            margin: const EdgeInsets.all(12),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vehicle: ${(() {
                      final parts = [widget.vehicle['make'], widget.vehicle['model']].where((v) => v != null && v.toString().isNotEmpty).toList();
                      return parts.isNotEmpty ? parts.join(' ') : widget.vehicle['id'];
                    })()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Inspection type: ${widget.inspectionType.toUpperCase()}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (widget.lastInspection != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Last inspection ID: ${widget.lastInspection!['id']}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Template list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: templates.length,
              itemBuilder: (_, index) {
                final template = templates[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.description, color: Colors.blue),
                    title: Text(
                      template['name'] ?? 'Unnamed Template',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Created by: ${template['created_by'] ?? 'unknown'}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => selectTemplate(template),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
