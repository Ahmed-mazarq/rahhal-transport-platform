import 'package:cloud_firestore/cloud_firestore.dart';

class DateParser {
  static DateTime parse(dynamic val, {DateTime? fallback}) {
    if (val == null) return fallback ?? DateTime.now();

    if (val is Timestamp) {
      return val.toDate();
    }

    if (val is String) {
      return DateTime.tryParse(val) ?? fallback ?? DateTime.now();
    }

    if (val is int) {
      return DateTime.fromMillisecondsSinceEpoch(val);
    }

    return fallback ?? DateTime.now();
  }

  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${formatTime(date)}';
  }
}
