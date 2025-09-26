import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/organization_service.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not authenticated')),
      );
      return;
    }

    final name = _nameController.text.trim();
    if (name.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Organization name must be at least 3 characters'),
        ),
      );
      return;
    }

    setState(() => _creating = true);

    try {
      final org = await OrganizationService.createOrg(token, name);

      // Update provider
      authProvider.setOrg(org['organization']);

      // Callback for dashboard refresh
      if (widget.onCreated != null) widget.onCreated!(org['organization']);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating organization: $e')),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Organization Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _creating ? null : _createOrganization,
          child: _creating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Organization'),
        ),
      ],
    );
  }
}
