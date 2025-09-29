import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'inspection_form_screen.dart';
import 'package:intl/intl.dart';
import '../services/inspection_service.dart';
import 'package:frontend/utils/date_time_utils.dart';


class InspectionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> inspection;

  const InspectionDetailScreen({super.key, required this.inspection});

  @override
  Widget build(BuildContext context) {
    final results = inspection['results'] as Map<String, dynamic>? ?? {};

    final createdAt = parseUtcToLocal(
      inspection['created_at'] ?? DateTime.now().toIso8601String(), asDateTime: true,
    );
    
    final formattedDate = DateFormat('MMM d, yyyy - h:mm a').format(createdAt);

    // Editable within 30 minutes of creation
    final editable = DateTime.now().difference(createdAt).inMinutes <= 30;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inspection #${inspection['id']} (${inspection['type'] ?? "N/A"})',
        ),
        actions: [
          if (editable)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final token = context.read<AuthProvider>().token;
                if (token == null) return;

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  final fullInspection =
                      await InspectionService.getInspectionById(
                        inspection['id'],
                        token,
                      );
                  Navigator.pop(context); // remove loading dialog

                  final template =
                      fullInspection['template'] as Map<String, dynamic>?;

                  if (template == null || template.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Template data is missing. Cannot edit.'),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InspectionFormScreen(
                        inspection: fullInspection,
                        editMode: true,
                      ),
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error fetching inspection: $e')),
                  );
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vehicle ID: ${inspection['vehicle_id'] ?? "N/A"}'),
            Text('Template ID: ${inspection['template_id'] ?? "N/A"}'),
            Text('Date: $formattedDate'),
            const SizedBox(height: 16),
            const Text(
              'Results:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView(
                children: results.entries.map((e) {
                  final displayKey = e.key.toString();
                  final displayValue = e.value?.toString() ?? "N/A";
                  return ListTile(
                    title: Text('Item $displayKey'),
                    trailing: Text(displayValue),
                  );
                }).toList(),
              ),
            ),
            if (inspection['notes'] != null &&
                (inspection['notes'] as String).isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Notes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(inspection['notes']),
            ],
          ],
        ),
      ),
    );
  }
}
