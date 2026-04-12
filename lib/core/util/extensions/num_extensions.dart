/// Utility extensions for [num] (distance formatting).
extension NumExtension on num {
  /// Format meters as distance string (e.g., "1.5 KM" or "450 m").
  String get formattedDistance {
    if (this < 1000) return '${toInt()} m';
    return '${(this / 1000).toStringAsFixed(1)} KM';
  }

  /// Format as percentage string (e.g., "85%").
  String get percentString => '${toStringAsFixed(0)}%';
}
