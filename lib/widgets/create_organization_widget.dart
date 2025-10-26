import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/organization_service.dart';
import 'package:frontend/utils/ui_helpers.dart';

class CreateOrganizationWidget extends StatefulWidget {
  final void Function(Map<String, dynamic> organization)? onCreated;

  const CreateOrganizationWidget({super.key, this.onCreated});

  @override
  State<CreateOrganizationWidget> createState() =>
      _CreateOrganizationWidgetState();
}

class _CreateOrganizationWidgetState extends State<CreateOrganizationWidget> {
  final _nameController = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createOrganization() async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      UIHelpers.showError(context, "Please log in again to continue.");
      return;
    }

    final name = _nameController.text.trim();
    if (name.length < 3) {
      if (!mounted) return;
      UIHelpers.showError(
        context,
        "Organization name must be at least 3 characters long.",
      );
      return;
    }

    setState(() => _creating = true);

    try {
      final org = await OrganizationService.createOrg(token, name);
      authProvider.setOrg(org['organization']);
      widget.onCreated?.call(org['organization']);
      if (mounted) {
        UIHelpers.showSuccess(context, "Organization created successfully!");
      }
    } catch (e) {
      if (!mounted) return;
      UIHelpers.showError(context, "Error creating organization: $e");
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.apartment_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "Create an Organization",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Organization Name",
                hintText: "Enter your organization's name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.edit_rounded),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _creating ? null : _createOrganization,
                icon: _creating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_business_rounded, size: 20),
                label: Text(
                  _creating ? "Creating..." : "Create Organization",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
