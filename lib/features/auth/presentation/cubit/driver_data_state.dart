part of 'driver_data_cubit.dart';

abstract class DriverDataState {
  const DriverDataState();
}

class DriverDataInitial extends DriverDataState {
  const DriverDataInitial();
}

class DriverDataLoading extends DriverDataState {
  const DriverDataLoading();
}

class DriverDataSaved extends DriverDataState {
  final DriverModel driver;
  const DriverDataSaved({required this.driver});
}

class DriverDataError extends DriverDataState {
  final String message;
  const DriverDataError({required this.message});
}
