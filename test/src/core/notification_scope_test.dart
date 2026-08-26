import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterNotificationQueue.reset();
  });

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
          permanent: true,
        ),
      );

      await widgetTester.pump();
      await widgetTester.pump(const Duration(milliseconds: 500));

      await widgetTester.pumpWidget(const SizedBox());
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

    testWidgets('supports multi-tenant isolation with distinct controllers',
        (final widgetTester) async {
      final controllerA = NotificationController(
        queues: {const NotificationQueue(position: QueuePosition.topLeft)},
      );
      final controllerB = NotificationController(
        queues: {const NotificationQueue(position: QueuePosition.bottomRight)},
      );

      late BuildContext contextA;
      late BuildContext contextB;

      final eventsA = <NotificationEvent>[];
      final eventsB = <NotificationEvent>[];

      final subA = controllerA.events.listen(eventsA.add);
      final subB = controllerB.events.listen(eventsB.add);

      await widgetTester.pumpWidget(
        MaterialApp(
          home: Row(
            children: [
              Expanded(
                child: NotificationScope(
                  controller: controllerA,
                  child: Builder(
                    builder: (final ctx) {
                      contextA = ctx;
                      return const Text('Subtree A');
                    },
                  ),
                ),
              ),
              Expanded(
                child: NotificationScope(
                  controller: controllerB,
                  child: Builder(
                    builder: (final ctx) {
                      contextB = ctx;
                      return const Text('Subtree B');
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      expect(controllerA.isAttached, isTrue);
      expect(controllerB.isAttached, isTrue);
      expect(NotificationScope.of(contextA), equals(controllerA));
      expect(NotificationScope.of(contextB), equals(controllerB));

      controllerA.show(
        const AppNotification(
          message: 'Message for A',
          permanent: true,
        ),
      );
      await widgetTester.pump();
      await widgetTester.pump(const Duration(milliseconds: 500));

      expect(find.text('Message for A'), findsOneWidget);
      expect(find.text('Subtree A'), findsOneWidget);
      expect(find.text('Subtree B'), findsOneWidget);

      controllerB.show(
        const AppNotification(
          message: 'Message for B',
          permanent: true,
        ),
      );
      await widgetTester.pump();
      await widgetTester.pump(const Duration(milliseconds: 500));

      expect(find.text('Message for A'), findsOneWidget);
      expect(find.text('Message for B'), findsOneWidget);

      // Verify event isolation
      expect(eventsA.any((final e) => e is NotificationQueued), isTrue);
      expect(eventsB.any((final e) => e is NotificationQueued), isTrue);

      await subA.cancel();
      await subB.cancel();
      controllerA.dispose();
      controllerB.dispose();
      await widgetTester.pumpWidget(const SizedBox());
      await widgetTester.pump();
    });

    testWidgets('detaches controller when NotificationScope is unmounted',
        (final widgetTester) async {
      final controller = NotificationController(
        queues: {const NotificationQueue()},
      );

      await widgetTester.pumpWidget(
        MaterialApp(
          home: NotificationScope(
            controller: controller,
            child: const Text('Mounted'),
          ),
        ),
      );

      expect(controller.isAttached, isTrue);

      // Unmount the NotificationScope
      await widgetTester.pumpWidget(
        const MaterialApp(
          home: Text('Unmounted Scope'),
        ),
      );

      expect(controller.isAttached, isFalse);

      controller.dispose();
    });

    testWidgets('nested NotificationScope correctly overrides outer controller',
        (final widgetTester) async {
      final outerController = NotificationController(
        queues: {const NotificationQueue()},
      );
      final innerController = NotificationController(
        queues: {const NotificationQueue()},
      );

      late BuildContext outerContext;
      late BuildContext innerContext;

      await widgetTester.pumpWidget(
        MaterialApp(
          home: NotificationScope(
            controller: outerController,
            child: Builder(
              builder: (final ctx1) {
                outerContext = ctx1;
                return NotificationScope(
                  controller: innerController,
                  child: Builder(
                    builder: (final ctx2) {
                      innerContext = ctx2;
                      return const Text('Nested Scopes');
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(NotificationScope.of(outerContext), equals(outerController));
      expect(NotificationScope.of(innerContext), equals(innerController));

      outerController.dispose();
      innerController.dispose();
      await widgetTester.pumpWidget(const SizedBox());
      await widgetTester.pump();
    });

    testWidgets(
        'cleans up active notification timers gracefully upon controller '
        'disposal', (final widgetTester) async {
      final controller = NotificationController(
        queues: {
          const NotificationQueue(position: QueuePosition.topRight),
        },
      );

      await widgetTester.pumpWidget(
        MaterialApp(
          home: NotificationScope(
            controller: controller,
            child: const Scaffold(body: Text('Timer Cleanup Test')),
          ),
        ),
      );

      controller.show(
        const AppNotification(
          message: 'Expiring Notification',
          permanent: true,
        ),
      );
      await widgetTester.pump();
      await widgetTester.pump(const Duration(milliseconds: 100));

      expect(() => controller.dispose(), returnsNormally);
      await widgetTester.pumpWidget(const SizedBox());
      await widgetTester.pump();
    });
  });
}
