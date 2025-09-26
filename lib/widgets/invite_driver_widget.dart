import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/auth_provider.dart';
import '../services/organization_service.dart';

class InviteDriverWidget extends StatefulWidget {
  const InviteDriverWidget({super.key});

  @override
  State<InviteDriverWidget> createState() => _InviteDriverWidgetState();
}

class _InviteDriverWidgetState extends State<InviteDriverWidget> {
  String? _inviteCode;
  bool _loading = false;
  bool _copied = false;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _fetchInviteCode() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      _showSnackBar('Not authenticated');
      return;
    }

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final code = await OrganizationService.getInviteCode(token);
      if (mounted) setState(() => _inviteCode = code);
    } catch (e) {
      _showSnackBar("Error fetching code: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copyToClipboard() async {
    if (_inviteCode == null) return;

    await Clipboard.setData(ClipboardData(text: _inviteCode!));

    if (!mounted) return;
    setState(() => _copied = true);
    _showSnackBar("Invite code copied!");

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _fetchInviteCode,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_inviteCode == null ? "Invite Drivers" : "Get New Code"),
            ),
            if (_inviteCode != null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _copied ? Colors.green[300] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    SelectableText(
                      _inviteCode!,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _copyToClipboard,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _copied ? Colors.green : Colors.grey[300],
                        ),
                        child: const Icon(
                          Icons.copy,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
