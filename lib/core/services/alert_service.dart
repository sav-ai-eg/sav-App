import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:sav/core/constants/app_constants.dart';

/// Manages alert sounds and vibration for drowsiness / yawn warnings.
@lazySingleton
class AlertService {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  // ─── Play Alerts ────────────────────────────────────────────

  /// Play a loud drowsiness alarm.
  Future<void> playDrowsinessAlert() async {
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled =
        prefs.getBool(AppConstants.prefAlertSoundEnabled) ?? true;
    final vibrationEnabled =
        prefs.getBool(AppConstants.prefVibrationEnabled) ?? true;

    if (vibrationEnabled) {
      _vibrate(duration: 1000);
    }

    if (soundEnabled && !_isPlaying) {
      _isPlaying = true;
      try {
        await _player.setVolume(1.0);
        final selectedSound =
            prefs.getString(AppConstants.prefSelectedAlertSound) ?? 'trucksound.wav';
        // Try custom selected asset first, then fallback to standard alert, then system alarm
        try {
          await _player.play(AssetSource('sounds/$selectedSound'));
        } catch (_) {
          try {
            await _player.play(AssetSource('sounds/alert.wav'));
          } catch (_) {
            // Fallback: Android system alarm sound
            await _player.play(UrlSource(
              'content://settings/system/alarm_alert',
            ));
          }
        }
        // Release isPlaying state once sound completes or after 4 seconds safety timeout
        Future.any<dynamic>([
          _player.onPlayerComplete.first,
          Future<void>.delayed(const Duration(seconds: 4)),
        ]).then((_) {
          _isPlaying = false;
        }).catchError((_) {
          _isPlaying = false;
        });
      } catch (e) {
        debugPrint('AlertService.playDrowsinessAlert error: $e');
        _isPlaying = false;
        // Last resort: vibrate heavily
        if (vibrationEnabled) _vibrate(duration: 2000);
      }
    }
  }

  /// Play a softer yawn warning.
  Future<void> playYawnWarning() async {
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled =
        prefs.getBool(AppConstants.prefAlertSoundEnabled) ?? true;
    final vibrationEnabled =
        prefs.getBool(AppConstants.prefVibrationEnabled) ?? true;

    if (vibrationEnabled) {
      _vibrate(duration: 500);
    }

    if (soundEnabled && !_isPlaying) {
      _isPlaying = true;
      try {
        await _player.setVolume(0.7);
        try {
          await _player.play(AssetSource('sounds/warning.wav'));
        } catch (_) {
          // Fallback: Android system notification sound
          await _player.play(UrlSource(
            'content://settings/system/notification_sound',
          ));
        }
        // Release isPlaying state once sound completes or after 3 seconds safety timeout
        Future.any<dynamic>([
          _player.onPlayerComplete.first,
          Future<void>.delayed(const Duration(seconds: 3)),
        ]).then((_) {
          _isPlaying = false;
        }).catchError((_) {
          _isPlaying = false;
        });
      } catch (e) {
        debugPrint('AlertService.playYawnWarning error: $e');
        _isPlaying = false;
        if (vibrationEnabled) _vibrate(duration: 500);
      }
    }
  }

  // ─── Vibration ──────────────────────────────────────────────

  Future<void> _vibrate({required int duration}) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: duration);
      }
    } catch (_) {}
  }

  // ─── Stop ───────────────────────────────────────────────────

  Future<void> stop() async {
    try {
      await _player.stop();
      _isPlaying = false;
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}
