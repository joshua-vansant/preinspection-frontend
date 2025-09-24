import 'package:flutter/material.dart';
import 'inspection_form_screen.dart';
import 'package:intl/intl.dart';

DateTime parseUtcToLocal(String timestamp) {
  // Try parsing it as UTC first
  DateTime utcTime = DateTime.tryParse(timestamp + 'Z') ?? DateTime.now().toUtc();

  print("Raw timestamp from backend: $timestamp + 'Z'");
  print("Parsed as UTC: ${utcTime.toUtc()}");
  print("Parsed as local (before toLocal()): $utcTime");

  // If the parsed time doesn't have a timezone, force it to UTC
  if (!utcTime.isUtc) {
    utcTime = utcTime.toUtc();
  }

  final localTime = utcTime.toLocal();
  print("Converted to local time: $localTime");

  return localTime;
}

class InspectionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> inspection;

  const InspectionDetailScreen({super.key, required this.inspection});

  @override
  Widget build(BuildContext context) {
    final results = inspection['results'] as Map<String, dynamic>? ?? {};

    final createdAt = parseUtcToLocal(inspection['created_at']);
    final formattedDate = DateFormat('MMM d, yyyy - h:mm a').format(createdAt);
    final editable = DateTime.now().difference(createdAt).inMinutes <= 30;

    print("Editable? $editable");
    print("Formatted date for display: $formattedDate");

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
            Text('Date: $formattedDate'),
            const SizedBox(height: 16),
            const Text('Results:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView(
                children: results.entries.map((e) {
                  return ListTile(
                    title: Text('Item ${e.key}'),
                    trailing: Text(e.value.toString()),
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
