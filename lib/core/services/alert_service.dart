import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:sav/core/constants/app_constants.dart';

/// Manages alert sounds and vibration for drowsiness / yawn warnings.
@lazySingleton
class AlertService {
  AlertService() {
    _initializeAudioContext();
  }

  final AudioPlayer _player = AudioPlayer();
  String? _currentAlertType;

  Future<void> _initializeAudioContext() async {
    try {
      await _player.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media, // Route to media stream for high reliability
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.defaultToSpeaker,
          },
        ),
      ));
    } catch (e) {
      debugPrint('AlertService constructor audio context error: $e');
    }
  }

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

    if (soundEnabled) {
      if (_currentAlertType == 'drowsiness') {
        // Already playing the drowsiness loop - do not restart to avoid stuttering!
        return;
      }

      // Interrupt any other active alarm immediately
      try {
        await _player.stop();
      } catch (_) {}

      _currentAlertType = 'drowsiness';

      try {
        await _player.setVolume(1.0);
        await _player.setReleaseMode(ReleaseMode.loop); // Enable native looping for critical alarms
        
        final selectedSound =
            prefs.getString(AppConstants.prefSelectedAlertSound) ?? 'alarm.wav';
        debugPrint('AlertService: playing looping asset sounds/$selectedSound');
        await _player.play(AssetSource('sounds/$selectedSound'));
      } catch (e) {
        debugPrint('AlertService.playDrowsinessAlert error: $e');
        _currentAlertType = null;
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

    if (soundEnabled) {
      if (_currentAlertType == 'yawn') {
        // Already playing a yawn sound - do not restart to avoid stuttering!
        return;
      }

      // Interrupt any other active alarm immediately
      try {
        await _player.stop();
      } catch (_) {}

      _currentAlertType = 'yawn';

      try {
        await _player.setVolume(0.7);
        await _player.setReleaseMode(ReleaseMode.release); // Do not loop for softer yawn warnings
        
        debugPrint('AlertService: playing asset sounds/warning.wav');
        await _player.play(AssetSource('sounds/warning.wav'));
        
        // Release alert state once sound completes or after 3 seconds safety timeout
        Future.any<dynamic>([
          _player.onPlayerComplete.first,
          Future<void>.delayed(const Duration(seconds: 3)),
        ]).then((_) {
          if (_currentAlertType == 'yawn') {
            _currentAlertType = null;
          }
        }).catchError((_) {
          if (_currentAlertType == 'yawn') {
            _currentAlertType = null;
          }
        });
      } catch (e) {
        debugPrint('AlertService.playYawnWarning error: $e');
        _currentAlertType = null;
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
      await _player.setReleaseMode(ReleaseMode.release); // Reset release mode from loop
      await _player.stop();
      _currentAlertType = null;
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}
