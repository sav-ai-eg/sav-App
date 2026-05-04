class VehicleInfo {
  const VehicleInfo({
    required this.id,
    required this.plateNumber,
    required this.modelName,
    required this.status,
    required this.mileageKm,
  });

  final int id;
  final String plateNumber;
  final String modelName;
  final String status;
  final int mileageKm;

  factory VehicleInfo.fromMap(Map<String, dynamic> map) {
    return VehicleInfo(
      id: _toInt(map['id']),
      plateNumber: _toString(map['plate_number']).toUpperCase(),
      modelName: _toString(map['model_name']),
      status: _toString(map['status']),
      mileageKm: _toInt(map['mileage_km']),
    );
  }

  String get statusLabel {
    if (status.isEmpty) {
      return '';
    }

    final normalized = status.toLowerCase();
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  static String _toString(dynamic value) {
    return (value ?? '').toString().trim();
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse((value ?? '').toString()) ?? 0;
  }
}
