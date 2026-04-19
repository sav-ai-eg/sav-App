import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/core/errors/exceptions.dart';
import 'package:sav/features/home/data/datasources/home_local_data_source.dart';
import 'package:sav/features/home/data/models/home_dashboard_model.dart';

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  HomeLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<void> cacheDashboard({required HomeDashboardModel dashboard}) async {
    try {
      await _prefs.setString(
        AppConstants.prefHomeDashboardCache,
        jsonEncode(dashboard.toMap()),
      );
      await _prefs.setInt(
        AppConstants.prefHomeDashboardCacheAt,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      throw const CacheException('Unable to cache dashboard data locally.');
    }
  }

  @override
  HomeDashboardModel? getCachedDashboard() {
    final cachedJson = _prefs.getString(AppConstants.prefHomeDashboardCache);
    if (cachedJson == null || cachedJson.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(cachedJson);
      if (decoded is Map<String, dynamic>) {
        return HomeDashboardModel.fromMap(decoded);
      }

      if (decoded is Map) {
        return HomeDashboardModel.fromMap(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  @override
  DateTime? getCachedDashboardAt() {
    final timestamp = _prefs.getInt(AppConstants.prefHomeDashboardCacheAt);
    if (timestamp == null || timestamp <= 0) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  @override
  Future<void> clearCache() async {
    await Future.wait(<Future<bool>>[
      _prefs.remove(AppConstants.prefHomeDashboardCache),
      _prefs.remove(AppConstants.prefHomeDashboardCacheAt),
    ]);
  }
}
