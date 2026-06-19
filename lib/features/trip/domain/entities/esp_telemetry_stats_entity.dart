import 'package:equatable/equatable.dart';

class EspTelemetryStatsEntity extends Equatable {
  const EspTelemetryStatsEntity({
    required this.total,
    required this.alertsTrue,
    required this.eyesClosed,
    required this.yawn,
    required this.headDown,
    required this.noFace,
  });

  final int total;
  final int alertsTrue;
  final int eyesClosed;
  final int yawn;
  final int headDown;
  final int noFace;

  int get safeCount {
    final safe = total - alertsTrue;
    if (safe < 0) {
      return 0;
    }
    return safe;
  }

  @override
  List<Object?> get props => <Object?>[
    total,
    alertsTrue,
    eyesClosed,
    yawn,
    headDown,
    noFace,
  ];
}
