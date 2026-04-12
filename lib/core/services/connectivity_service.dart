import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Monitors network connectivity and notifies listeners on changes.
///
/// Used to trigger offline cache sync when connectivity is restored.
@lazySingleton
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Callback fired when connectivity changes.
  /// Parameter is true if online, false if offline.
  VoidCallback? onConnectivityRestored;
  VoidCallback? onConnectivityLost;

  // ─── Initialization ─────────────────────────────────────────

  /// Start monitoring connectivity. Call once at app startup.
  Future<void> initialize() async {
    try {
      // Check initial state
      final results = await _connectivity.checkConnectivity();
      _isOnline = _hasConnection(results);
      debugPrint('🌐 ConnectivityService: initialized (online=$_isOnline)');

      // Listen for changes
      _subscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (e) {
          debugPrint('❌ ConnectivityService stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('❌ ConnectivityService.initialize error: $e');
      _isOnline = true; // Assume online if we can't determine
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = _hasConnection(results);

    if (!wasOnline && _isOnline) {
      debugPrint('🌐 ConnectivityService: Back online');
      onConnectivityRestored?.call();
    } else if (wasOnline && !_isOnline) {
      debugPrint('🌐 ConnectivityService: Gone offline');
      onConnectivityLost?.call();
    }
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  }

  // ─── Dispose ────────────────────────────────────────────────

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    onConnectivityRestored = null;
    onConnectivityLost = null;
    debugPrint('🌐 ConnectivityService: disposed');
  }
}
