/// Utility extensions for [String].
extension StringExtension on String {
  /// Capitalize first letter.
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Check if string is a valid phone number (basic).
  bool get isValidPhone => RegExp(r'^[0-9+]{8,15}$').hasMatch(trim());

  /// Check if string is a valid URL.
  bool get isValidUrl => Uri.tryParse(this)?.hasAbsolutePath ?? false;

  /// Truncate with ellipsis.
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}
