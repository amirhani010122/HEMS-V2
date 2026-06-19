import 'package:flutter/foundation.dart';

class AppLogger {
  static const String _tag = '🔋 EnergyIQ';

  static void debug(String message, [Object? error, StackTrace? trace]) {
    if (kDebugMode) {
      print('$_tag [DEBUG] $message');
      if (error != null) print('Error: $error');
      if (trace != null) print('StackTrace: $trace');
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      print('$_tag [INFO] $message');
    }
  }

  static void warning(String message, [Object? error]) {
    if (kDebugMode) {
      print('$_tag [WARNING] $message');
      if (error != null) print('Error: $error');
    }
  }

  static void error(String message, [Object? error, StackTrace? trace]) {
    if (kDebugMode) {
      print('$_tag [ERROR] $message');
      if (error != null) print('Error: $error');
      if (trace != null) print('StackTrace: $trace');
    }
  }

  static void success(String message) {
    if (kDebugMode) {
      print('$_tag [SUCCESS] ✓ $message');
    }
  }

  static void api(String method, String path, {int? statusCode, Object? body}) {
    if (kDebugMode) {
      print('$_tag [API] $method $path${statusCode != null ? ' [$statusCode]' : ''}');
      if (body != null) print('Response: $body');
    }
  }

  static void performance(String name, Duration duration) {
    if (kDebugMode) {
      print('$_tag [PERFORMANCE] $name took ${duration.inMilliseconds}ms');
    }
  }
}
