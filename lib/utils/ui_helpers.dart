import 'dart:convert';
import 'package:flutter/material.dart';

class UIHelpers {
  /// Public API: show a user-friendly error. Accepts raw strings that may
  /// contain JSON or extra prefixes (Exception:, stack, etc).
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

  /// Make the raw parsing available to other parts of the app (providers)
  /// so they can set clean `_error` values early.
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

  /// Try many sensible things to produce a short, user-friendly error:
  /// 1) parse raw as JSON
  /// 2) extract JSON substring (first { ... } or [ ... ]) then parse
  /// 3) regex-extract "error" or "errors" values
  /// 4) trim common prefixes like "Exception:" and return the remainder
  /// 5) fallback to the raw string
  static String _parseBackendError(String raw) {
    if (raw == null) return 'An unknown error occurred';
    final msg = raw.trim();
    if (msg.isEmpty) return 'An unknown error occurred';

    // 1) direct JSON parse
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

    // 2) try to find a JSON object substring { ... }
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

    // 2b) try to find JSON array substring [ ... ]
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

    // 3) regex: extract "error": "..." inside the string
    // final errorRegex = RegExp(r'"error"\s*:\s*"([^"]+)"');
    // final match = errorRegex.firstMatch(msg);
    // if (match != null) return match.group(1)!;

    // // 3b) regex for "errors": ["a","b"]
    // final errorsRegex = RegExp(r'"errors"\s*:\s*\[([^\]]+)\]');
    // final matchErrors = errorsRegex.firstMatch(msg);
    // if (matchErrors != null) {
    //   final content = matchErrors.group(1)!;
    //   final parts = content
    //       .split(',')
    //       .map((s) => s.replaceAll(RegExp(r'["\']'), '').trim())
    //       .where((s) => s.isNotEmpty)
    //       .toList();
    //   if (parts.isNotEmpty) return parts.join('; ');
    // }

    // 4) trim common prefixes (e.g. "Exception: ...", "Failed to submit inspection:")
    // Return the remainder if it's reasonably short/meaningful.
    final prefixTrimmed = msg.replaceFirst(RegExp(r'^[A-Za-z0-9_.\s:-]{0,80}?(:\s*)'), '');
    if (prefixTrimmed.isNotEmpty && prefixTrimmed.length < msg.length) {
      // If the trimmed part is sensible (not huge stack trace), return it
      if (prefixTrimmed.length < 240) return prefixTrimmed;
    }

    // 5) fallback
    // As last resort, return the original message but shortened if it's huge
    if (msg.length > 300) return msg.substring(0, 300) + '...';
    return msg;
  }
}
