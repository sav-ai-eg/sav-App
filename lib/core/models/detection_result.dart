/// Result of on-device AI detection for drowsiness / yawning.
class DetectionResult {
  final bool isDrowsy;
  final bool isYawning;
  final bool isDanger;
  final double eyeConfidence;
  final double yawnConfidence;
  final DateTime timestamp;

  const DetectionResult({
    required this.isDrowsy,
    required this.isYawning,
    required this.isDanger,
    required this.eyeConfidence,
    required this.yawnConfidence,
    required this.timestamp,
  });

  /// Create a result from on-device model output tensors.
  ///
  /// [eyeDetections] and [yawnDetections] are lists of detected bounding boxes
  /// from YOLOv8 output. Each detection is [x, y, w, h, confidence, classId].
  factory DetectionResult.fromModelOutput({
    required List<List<double>> eyeDetections,
    required List<List<double>> yawnDetections,
    required double confidenceThreshold,
  }) {
    bool drowsy = false;
    bool yawning = false;
    double eyeConf = 0.0;
    double yawnConf = 0.0;

    // Process eye model detections — class 0 = closed eyes (drowsy)
    for (final det in eyeDetections) {
      if (det.length >= 6) {
        final confidence = det[4];
        final classId = det[5].toInt();
        if (classId == 0 && confidence >= confidenceThreshold) {
          drowsy = true;
          if (confidence > eyeConf) eyeConf = confidence;
        }
      }
    }

    // Process yawn model detections — class 0 = yawning
    for (final det in yawnDetections) {
      if (det.length >= 6) {
        final confidence = det[4];
        final classId = det[5].toInt();
        if (classId == 0 && confidence >= confidenceThreshold) {
          yawning = true;
          if (confidence > yawnConf) yawnConf = confidence;
        }
      }
    }

    return DetectionResult(
      isDrowsy: drowsy,
      isYawning: yawning,
      isDanger: drowsy || yawning,
      eyeConfidence: eyeConf,
      yawnConfidence: yawnConf,
      timestamp: DateTime.now(),
    );
  }

  /// Safe result — no danger detected.
  factory DetectionResult.safe() {
    return DetectionResult(
      isDrowsy: false,
      isYawning: false,
      isDanger: false,
      eyeConfidence: 0.0,
      yawnConfidence: 0.0,
      timestamp: DateTime.now(),
    );
  }

  /// Get the alert type string for Firestore.
  String get alertType {
    if (isDrowsy) return 'drowsiness';
    if (isYawning) return 'yawn';
    return 'safe';
  }

  /// Get the highest confidence value for the detected danger.
  double get maxConfidence {
    if (isDrowsy) return eyeConfidence;
    if (isYawning) return yawnConfidence;
    return 0.0;
  }

  /// Convert to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'isDrowsy': isDrowsy,
      'isYawning': isYawning,
      'isDanger': isDanger,
      'eyeConfidence': eyeConfidence,
      'yawnConfidence': yawnConfidence,
      'type': alertType,
      'confidence': maxConfidence,
      'detectedAt': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'DetectionResult(drowsy=$isDrowsy, yawn=$isYawning, '
      'eyeConf=${eyeConfidence.toStringAsFixed(3)}, '
      'yawnConf=${yawnConfidence.toStringAsFixed(3)})';
}
