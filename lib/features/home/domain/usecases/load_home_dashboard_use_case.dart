import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/home/domain/entities/home_dashboard_entity.dart';
import 'package:sav/features/home/domain/repositories/home_repository.dart';

@injectable
class LoadHomeDashboardUseCase {
  const LoadHomeDashboardUseCase(this._repository);

  final HomeRepository _repository;

  Future<Either<Failure, HomeDashboardEntity>> call({DateTime? now}) {
    return _repository.loadDashboard(now: now ?? DateTime.now());
  }
}
