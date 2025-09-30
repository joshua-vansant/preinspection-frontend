import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/inspection_history_provider.dart';
import '../providers/socket_provider.dart';
import 'package:frontend/utils/date_time_utils.dart';

class AdminInspectionsScreen extends StatefulWidget {
  const AdminInspectionsScreen({super.key});

  @override
  State<AdminInspectionsScreen> createState() => _AdminInspectionsScreenState();
}

class _AdminInspectionsScreenState extends State<AdminInspectionsScreen> {
  bool _isSubscribed = false;
  late SocketProvider _socketProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isSubscribed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final token = context.read<AuthProvider>().token;
        final inspectionProvider = context.read<InspectionHistoryProvider>();
        _socketProvider = context.read<SocketProvider>();

        if (token != null) {
          debugPrint("AdminInspectionsScreen: Fetching initial inspection history...");
          inspectionProvider.fetchHistory(token);
        }

        // Subscribe to new inspection events
        _socketProvider.onEvent('inspection_created', (data) {
          debugPrint("AdminInspectionsScreen: SOCKET RAW DATA: $data");

          try {
            final newInspection = Map<String, dynamic>.from(data);
            debugPrint("AdminInspectionsScreen: Parsed new inspection: $newInspection");
            inspectionProvider.addInspection(newInspection);
          } catch (e) {
            debugPrint("AdminInspectionsScreen: Failed to parse inspection_created payload: $e");
          }
        });

        _isSubscribed = true;
      });
    }
  }

  @override
  void dispose() {
    // use cached provider instead of context.read
    _socketProvider.offEvent('inspection_created');
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final inspectionProvider = context.watch<InspectionHistoryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Inspection History")),
      body: inspectionProvider.isLoading
    ? const Center(child: CircularProgressIndicator())
    : inspectionProvider.error.isNotEmpty
        ? Center(child: Text(inspectionProvider.error))
        : inspectionProvider.history.isEmpty
            ? const Center(child: Text("No inspections found"))
            : RefreshIndicator(
                onRefresh: () async {
                  final token = context.read<AuthProvider>().token;
                  if (token != null) {
                    await inspectionProvider.fetchHistory(token);
                  }
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: inspectionProvider.history.length,
                  itemBuilder: (context, index) {
                    final inspection = inspectionProvider.history[index];
                    final formattedDate = parseUtcToLocal(inspection['created_at']);
                    final vehicle = inspection['vehicle'];
                    final mileage = inspection['mileage'];

                    return Card(
  margin: const EdgeInsets.symmetric(vertical: 6),
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
  ),
  child: ExpansionTile(
    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    leading: Icon(
      Icons.assignment_turned_in,
      color: inspection['status'] == 'complete'
          ? Colors.green
          : Colors.orange,
    ),
    title: Text(
      "Inspection #${inspection['id'] ?? ''}",
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
    subtitle: Text(
      "Driver: ${inspection['driver']?['full_name'] ?? 'N/A'}\n"
      "Date: $formattedDate",
      style: const TextStyle(fontSize: 14),
    ),
    children: [
      if (inspection['vehicle'] != null)
        Text(
          "Vehicle: ${inspection['vehicle']['make'] ?? ''} ${inspection['vehicle']['model'] ?? ''} (${inspection['vehicle']['license_plate'] ?? ''})",
        ),
      if (inspection['start_mileage'] != null)
        Text("Mileage: ${inspection['start_mileage']}"),
      if (inspection['fuel_level'] != null)
        Text("Fuel Level: ${inspection['fuel_level']}%"),
      if (inspection['odometer_verified'] != null)
        Text("Odometer Verified: ${inspection['odometer_verified']}"),
      if (inspection['notes'] != null)
        Text("Notes: ${inspection['notes']}"),
      const SizedBox(height: 8),
      if (inspection['results'] != null && inspection['results'].isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Items:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...inspection['results'].entries.map((entry) {
              final itemId = entry.key;
              final answer = entry.value ?? 'N/A';
              // Optionally map itemId -> question if you have template_items
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text("- Item $itemId: $answer"),
              );
            }).toList(),
          ],
        ),
    ],
  ),
);
                  },
                ),
              ),

              

    );
  }
}
