import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/providers/inspection_provider.dart';
import 'package:frontend/utils/ui_helpers.dart';
import 'package:provider/provider.dart';
import '../services/template_service.dart';
import '../providers/auth_provider.dart';
import 'inspection_form_screen.dart';

class TemplateSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  final String inspectionType;
  final Map<String, dynamic>? lastInspection;

  const TemplateSelectionScreen({
    super.key,
    required this.vehicle,
    required this.inspectionType,
    this.lastInspection,
  });

  @override
  State<TemplateSelectionScreen> createState() =>
      _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState extends State<TemplateSelectionScreen> {
  List<Map<String, dynamic>> templates = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchTemplates();
  }

  Future<void> fetchTemplates() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception("No token found");

      final result = await TemplateService.getTemplates(token);

      if (!mounted) return;
      setState(() {
        templates = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      UIHelpers.showError(context, "Failed to load templates: $e");
      setState(() {
        error = "Failed to load templates";
        isLoading = false;
      });
    }
  }

  Future<void> selectTemplate(Map<String, dynamic> template) async {
    final inspectionProvider = context.read<InspectionProvider>();
    final vehicleId = widget.vehicle['id'];
    final inspectionType = widget.inspectionType;

    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await inspectionProvider.startInspection(
        vehicleId: vehicleId,
        templateId: template['id'],
        type: inspectionType,
        selectedVehicle: widget.vehicle,
      );

      Navigator.of(context).pop(); // close loading spinner

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InspectionFormScreen(
            inspection: template,
            vehicleId: vehicleId,
            inspectionType: inspectionType,
          ),
        ),
      );

      if (!mounted) return;
      if (result == true) {
        debugPrint(
            "DEBUG: Inspection completed for vehicle ${widget.vehicle['id']}");
        Navigator.pop(context, true);
      }
    } catch (e) {
      Navigator.of(context).pop();
      UIHelpers.showError(context, "Failed to start inspection: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Select Template"),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.secondary.withOpacity(0.03),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(child: Text(error!))
                    : Column(
                        children: [
                          _buildVehicleHeader(context),
                          const SizedBox(height: 8),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: fetchTemplates,
                              child: templates.isEmpty
                                  ? _buildEmptyState(context)
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      itemCount: templates.length,
                                      itemBuilder: (_, index) {
                                        final template = templates[index];
                                        return _buildTemplateCard(
                                          context,
                                          template,
                                          onTap: () => selectTemplate(template),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleHeader(BuildContext context) {
    final theme = Theme.of(context);
    final vehicle = widget.vehicle;

    final vehicleName = (() {
      final parts = [vehicle['make'], vehicle['model']]
          .where((v) => v != null && v.toString().isNotEmpty)
          .toList();
      return parts.isNotEmpty
          ? parts.join(' ')
          : vehicle['license_plate'] ?? vehicle['id'];
    })();

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.directions_car_rounded,
              color: theme.colorScheme.primary,
              size: 36,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicleName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Inspection Type: ${widget.inspectionType.toUpperCase()}",
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (widget.lastInspection != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Last inspection ID: ${widget.lastInspection!['id']}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    Map<String, dynamic> template, {
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        splashColor: theme.colorScheme.primary.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(Icons.description_rounded,
                    color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template['name'] ?? 'Unnamed Template',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Created by: ${template['created_by'] ?? 'Unknown'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined,
              size: 72, color: theme.disabledColor),
          const SizedBox(height: 12),
          Text(
            'No templates available',
            style: TextStyle(color: theme.disabledColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Try again later or contact your admin.',
            style: TextStyle(
              fontSize: 13,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
