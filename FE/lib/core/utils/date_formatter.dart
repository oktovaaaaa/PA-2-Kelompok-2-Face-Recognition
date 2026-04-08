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

  /// Detects YYYY-MM-DD patterns in a string and replaces them with full Indonesian format
  static String formatInString(String text) {
    if (text.isEmpty) return text;
    
    final dateRegex = RegExp(r'\b\d{4}-\d{2}-\d{2}\b');
    return text.replaceAllMapped(dateRegex, (match) {
      final matchStr = match.group(0)!;
      try {
        final dateTime = DateFormat('yyyy-MM-dd').parse(matchStr);
        return DateFormat('EEEE d MMMM yyyy', 'id').format(dateTime);
      } catch (e) {
        return matchStr;
      }
    });
  }
}
