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
        .map((c) => {
              "name": c["name"]!.text.trim(),
              "question": c["question"]!.text.trim(),
            })
        .where((item) =>
            item["name"]!.isNotEmpty && item["question"]!.isNotEmpty)
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Create Template"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: creating ? null : _createTemplate,
            tooltip: "Save Template",
          ),
        ],
      ),
      body: Container(
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
        child: creating
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Template Details",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: nameController,
                              decoration: InputDecoration(
                                labelText: "Template Name",
                                prefixIcon:
                                    const Icon(Icons.description_outlined),
                                filled: true,
                                fillColor: colorScheme.surfaceVariant
                                    .withOpacity(0.2),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              value: isDefault,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                "Set as Default Template",
                                style: theme.textTheme.bodyMedium,
                              ),
                              secondary: Icon(
                                isDefault
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: isDefault
                                    ? Colors.amber.shade700
                                    : theme.iconTheme.color,
                              ),
                              onChanged: (val) =>
                                  setState(() => isDefault = val),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Items Section
                    Text(
                      "Template Items",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...itemsControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controllers = entry.value;
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Item ${index + 1}",
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildTextField(
                                context,
                                controller: controllers["name"]!,
                                label: "Item Name",
                                icon: Icons.label_important_outline_rounded,
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                context,
                                controller: controllers["question"]!,
                                label: "Question",
                                icon: Icons.help_outline_rounded,
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: theme.colorScheme.error,
                                  tooltip: "Remove this item",
                                  onPressed: () => _removeItem(index),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text("Add Item"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(
                          color: colorScheme.primary.withOpacity(0.4),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: creating ? null : _createTemplate,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text("Create Template"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
      ),
    );
  }
}
