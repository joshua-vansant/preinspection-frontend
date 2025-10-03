import 'package:intl/intl.dart';

dynamic parseUtcToLocal(String utcString, {bool asDateTime = false}) {
  try {
    final utcDateTime = DateTime.parse(utcString).toUtc();
    final localDateTime = utcDateTime.toLocal();

    if (asDateTime) {
      return localDateTime;
    }

    final formatter = DateFormat("M/d/yyyy h:mm a");
    return formatter.format(localDateTime);
  } catch (e) {
    return asDateTime ? null : utcString;
  }
}
