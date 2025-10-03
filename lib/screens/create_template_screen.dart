import 'package:flutter/material.dart';
import 'package:frontend/utils/ui_helpers.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/template_service.dart';

class CreateTemplateScreen extends StatefulWidget {
  const CreateTemplateScreen({super.key});

  @override
  State<CreateTemplateScreen> createState() => _CreateTemplateScreenState();
}

class _CreateTemplateScreenState extends State<CreateTemplateScreen> {
  final TextEditingController nameController = TextEditingController();
  final List<Map<String, TextEditingController>> itemsControllers = [];
  bool isDefault = false;
  bool creating = false;

  @override
  void initState() {
    super.initState();
    _addItem();
  }

  void _addItem() {
    setState(() {
      itemsControllers.add({
        "name": TextEditingController(),
        "question": TextEditingController(),
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      itemsControllers.removeAt(index);
    });
  }

  Future<void> _createTemplate() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final items = itemsControllers
        .map(
          (c) => {
            "name": c["name"]!.text.trim(),
            "question": c["question"]!.text.trim(),
          },
        )
        .where(
          (item) => item["name"]!.isNotEmpty && item["question"]!.isNotEmpty,
        )
        .toList();

    if (nameController.text.trim().isEmpty || items.isEmpty) {
      if (!mounted) return;
      UIHelpers.showError(context, "Please enter a name and at least one item");
      return;
    }

    setState(() => creating = true);

    try {
      await TemplateService.createTemplate(
        token: token,
        name: nameController.text.trim(),
        items: items.cast<Map<String, String>>(),
        isDefault: isDefault,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Template created successfully")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      UIHelpers.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Create Template"),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: creating ? null : _createTemplate,
            ),
          ],
        ),
        body: creating
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Template Name",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: isDefault,
                      title: const Text("Default Template"),
                      onChanged: (val) => setState(() => isDefault = val),
                    ),
                    const Divider(),
                    ...itemsControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controllers = entry.value;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: controllers["name"],
                                decoration: InputDecoration(
                                  labelText: "Item ${index + 1} Name",
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: controllers["question"],
                                decoration: InputDecoration(
                                  labelText: "Item ${index + 1} Question",
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _removeItem(index),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: const Text("Add Item"),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: creating ? null : _createTemplate,
                      icon: const Icon(Icons.save),
                      label: const Text("Create Template"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
