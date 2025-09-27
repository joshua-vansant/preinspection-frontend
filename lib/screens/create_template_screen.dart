import 'package:flutter/material.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a name and at least one item"),
        ),
      );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error creating template: $e")));
    } finally {
      if (mounted) setState(() => creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                            icon: const Icon(Icons.delete, color: Colors.red),
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
                    onPressed: creating ? null : _createTemplate,
                    icon: const Icon(Icons.save),
                    label: const Text("Create Template"),
                  ),
                ],
              ),
            ),
    );
  }
}
