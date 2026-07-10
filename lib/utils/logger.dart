import 'package:flutter/foundation.dart';

final class AppLogger {
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[omnyadriver] $message');
    }
  }
}
