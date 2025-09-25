import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/template_service.dart'; // you’ll create this

class AdminTemplatesScreen extends StatelessWidget {
  const AdminTemplatesScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchTemplates(String token) async {
    final response = await TemplateService.getTemplates(token);
    return response; // should return List<Map<String,dynamic>>
  }

  @override
  Widget build(BuildContext context) {
    final token = context.watch<AuthProvider>().token!;
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Templates")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchTemplates(token),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No templates available"));
          }

          final templates = snapshot.data!;
          return ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final t = templates[index];
              return ListTile(
                title: Text(t['name']),
                subtitle: Text("Items: ${t['items'].length}"),
                trailing: t['is_default'] ? const Icon(Icons.star) : null,
                onTap: () {
                  // Optionally navigate to detail/edit screen
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // Open Create Template dialog/screen
        },
      ),
    );
  }
}
