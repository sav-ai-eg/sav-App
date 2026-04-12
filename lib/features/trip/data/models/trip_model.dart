import 'package:cloud_firestore/cloud_firestore.dart';

class TripModel {
  final String id;
  final String driverId;
  final String from;
  final String to;
  final String? fromPlaceId;
  final String? toPlaceId;
  final double? fromLatitude;
  final double? fromLongitude;
  final double? toLatitude;
  final double? toLongitude;
  final String status; // 'active', 'completed', 'cancelled'
  final DateTime startTime;
  final DateTime? endTime;
  final String? duration;
  final String? distance;
  final int alerts;
  final int drowsinessAlerts;
  final int distractionAlerts;
  final double? awakePercentage;

  const TripModel({
    required this.id,
    required this.driverId,
    required this.from,
    required this.to,
    this.fromPlaceId,
    this.toPlaceId,
    this.fromLatitude,
    this.fromLongitude,
    this.toLatitude,
    this.toLongitude,
    required this.status,
    required this.startTime,
    this.endTime,
    this.duration,
    this.distance,
    this.alerts = 0,
    this.drowsinessAlerts = 0,
    this.distractionAlerts = 0,
    this.awakePercentage,
  });

  factory TripModel.fromMap(Map<String, dynamic> map, String docId) {
    return TripModel(
      id: docId,
      driverId: map['driverId'] ?? '',
      from: map['from'] ?? '',
      to: map['to'] ?? '',
      fromPlaceId: map['fromPlaceId'] as String?,
      toPlaceId: map['toPlaceId'] as String?,
      fromLatitude: (map['fromLatitude'] as num?)?.toDouble(),
      fromLongitude: (map['fromLongitude'] as num?)?.toDouble(),
      toLatitude: (map['toLatitude'] as num?)?.toDouble(),
      toLongitude: (map['toLongitude'] as num?)?.toDouble(),
      status: map['status'] ?? 'active',
      startTime: (map['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (map['endTime'] as Timestamp?)?.toDate(),
      duration: map['duration'],
      distance: map['distance'],
      alerts: map['alerts'] ?? 0,
      drowsinessAlerts: map['drowsinessAlerts'] ?? 0,
      distractionAlerts: map['distractionAlerts'] ?? 0,
      awakePercentage: (map['awakePercentage'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'from': from,
      'to': to,
      'fromPlaceId': fromPlaceId,
      'toPlaceId': toPlaceId,
      'fromLatitude': fromLatitude,
      'fromLongitude': fromLongitude,
      'toLatitude': toLatitude,
      'toLongitude': toLongitude,
      'status': status,
      'startTime': Timestamp.fromDate(startTime),
      if (endTime != null) 'endTime': Timestamp.fromDate(endTime!),
      'duration': duration,
      'distance': distance,
      'alerts': alerts,
      'drowsinessAlerts': drowsinessAlerts,
      'distractionAlerts': distractionAlerts,
      'awakePercentage': awakePercentage,
    };
  }
}
