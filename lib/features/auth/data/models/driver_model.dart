import 'package:cloud_firestore/cloud_firestore.dart';

class DriverModel {
  final String id;
  final String name;
  final String phone;
  final String licenseNumber;
  final String vehiclePlate;
  final String? companyName;
  final String? emergencyContact;
  final DateTime createdAt;
  final Map<String, dynamic>? statistics;

  const DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.licenseNumber,
    required this.vehiclePlate,
    this.companyName,
    this.emergencyContact,
    required this.createdAt,
    this.statistics,
  });

  factory DriverModel.fromMap(Map<String, dynamic> map, String docId) {
    return DriverModel(
      id: docId,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      licenseNumber: map['licenseNumber'] ?? '',
      vehiclePlate: map['vehiclePlate'] ?? '',
      companyName: map['companyName'],
      emergencyContact: map['emergencyContact'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statistics: map['statistics'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'licenseNumber': licenseNumber,
      'vehiclePlate': vehiclePlate,
      'companyName': companyName,
      'emergencyContact': emergencyContact,
      'createdAt': Timestamp.fromDate(createdAt),
      'statistics': statistics,
    };
  }

  DriverModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? licenseNumber,
    String? vehiclePlate,
    String? companyName,
    String? emergencyContact,
    DateTime? createdAt,
    Map<String, dynamic>? statistics,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      companyName: companyName ?? this.companyName,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      createdAt: createdAt ?? this.createdAt,
      statistics: statistics ?? this.statistics,
    );
  }
}
