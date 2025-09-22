import 'package:flutter/material.dart';


class InspectionFormScreen extends StatefulWidget {
  final Map<String, dynamic> template;

  const InspectionFormScreen({super.key, required this.template});

  @override
  State<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends State<InspectionFormScreen> {
  late Map<int, bool> answers;
  final notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final items = widget.template['items'] as List<dynamic>? ?? [];
    answers = {
      for (int i = 0; i < items.length; i++) i: false, // default all "No"
    };
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.template['items'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(title: Text("Inspection: ${widget.template['name']}")),
      body: ListView.builder(
        itemCount: items.length + 1, // +1 for notes field
        itemBuilder: (_, index) {
          if (index < items.length) {
            final item = items[index];
            return ListTile(
              title: Text(item['name']),
              subtitle: Text(item['question']),
              trailing: Switch(
                value: answers[index] ?? false,
                onChanged: (value) {
                  setState(() {
                    answers[index] = value;
                  });
                },
              ),
            );
          } else {
            // Notes field
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Additional Notes",
                  border: OutlineInputBorder(),
                ),
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
  onPressed: () {
    final inspectionResult = {
      "template_id": widget.template['id'],
      "results": items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return {
          "item_id": item['id'],
          "question": item['question'], // <-- include question text
          "answer": answers[i] == true ? "yes" : "no",
        };
      }).toList(),
      "notes": notesController.text.trim(),
    };

    // TODO: send inspectionResult to backend
    debugPrint("Submitting inspection: $inspectionResult");
  },
  child: const Icon(Icons.check),
  tooltip: "Submit Inspection",
      ),
    );
  }
}
