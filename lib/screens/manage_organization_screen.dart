import 'package:flutter/material.dart';
import 'package:frontend/utils/ui_helpers.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/organization_service.dart';

class ManageOrganizationScreen extends StatefulWidget {
  const ManageOrganizationScreen({super.key});

  @override
  State<ManageOrganizationScreen> createState() =>
      _ManageOrganizationScreenState();
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
    _contactNameController =
        TextEditingController(text: org?['contact_name'] ?? '');
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
        final updatedOrg =
            await OrganizationService.updateOrganization(token, orgId, {
          'name': _nameController.text.trim(),
          'address': _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          'phone_number': _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          'contact_name': _contactNameController.text.trim().isEmpty
              ? null
              : _contactNameController.text.trim(),
        });

        context.read<AuthProvider>().setOrg(updatedOrg);

        if (!context.mounted) return;
        UIHelpers.showSuccess(context, "Organization updated!");
        Navigator.pop(context);
      }
    } catch (e) {
      if (!context.mounted) return;
      UIHelpers.showError(context, "Error updating organization: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Manage Organization"),
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? const CircularProgressIndicator()
                : Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Organization Details",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                context,
                                controller: _nameController,
                                label: "Organization Name *",
                                icon: Icons.apartment_rounded,
                                validator: (value) => value == null ||
                                        value.isEmpty
                                    ? "Organization name is required"
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "Optional Information",
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withOpacity(0.9),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                context,
                                controller: _addressController,
                                label: "Address",
                                icon: Icons.location_on_outlined,
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                context,
                                controller: _phoneController,
                                label: "Phone Number",
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                context,
                                controller: _contactNameController,
                                label: "Contact Name",
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 28),
                              ElevatedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : () => _saveOrganization(),
                                icon: const Icon(Icons.save_rounded),
                                label: const Text("Save Changes"),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
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
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
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
