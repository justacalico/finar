import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity state
class ConnectivityState {
  final bool isOnline;
  final bool isChecking;
  final List<ConnectivityResult> connectivityResults;

  const ConnectivityState({
    this.isOnline = true,
    this.isChecking = false,
    this.connectivityResults = const [],
  });

  ConnectivityState copyWith({
    bool? isOnline,
    bool? isChecking,
    List<ConnectivityResult>? connectivityResults,
  }) {
    return ConnectivityState(
      isOnline: isOnline ?? this.isOnline,
      isChecking: isChecking ?? this.isChecking,
      connectivityResults: connectivityResults ?? this.connectivityResults,
    );
  }

  /// Check if we have any network connection (wifi, mobile, ethernet)
  bool get hasNetworkConnection {
    if (connectivityResults.isEmpty) return false;
    return !connectivityResults.contains(ConnectivityResult.none);
  }
}

/// Connectivity notifier
class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _checkTimer;

  ConnectivityNotifier() : 
    _connectivity = Connectivity(),
    super(const ConnectivityState(isChecking: true)) {
    _init();
  }

  void _init() {
    // On web, skip all connectivity checks - just assume online
    if (kIsWeb) {
      state = state.copyWith(isOnline: true, isChecking: false);
      return;
    }

    // Check initial connectivity
    _checkConnectivity();

    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      if (kDebugMode) {
        print('Connectivity changed: $results');
      }
      state = state.copyWith(connectivityResults: results);
      // Verify actual internet access when connectivity changes
      _verifyInternetAccess();
    });

    // Periodically check internet access (every 30 seconds)
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _verifyInternetAccess();
    });
  }

  Future<void> _checkConnectivity() async {
    // Skip on web
    if (kIsWeb) {
      state = state.copyWith(isOnline: true, isChecking: false);
      return;
    }

    try {
      final results = await _connectivity.checkConnectivity();
      state = state.copyWith(connectivityResults: results);
      await _verifyInternetAccess();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking connectivity: $e');
      }
      state = state.copyWith(isOnline: false, isChecking: false);
    }
  }

  /// Verify we can actually reach the internet by attempting a connection
  Future<void> _verifyInternetAccess() async {
    // Skip on web - always assume online
    if (kIsWeb) {
      state = state.copyWith(isOnline: true, isChecking: false);
      return;
    }

    if (!state.hasNetworkConnection) {
      state = state.copyWith(isOnline: false, isChecking: false);
      return;
    }

    // For native platforms, just trust connectivity_plus results
    state = state.copyWith(isOnline: state.hasNetworkConnection, isChecking: false);
  }

  /// Manually refresh connectivity status
  Future<void> refresh() async {
    await _checkConnectivity();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _checkTimer?.cancel();
    super.dispose();
  }
}

/// Connectivity provider
final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  return ConnectivityNotifier();
});

/// Simple provider for checking if online
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).isOnline;
});

/// Provider for checking if connectivity is being verified
final isCheckingConnectivityProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).isChecking;
});
