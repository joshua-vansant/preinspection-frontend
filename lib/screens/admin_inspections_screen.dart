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
          debugPrint(
            "DEBUG: AdminInspectionsScreen: Fetching initial inspection history...",
          );
          inspectionProvider.fetchHistory();
        }

        _socketProvider.onEvent('inspection_created', (data) {
          debugPrint("DEBUG: AdminInspectionsScreen: SOCKET RAW DATA: $data");
          try {
            final newInspection = Map<String, dynamic>.from(data);
            debugPrint(
              "DEBUG: AdminInspectionsScreen: Parsed new inspection: $newInspection",
            );
            inspectionProvider.addInspection(newInspection);
          } catch (e) {
            debugPrint(
              "DEBUG: AdminInspectionsScreen: Failed to parse inspection_created payload: $e",
            );
          }
        });

        _isSubscribed = true;
      });
    }
  }

  @override
  void dispose() {
    _socketProvider.offEvent('inspection_created');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inspectionHistoryProvider = context
        .watch<InspectionHistoryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Inspection History")),
      body: SafeArea(
        child: inspectionHistoryProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : inspectionHistoryProvider.error.isNotEmpty
            ? Center(child: Text(inspectionHistoryProvider.error))
            : inspectionHistoryProvider.history.isEmpty
            ? const Center(child: Text("No inspections found"))
            : RefreshIndicator(
                onRefresh: () async {
                  final token = context.read<AuthProvider>().token;
                  if (token != null) {
                    await inspectionHistoryProvider.fetchHistory();
                  }
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: inspectionHistoryProvider.history.length,
                  itemBuilder: (context, index) {
                    final inspection = inspectionHistoryProvider.history[index];
                    final formattedDate = parseUtcToLocal(
                      inspection['updated_at'],
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        childrenPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
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
                          "Driver: ${inspection['driver']?['full_name'] ?? 'N/A'}\nDate: $formattedDate",
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
                            Text(
                              "Odometer Verified: ${inspection['odometer_verified']}",
                            ),
                          if (inspection['notes'] != null)
                            Text("Notes: ${inspection['notes']}"),
                          const SizedBox(height: 8),
                          if (inspection['results'] != null &&
                              inspection['results'].isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Items:",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ...inspection['results'].entries.map((entry) {
                                  final entryValue = entry.value;
                                  String itemName;
                                  String answer;

                                  if (entryValue is Map<String, dynamic>) {
                                    itemName = entryValue['name'] ?? entry.key;
                                    answer =
                                        entryValue['answer']?.toString() ??
                                        'N/A';
                                  } else {
                                    // fallback for old structure
                                    itemName = entry.key;
                                    answer = entryValue?.toString() ?? 'N/A';
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Text("- $itemName: $answer"),
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
      ),
    );
  }
}
