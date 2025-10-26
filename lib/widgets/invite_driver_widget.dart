import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/utils/ui_helpers.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import '../providers/auth_provider.dart';
import '../services/organization_service.dart';

class InviteDriverWidget extends StatefulWidget {
  final GlobalKey? showcaseKey;

  const InviteDriverWidget({super.key, this.showcaseKey});

  @override
  State<InviteDriverWidget> createState() => _InviteDriverWidgetState();
}

class _InviteDriverWidgetState extends State<InviteDriverWidget> {
  String? _inviteCode;
  bool _loading = false;
  bool _copied = false;

  Future<void> _fetchInviteCode() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      UIHelpers.showError(context, "Not authenticated");
      return;
    }

    setState(() {
      _loading = true;
      _copied = false;
    });

    try {
      final code = _inviteCode == null
          ? await OrganizationService.getInviteCode(token)
          : await OrganizationService.getNewCode(token);

      setState(() => _inviteCode = code);
    } catch (e) {
      UIHelpers.showError(context, "Error fetching invite code: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _copyToClipboard() async {
    if (_inviteCode == null) return;

    await Clipboard.setData(ClipboardData(text: _inviteCode!));
    setState(() => _copied = true);
    UIHelpers.showSuccess(context, "Invite code copied!");

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.person_add_alt_1_rounded,
                      color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    "Invite Drivers",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (widget.showcaseKey != null)
                    Showcase(
                      key: widget.showcaseKey!,
                      description:
                          "Generate an invite code to add new drivers to your organization.",
                      child: _buildInviteButton(colorScheme),
                    )
                  else
                    _buildInviteButton(colorScheme),
                  if (_inviteCode != null) ...[
                    const SizedBox(width: 12),
                    Expanded(child: _buildInviteCodeBox(isDark, colorScheme)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInviteButton(ColorScheme colorScheme) {
    return ElevatedButton.icon(
      onPressed: _loading ? null : _fetchInviteCode,
      icon: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.qr_code_2_rounded, size: 20),
      label: Text(
        _loading
            ? "Loading..."
            : _inviteCode == null
                ? "Generate Code"
                : "New Code",
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildInviteCodeBox(bool isDark, ColorScheme colorScheme) {
    final backgroundColor = _copied
        ? Colors.green[300]
        : isDark
            ? Colors.grey[850]
            : Colors.grey[200];

    final textColor = isDark ? Colors.white : Colors.black;
    final iconBg = _copied
        ? Colors.green
        : isDark
            ? Colors.grey[700]
            : Colors.grey[300];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              _inviteCode!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _copyToClipboard,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBg,
              ),
              child: const Icon(Icons.copy, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
