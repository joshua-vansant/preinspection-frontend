import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'inspection_form_screen.dart';
import 'package:intl/intl.dart';
import '../services/inspection_service.dart';
import '../utils/date_time_utils.dart';

class InspectionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> inspection;

  const InspectionDetailScreen({super.key, required this.inspection});

  @override
  Widget build(BuildContext context) {
    final results = inspection['results'] as Map<String, dynamic>? ?? {};

    final createdAt = parseUtcToLocal(
      inspection['created_at'] ?? DateTime.now().toIso8601String(),
      asDateTime: true,
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
                  Navigator.pop(context);

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
            _infoRow(
              'Vehicle ID',
              inspection['vehicle_id']?.toString() ?? "N/A",
            ),
            _infoRow(
              'Template ID',
              inspection['template_id']?.toString() ?? "N/A",
            ),
            _infoRow('Date', formattedDate),
            const SizedBox(height: 16),

            // Start Mileage card with icon
            Card(
              color: Colors.blue.shade50,
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.speed, color: Colors.blue),
                title: const Text(
                  'Start Mileage',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  inspection['start_mileage']?.toString() ?? "N/A",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Fuel info
            Card(
              color: Colors.green.shade50,
              elevation: 2,
              child: ListTile(
                leading: const Icon(
                  Icons.local_gas_station,
                  color: Colors.green,
                ),
                title: const Text(
                  'Fuel Level',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text('${(inspection['fuel_level'] ?? 0).round()}%'),
              ),
            ),
            if (inspection['fuel_notes'] != null &&
                (inspection['fuel_notes'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Fuel Notes: ${inspection['fuel_notes']}'),
            ],

            const SizedBox(height: 8),
            _infoRow(
              'Odometer Verified',
              inspection['odometer_verified']?.toString() ?? "false",
            ),

            const SizedBox(height: 16),
            const Text(
              'Results:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                children: results.entries.map((e) {
                  final displayKey = e.key.toString();
                  final displayValue = e.value?.toString() ?? "N/A";
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(displayKey),
                      trailing: Text(displayValue),
                    ),
                  );
                }).toList(),
              ),
            ),

            if (inspection['notes'] != null &&
                (inspection['notes'] as String).isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Notes:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(inspection['notes']),
            ],
          ],
        ),
      ),
    );
  }

  // Helper for consistent rows
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
