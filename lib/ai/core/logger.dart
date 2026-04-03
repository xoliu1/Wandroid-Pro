import 'package:flutter/foundation.dart';

/// AI 模块日志器
class AILogger {
  static const String _tag = 'AI_MODULE';
  static bool _enableDebugLog = kDebugMode;

  /// 设置是否启用调试日志
  static void setDebugEnabled(bool enabled) {
    _enableDebugLog = enabled;
  }

  /// Debug 日志
  static void debug(String message, {String? tag}) {
    if (_enableDebugLog) {
      _log('🔍', tag ?? _tag, message);
    }
  }

  /// Info 日志
  static void info(String message, {String? tag}) {
    _log('ℹ️', tag ?? _tag, message);
  }

  /// Warning 日志
  static void warning(String message, {String? tag}) {
    _log('⚠️', tag ?? _tag, message);
  }

  /// Error 日志
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log('❌', tag ?? _tag, message);
    if (error != null) {
      debugPrint('   Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('   StackTrace: $stackTrace');
    }
  }

  /// Success 日志
  static void success(String message, {String? tag}) {
    _log('✅', tag ?? _tag, message);
  }

  /// 内部日志方法
  static void _log(String emoji, String tag, String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    debugPrint('$emoji [$timestamp][$tag] $message');
  }
}
