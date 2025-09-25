import 'package:flutter/material.dart';
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
        .map((item) => {
              "name": TextEditingController(text: item["name"] ?? ""),
              "question": TextEditingController(text: item["question"] ?? ""),
            })
        .toList();

    if (itemsControllers.isEmpty) {
      _addItem();
    }
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
    final token = context.read<AuthProvider>().token!;
    final id = widget.template["id"];

    final items = itemsControllers
        .map((c) => {
              "name": c["name"]!.text.trim(),
              "question": c["question"]!.text.trim(),
            })
        .where((item) =>
            item["name"]!.isNotEmpty && item["question"]!.isNotEmpty)
        .toList();

    if (nameController.text.trim().isEmpty || items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please enter a name and at least one item")),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Template updated successfully")),
      );
      Navigator.pop(context, true); // return success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating template: $e")),
      );
    } finally {
      setState(() => saving = false);
    }
  }

  Future<void> _deleteTemplate() async {
    final token = context.read<AuthProvider>().token!;
    final id = widget.template["id"];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Template"),
        content: const Text(
            "Are you sure you want to delete this template? This action cannot be undone."),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Template deleted successfully")),
      );
      Navigator.pop(context, true); // return success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting template: $e")),
      );
    } finally {
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: "Template Name"),
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
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: controllers["name"],
                          decoration: InputDecoration(
                            labelText: "Item ${index + 1} Name",
                          ),
                        ),
                        TextField(
                          controller: controllers["question"],
                          decoration: InputDecoration(
                            labelText: "Item ${index + 1} Question",
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon:
                                const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeItem(index),
                          ),
                        ),
                        const Divider(),
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
    );
  }
}
