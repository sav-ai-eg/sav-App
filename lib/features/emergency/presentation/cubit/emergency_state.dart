part of 'emergency_cubit.dart';

abstract class EmergencyState {
  const EmergencyState();
}

class EmergencyInitial extends EmergencyState {
  const EmergencyInitial();
}

class EmergencyTypeSelected extends EmergencyState {
  final EmergencyType type;
  const EmergencyTypeSelected(this.type);
}

class EmergencyLoading extends EmergencyState {
  const EmergencyLoading();
}

class EmergencyTriggered extends EmergencyState {
  final EmergencyType type;
  const EmergencyTriggered(this.type);
}

class EmergencyError extends EmergencyState {
  final String message;
  const EmergencyError(this.message);
}
