class TripPlaceModel {
  final String placeId;
  final String title;
  final String subtitle;
  final double? latitude;
  final double? longitude;

  const TripPlaceModel({
    required this.placeId,
    required this.title,
    this.subtitle = '',
    this.latitude,
    this.longitude,
  });

  factory TripPlaceModel.manual(String value) {
    final normalized = value.trim();
    return TripPlaceModel(
      placeId: 'manual_${normalized.toLowerCase().replaceAll(' ', '_')}',
      title: normalized,
    );
  }

  factory TripPlaceModel.fromAutocomplete(Map<String, dynamic> map) {
    final formatting =
        map['structured_formatting'] as Map<String, dynamic>? ?? const {};

    return TripPlaceModel(
      placeId: map['place_id'] as String? ?? '',
      title:
          formatting['main_text'] as String? ??
          map['description'] as String? ??
          '',
      subtitle: formatting['secondary_text'] as String? ?? '',
    );
  }

  TripPlaceModel copyWith({
    String? placeId,
    String? title,
    String? subtitle,
    double? latitude,
    double? longitude,
  }) {
    return TripPlaceModel(
      placeId: placeId ?? this.placeId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  String get fullText {
    if (subtitle.trim().isEmpty) {
      return title.trim();
    }
    return '$title, $subtitle';
  }

  bool get hasCoordinates => latitude != null && longitude != null;
}
