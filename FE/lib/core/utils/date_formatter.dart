import 'package:intl/intl.dart';

class AppDateFormatter {
  /// Format: Kamis 1 Juni 2026 (EEEEE d MMMM yyyy)
  /// EEEEE in intl produces the weekday name (e.g., Kamis)
  static String formatFullDate(String dateStr) {
    if (dateStr == '-' || dateStr.isEmpty) return dateStr;
    try {
      DateTime dateTime;
      if (dateStr.contains('T')) {
        dateTime = DateTime.parse(dateStr).toLocal();
      } else {
        dateTime = DateFormat('yyyy-MM-dd').parse(dateStr);
      }
      
      // We use 'id' locale. Make sure to initialize it in main.dart
      return DateFormat('EEEE d MMMM yyyy', 'id').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  /// Format: 1 Juni 2026 (d MMMM yyyy)
  static String formatDate(String dateStr) {
    if (dateStr == '-' || dateStr.isEmpty) return dateStr;
    try {
      DateTime dateTime;
      if (dateStr.contains('T')) {
        dateTime = DateTime.parse(dateStr).toLocal();
      } else {
        dateTime = DateFormat('yyyy-MM-dd').parse(dateStr);
      }
      return DateFormat('d MMMM yyyy', 'id').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }
}
