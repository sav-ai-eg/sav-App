/// Utility extensions for [Duration].
extension DurationExtension on Duration {
  /// Format as "HH:MM:SS" (e.g., "01:23:45").
  String get formatted {
    final hours = inHours.toString().padLeft(2, '0');
    final minutes = (inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Format as human-readable (e.g., "1h 23min" or "45 min").
  String get humanReadable {
    if (inHours > 0) {
      final m = inMinutes % 60;
      return '${inHours}h ${m}min';
    }
    if (inMinutes > 0) {
      return '$inMinutes min';
    }
    return '${inSeconds}s';
  }
}
