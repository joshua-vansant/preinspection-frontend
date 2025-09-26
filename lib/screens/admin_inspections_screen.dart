import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/inspection_service.dart';

class AdminInspectionsScreen extends StatefulWidget {
  const AdminInspectionsScreen({super.key});

  @override
  State<AdminInspectionsScreen> createState() => _AdminInspectionsScreenState();
}

class _AdminInspectionsScreenState extends State<AdminInspectionsScreen> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _inspections = [];

  @override
  void initState() {
    super.initState();
    _fetchInspections();
  }

  Future<void> _fetchInspections() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final token = context.read<AuthProvider>().token!;
    try {
      final data = await InspectionService.getInspectionHistory(token);
      setState(() => _inspections = data);
    } catch (e) {
      setState(() => _error = "Error loading inspections: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inspection History")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _inspections.isEmpty
                  ? const Center(child: Text("No inspections found"))
                  : RefreshIndicator(
                      onRefresh: _fetchInspections,
                      child: ListView.builder(
                        itemCount: _inspections.length,
                        itemBuilder: (context, index) {
                          final inspection = _inspections[index];
                          return ListTile(
                            leading: const Icon(Icons.assignment),
                            title: Text(
                              "Inspection #${inspection['id'] ?? ''}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "Date: ${inspection['created_at'] ?? 'Unknown'}\n"
                              "Driver: ${inspection['driver_name'] ?? 'N/A'}",
                            ),
                            isThreeLine: true,
                          );
                        },
                      ),
                    ),
    );
  }
}
