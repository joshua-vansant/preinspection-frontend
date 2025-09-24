import 'package:flutter/material.dart';
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
  _TemplateSelectionScreenState createState() => _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState extends State<TemplateSelectionScreen> {
  List<Map<String, dynamic>> templates = [];
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchTemplates();
  }

  Future<void> fetchTemplates() async {
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception("No token found");

      final result = await TemplateService.getTemplates(token);
      setState(() {
        templates = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load templates: $e';
        isLoading = false;
      });
    }
  }

  void selectTemplate(Map<String, dynamic> template) async {
  // merge vehicle and inspection metadata into the template payload
  final merged = Map<String, dynamic>.from(template);
  merged['vehicle_id'] = widget.vehicle['id'];
  merged['inspection_type'] = widget.inspectionType;
  merged['last_inspection'] = widget.lastInspection;

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => InspectionFormScreen(template: merged),
    ),
  );

  if (result == true) {
    // A new inspection was submitted
    debugPrint("Inspection completed for vehicle ${widget.vehicle['name']} (${widget.vehicle['id']})");

    // Optionally, you can pop this screen too so the Dashboard knows:
    Navigator.pop(context, true);
  }
}


  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error.isNotEmpty) return Center(child: Text(error));

    return Scaffold(
      appBar: AppBar(title: const Text("Select Template")),
      body: Column(
        children: [
          // small header showing vehicle + inspection type
          Container(
            width: double.infinity,
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vehicle: ${widget.vehicle['name'] ?? widget.vehicle['id']}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Inspection type: ${widget.inspectionType.toUpperCase()}'),
                if (widget.lastInspection != null) ...[
                  const SizedBox(height: 6),
                  Text('Last inspection id: ${widget.lastInspection!['id']}', style: const TextStyle(fontSize: 12)),
                ]
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: templates.length,
              itemBuilder: (_, index) {
                final template = templates[index];
                return ListTile(
                  title: Text(template['name']),
                  subtitle: Text('Created by: ${template['created_by'] ?? 'unknown'}'),
                  onTap: () => selectTemplate(template),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
