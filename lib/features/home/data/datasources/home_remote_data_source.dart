import 'package:sav/features/home/data/models/home_alert_item_model.dart';
import 'package:sav/features/home/data/models/home_trip_history_item_model.dart';

abstract class HomeRemoteDataSource {
  Future<Map<String, dynamic>> fetchDriverFeed();

  Future<List<HomeTripHistoryItemModel>> fetchTripHistory({
    DateTime? startDate,
    DateTime? endDate,
    int pageSize = 100,
    int maxPages = 6,
  });

  Future<List<HomeAlertItemModel>> fetchAlerts();
}
