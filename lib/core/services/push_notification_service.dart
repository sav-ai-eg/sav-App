import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/core/services/backend_api_service.dart';
import 'package:sav/core/services/alert_service.dart';
import 'package:sav/core/di/injection.dart';
import 'package:sav/features/trip/presentation/cubit/trip_cubit.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM Background message: ${message.messageId} - ${message.notification?.title}');
}

class PushNotificationService {
  static final StreamController<Map<String, dynamic>> _chatMessageStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get chatMessageStream =>
      _chatMessageStreamController.stream;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final BackendApiService _backendApiService;
  final SharedPreferences _prefs;
  final AlertService _alertService;

  PushNotificationService(
    this._backendApiService,
    this._prefs,
    this._alertService,
  );

  /// Initialize Push Notifications setup
  Future<void> initialize() async {
    try {
      // 1. Register background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 2. Request runtime system permissions (iOS / Android 13+)
      await requestPermissions();

      // 3. Register token with the backend
      await checkAndUploadToken();

      // 4. Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message received: ${message.notification?.title}');
        _handleIncomingNotification(message);
      });

      // 5. Handle notification tap when application is opened from a terminated state
      final RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('FCM Initial message tapped: ${initialMessage.notification?.title}');
        _handleIncomingNotification(initialMessage);
      }

      // 6. Handle notification tap when application is in the background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Message opened from background: ${message.notification?.title}');
        _handleIncomingNotification(message);
      });

      // 7. Auto-refresh token if it changes
      _fcm.onTokenRefresh.listen((String token) async {
        debugPrint('FCM Token refreshed: $token');
        await _prefs.setString('${AppConstants.prefSelectedAlertSound}_fcm_token', token);
        await _uploadTokenToBackend(token);
      });
    } catch (e) {
      debugPrint('PushNotificationService initialization error: $e');
    }
  }

  /// Request iOS & Android 13+ Notification permissions
  Future<void> requestPermissions() async {
    try {
      final NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );
      
      final bool enabled = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
          
      // Cache settings status
      await _prefs.setBool(AppConstants.prefNotificationsEnabled, enabled);
      debugPrint('FCM permission authorization status: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('FCM requestPermissions error: $e');
    }
  }

  /// Check token status and upload it to Django backend
  Future<void> checkAndUploadToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        debugPrint('FCM fetched token: $token');
        await _prefs.setString('${AppConstants.prefSelectedAlertSound}_fcm_token', token);
        await _uploadTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('FCM checkAndUploadToken error: $e');
    }
  }

  /// Upload the token using BackendApiService
  Future<void> _uploadTokenToBackend(String token) async {
    try {
      final hasNotificationsEnabled = _prefs.getBool(AppConstants.prefNotificationsEnabled) ?? true;
      if (!hasNotificationsEnabled) {
        debugPrint('Push notifications are disabled in user settings. Skipping upload.');
        return;
      }
      
      await _backendApiService.registerDeviceToken(token);
      debugPrint('FCM token successfully uploaded/registered with backend.');
    } catch (e) {
      debugPrint('FCM token upload failed: $e');
    }
  }

  /// Direct safety alerts to play the corresponding custom sounds
  void _handleIncomingNotification(RemoteMessage message) {
    final Map<String, dynamic> data = message.data;
    final String type = data['type'] ?? '';
    final String alertType = data['alert_type'] ?? '';

    debugPrint('FCM Payload - Type: $type, AlertType: $alertType');

    if (type == 'chat_message' || type == 'chat') {
      _chatMessageStreamController.add(data);
    }

    if (type == 'trip' || type == 'trip_event') {
      try {
        getIt<TripCubit>().restoreCurrentTrip();
      } catch (e) {
        debugPrint('Failed to restore current trip on notification: $e');
      }
    }

    final soundEnabled = _prefs.getBool(AppConstants.prefAlertSoundEnabled) ?? true;
    if (!soundEnabled) {
      debugPrint('Sound is disabled in user preferences. Not playing audio.');
      return;
    }

    if (type == 'alert') {
      if (alertType == 'yawning' || alertType == 'no_face') {
        _alertService.playYawnWarning();
      } else if (alertType == 'drowsy' || alertType == 'sleep' || alertType == 'eyes_closed') {
        _alertService.playDrowsinessAlert();
      } else {
        // Fallback to standard drowsiness warning sound
        _alertService.playDrowsinessAlert();
      }
    } else if (type == 'emergency') {
      _alertService.playDrowsinessAlert();
    }
  }
}
