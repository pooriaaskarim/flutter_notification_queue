import 'package:flutter/widgets.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_notification_queue/src/core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockOverlayPortalController extends Mock
    implements OverlayPortalController {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QueueCoordinator', () {
    late NotificationController controller;
    late QueueCoordinator coordinator;
    late MockOverlayPortalController mockOverlayController;

    setUp(() {
      controller = NotificationController(
        queues: {
          const NotificationQueue(position: QueuePosition.topRight),
        },
        channels: {
          const NotificationChannel(
            name: 'default',
            description: 'Default channel',
            defaultDismissDuration: null,
          ),
        },
      );
      coordinator = QueueCoordinator.fromController(controller);
      mockOverlayController = MockOverlayPortalController();
      coordinator.attach(mockOverlayController);
      when(() => mockOverlayController.show()).thenReturn(null);
      when(() => mockOverlayController.hide()).thenReturn(null);
    });

    tearDown(() {
      coordinator.dispose();
      controller.dispose();
    });

    test('Initial state is clear', () {
      expect(coordinator.activeQueues.value.isEmpty, isTrue);
    });

    group('Initialization Queue', () {
      test('enqueue adds to initialization queue when not mounted', () {
        final notification = NotificationWidget(
          id: 'test',
          message: 'Test Message',
          coordinator: coordinator,
        );

        coordinator.queue(notification);

        // Should be active to trigger mount
        expect(coordinator.activeQueues.value.isNotEmpty, isTrue);
        expect(
          coordinator.activeQueues.value.keys.first,
          QueuePosition.topRight,
        );

        // Should be retrievable via consume
        final items =
            coordinator.consumeInitializationQueue(QueuePosition.topRight);
        expect(items.length, 1);
        expect(items.first.blueprint, notification);

        // Should trigger overlay show
        verify(() => mockOverlayController.show()).called(1);
      });

      test('consumeInitializationQueue clears the queue', () {
        final notification = NotificationWidget(
          id: 'test',
          message: 'Test Message',
          coordinator: coordinator,
        );
        coordinator.queue(notification);

        final items1 =
            coordinator.consumeInitializationQueue(QueuePosition.topRight);
        expect(items1.length, 1);

        final items2 =
            coordinator.consumeInitializationQueue(QueuePosition.topRight);
        expect(items2.isEmpty, isTrue);
      });
    });
  });
}
