import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationScope', () {
    testWidgets('mounts scope, attaches controller, and dispatches to overlay',
        (final widgetTester) async {
      final controller = NotificationController(
        queues: {const NotificationQueue(position: QueuePosition.topCenter)},
      );

      late BuildContext savedContext;

      await widgetTester.pumpWidget(
        MaterialApp(
          builder: (final context, final child) => NotificationScope(
            controller: controller,
            child: child!,
          ),
          home: Builder(
            builder: (final context) {
              savedContext = context;
              return const Scaffold(
                body: Text('Home'),
              );
            },
          ),
        ),
      );

      expect(controller.isAttached, isTrue);
      expect(NotificationScope.of(savedContext), equals(controller));

      controller.show(
        const AppNotification(
          message: 'Scoped Notification',
        ),
      );

      await widgetTester.pumpAndSettle();

      expect(find.text('Scoped Notification'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('maybeOf returns null when no scope is in context',
        (final widgetTester) async {
      late BuildContext savedContext;

      await widgetTester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (final context) {
              savedContext = context;
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      );

      expect(NotificationScope.maybeOf(savedContext), isNull);
      expect(
        () => NotificationScope.of(savedContext),
        throwsA(isA<StateError>()),
      );
    });
  });
}
