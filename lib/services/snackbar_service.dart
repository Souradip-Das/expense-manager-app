// lib/services/snackbar_service.dart
import 'package:flutter/material.dart';

enum SnackType { success, error, warning, info }

class SnackbarService {
  static void show(
    BuildContext context,
    String message, {
    SnackType type = SnackType.success,
  }) {
    final config = _config(type);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(config.icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: config.color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
          duration: Duration(
            seconds: type == SnackType.error ? 3 : 2,
          ),
        ),
      );
  }

  static _SnackConfig _config(SnackType type) {
    switch (type) {
      case SnackType.success:
        return _SnackConfig(Icons.check_circle_outline, const Color(0xFF2E7D32));
      case SnackType.error:
        return _SnackConfig(Icons.error_outline, const Color(0xFFC62828));
      case SnackType.warning:
        return _SnackConfig(Icons.warning_amber_outlined, const Color(0xFFE65100));
      case SnackType.info:
        return _SnackConfig(Icons.info_outline, const Color(0xFF1565C0));
    }
  }
}

class _SnackConfig {
  final IconData icon;
  final Color color;
  const _SnackConfig(this.icon, this.color);
}