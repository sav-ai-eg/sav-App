import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Driver ───────────────────────────────────────────────────
  CollectionReference get _driversCollection =>
      _firestore.collection('drivers');

  Future<void> saveDriver({
    required String driverId,
    required Map<String, dynamic> data,
  }) async {
    await _driversCollection.doc(driverId).set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot> getDriver(String driverId) async {
    return await _driversCollection.doc(driverId).get();
  }

  Future<QuerySnapshot> getDriverByPhone(String phone) async {
    return await _driversCollection
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
  }

  // ─── Trips ────────────────────────────────────────────────────
  CollectionReference _tripsCollection(String driverId) =>
      _driversCollection.doc(driverId).collection('trips');

  Future<void> saveTrip({
    required String driverId,
    required String tripId,
    required Map<String, dynamic> data,
  }) async {
    await _tripsCollection(driverId).doc(tripId).set(data);
  }

  Future<void> updateTrip({
    required String driverId,
    required String tripId,
    required Map<String, dynamic> data,
  }) async {
    await _tripsCollection(driverId).doc(tripId).update(data);
  }

  Stream<QuerySnapshot> getTripsStream(String driverId) {
    return _tripsCollection(driverId)
        .orderBy('startTime', descending: true)
        .snapshots();
  }

  Future<QuerySnapshot> getTrips(String driverId) async {
    return await _tripsCollection(driverId)
        .orderBy('startTime', descending: true)
        .get();
  }

  // ─── Alerts ───────────────────────────────────────────────────
  CollectionReference _alertsCollection(String driverId) =>
      _driversCollection.doc(driverId).collection('alerts');

  Future<void> saveAlert({
    required String driverId,
    required Map<String, dynamic> data,
  }) async {
    await _alertsCollection(driverId).add(data);
  }

  Stream<QuerySnapshot> getAlertsStream(String driverId) {
    return _alertsCollection(driverId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ─── Emergency ────────────────────────────────────────────────
  CollectionReference get _emergenciesCollection =>
      _firestore.collection('emergencies');

  Future<void> saveEmergency({
    required Map<String, dynamic> data,
  }) async {
    await _emergenciesCollection.add(data);
  }

  // ─── Statistics ───────────────────────────────────────────────
  Future<void> updateDriverStatistics({
    required String driverId,
    required Map<String, dynamic> stats,
  }) async {
    final updates = <String, dynamic>{
      'lastUpdated': FieldValue.serverTimestamp(),
    };
    for (final entry in stats.entries) {
      updates['statistics.${entry.key}'] = entry.value;
    }
    await _driversCollection.doc(driverId).update(updates);
  }

  Stream<DocumentSnapshot> getDriverStream(String driverId) {
    return _driversCollection.doc(driverId).snapshots();
  }

  // ─── Location (Fleet Tracking) ────────────────────────────────
  Future<void> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
  }) async {
    await _driversCollection.doc(driverId).update({
      'location': {
        'latitude': latitude,
        'longitude': longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    });
  }

  // ─── Trip Alert Counters (Atomic) ─────────────────────────────
  Future<void> incrementTripAlerts({
    required String driverId,
    required String tripId,
    required String alertType,
  }) async {
    final Map<String, dynamic> updates = {
      'alerts': FieldValue.increment(1),
    };
    if (alertType == 'drowsiness') {
      updates['drowsinessAlerts'] = FieldValue.increment(1);
    } else if (alertType == 'yawn') {
      updates['distractionAlerts'] = FieldValue.increment(1);
    }
    await _tripsCollection(driverId).doc(tripId).update(updates);
  }

  // ─── Trip Awake % ─────────────────────────────────────────────
  Future<void> updateTripAwakePercentage({
    required String driverId,
    required String tripId,
    required double percentage,
  }) async {
    await _tripsCollection(driverId).doc(tripId).update({
      'awakePercentage': percentage,
    });
  }

  // ─── Today's Statistics ───────────────────────────────────────
  Future<Map<String, dynamic>> getTodayStatistics(String driverId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final snapshot = await _tripsCollection(driverId)
        .where('startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('startTime', isLessThan: Timestamp.fromDate(todayEnd))
        .get();

    int totalTrips = snapshot.docs.length;
    int totalAlerts = 0;
    int totalDrowsinessAlerts = 0;
    int totalDistractionAlerts = 0;
    int totalDurationMinutes = 0;
    double avgAwake = 100.0;
    List<double> awakePercentages = [];

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalAlerts += (data['alerts'] as int?) ?? 0;
      totalDrowsinessAlerts += (data['drowsinessAlerts'] as int?) ?? 0;
      totalDistractionAlerts += (data['distractionAlerts'] as int?) ?? 0;

      if (data['awakePercentage'] != null) {
        awakePercentages.add((data['awakePercentage'] as num).toDouble());
      }

      // Parse duration
      final startTime = (data['startTime'] as Timestamp?)?.toDate();
      final endTime = (data['endTime'] as Timestamp?)?.toDate();
      if (startTime != null && endTime != null) {
        totalDurationMinutes += endTime.difference(startTime).inMinutes;
      }
    }

    if (awakePercentages.isNotEmpty) {
      avgAwake = awakePercentages.reduce((a, b) => a + b) /
          awakePercentages.length;
    }

    return {
      'totalTrips': totalTrips,
      'totalAlerts': totalAlerts,
      'totalDrowsinessAlerts': totalDrowsinessAlerts,
      'totalDistractionAlerts': totalDistractionAlerts,
      'totalDurationMinutes': totalDurationMinutes,
      'awakePercentage': avgAwake,
    };
  }

  // ─── Week Trip Activity ───────────────────────────────────────
  Future<Map<int, bool>> getWeekActivity(String driverId) async {
    final now = DateTime.now();
    // Start from Saturday (weekday 6)
    final daysFromSat = (now.weekday % 7 + 1);
    final weekStart =
        DateTime(now.year, now.month, now.day).subtract(Duration(days: daysFromSat));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final snapshot = await _tripsCollection(driverId)
        .where('startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .where('startTime', isLessThan: Timestamp.fromDate(weekEnd))
        .get();

    // Map: weekday (1=Mon..7=Sun) → had trip
    final Map<int, bool> activity = {};
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final startTime = (data['startTime'] as Timestamp?)?.toDate();
      if (startTime != null) {
        activity[startTime.weekday] = true;
      }
    }
    return activity;
  }
}
