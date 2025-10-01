import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/organization_service.dart';
import 'join_organization_widget.dart';
import 'package:frontend/utils/ui_helpers.dart';

class DriverDrawerWidget extends StatelessWidget {
  const DriverDrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.role == 'admin';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              "Organization",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          if (authProvider.org == null)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: JoinOrganizationWidget(),
            ),
          if (authProvider.org != null && !isAdmin)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: RedeemAdminInviteWidget(),
            ),
          if (authProvider.org != null)
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text("Leave Organization"),
              onTap: () async {
                final token = authProvider.token;
                if (token == null) {
                  UIHelpers.showError(context, "Not authenticated");
                  return;
                }

                try {
                  await OrganizationService.leaveOrg(token);
                  authProvider.clearOrg();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  UIHelpers.showError(context, "You left the organization");
                } catch (e) {
                  if (!context.mounted) return;
                  UIHelpers.showError(context, "Error leaving org: $e");
                }
              },
            ),
        ],
      ),
    );
  }
}

class RedeemAdminInviteWidget extends StatefulWidget {
  const RedeemAdminInviteWidget({super.key});

  @override
  State<RedeemAdminInviteWidget> createState() =>
      _RedeemAdminInviteWidgetState();
}

class _RedeemAdminInviteWidgetState extends State<RedeemAdminInviteWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _message;

  Future<void> _redeemAdminCode() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    final authProvider = context.read<AuthProvider>();
    final code = _controller.text.trim();
    final token = authProvider.token;

    if (token == null) {
      setState(() {
        _message = "Not authenticated";
        _loading = false;
      });
      return;
    }

    try {
      final result = await OrganizationService.redeemAdminInvite(token, code);
      print("DEBUG: Returned from orgService.redeem");
        authProvider.setUser({...?authProvider.user, 'role': 'admin'});

      await authProvider.loadOrg();
      if(!mounted) return;
      setState(() {
        _message = "Success! You are now an admin.";
      });

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      if(!mounted) return;
      setState(() {
        _message = "Invalid code. Please try again.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    debugPrint("DriverDrawerWidget: role=${authProvider.role}, org=${authProvider.org}");

    return Column(
      children: [
        const Text("Enter admin invite code:"),
        const SizedBox(height: 4),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: "Admin Code",
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _loading ? null : _redeemAdminCode,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Redeem"),
        ),
        if (_message != null) ...[
          const SizedBox(height: 8),
          Text(
            _message!,
            style: TextStyle(
              color: _message!.startsWith("Success") ? Colors.green : Colors.red,
            ),
          ),
        ],
      ],
    );
  }
}
