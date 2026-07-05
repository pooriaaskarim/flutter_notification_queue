import 'package:flutter/foundation.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logd/logd.dart';
import 'package:logd/testing.dart';

void main() {
  group('FlutterNotificationQueue Logger Configuration', () {
    final originalOnError = FlutterError.onError;

    setUp(() {
      FlutterNotificationQueue.reset();
    });

    tearDown(() {
      FlutterError.onError = originalOnError;
      FlutterNotificationQueue.reset();
    });

    test('Custom log level is configured correctly', () {
      FlutterNotificationQueue.configure(
        logLevel: LogLevel.warning,
      );

      final hierarchy = Logger.exportHierarchy();
      final fnqConfig = hierarchy['fnq'];
      expect(fnqConfig, isA<Map<String, dynamic>>());

      final fnqConfigMap = fnqConfig as Map<String, dynamic>;
      final effective = fnqConfigMap['effective'] as Map<String, dynamic>;
      final Object? logLevelVal = effective['logLevel'];
      expect(logLevelVal.toString(), contains('warning'));
    });

    test('Custom log handlers are configured correctly', () {
      final sink = CaptureSink();
      final handler = Handler(
        formatter: const PlainFormatter(),
        sink: sink,
      );

      FlutterNotificationQueue.configure(
        logLevel: LogLevel.info,
        logHandlers: [handler],
      );

      Logger.get('fnq.test').info('Test log message');

      final log = sink.logs.last;
      final logMessage = log.message;
      final logLevel = log.level;
      expect(logMessage, equals('Test log message'));
      expect(logLevel, equals(LogLevel.info));
    });

    test(
        'FlutterError.onError is hooked only when '
        'captureFlutterErrors is true', () {
      // By default, captureFlutterErrors should be false
      FlutterNotificationQueue.configure();
      expect(FlutterError.onError, equals(originalOnError));

      // With captureFlutterErrors set to true, it should wrap
      // FlutterError.onError
      FlutterNotificationQueue.configure(captureFlutterErrors: true);
      expect(FlutterError.onError, isNot(equals(originalOnError)));
    });
  });
}
