import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/constants/app_constants.dart';

/// Offline store-and-forward cache using Hive.
///
/// Caches alerts and location updates when the device is offline.
/// Synced to Firestore when connectivity is restored.
@lazySingleton
class OfflineCacheService {
  Box? _alertsBox;
  Box? _locationsBox;
  Box? _settingsBox;

  bool get isInitialized =>
      _alertsBox != null && _locationsBox != null && _settingsBox != null;

  // ─── Initialization ─────────────────────────────────────────

  /// Open all Hive boxes. Call once at app startup.
  Future<void> initialize() async {
    try {
      _alertsBox = await Hive.openBox(AppConstants.pendingAlertsBox);
      _locationsBox = await Hive.openBox(AppConstants.pendingLocationsBox);
      _settingsBox = await Hive.openBox(AppConstants.appSettingsBox);
      debugPrint('💾 OfflineCacheService: initialized '
          '(alerts=${_alertsBox!.length}, locations=${_locationsBox!.length})');
    } catch (e) {
      debugPrint('❌ OfflineCacheService.initialize error: $e');
    }
  }

  // ─── Alert Cache ────────────────────────────────────────────

  /// Cache an alert for later Firestore sync.
  Future<void> cacheAlert(Map<String, dynamic> alertData) async {
    try {
      if (_alertsBox == null) return;
      // Store as JSON string to avoid Hive type issues
      final jsonStr = jsonEncode(_sanitizeForCache(alertData));
      await _alertsBox!.add(jsonStr);
      debugPrint('💾 Cached alert (pending: ${_alertsBox!.length})');
    } catch (e) {
      debugPrint('❌ OfflineCacheService.cacheAlert error: $e');
    }
  }

  /// Get all pending alerts and clear the cache.
  /// Returns a list of alert data maps.
  Future<List<Map<String, dynamic>>> drainAlerts() async {
    if (_alertsBox == null || _alertsBox!.isEmpty) return [];

    try {
      final alerts = <Map<String, dynamic>>[];
      for (final value in _alertsBox!.values) {
        try {
          final map = jsonDecode(value as String) as Map<String, dynamic>;
          alerts.add(map);
        } catch (_) {
          // Skip malformed entries
        }
      }
      await _alertsBox!.clear();
      debugPrint('💾 Drained ${alerts.length} pending alerts');
      return alerts;
    } catch (e) {
      debugPrint('❌ OfflineCacheService.drainAlerts error: $e');
      return [];
    }
  }

  /// Number of pending alerts.
  int get pendingAlertCount => _alertsBox?.length ?? 0;

  // ─── Location Cache ─────────────────────────────────────────

  /// Cache a location update for later Firestore sync.
  Future<void> cacheLocation(Map<String, dynamic> locationData) async {
    try {
      if (_locationsBox == null) return;
      final jsonStr = jsonEncode(_sanitizeForCache(locationData));
      await _locationsBox!.add(jsonStr);
    } catch (e) {
      debugPrint('❌ OfflineCacheService.cacheLocation error: $e');
    }
  }

  /// Get all pending locations and clear the cache.
  Future<List<Map<String, dynamic>>> drainLocations() async {
    if (_locationsBox == null || _locationsBox!.isEmpty) return [];

    try {
      final locations = <Map<String, dynamic>>[];
      for (final value in _locationsBox!.values) {
        try {
          final map = jsonDecode(value as String) as Map<String, dynamic>;
          locations.add(map);
        } catch (_) {}
      }
      await _locationsBox!.clear();
      debugPrint('💾 Drained ${locations.length} pending locations');
      return locations;
    } catch (e) {
      debugPrint('❌ OfflineCacheService.drainLocations error: $e');
      return [];
    }
  }

  /// Number of pending location updates.
  int get pendingLocationCount => _locationsBox?.length ?? 0;

  /// Total pending items across all caches.
  int get totalPendingCount => pendingAlertCount + pendingLocationCount;

  // ─── Settings Cache ─────────────────────────────────────────

  /// Store a setting value.
  Future<void> putSetting(String key, dynamic value) async {
    try {
      await _settingsBox?.put(key, value);
    } catch (e) {
      debugPrint('❌ OfflineCacheService.putSetting error: $e');
    }
  }

  /// Get a setting value.
  T? getSetting<T>(String key, {T? defaultValue}) {
    try {
      return _settingsBox?.get(key, defaultValue: defaultValue) as T?;
    } catch (_) {
      return defaultValue;
    }
  }

  // ─── Helpers ────────────────────────────────────────────────

  /// Remove non-JSON-serializable values (like FieldValue.serverTimestamp).
  Map<String, dynamic> _sanitizeForCache(Map<String, dynamic> data) {
    final clean = <String, dynamic>{};
    for (final entry in data.entries) {
      final value = entry.value;
      if (value is String ||
          value is num ||
          value is bool ||
          value == null) {
        clean[entry.key] = value;
      } else if (value is DateTime) {
        clean[entry.key] = value.toIso8601String();
      } else if (value is Map) {
        clean[entry.key] = _sanitizeForCache(Map<String, dynamic>.from(value));
      } else if (value is List) {
        clean[entry.key] = value
            .map((e) => e is Map
                ? _sanitizeForCache(Map<String, dynamic>.from(e))
                : e)
            .toList();
      }
      // Skip FieldValue, Timestamp, etc.
    }
    return clean;
  }

  // ─── Dispose ────────────────────────────────────────────────

  Future<void> dispose() async {
    await _alertsBox?.close();
    await _locationsBox?.close();
    await _settingsBox?.close();
    debugPrint('💾 OfflineCacheService: disposed');
  }
}
