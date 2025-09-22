import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/template_service.dart';
import '../providers/auth_provider.dart';
import 'inspection_form_screen.dart';

class TemplateSelectionScreen extends StatefulWidget {
  const TemplateSelectionScreen({super.key});

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

  void selectTemplate(Map<String, dynamic> template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InspectionFormScreen(template: template),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error.isNotEmpty) return Center(child: Text(error));

    return Scaffold(
      appBar: AppBar(title: const Text("Select Template")),
      body: ListView.builder(
        itemCount: templates.length,
        itemBuilder: (_, index) {
          final template = templates[index];
          return ListTile(
            title: Text(template['name']),
            subtitle: Text('Created by: ${template['created_by']}'),
            onTap: () => selectTemplate(template),
          );
        },
      ),
    );
  }
}
