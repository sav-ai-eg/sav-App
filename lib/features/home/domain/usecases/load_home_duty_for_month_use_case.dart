import 'package:dartz/dartz.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/home/domain/entities/home_duty_level.dart';
import 'package:sav/features/home/domain/repositories/home_repository.dart';

class LoadHomeDutyForMonthUseCase {
  const LoadHomeDutyForMonthUseCase(this._repository);

  final HomeRepository _repository;

  Future<Either<Failure, Map<DateTime, HomeDutyLevel>>> call({
    required DateTime month,
  }) {
    return _repository.loadDutyForMonth(month: month);
  }
}
