import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

/// Wraps [Geolocator] for GPS tracking, permission handling,
/// and live location updates to Firestore.
@lazySingleton
class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;

  Position? get lastPosition => _lastPosition;

  // ─── Permissions ────────────────────────────────────────────

  /// Returns true if location services are enabled AND permission granted.
  Future<bool> isReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Request location permission. Returns true if granted.
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  // ─── Current Position ──────────────────────────────────────

  Future<Position?> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _lastPosition = position;
      return position;
    } catch (e) {
      debugPrint('LocationService.getCurrentPosition error: $e');
      return null;
    }
  }

  // ─── Live Tracking ─────────────────────────────────────────

  /// Start real-time location tracking.
  /// [onUpdate] is called with each new position.
  /// [distanceFilter] = minimum meters before next update.
  void startTracking({
    required void Function(Position position) onUpdate,
    int distanceFilter = 10,
  }) {
    stopTracking();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    ).listen(
      (position) {
        _lastPosition = position;
        onUpdate(position);
      },
      onError: (e) {
        debugPrint('LocationService.startTracking error: $e');
      },
    );
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  // ─── Firestore Location Update ─────────────────────────────

  /// Push current driver location to Firestore for fleet tracking.
  Future<void> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .update({
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      debugPrint('LocationService.updateDriverLocation error: $e');
    }
  }

  // ─── Distance Calculation ──────────────────────────────────

  /// Calculate distance in meters between two positions.
  double calculateDistance(Position start, Position end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  // ─── Dispose ───────────────────────────────────────────────

  void dispose() {
    stopTracking();
  }
}
