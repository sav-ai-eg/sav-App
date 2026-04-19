import 'package:sav/features/home/data/models/home_dashboard_model.dart';

abstract class HomeLocalDataSource {
  Future<void> cacheDashboard({required HomeDashboardModel dashboard});

  HomeDashboardModel? getCachedDashboard();

  DateTime? getCachedDashboardAt();

  Future<void> clearCache();
}
