import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TripHistoryModel {
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
      return 'Completed';
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

  factory TripHistoryModel.fromMap(Map<String, dynamic> map, String docId) {
    final startTime = (map['startTime'] as Timestamp?)?.toDate();
    final endTime = (map['endTime'] as Timestamp?)?.toDate();

    String dateStr = map['date'] ?? '';
    if (dateStr.isEmpty && startTime != null) {
      dateStr = DateFormat('dd MMM yyyy - h:mm a').format(startTime);
    }

    String duration = map['duration'] ?? '';
    if (duration.isEmpty && startTime != null && endTime != null) {
      final diff = endTime.difference(startTime);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      duration = '$hours h , $minutes min';
    }

    return TripHistoryModel(
      id: docId,
      date: dateStr,
      from: map['from'] ?? '',
      to: map['to'] ?? '',
      duration: duration,
      distance: map['distance'] ?? '',
      alerts: map['alerts'] ?? 0,
      status: map['status'],
      startTime: startTime,
      endTime: endTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'from': from,
      'to': to,
      'duration': duration,
      'distance': distance,
      'alerts': alerts,
      'status': status ?? 'completed',
      if (startTime != null) 'startTime': Timestamp.fromDate(startTime!),
      if (endTime != null) 'endTime': Timestamp.fromDate(endTime!),
    };
  }
}
