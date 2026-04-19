import 'package:intl/intl.dart';

class HomeTripHistoryQueryParams {
  const HomeTripHistoryQueryParams({
    this.startDate,
    this.endDate,
    this.page = 1,
    this.pageSize = 100,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int pageSize;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'page': page, 'page_size': pageSize};

    if (startDate != null) {
      map['start_date'] = DateFormat('yyyy-MM-dd').format(startDate!);
    }

    if (endDate != null) {
      map['end_date'] = DateFormat('yyyy-MM-dd').format(endDate!);
    }

    return map;
  }
}
