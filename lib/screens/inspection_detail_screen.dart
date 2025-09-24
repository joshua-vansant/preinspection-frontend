import 'package:flutter/material.dart';
import 'inspection_form_screen.dart';

class InspectionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> inspection;

  const InspectionDetailScreen({super.key, required this.inspection});

  @override
  Widget build(BuildContext context) {
    final results = inspection['results'] as Map<String, dynamic>? ?? {};
    final createdAtString = inspection['created_at'] as String? ?? '';
    DateTime? createdAt;

    try {
      createdAt = DateTime.parse(createdAtString.replaceFirst(' ', 'T'));
      print('Parsed createdAt: $createdAt from string: $createdAtString');
    } catch (e) {
      createdAt = DateTime.now();
      print('Failed to parse createdAt from: $createdAtString, defaulting to now. Error: $e');
    }

    final editable = DateTime.now().difference(createdAt).inMinutes <= 30;
    print('Editable flag for inspection ${inspection['id']}: $editable');

    return Scaffold(
      appBar: AppBar(
        title: Text('Inspection #${inspection['id']} (${inspection['type']})'),
        actions: [
          if (editable)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InspectionFormScreen(
                      template: inspection,
                      editMode: true,
                    ),
                  ),
                );
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
            Text('Template ID: ${inspection['template_id']}'),
            Text('Date: ${inspection['created_at']}'),
            const SizedBox(height: 16),
            const Text('Results:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView(
                children: results.entries.map((e) {
                  return ListTile(
                    title: Text('Item ${e.key}'),
                    trailing: Text(e.value),
                  );
                }).toList(),
              ),
            ),
            if (inspection['notes'] != null && inspection['notes'].isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(inspection['notes']),
            ]
          ],
        ),
      ),
    );
  }
}
