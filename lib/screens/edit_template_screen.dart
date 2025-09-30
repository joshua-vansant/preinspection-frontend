import 'package:flutter/material.dart';
import 'package:frontend/utils/ui_helpers.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/template_service.dart';

class EditTemplateScreen extends StatefulWidget {
  final Map<String, dynamic> template;

  const EditTemplateScreen({super.key, required this.template});

  @override
  State<EditTemplateScreen> createState() => _EditTemplateScreenState();
}

class _EditTemplateScreenState extends State<EditTemplateScreen> {
  late TextEditingController nameController;
  late List<Map<String, TextEditingController>> itemsControllers;
  bool isDefault = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.template["name"]);
    isDefault = widget.template["is_default"] ?? false;

    final List items = widget.template["items"] ?? [];
    itemsControllers = items
        .map(
          (item) => {
            "name": TextEditingController(text: item["name"] ?? ""),
            "question": TextEditingController(text: item["question"] ?? ""),
          },
        )
        .toList();

    if (itemsControllers.isEmpty) _addItem();
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

  Future<void> _saveTemplate() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final id = widget.template["id"];
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
      UIHelpers.showError(context, "Please enter a name and at least one item");
      return;
    }

    setState(() => saving = true);

    try {
      await TemplateService.updateTemplate(
        token: token,
        id: id,
        name: nameController.text.trim(),
        items: items.cast<Map<String, String>>(),
        isDefault: isDefault,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Template updated successfully")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      UIHelpers.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _deleteTemplate() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final id = widget.template["id"];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Template"),
        content: const Text(
          "Are you sure you want to delete this template? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => saving = true);

    try {
      await TemplateService.deleteTemplate(token, id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Template deleted successfully")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      UIHelpers.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
      appBar: AppBar(
        title: const Text("Edit Template"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saving ? null : _saveTemplate,
          ),
        ],
      ),
      body: saving
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Template Info",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: "Template Name",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          value: isDefault,
                          title: const Text("Default Template"),
                          onChanged: (val) => setState(() => isDefault = val),
                        ),
                        const Divider(height: 24),
                        const Text(
                          "Items",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...itemsControllers.asMap().entries.map((entry) {
                          final index = entry.key;
                          final controllers = entry.value;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: controllers["name"],
                                decoration: InputDecoration(
                                  labelText: "Item ${index + 1} Name",
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: controllers["question"],
                                decoration: InputDecoration(
                                  labelText: "Item ${index + 1} Question",
                                  border: const OutlineInputBorder(),
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
                              const SizedBox(height: 12),
                            ],
                          );
                        }),
                        TextButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add),
                          label: const Text("Add Item"),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: saving ? null : _deleteTemplate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.delete),
                          label: const Text("Delete Template"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }
}
