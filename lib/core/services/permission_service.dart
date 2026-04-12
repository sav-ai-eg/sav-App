import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

/// Centralized permission handling with user-friendly dialogs.
class PermissionService {
  /// Check & request camera permission. Returns true if granted.
  static Future<bool> requestCamera(BuildContext context) async {
    var status = await Permission.camera.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      status = await Permission.camera.request();
      if (status.isGranted) return true;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        final opened = await _showSettingsDialog(
          context,
          title: 'Camera Permission Required',
          message:
              'SAV needs camera access to monitor your alertness while driving. '
              'Please enable camera permission in app settings.',
          icon: Icons.camera_alt_rounded,
        );
        if (opened) await openAppSettings();
      }
      return false;
    }

    return false;
  }

  /// Check & request location permission. Returns true if granted.
  static Future<bool> requestLocation(BuildContext context) async {
    // First check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        final shouldOpen = await _showSettingsDialog(
          context,
          title: 'Location Services Disabled',
          message:
              'SAV needs GPS to track your trip route and share your location with the fleet manager. '
              'Please enable location services.',
          icon: Icons.location_off_rounded,
        );
        if (shouldOpen) await Geolocator.openLocationSettings();
      }
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
    }

    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return true;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        return true;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        final opened = await _showSettingsDialog(
          context,
          title: 'Location Permission Required',
          message:
              'SAV needs location access to track your trip and display your position on the map. '
              'Please enable location permission in app settings.',
          icon: Icons.location_disabled_rounded,
        );
        if (opened) await Geolocator.openAppSettings();
      }
      return false;
    }

    return false;
  }

  /// Check both camera and location permissions at once.
  /// Returns a record of (camera: bool, location: bool).
  static Future<({bool camera, bool location})> requestAll(
      BuildContext context) async {
    final camera = await requestCamera(context);
    if (!context.mounted) return (camera: camera, location: false);
    final location = await requestLocation(context);
    return (camera: camera, location: location);
  }

  // ─── Private: Settings Dialog ──────────────────────────────

  static Future<bool> _showSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: Icon(icon, size: 48, color: const Color(0xFF023059)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF023059),
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF023059),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
