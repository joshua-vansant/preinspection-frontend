import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/inspection_history_provider.dart';
import '../utils/date_time_utils.dart';
import '../utils/ui_helpers.dart';
import 'inspection_form_screen.dart';

class InspectionDetailScreen extends StatefulWidget {
  final int inspectionId;
  const InspectionDetailScreen({super.key, required this.inspectionId});

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  Map<String, dynamic>? _inspection;
  bool _isFetching = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchInspectionIfNeeded();
  }

  void _fetchInspectionIfNeeded() async {
    final historyProvider = context.read<InspectionHistoryProvider>();

    // Check if we already have this inspection
    final existing = historyProvider.history.firstWhere(
      (i) => i['id'] == widget.inspectionId,
      orElse: () => {},
    );

    if (existing.isEmpty || existing['template'] == null) {
      setState(() => _isFetching = true);

      try {
        final full = await historyProvider.fetchFullInspection(
          widget.inspectionId,
        );
        if (!mounted) return;

        setState(() {
          _inspection = full;
          _isFetching = false;
          debugPrint('DEBUG: _inspection updated: $_inspection');
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _isFetching = false);
        UIHelpers.showError(context, 'Error fetching inspection: $e');
      }
    } else {
      _inspection = existing;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching || _inspection == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final inspection = _inspection!;
    final templateItems =
        (inspection['template']?['items'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

    String getItemName(String id) {
      final item = templateItems.firstWhere(
        (i) => i['id'].toString() == id,
        orElse: () => {'name': id},
      );
      return item['name']?.toString() ?? id;
    }

    final results = inspection['results'] as Map<String, dynamic>? ?? {};
    final createdAt = parseUtcToLocal(
      inspection['created_at'] ?? DateTime.now().toIso8601String(),
      asDateTime: true,
    );
    final formattedDate = DateFormat('MMM d, yyyy - h:mm a').format(createdAt);
    final editable = DateTime.now().difference(createdAt).inMinutes <= 30;
    final fuelLevel = inspection['fuel_level'] != null
        ? ((inspection['fuel_level'] as num) * 100).round()
        : 0;

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
                  final fullInspection = await context
                      .read<InspectionHistoryProvider>()
                      .fetchFullInspection(inspection['id']);
                  if (!mounted) return;
                  Navigator.pop(context);

                  final template =
                      fullInspection['template'] as Map<String, dynamic>?;

                  if (template == null || template.isEmpty) {
                    UIHelpers.showError(
                      context,
                      'Template data is missing. Cannot edit.',
                    );
                    return;
                  }

                  if (!mounted) return;
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
                  if (!mounted) return;
                  Navigator.pop(context);
                  UIHelpers.showError(context, 'Error fetching inspection: $e');
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
            Card(
  color: Theme.of(context).brightness == Brightness.dark
      ? Colors.blueGrey.shade800 // darker background in dark mode
      : Colors.blue.shade50,     // original light mode background
  elevation: 2,
  child: ListTile(
    leading: Icon(
      Icons.speed,
      color: Colors.blue, // keep the icon color
    ),
    title: Text(
      'Start Mileage',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white // readable in dark mode
            : Colors.blue.shade800,
      ),
    ),
    trailing: Text(
      inspection['start_mileage']?.toString() ?? "N/A",
      style: TextStyle(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.blue.shade800,
      ),
    ),
  ),
),


            const SizedBox(height: 8),
            Card(
  color: Theme.of(context).brightness == Brightness.dark
      ? Colors.blueGrey.shade800 // darker background in dark mode
      : Colors.blue.shade50,     // original light mode background
  elevation: 2,
  child: ListTile(
    leading: Icon(
      Icons.speed,
      color: Colors.blue, // keep the icon color
    ),
    title: Text(
      'Fuel Level',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white 
            : Colors.green.shade800,
      ),
    ),
    trailing: Text(
      inspection['start_mileage']?.toString() ?? "N/A",
      style: TextStyle(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.green.shade800,
      ),
    ),
  ),
),


            const SizedBox(height: 16),
            Text(
              'Results:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),

            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                children: results.entries.map((e) {
                  final displayKey = getItemName(e.key.toString());
                  final displayValue = e.value?.toString() ?? "N/A";
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(
                        displayKey,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      trailing: Text(
                        displayValue,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (inspection['notes'] != null &&
                (inspection['notes'] as String).isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Notes:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),

              Text(inspection['notes']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}
