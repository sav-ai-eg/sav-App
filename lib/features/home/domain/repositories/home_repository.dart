import 'package:dartz/dartz.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/home/domain/entities/home_dashboard_entity.dart';
import 'package:sav/features/home/domain/entities/home_duty_level.dart';

abstract class HomeRepository {
  Future<Either<Failure, HomeDashboardEntity>> loadDashboard({
    required DateTime now,
  });

  Future<Either<Failure, Map<DateTime, HomeDutyLevel>>> loadDutyForMonth({
    required DateTime month,
  });
}
