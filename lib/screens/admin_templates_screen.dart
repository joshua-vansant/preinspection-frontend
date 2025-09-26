import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/template_service.dart';
import 'edit_template_screen.dart';
import 'create_template_screen.dart';

class AdminTemplatesScreen extends StatefulWidget {
  const AdminTemplatesScreen({super.key});

  @override
  State<AdminTemplatesScreen> createState() => _AdminTemplatesScreenState();
}

class _AdminTemplatesScreenState extends State<AdminTemplatesScreen> {
  List<Map<String, dynamic>> templates = [];
  bool loading = false;

  Future<void> _fetchTemplates() async {
    setState(() => loading = true);
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      final result = await TemplateService.getTemplates(token);
      setState(() => templates = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching templates: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Templates")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : templates.isEmpty
              ? const Center(child: Text("No templates available"))
              : ListView.builder(
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    return ListTile(
                      title: Text(template['name'] ?? "Unnamed"),
                      subtitle: Text(
                        "Items: ${(template['items'] as List?)?.length ?? 0}",
                      ),
                      trailing: template['is_default'] == true
                          ? const Icon(Icons.star)
                          : null,
                      onTap: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EditTemplateScreen(template: template),
                          ),
                        );
                        if (updated == true) {
                          _fetchTemplates(); // Refresh list after edit
                        }
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTemplateScreen()),
          );
          if (created == true) {
            _fetchTemplates(); // Refresh list after new template
          }
        },
      ),
    );
  }
}
