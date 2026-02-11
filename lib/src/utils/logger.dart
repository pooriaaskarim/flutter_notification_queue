import 'package:flutter/foundation.dart';

enum LogLevel {
  trace,
  debug,
  info,
  warning,
  error,
}

/// Logger
class Logger {
  Logger._();

  static bool enabled = kDebugMode;
  static LogLevel minLevel = LogLevel.debug;

  /// Logs **Trace** messages
  static void t(final LogBuffer? buffer) => _log(buffer, level: LogLevel.trace);

  /// Logs **Debug** messages
  static void d(final LogBuffer? buffer) => _log(buffer, level: LogLevel.debug);

  /// Logs **Info** messages
  static void i(final LogBuffer? buffer) => _log(buffer, level: LogLevel.info);

  /// Logs **Warning** messages
  static void w(final LogBuffer? buffer) =>
      _log(buffer, level: LogLevel.warning);

  /// Logs **Error** messages
  static void e(final LogBuffer? buffer) => _log(buffer, level: LogLevel.error);

  static void _log(
    final LogBuffer? buffer, {
    final LogLevel level = LogLevel.debug,
  }) {
    if (!enabled || level.index < minLevel.index) {
      return;
    }

    final stackLines = StackTrace.current.toString().split('\n');
    int index = 0;
    String callerFrame = '';
    while (index < stackLines.length) {
      final line = stackLines[index].trim();
      if (line.isEmpty ||
          line.contains(RegExp('Logger.*')) ||
          line.contains(RegExp('LogBuffer.*'))) {
        index++;
        continue;
      }

      callerFrame = line;
      break;
    }
    if (callerFrame.isEmpty) {
      return;
    }

    final regex = RegExp(r'^#\d+\s+([^\s]+)\s+\(.+\)$');
    final match = regex.firstMatch(callerFrame);
    if (match == null) {
      return;
    }

    final String fullMethod = match.group(1)!;
    String className = '';
    String methodName = '';
    final dotIndex = fullMethod.lastIndexOf('.');
    if (dotIndex != -1) {
      className = fullMethod.substring(0, dotIndex);
      methodName = fullMethod.substring(dotIndex + 1);
    } else {
      methodName = fullMethod;
    }
    if (className.startsWith('_')) {
      className = className.substring(1);
    }
    final origin = className.isNotEmpty ? '$className.$methodName' : methodName;

    // Calculate depth: number of consecutive frames in the package
    int depth = 1;
    index++;
    while (index < stackLines.length) {
      final line = stackLines[index].trim();
      if (line.isEmpty) {
        break;
      }
      final thisMatch =
          RegExp(r'^#\d+\s+[^\s]+\s+\(([^)]+)\)$').firstMatch(line);
      if (thisMatch != null) {
        final file = thisMatch.group(1)!;
        if (file.startsWith('package:flutter_notification_queue/')) {
          depth++;
        } else {
          break;
        }
      }
      index++;
    }

    final levelStr = level.name.toUpperCase();
    final headerPrefix = '-' * (depth * 2);
    final header = '$headerPrefix[$levelStr]:'
        '\n$headerPrefix$origin$headerPrefix';
    debugPrint(header);

    final lines = buffer
        .toString()
        .split('\n')
        .where((final l) => l.trim().isNotEmpty)
        .toList();
    final linePrefix = '-' * ((depth + 1) * 2) + '|';
    for (final line in lines) {
      debugPrint('$linePrefix$line');
    }

    debugPrint('\n');
  }
}

class LogBuffer extends StringBuffer {
  LogBuffer._();

  static LogLevel _level = LogLevel.debug;

  /// Crates a **Trace** Log Buffer
  static LogBuffer? get t {
    if (Logger.enabled) {
      _level = LogLevel.trace;
      return LogBuffer._();
    }
    return null;
  }

  /// Creates a **Debug** Log Buffer
  static LogBuffer? get d {
    if (Logger.enabled) {
      _level = LogLevel.debug;
      return LogBuffer._();
    }
    return null;
  }

  /// Creates a **Info** Log Buffer
  static LogBuffer? get i {
    if (Logger.enabled) {
      _level = LogLevel.info;
      return LogBuffer._();
    }
    return null;
  }

  /// Creates a **Warning** Log Buffer
  static LogBuffer? get w {
    if (Logger.enabled) {
      _level = LogLevel.warning;
      return LogBuffer._();
    }
    return null;
  }

  /// Creates a **Error** Log Buffer
  static LogBuffer? get e {
    if (Logger.enabled) {
      _level = LogLevel.error;
      return LogBuffer._();
    }
    return null;
  }

  @override
  void writeAll(final Iterable objects, [final String separator = ""]) {
    for (final object in objects) {
      writeln(object);
    }
  }

  void flush() {
    Logger._log(this, level: _level);
    clear();
  }
}
