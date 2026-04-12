import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:injectable/injectable.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/core/models/detection_result.dart';

/// On-device AI detection service using TFLite interpreters
/// for drowsiness (eye) and yawning detection.
///
/// Replaces the old HTTP-based [AiDetectionService].
/// Runs two YOLOv8 models locally — no network required.
@lazySingleton
class TfliteDetectionService {
  Interpreter? _eyeInterpreter;
  Interpreter? _yawnInterpreter;
  bool _isInitialized = false;
  bool _isBusy = false;

  bool get isInitialized => _isInitialized;
  bool get isBusy => _isBusy;

  // ─── Initialization ─────────────────────────────────────────

  /// Load both TFLite models from assets.
  /// Returns true if at least one model loaded successfully.
  Future<bool> initialize() async {
    try {
      final results = await Future.wait([
        _loadInterpreter(AppConstants.eyeModelAsset),
        _loadInterpreter(AppConstants.yawnModelAsset),
      ]);

      _eyeInterpreter = results[0];
      _yawnInterpreter = results[1];

      _isInitialized =
          _eyeInterpreter != null || _yawnInterpreter != null;

      debugPrint(
        '🧠 TfliteDetectionService: initialized=$_isInitialized '
        '(eye=${_eyeInterpreter != null}, yawn=${_yawnInterpreter != null})',
      );

      return _isInitialized;
    } catch (e) {
      debugPrint('❌ TfliteDetectionService.initialize error: $e');
      _isInitialized = false;
      return false;
    }
  }

  Future<Interpreter?> _loadInterpreter(String assetPath) async {
    try {
      final options = InterpreterOptions()..threads = 2;
      // Try GPU delegate first, fall back to CPU
      try {
        options.addDelegate(GpuDelegateV2());
        debugPrint('🚀 TfliteDetectionService: GPU delegate enabled for $assetPath');
      } catch (_) {
        debugPrint('ℹ️ TfliteDetectionService: Using CPU for $assetPath');
      }

      final interpreter = await Interpreter.fromAsset(
        assetPath,
        options: options,
      );

      debugPrint(
        '✅ TfliteDetectionService: Loaded $assetPath '
        '(input=${interpreter.getInputTensors().map((t) => t.shape)}, '
        'output=${interpreter.getOutputTensors().map((t) => t.shape)})',
      );

      return interpreter;
    } catch (e) {
      debugPrint('❌ TfliteDetectionService: Failed to load $assetPath: $e');
      return null;
    }
  }

  // ─── Detection ──────────────────────────────────────────────

  /// Run detection on a camera frame (JPEG bytes).
  ///
  /// Returns a [DetectionResult] or null if detection fails.
  /// Thread-safe: skips if a detection is already running.
  Future<DetectionResult?> detectFrame(Uint8List jpegBytes) async {
    if (!_isInitialized || _isBusy) return null;
    _isBusy = true;

    try {
      // Preprocess the image on a background isolate
      final inputTensor = await compute(_preprocessImage, jpegBytes);
      if (inputTensor == null) {
        _isBusy = false;
        return null;
      }

      // Run both models
      List<List<double>> eyeDetections = [];
      List<List<double>> yawnDetections = [];

      if (_eyeInterpreter != null) {
        eyeDetections = _runModel(_eyeInterpreter!, inputTensor);
      }
      if (_yawnInterpreter != null) {
        yawnDetections = _runModel(_yawnInterpreter!, inputTensor);
      }

      final result = DetectionResult.fromModelOutput(
        eyeDetections: eyeDetections,
        yawnDetections: yawnDetections,
        confidenceThreshold: AppConstants.detectionConfidenceThreshold,
      );

      debugPrint('🔍 TfliteDetection: $result');
      _isBusy = false;
      return result;
    } catch (e) {
      debugPrint('❌ TfliteDetectionService.detectFrame error: $e');
      _isBusy = false;
      return null;
    }
  }

  /// Run a single YOLOv8 TFLite model and parse its output.
  ///
  /// YOLOv8 TFLite output shape: [1, numDetections, 6]
  /// where each detection = [x_center, y_center, width, height, confidence, classId]
  ///
  /// Some exports have shape [1, 6, numDetections] (transposed).
  List<List<double>> _runModel(
    Interpreter interpreter,
    List<List<List<List<double>>>> input,
  ) {
    try {
      final outputTensors = interpreter.getOutputTensors();
      final outputShape = outputTensors.first.shape;

      // Allocate output buffer matching model output shape
      final output = _allocateOutput(outputShape);
      interpreter.run(input, output);

      return _parseYoloOutput(output, outputShape);
    } catch (e) {
      debugPrint('❌ TfliteDetectionService._runModel error: $e');
      return [];
    }
  }

  /// Allocate output buffer based on the model's output tensor shape.
  dynamic _allocateOutput(List<int> shape) {
    if (shape.length == 3) {
      // [1, N, 6] or [1, 6, N]
      return List.generate(
        shape[0],
        (_) => List.generate(
          shape[1],
          (_) => List.filled(shape[2], 0.0),
        ),
      );
    }
    // Fallback: 2D output [1, N]
    return List.generate(
      shape[0],
      (_) => List.filled(shape[1], 0.0),
    );
  }

  /// Parse YOLOv8 output into a list of detections.
  /// Handles both [1, numDet, 6] and [1, 6, numDet] layouts.
  List<List<double>> _parseYoloOutput(dynamic output, List<int> shape) {
    final detections = <List<double>>[];

    if (shape.length != 3) return detections;

    final batch = output[0] as List;
    final dim1 = shape[1];
    final dim2 = shape[2];

    // Determine layout
    final bool isTransposed = dim1 <= 10 && dim2 > 10;
    // If transposed: [1, 6, N] → iterate over N (dim2)
    // If normal:     [1, N, 6] → iterate over N (dim1)

    final int numDetections = isTransposed ? dim2 : dim1;
    final int numFields = isTransposed ? dim1 : dim2;

    if (numFields < 5) return detections; // need at least x,y,w,h,conf

    for (int i = 0; i < numDetections; i++) {
      final List<double> values;
      if (isTransposed) {
        values = List.generate(numFields, (f) => (batch[f][i] as num).toDouble());
      } else {
        values = List.generate(numFields, (f) => (batch[i][f] as num).toDouble());
      }

      // YOLOv8 detection format:
      // If numFields == 6: [x, y, w, h, conf, classId]
      // If numFields > 6:  [x, y, w, h, class0_conf, class1_conf, ...]
      double confidence;
      int classId;

      if (numFields == 6) {
        confidence = values[4];
        classId = values[5].toInt();
      } else {
        // Multi-class: pick best class from index 4 onward
        classId = 0;
        confidence = values[4];
        for (int c = 5; c < numFields; c++) {
          if (values[c] > confidence) {
            confidence = values[c];
            classId = c - 4;
          }
        }
      }

      if (confidence >= AppConstants.detectionConfidenceThreshold) {
        detections.add([
          values[0], // x
          values[1], // y
          values[2], // w
          values[3], // h
          confidence,
          classId.toDouble(),
        ]);
      }
    }

    // Apply simple NMS (Non-Maximum Suppression)
    return _nms(detections, iouThreshold: 0.5);
  }

  /// Simple NMS to remove overlapping detections.
  List<List<double>> _nms(List<List<double>> detections,
      {double iouThreshold = 0.5}) {
    if (detections.length <= 1) return detections;

    // Sort by confidence descending
    detections.sort((a, b) => b[4].compareTo(a[4]));

    final kept = <List<double>>[];
    final suppressed = List.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;
      kept.add(detections[i]);

      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;
        if (_iou(detections[i], detections[j]) >= iouThreshold) {
          suppressed[j] = true;
        }
      }
    }
    return kept;
  }

  /// Calculate Intersection over Union for two [x, y, w, h, ...] boxes.
  double _iou(List<double> a, List<double> b) {
    final aX1 = a[0] - a[2] / 2, aY1 = a[1] - a[3] / 2;
    final aX2 = a[0] + a[2] / 2, aY2 = a[1] + a[3] / 2;
    final bX1 = b[0] - b[2] / 2, bY1 = b[1] - b[3] / 2;
    final bX2 = b[0] + b[2] / 2, bY2 = b[1] + b[3] / 2;

    final interX1 = aX1 > bX1 ? aX1 : bX1;
    final interY1 = aY1 > bY1 ? aY1 : bY1;
    final interX2 = aX2 < bX2 ? aX2 : bX2;
    final interY2 = aY2 < bY2 ? aY2 : bY2;

    final interW = (interX2 - interX1) > 0 ? (interX2 - interX1) : 0.0;
    final interH = (interY2 - interY1) > 0 ? (interY2 - interY1) : 0.0;
    final interArea = interW * interH;

    final aArea = a[2] * a[3];
    final bArea = b[2] * b[3];
    final unionArea = aArea + bArea - interArea;

    return unionArea > 0 ? interArea / unionArea : 0.0;
  }

  // ─── Preprocessing (runs in isolate via compute) ────────────

  /// Decode JPEG → resize to 320×320 → normalize to [0, 1] float32.
  /// Returns shape [1, 320, 320, 3].
  static List<List<List<List<double>>>>? _preprocessImage(
      Uint8List jpegBytes) {
    try {
      final decoded = img.decodeJpg(jpegBytes);
      if (decoded == null) return null;

      final size = AppConstants.modelInputSize;
      final resized = img.copyResize(decoded, width: size, height: size);

      // Build [1, H, W, 3] float32 tensor
      final input = List.generate(
        1,
        (_) => List.generate(
          size,
          (y) => List.generate(
            size,
            (x) {
              final pixel = resized.getPixel(x, y);
              return [
                pixel.r / 255.0,
                pixel.g / 255.0,
                pixel.b / 255.0,
              ];
            },
          ),
        ),
      );

      return input;
    } catch (e) {
      debugPrint('❌ _preprocessImage error: $e');
      return null;
    }
  }

  // ─── Dispose ────────────────────────────────────────────────

  void dispose() {
    _eyeInterpreter?.close();
    _yawnInterpreter?.close();
    _eyeInterpreter = null;
    _yawnInterpreter = null;
    _isInitialized = false;
    _isBusy = false;
    debugPrint('🧠 TfliteDetectionService: disposed');
  }
}
