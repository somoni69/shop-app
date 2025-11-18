import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Centralized logging helper used by providers/services.
///
/// Behavior:
/// - Writes full error + stacktrace to a log file under the system temp directory (folder name 'shop_app_logs').
/// - Calls `developer.log` so logs are visible in tooling.
/// - Prints to console in debug mode.
class LoggingService {
  static final Directory _systemTemp = Directory.systemTemp;
  static final String _subDirName = 'shop_app_logs';
  static File? _logFile;

  static Future<File> _ensureLogFile() async {
    if (_logFile != null) return _logFile!;
    final dir =
        Directory('${_systemTemp.path}${Platform.pathSeparator}$_subDirName');
    if (!await dir.exists()) await dir.create(recursive: true);
    final file = File('${dir.path}${Platform.pathSeparator}shop_app.log');
    if (!await file.exists()) await file.create(recursive: true);
    _logFile = file;
    return file;
  }

  /// Log an error with optional stacktrace and context. In debug mode prints to console and writes full details to file.
  static Future<void> logError(Object error, StackTrace? stackTrace,
      {String? context}) async {
    final timestamp = DateTime.now().toIso8601String();
    final header = '${timestamp}${context != null ? ' [$context]' : ''} ERROR:';
    final body = '$error\n${stackTrace ?? ''}';
    final msg = '$header $body\n';

    if (kDebugMode) {
      // ignore: avoid_print
      print(msg);
    }

    try {
      final file = await _ensureLogFile();
      await file.writeAsString(msg, mode: FileMode.append, flush: true);
    } catch (e) {
      developer.log('Failed to write log file: $e', name: 'shop_app');
    }

    developer.log(msg, name: 'shop_app', error: error, stackTrace: stackTrace);
  }

  /// Log info-level messages
  static Future<void> logInfo(String message, {String? context}) async {
    final timestamp = DateTime.now().toIso8601String();
    final header = '${timestamp}${context != null ? ' [$context]' : ''} INFO:';
    final msg = '$header $message\n';

    if (kDebugMode) {
      // ignore: avoid_print
      print(msg);
    }

    try {
      final file = await _ensureLogFile();
      await file.writeAsString(msg, mode: FileMode.append, flush: true);
    } catch (_) {
      // ignore file write failures
    }

    developer.log(msg, name: 'shop_app');
  }
}
