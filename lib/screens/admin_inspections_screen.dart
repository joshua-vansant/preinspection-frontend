import 'package:flutter/material.dart';
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

        if (token != null) inspectionProvider.fetchHistory();

        _socketProvider.onEvent('inspection_created', (data) {
          try {
            final newInspection = Map<String, dynamic>.from(data);
            inspectionProvider.addInspection(newInspection);
          } catch (e) {
            debugPrint("Failed to parse inspection_created payload: $e");
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
    final inspectionProvider = context.watch<InspectionHistoryProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Inspection History"),
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
            duration: const Duration(milliseconds: 250),
            child: inspectionProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : inspectionProvider.error.isNotEmpty
                    ? Center(
                        child: Text(
                          inspectionProvider.error,
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : inspectionProvider.history.isEmpty
                        ? _buildEmptyState(theme)
                        : RefreshIndicator(
                            onRefresh: () async {
                              final token =
                                  context.read<AuthProvider>().token;
                              if (token != null) {
                                await inspectionProvider.fetchHistory();
                              }
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: inspectionProvider.history.length,
                              itemBuilder: (context, index) {
                                final inspection =
                                    inspectionProvider.history[index];
                                return _buildInspectionCard(context, inspection);
                              },
                            ),
                          ),
          ),
        ),
      ),
    );
  }

  Widget _buildInspectionCard(
      BuildContext context, Map<String, dynamic> inspection) {
    final theme = Theme.of(context);
    final formattedDate = parseUtcToLocal(inspection['updated_at']);
    final isComplete = inspection['status'] == 'complete';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor:
              isComplete ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
          child: Icon(
            isComplete ? Icons.check_circle : Icons.pending_actions,
            color: isComplete ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          "Inspection #${inspection['id'] ?? ''}",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            "Driver: ${inspection['driver']?['full_name'] ?? 'N/A'}\nDate: $formattedDate",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
            ),
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (inspection['vehicle'] != null)
                  _buildInfoRow(
                    theme,
                    Icons.directions_car_rounded,
                    "Vehicle",
                    "${inspection['vehicle']['make'] ?? ''} "
                    "${inspection['vehicle']['model'] ?? ''} "
                    "(${inspection['vehicle']['license_plate'] ?? ''})",
                  ),
                if (inspection['start_mileage'] != null)
                  _buildInfoRow(
                    theme,
                    Icons.speed_rounded,
                    "Mileage",
                    "${inspection['start_mileage']}",
                  ),
                if (inspection['fuel_level'] != null)
                  _buildInfoRow(
                    theme,
                    Icons.local_gas_station_rounded,
                    "Fuel Level",
                    "${(inspection['fuel_level'] * 100).round()}%",
                  ),
                if (inspection['odometer_verified'] != null)
                  _buildInfoRow(
                    theme,
                    Icons.verified_rounded,
                    "Odometer Verified",
                    "${inspection['odometer_verified']}",
                  ),
                if (inspection['notes'] != null &&
                    (inspection['notes'] as String).isNotEmpty)
                  _buildInfoRow(
                    theme,
                    Icons.note_alt_outlined,
                    "Notes",
                    inspection['notes'],
                  ),
                const Divider(height: 20, thickness: 0.8),
                if (inspection['results'] != null &&
                    inspection['results'].isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Inspection Items",
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...inspection['results'].entries.map((entry) {
                        final entryValue = entry.value;
                        String itemName;
                        String answer;

                        if (entryValue is Map<String, dynamic>) {
                          itemName = entryValue['name'] ?? entry.key;
                          answer = entryValue['answer']?.toString() ?? 'N/A';
                        } else {
                          itemName = entry.key;
                          answer = entryValue?.toString() ?? 'N/A';
                        }

                        final isPass = answer.toLowerCase() == 'yes';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                isPass
                                    ? Icons.check_circle_outline
                                    : Icons.error_outline,
                                color: isPass
                                    ? Colors.green
                                    : theme.colorScheme.error,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "$itemName: $answer",
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: "$label: ",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyMedium?.color,
                ),
                children: [
                  TextSpan(
                    text: value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.normal,
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined,
              size: 72, color: theme.disabledColor),
          const SizedBox(height: 12),
          Text(
            'No inspections found',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Once inspections are submitted, they will appear here.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
