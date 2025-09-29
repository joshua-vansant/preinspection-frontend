import 'package:intl/intl.dart';


///   parseUtcToLocal("2025-09-29T04:59:00Z");  // "9/29/2025 12:59 AM"
///   parseUtcToLocal("2025-09-29T04:59:00Z", asDateTime: true); // DateTime object
dynamic parseUtcToLocal(String utcString, {bool asDateTime = false}) {
  try {
    final utcDateTime = DateTime.parse(utcString).toUtc();
    final localDateTime = utcDateTime.toLocal();

    if (asDateTime) {
      return localDateTime;
    }

    // Default formatting
    final formatter = DateFormat("M/d/yyyy h:mm a");
    return formatter.format(localDateTime);
  } catch (e) {
    // Fallback
    return asDateTime ? null : utcString;
  }
}
