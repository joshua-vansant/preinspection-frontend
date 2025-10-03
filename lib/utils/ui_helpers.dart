import 'dart:convert';
import 'package:flutter/material.dart';

class UIHelpers {
  static void showError(BuildContext context, String rawMessage) {
    final parsed = _parseBackendError(rawMessage);
    _showSnackBar(
      context,
      parsed,
      backgroundColor: Colors.red.shade600,
      icon: Icons.error_outline,
    );
  }

  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      backgroundColor: Colors.green.shade600,
      icon: Icons.check_circle_outline,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      backgroundColor: Colors.orange.shade700,
      icon: Icons.warning_amber_rounded,
    );
  }


  static String parseError(String rawMessage) => _parseBackendError(rawMessage);

  static void _showSnackBar(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(12),
      ),
    );
  }


  static String _parseBackendError(String raw) {
    final msg = raw.trim();
    if (msg.isEmpty) return 'An unknown error occurred';
    try {
      final decoded = jsonDecode(msg);
      if (decoded is Map) {
        if (decoded.containsKey('error')) return decoded['error'].toString();
        if (decoded.containsKey('errors')) {
          final errs = decoded['errors'];
          if (errs is List) return errs.map((e) => e.toString()).join('; ');
          return errs.toString();
        }
        if (decoded.containsKey('message')) return decoded['message'].toString();
      }
    } catch (_) {}
    final objStart = msg.indexOf('{');
    final objEnd = msg.lastIndexOf('}');
    if (objStart != -1 && objEnd != -1 && objEnd > objStart) {
      final sub = msg.substring(objStart, objEnd + 1);
      try {
        final decoded = jsonDecode(sub);
        if (decoded is Map) {
          if (decoded.containsKey('error')) return decoded['error'].toString();
          if (decoded.containsKey('errors')) {
            final errs = decoded['errors'];
            if (errs is List) return errs.map((e) => e.toString()).join('; ');
            return errs.toString();
          }
          if (decoded.containsKey('message')) return decoded['message'].toString();
        }
      } catch (_) {}
    }
    final arrStart = msg.indexOf('[');
    final arrEnd = msg.lastIndexOf(']');
    if (arrStart != -1 && arrEnd != -1 && arrEnd > arrStart) {
      final sub = msg.substring(arrStart, arrEnd + 1);
      try {
        final decoded = jsonDecode(sub);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded.map((e) => e.toString()).join('; ');
        }
      } catch (_) {}
    }
    final prefixTrimmed = msg.replaceFirst(RegExp(r'^[A-Za-z0-9_.\s:-]{0,80}?(:\s*)'), '');
    if (prefixTrimmed.isNotEmpty && prefixTrimmed.length < msg.length) {
      if (prefixTrimmed.length < 240) return prefixTrimmed;
    }
    if (msg.length > 300) return msg.substring(0, 300) + '...';
    return msg;
  }
}
