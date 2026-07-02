import 'package:flutter/material.dart';

class AppFeedback {
  AppFeedback._();

  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static void show(String message) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
  }
}