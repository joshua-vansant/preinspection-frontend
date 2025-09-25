import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/template_service.dart';
import '../screens/edit_template_screen.dart';

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
    final token = context.read<AuthProvider>().token!;
    try {
      final result = await TemplateService.getTemplates(token);
      setState(() => templates = result);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error fetching templates: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

Future<void> _handleCreateTemplate() async {
  final token = context.read<AuthProvider>().token!;
  final templateNameController = TextEditingController();
  List<Map<String, TextEditingController>> itemsControllers = [];

  void addItem() {
    itemsControllers.add({
      "name": TextEditingController(),
      "question": TextEditingController(),
    });
  }

  addItem(); // start with one item

  bool isSubmitting = false;

  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Create Template"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: templateNameController,
                    decoration:
                        const InputDecoration(labelText: "Template Name"),
                  ),
                  const SizedBox(height: 12),
                  ...itemsControllers.map((item) {
                    final index = itemsControllers.indexOf(item);
                    return Column(
                      children: [
                        TextField(
                          controller: item["name"],
                          decoration: InputDecoration(
                              labelText: "Item ${index + 1} Name"),
                        ),
                        TextField(
                          controller: item["question"],
                          decoration: InputDecoration(
                              labelText: "Item ${index + 1} Question"),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Confirm Delete"),
                                    content: const Text(
                                        "Are you sure you want to remove this item?"),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text("Cancel")),
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text("Delete")),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  setDialogState(() {
                                    itemsControllers.removeAt(index);
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const Divider(),
                      ],
                    );
                  }),
                  TextButton.icon(
                    onPressed: () {
                      setDialogState(addItem);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Add Item"),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: isSubmitting ||
                      templateNameController.text.trim().isEmpty ||
                      itemsControllers
                          .every((c) =>
                              c["name"]!.text.trim().isEmpty &&
                              c["question"]!.text.trim().isEmpty)
                  ? null
                  : () => Navigator.pop(context, true),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Create"),
            ),
          ],
        ),
      );
    },
  );

  if (ok != true) return;

  try {
    setState(() => isSubmitting = true);

    final items = itemsControllers
        .map((c) => {
              "name": c["name"]!.text.trim(),
              "question": c["question"]!.text.trim()
            })
        .where((item) => item["name"]!.isNotEmpty && item["question"]!.isNotEmpty)
        .toList();

    await TemplateService.createTemplate(
      token: token,
      name: templateNameController.text.trim(),
      items: items,
      isDefault: false,
    );

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Template created")));
    _fetchTemplates(); // refresh the list
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Error: $e")));
  } finally {
    setState(() => isSubmitting = false);
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
                    final t = templates[index];
                    return ListTile(
                      title: Text(t['name']),
                      subtitle: Text("Items: ${t['items'].length}"),
                      trailing:
                          t['is_default'] ? const Icon(Icons.star) : null,
                      onTap: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => EditTemplateScreen(template: t),),);
                          if(updated == true){
                            _fetchTemplates(); //refresh list
                          }
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _handleCreateTemplate,
      ),
    );
  }
}

