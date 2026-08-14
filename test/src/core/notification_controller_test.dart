import 'dart:async';

import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_notification_queue/src/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNotificationScopeState implements NotificationScopeState {
  final _eventController = StreamController<FnqEvent>.broadcast();
  final List<AppNotification> shownNotifications = [];
  final List<AppNotification> dismissedNotifications = [];
  bool dismissedAll = false;
  bool dismissedNewest = false;
  bool clearedHistory = false;
  final List<String> dismissedGroups = [];
  final List<(AppNotification, QueuePosition)> relocated = [];
  final List<(AppNotification, int)> reordered = [];
  final List<AppNotification> snoozed = [];
  final List<AppNotification> pinned = [];
  final List<AppNotification> unpinned = [];

  @override
  Stream<FnqEvent> get events => _eventController.stream;

  @override
  void show(final AppNotification notification) {
    shownNotifications.add(notification);
  }

  @override
  void dismiss(
    final AppNotification notification, {
    final DismissReason reason = DismissReason.programmatic,
  }) {
    dismissedNotifications.add(notification);
  }

  @override
  void dismissAll({final DismissReason reason = DismissReason.programmatic}) {
    dismissedAll = true;
  }

  @override
  void dismissNewest() {
    dismissedNewest = true;
  }

  @override
  void dismissGroup(
    final String groupKey, {
    final DismissReason reason = DismissReason.programmatic,
  }) {
    dismissedGroups.add(groupKey);
  }

  @override
  void relocate(
    final AppNotification notification,
    final QueuePosition newPosition,
  ) {
    relocated.add((notification, newPosition));
  }

  @override
  void reorder(final AppNotification notification, final int targetIndex) {
    reordered.add((notification, targetIndex));
  }

  @override
  void snooze(
    final AppNotification notification,
    final Duration duration,
  ) {
    snoozed.add(notification);
  }

  @override
  void pin(final AppNotification notification) {
    pinned.add(notification);
  }

  @override
  void unpin(final AppNotification notification) {
    unpinned.add(notification);
  }

  @override
  List<FnqEvent> getHistory({
    final String? channelName,
    final DismissReason? dismissReason,
    final DateTime? since,
    final int? limit,
  }) =>
      const [];

  @override
  void clearHistory() {
    clearedHistory = true;
  }

  void emitEvent(final FnqEvent event) {
    _eventController.add(event);
  }
}

void main() {
  group('NotificationController', () {
    test('initializes with configuration without attaching', () {
      final controller = NotificationController(
        queues: {const NotificationQueue(position: QueuePosition.topRight)},
        channels: {const NotificationChannel(name: 'custom')},
      );

      expect(controller.isAttached, isFalse);
      expect(
        controller.configuration.getQueue(QueuePosition.topRight).position,
        equals(QueuePosition.topRight),
      );
      expect(
        controller.configuration.getChannel('custom').name,
        equals('custom'),
      );

      controller.dispose();
    });

    test('show throws StateError when controller is unattached', () {
      final controller = NotificationController(
        queues: {const NotificationQueue()},
      );

      const notification = AppNotification(message: 'Unattached');

      expect(
        () => controller.show(notification),
        throwsStateError,
      );

      controller.dispose();
    });

    test('tryShow does not throw when controller is unattached', () {
      final controller = NotificationController(
        queues: {const NotificationQueue()},
      );

      const notification = AppNotification(message: 'Safe no-op');

      expect(
        () => controller.tryShow(notification),
        returnsNormally,
      );

      controller.dispose();
    });

    test('attaches and detaches scope successfully', () {
      final controller = NotificationController(
        queues: {const NotificationQueue()},
      );
      final fakeScope = _FakeNotificationScopeState();

      expect(controller.isAttached, isFalse);

      controller.attach(fakeScope);
      expect(controller.isAttached, isTrue);

      const notification = AppNotification(message: 'Hello Scope');
      controller.show(notification);
      expect(fakeScope.shownNotifications.length, equals(1));
      expect(
        fakeScope.shownNotifications.first.message,
        equals('Hello Scope'),
      );

      controller.detach();
      expect(controller.isAttached, isFalse);

      controller.dispose();
    });

    test('proxies events from attached scope to controller events stream',
        () async {
      final controller = NotificationController(
        queues: {const NotificationQueue()},
      );
      final fakeScope = _FakeNotificationScopeState();

      controller.attach(fakeScope);

      final event = QueueOverflowed(
        queue: const NotificationQueue(),
        dropped: NotificationWidget(message: 'Dropped'),
      );

      final nextEventFuture = controller.nextEvent<QueueOverflowed>();
      fakeScope.emitEvent(event);

      final received = await nextEventFuture;
      expect(received, equals(event));

      controller.dispose();
    });

    test('dismiss, dismissAll, clearHistory delegate to attached scope', () {
      final controller = NotificationController(
        queues: {const NotificationQueue()},
      );
      final fakeScope = _FakeNotificationScopeState();
      const notification = AppNotification(message: 'Test', id: 'notif-1');

      controller
        ..attach(fakeScope)
        ..dismiss(notification)
        ..dismissAll()
        ..clearHistory();

      expect(
        fakeScope.dismissedNotifications.map((final n) => n.id),
        contains('notif-1'),
      );
      expect(fakeScope.dismissedAll, isTrue);
      expect(fakeScope.clearedHistory, isTrue);

      controller.dispose();
    });

    test(
        'dismissNewest, dismissGroup, relocate, reorder, snooze, pin, unpin '
        'delegate to attached scope', () {
      final controller = NotificationController(
        queues: {const NotificationQueue()},
      );
      final fakeScope = _FakeNotificationScopeState();
      const notification = AppNotification(message: 'Test');

      controller
        ..attach(fakeScope)
        ..dismissNewest()
        ..dismissGroup('orders')
        ..relocate(notification, QueuePosition.topLeft)
        ..reorder(notification, 2)
        ..snooze(notification, const Duration(seconds: 5))
        ..pin(notification)
        ..unpin(notification);

      expect(fakeScope.dismissedNewest, isTrue);
      expect(fakeScope.dismissedGroups, contains('orders'));
      expect(fakeScope.relocated, isNotEmpty);
      expect(fakeScope.reordered, isNotEmpty);
      expect(fakeScope.snoozed, isNotEmpty);
      expect(fakeScope.pinned, isNotEmpty);
      expect(fakeScope.unpinned, isNotEmpty);

      controller.dispose();
    });

    test('reconfigure updates configuration settings in-place', () {
      final controller = NotificationController(
        queues: {const NotificationQueue(position: QueuePosition.topCenter)},
        channels: {const NotificationChannel(name: 'default')},
        enableDynamicChannelParking: false,
      );

      expect(controller.configuration.queues.length, equals(1));
      expect(controller.configuration.enableDynamicChannelParking, isFalse);

      controller.reconfigure(
        queues: {
          const NotificationQueue(position: QueuePosition.topCenter),
          const NotificationQueue(position: QueuePosition.bottomRight),
        },
        enableDynamicChannelParking: true,
      );

      expect(controller.configuration.queues.length, equals(2));
      expect(controller.configuration.enableDynamicChannelParking, isTrue);

      controller.dispose();
    });
  });
}
