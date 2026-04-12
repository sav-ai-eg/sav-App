import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

/// Wraps the [camera] package for front-camera frame capture
/// used by the AI drowsiness detection pipeline.
@lazySingleton
class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  // ─── Initialize ─────────────────────────────────────────────

  /// Initialize the front camera at medium resolution.
  /// Returns true on success.
  Future<bool> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('CameraService: No cameras available');
        return false;
      }

      // Prefer front camera for face detection
      final frontCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('CameraService.initialize error: $e');
      _isInitialized = false;
      return false;
    }
  }

  // ─── Capture Frame ──────────────────────────────────────────

  /// Capture a single JPEG frame and return its bytes.
  /// Returns null if camera is not initialized or capture fails.
  Future<Uint8List?> captureFrame() async {
    if (!_isInitialized || _controller == null) return null;
    if (!_controller!.value.isInitialized) return null;
    if (_controller!.value.isTakingPicture) return null;

    try {
      final xFile = await _controller!.takePicture();
      final bytes = await xFile.readAsBytes();
      return bytes;
    } catch (e) {
      debugPrint('CameraService.captureFrame error: $e');
      return null;
    }
  }

  // ─── Lifecycle ──────────────────────────────────────────────

  /// Pause the camera (on app background).
  Future<void> pause() async {
    if (_isInitialized && _controller != null) {
      await _controller!.pausePreview();
    }
  }

  /// Resume the camera (on app foreground).
  Future<void> resume() async {
    if (_isInitialized && _controller != null) {
      await _controller!.resumePreview();
    }
  }

  // ─── Dispose ────────────────────────────────────────────────

  Future<void> dispose() async {
    _isInitialized = false;
    await _controller?.dispose();
    _controller = null;
  }
}
