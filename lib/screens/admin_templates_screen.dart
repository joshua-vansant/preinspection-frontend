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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Manage Templates"),
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
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : templates.isEmpty
                    ? _buildEmptyState(theme)
                    : RefreshIndicator(
                        onRefresh: _fetchTemplates,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: templates.length,
                          itemBuilder: (context, index) {
                            final template = templates[index];
                            final isDefault = template['is_default'] == true;
                            final itemCount =
                                (template['items'] as List?)?.length ?? 0;

                            return _buildTemplateCard(
                              context,
                              template,
                              isDefault: isDefault,
                              itemCount: itemCount,
                            );
                          },
                        ),
                      ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTemplateScreen()),
          );
          if (created == true) _fetchTemplates();
        },
        label: const Text("New Template"),
        icon: const Icon(Icons.add),
        backgroundColor: colorScheme.primary,
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    Map<String, dynamic> template, {
    required bool isDefault,
    required int itemCount,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final updated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditTemplateScreen(template: template),
            ),
          );
          if (updated == true) _fetchTemplates();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon / default badge
              CircleAvatar(
                radius: 24,
                backgroundColor: isDefault
                    ? Colors.amber.withOpacity(0.15)
                    : theme.colorScheme.primary.withOpacity(0.08),
                child: Icon(
                  isDefault ? Icons.star : Icons.description_rounded,
                  color: isDefault
                      ? Colors.amber.shade700
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              // Template info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template['name'] ?? "Unnamed Template",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Items: $itemCount",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                      ),
                    ),
                    if (isDefault)
                      Text(
                        "Default Template",
                        style: TextStyle(
                          color: Colors.amber.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              "No templates found",
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.disabledColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Create your first inspection template to get started.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
