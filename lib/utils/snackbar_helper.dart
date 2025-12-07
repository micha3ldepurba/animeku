import 'package:flutter/material.dart';

class SnackbarHelper {
  SnackbarHelper._();

  static OverlayEntry? _currentOverlay;

  static void showError(BuildContext context, String message) {
    _show(context, message, Colors.red.shade700, 4);
  }

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, Colors.green.shade700, 3);
  }

  static void _show(
      BuildContext context,
      String message,
      Color color,
      int seconds,
      ) {
    _currentOverlay?.remove();
    _currentOverlay = null;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
    );

    _currentOverlay = overlayEntry;
    Overlay.of(context).insert(overlayEntry);

    Future.delayed(Duration(seconds: seconds), () {
      overlayEntry.remove();
      if (_currentOverlay == overlayEntry) {
        _currentOverlay = null;
      }
    });
  }
}