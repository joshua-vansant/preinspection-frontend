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
                          debugPrint("AdminInspectionsScreen: Refreshing inspection history...");
                          await inspectionProvider.fetchHistory(token);
                        }
                      },
                      child: ListView.builder(
                        itemCount: inspectionProvider.history.length,
                        itemBuilder: (context, index) {
                          
                          final inspection = inspectionProvider.history[index];
                          final formattedDate = parseUtcToLocal(inspection['created_at']);

                          return ListTile(
                            leading: const Icon(Icons.assignment),
                            title: Text(
                              "Inspection #${inspection['id'] ?? ''}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "Date: $formattedDate\n"
                              "Driver: ${inspection['driver'] != null ? inspection['driver']['full_name'] : 'N/A'}",
                            ),
                            isThreeLine: true,
                          );
                        },
                      ),
                    ),
    );
  }
}
