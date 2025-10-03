import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/template_service.dart';
import 'edit_template_screen.dart';
import 'create_template_screen.dart';
import 'package:frontend/utils/ui_helpers.dart';

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
      if (!mounted) return;
      UIHelpers.showError(context, e.toString());
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
      appBar: AppBar(
        title: const Text("Manage Templates"),
        backgroundColor: Colors.blue.shade600,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : templates.isEmpty
          ? const Center(
              child: Text(
                "No templates available",
                style: TextStyle(fontSize: 16),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListView.builder(
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  final isDefault = template['is_default'] == true;
                  final itemCount = (template['items'] as List?)?.length ?? 0;

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EditTemplateScreen(template: template),
                          ),
                        );
                        if (updated == true) _fetchTemplates();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            // Default/star indicator
                            if (isDefault)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                              ),
                            if (isDefault) const SizedBox(width: 12),
                            // Template info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    template['name'] ?? "Unnamed Template",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Items: $itemCount",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Arrow icon
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.add),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTemplateScreen()),
          );
          if (created == true) _fetchTemplates();
        },
      ),
    );
  }
}
