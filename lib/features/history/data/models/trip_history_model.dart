import 'package:intl/intl.dart';
import 'package:sav/features/trip/domain/entities/trip_entity.dart';

class TripHistoryModel {
  const TripHistoryModel({
    this.id,
    required this.date,
    required this.from,
    required this.to,
    required this.duration,
    required this.distance,
    required this.alerts,
    this.status,
    this.startTime,
    this.endTime,
  });

  final String? id;
  final String date;
  final String from;
  final String to;
  final String duration;
  final String distance;
  final int alerts;
  final String? status;
  final DateTime? startTime;
  final DateTime? endTime;

  String get route => '$from to $to';

  String get compactFrom => _compactAddress(from);

  String get compactTo => _compactAddress(to);

  String get displayDuration =>
      duration.trim().isEmpty ? '--' : duration.trim();

  String get displayDistance =>
      distance.trim().isEmpty ? '--' : distance.trim();

  String get displayStatus {
    final normalized = status?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'Finished';
    }

    return normalized
        .split('_')
        .where((segment) => segment.trim().isNotEmpty)
        .map(
          (segment) =>
              '${segment[0].toUpperCase()}${segment.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  factory TripHistoryModel.fromTripEntity(TripEntity trip) {
    final formattedDate = DateFormat('dd MMM yyyy - h:mm a').format(
      trip.startTime,
    );

    final duration = (trip.duration ?? '').trim().isNotEmpty
        ? trip.duration!.trim()
        : _durationFromSeconds(trip.durationSeconds);

    return TripHistoryModel(
      id: trip.id,
      date: formattedDate,
      from: trip.from,
      to: trip.to,
      duration: duration,
      distance: (trip.distance ?? '').trim(),
      alerts: trip.alerts,
      status: trip.status,
      startTime: trip.startTime,
      endTime: trip.endTime,
    );
  }

  factory TripHistoryModel.fromCacheMap(Map<String, dynamic> map) {
    return TripHistoryModel(
      id: (map['id'] ?? '').toString(),
      date: (map['date'] ?? '').toString(),
      from: (map['from'] ?? '').toString(),
      to: (map['to'] ?? '').toString(),
      duration: (map['duration'] ?? '').toString(),
      distance: (map['distance'] ?? '').toString(),
      alerts: _toInt(map['alerts']),
      status: (map['status'] ?? '').toString(),
      startTime: _toDateTime(map['startTime']),
      endTime: _toDateTime(map['endTime']),
    );
  }

  Map<String, dynamic> toCacheMap() {
    return <String, dynamic>{
      'id': id,
      'date': date,
      'from': from,
      'to': to,
      'duration': duration,
      'distance': distance,
      'alerts': alerts,
      'status': status,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  static String _compactAddress(String value) {
    final parts = value
        .split(',')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'Unknown location';
    }

    if (parts.length == 1) {
      return parts.first;
    }

    final first = parts.first;
    final trailing = parts.length > 2 ? parts[parts.length - 2] : parts.last;

    if (first.toLowerCase() == trailing.toLowerCase()) {
      return first;
    }

    return '$first, $trailing';
  }

  static String _durationFromSeconds(int seconds) {
    if (seconds <= 0) {
      return '';
    }

    final totalMinutes = (seconds / 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0) {
      return '$hours h, $minutes min';
    }

    return '$totalMinutes min';
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
