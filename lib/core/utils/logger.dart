import 'package:flutter/foundation.dart';

/// Simple logger utility for the application
class Logger {
  static const String _tag = '[CareerApp]';
  
  /// Log info message
  static void info(String message) {
    if (kDebugMode) {
      print('$_tag INFO: $message');
    }
  }
  
  /// Log debug message
  static void debug(String message) {
    if (kDebugMode) {
      print('$_tag DEBUG: $message');
    }
  }
  
  /// Log warning message
  static void warning(String message) {
    if (kDebugMode) {
      print('$_tag WARNING: $message');
    }
  }
  
  /// Log error message with optional error object
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('$_tag ERROR: $message');
      if (error != null) {
        print('$_tag ERROR Details: $error');
      }
      if (stackTrace != null) {
        print('$_tag STACK: $stackTrace');
      }
    }
  }
}