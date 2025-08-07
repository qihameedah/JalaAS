// lib/widgets/timeout_wrapper.dart
import 'package:flutter/material.dart';
import '../utils/timeout_manager.dart';

class TimeoutWrapper extends StatelessWidget {
  final Widget child;

  const TimeoutWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final timeoutManager = TimeoutManager();

    return GestureDetector(
      onTap: () {
        // Reset timeout on any tap
        timeoutManager.resetTimer();
      },
      onPanDown: (_) {
        // Reset timeout on any touch/pan
        timeoutManager.resetTimer();
      },
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
