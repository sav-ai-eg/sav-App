import 'package:sav/features/auth/data/models/driver_model.dart';

abstract class SettingsState {
  const SettingsState();
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final DriverModel driver;

  const SettingsLoaded({required this.driver});

  SettingsLoaded copyWith({DriverModel? driver}) {
    return SettingsLoaded(driver: driver ?? this.driver);
  }
}

class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
}
