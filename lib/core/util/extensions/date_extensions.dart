import 'package:intl/intl.dart';

/// Utility extensions for [DateTime].
extension DateTimeExtension on DateTime {
  /// e.g. "21 Feb 2026"
  String get formatted => DateFormat('dd MMM yyyy').format(this);

  /// e.g. "21 Feb 2026 - 3:45 PM"
  String get formattedWithTime => DateFormat('dd MMM yyyy - h:mm a').format(this);

  /// e.g. "3:45 PM"
  String get timeOnly => DateFormat('h:mm a').format(this);

  /// e.g. "Feb 21"
  String get shortDate => DateFormat('MMM dd').format(this);

  /// Returns true if this date is the same calendar day as [other].
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Returns start of day (00:00:00).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Returns end of day (23:59:59.999).
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);
}
