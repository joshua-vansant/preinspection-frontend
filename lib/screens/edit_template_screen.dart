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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Edit Template"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            tooltip: "Save Template",
            onPressed: saving ? null : _saveTemplate,
          ),
        ],
      ),
      body: saving
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.05),
                    colorScheme.secondary.withOpacity(0.03),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Template Details",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          context,
                          controller: nameController,
                          label: "Template Name",
                          icon: Icons.description_outlined,
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          value: isDefault,
                          title: const Text("Default Template"),
                          onChanged: (val) => setState(() => isDefault = val),
                        ),
                        const Divider(height: 32),
                        Text(
                          "Template Items",
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...itemsControllers.asMap().entries.map((entry) {
                          final index = entry.key;
                          final controllers = entry.value;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Item ${index + 1}",
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    context,
                                    controller: controllers["name"]!,
                                    label: "Name",
                                    icon: Icons.label_outline,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    context,
                                    controller: controllers["question"]!,
                                    label: "Question",
                                    icon: Icons.help_outline,
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
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
                          icon: const Icon(Icons.add_rounded),
                          label: const Text("Add New Item"),
                        ),
                        const SizedBox(height: 32),
                        Divider(color: colorScheme.outline.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                "Danger Zone",
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: saving ? null : _deleteTemplate,
                                icon: const Icon(Icons.delete_forever),
                                label: const Text("Delete Template"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}
