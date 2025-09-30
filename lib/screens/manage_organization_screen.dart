import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/organization_service.dart';

class ManageOrganizationScreen extends StatefulWidget {
  const ManageOrganizationScreen({super.key});

  @override
  State<ManageOrganizationScreen> createState() => _ManageOrganizationScreenState();
}

class _ManageOrganizationScreenState extends State<ManageOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _contactNameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final org = context.read<AuthProvider>().org;
    _nameController = TextEditingController(text: org?['name'] ?? '');
    _addressController = TextEditingController(text: org?['address'] ?? '');
    _phoneController = TextEditingController(text: org?['phone_number'] ?? '');
    _contactNameController = TextEditingController(text: org?['contact_name'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _contactNameController.dispose();
    super.dispose();
  }

  Future<void> _saveOrganization() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final token = context.read<AuthProvider>().token!;
    final orgId = context.read<AuthProvider>().org?['id'];

    try {
      if (orgId != null) {
        final updatedOrg = await OrganizationService.updateOrganization(
          token,
          orgId,
          {
            'name': _nameController.text.trim(),
            'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
            'phone_number': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            'contact_name': _contactNameController.text.trim().isEmpty ? null : _contactNameController.text.trim(),
          },
        );

        context.read<AuthProvider>().setOrg(updatedOrg);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Organization updated!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating organization: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Organization")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: "Organization Name"),
                        validator: (value) =>
                            value == null || value.isEmpty ? "Name cannot be empty" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: "Address (optional)"),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: "Phone Number (optional)"),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _contactNameController,
                        decoration: const InputDecoration(labelText: "Contact Name (optional)"),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saveOrganization,
                        child: const Text("Save"),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
