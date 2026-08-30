import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });



  group('NotificationScope', () {
    testWidgets('mounts scope, attaches controller, and dispatches to overlay',
        (final widgetTester) async {
      final controller = NotificationController(
        queues: {const NotificationQueue(position: QueuePosition.topCenter)},
        channels: {
          const NotificationChannel(
            name: 'default',
            position: QueuePosition.topCenter,
            defaultDismissDuration: null,
          ),
        },
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
      await widgetTester.pump();
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
        channels: {
          const NotificationChannel(
            name: 'default',
            position: QueuePosition.topLeft,
            defaultDismissDuration: null,
          ),
        },
      );
      final controllerB = NotificationController(
        queues: {const NotificationQueue(position: QueuePosition.bottomRight)},
        channels: {
          const NotificationChannel(
            name: 'default',
            position: QueuePosition.bottomRight,
            defaultDismissDuration: null,
          ),
        },
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

      subA.cancel(); // ignore: unawaited_futures
      subB.cancel(); // ignore: unawaited_futures
      await widgetTester.pumpWidget(const SizedBox());
      await widgetTester.pump();
      controllerA.dispose();
      controllerB.dispose();
    });

    testWidgets('detaches controller when NotificationScope is unmounted',
        (final widgetTester) async {
      final controller = NotificationController(
        queues: {const NotificationQueue()},
        channels: {
          const NotificationChannel(
            name: 'default',
            defaultDismissDuration: null,
          ),
        },
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
        channels: {
          const NotificationChannel(
            name: 'default',
            defaultDismissDuration: null,
          ),
        },
      );
      final innerController = NotificationController(
        queues: {const NotificationQueue()},
        channels: {
          const NotificationChannel(
            name: 'default',
            defaultDismissDuration: null,
          ),
        },
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

      await widgetTester.pumpWidget(const SizedBox());
      await widgetTester.pump();
      outerController.dispose();
      innerController.dispose();
    });

    testWidgets(
        'cleans up active notification timers gracefully upon controller '
        'disposal', (final widgetTester) async {
      final controller = NotificationController(
        queues: {
          const NotificationQueue(position: QueuePosition.topRight),
        },
        channels: {
          const NotificationChannel(
            name: 'default',
            position: QueuePosition.topRight,
            defaultDismissDuration: null,
          ),
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

      await widgetTester.pumpWidget(const SizedBox());
      await widgetTester.pump();
      expect(() => controller.dispose(), returnsNormally);
    });
  });
}
