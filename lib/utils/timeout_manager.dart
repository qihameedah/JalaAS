// lib/utils/timeout_manager.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'constants.dart';
import 'helpers.dart';
import '../screens/mobile/pin_enter_screen.dart';

class TimeoutManager {
  static final TimeoutManager _instance = TimeoutManager._internal();
  factory TimeoutManager() => _instance;
  TimeoutManager._internal();

  Timer? _timer;
  DateTime? _lastActiveTime;
  bool _isInBackground = false;
  bool _isCheckingPin = false;

  // Global navigation key to access navigator from anywhere
  static GlobalKey<NavigatorState>? navigatorKey;

  void startTimer() {
    _timer?.cancel();
    _updateLastActiveTime();

    // Check every 30 seconds for timeout
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkTimeout();
    });
  }

  void stopTimer() {
    _timer?.cancel();
  }

  void _updateLastActiveTime() {
    _lastActiveTime = DateTime.now();
    Helpers.updateLastActiveTime();
  }

  void resetTimer() {
    if (!_isCheckingPin) {
      _updateLastActiveTime();
    }
  }

  void setBackgroundState(bool isInBackground) {
    _isInBackground = isInBackground;
    if (isInBackground) {
      _updateLastActiveTime();
    }
  }

  void _checkTimeout() {
    if (_isInBackground || _isCheckingPin || _lastActiveTime == null) {
      return;
    }

    final now = DateTime.now();
    final timeDifference = now.difference(_lastActiveTime!);

    print(
        'Checking timeout: ${timeDifference.inMinutes} minutes since last active');

    if (timeDifference.inMinutes >= AppConstants.backgroundTimeoutMinutes) {
      print('Timeout detected! Showing PIN screen');
      _showPinScreen();
    }
  }

  void _showPinScreen() {
    if (_isCheckingPin || navigatorKey?.currentContext == null) {
      return;
    }

    _isCheckingPin = true;

    Navigator.of(navigatorKey!.currentContext!).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => PinEnterScreen(
          onPinVerified: () {
            _isCheckingPin = false;
            _updateLastActiveTime();
            // Don't navigate anywhere, just dismiss the PIN screen
            // The user will return to where they were
          },
        ),
      ),
      (route) => false, // Remove all previous routes
    );
  }

  void dispose() {
    _timer?.cancel();
  }
}
