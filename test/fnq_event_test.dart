import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    FlutterNotificationQueue.reset();
    FlutterNotificationQueue.configure();
  });

  tearDown(() {
    FlutterNotificationQueue.reset();
  });

  // ── Helpers ──

  NotificationWidget _widget({
    String? id,
    String channelName = 'info',
    TapBehavior? tapBehavior,
  }) =>
      NotificationWidget(
        title: 'Test',
        message: 'Test message',
        channelName: channelName,
        tapBehavior: tapBehavior,
      );

  // ── NotificationQueued ─────────────────────────────────────────────────────

  group('NotificationQueued', () {
    test('emits when show() is called', () async {
      final events = <FnqEvent>[];
      final sub =
          FlutterNotificationQueue.events.listen(events.add);

      _widget().show();
      await Future.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first, isA<NotificationQueued>());
      await sub.cancel();
    });

    test('does NOT emit when channel is disabled', () async {
      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'disabled_ch',
            enabled: false,
          ),
        },
      );
      final events = <FnqEvent>[];
      final sub =
          FlutterNotificationQueue.events.listen(events.add);

      _widget(channelName: 'disabled_ch').show();
      await Future.delayed(Duration.zero);

      expect(events, isEmpty);
      await sub.cancel();
    });

    test('carries correct notification reference', () async {
      final n = _widget();
      final events = <FnqEvent>[];
      final sub =
          FlutterNotificationQueue.events.listen(events.add);

      n.show();
      await Future.delayed(Duration.zero);

      final queued = events.first as NotificationQueued;
      expect(queued.notification.id, equals(n.id));
      await sub.cancel();
    });
  });

  // ── NotificationDismissed — programmatic ──────────────────────────────────

  group('NotificationDismissed (programmatic)', () {
    test('emits NotificationDismissed with reason=programmatic', () async {
      final n = _widget();
      final events = <FnqEvent>[];
      final sub = FlutterNotificationQueue.events.listen(events.add);

      // Emit directly — tests without a widget tree cannot call show()/dismiss()
      // on a mounted widget, but the coordinator can emit standalone.
      FlutterNotificationQueue.coordinator.emitEvent(
        NotificationDismissed(
          notification: n,
          reason: DismissReason.programmatic,
        ),
      );
      await Future.delayed(Duration.zero);

      final dismissed = events.whereType<NotificationDismissed>().first;
      expect(dismissed.reason, DismissReason.programmatic);
      await sub.cancel();
    });

    test('emits with reason=timeout', () async {
      final n = _widget();
      final events = <FnqEvent>[];
      final sub = FlutterNotificationQueue.events.listen(events.add);

      FlutterNotificationQueue.coordinator.emitEvent(
        NotificationDismissed(
          notification: n,
          reason: DismissReason.timeout,
        ),
      );
      await Future.delayed(Duration.zero);

      final dismissed = events.whereType<NotificationDismissed>().first;
      expect(dismissed.reason, DismissReason.timeout);
      await sub.cancel();
    });

    test('emits with reason=userSwipe', () async {
      final n = _widget();
      final events = <FnqEvent>[];
      final sub = FlutterNotificationQueue.events.listen(events.add);

      FlutterNotificationQueue.coordinator.emitEvent(
        NotificationDismissed(
          notification: n,
          reason: DismissReason.userSwipe,
        ),
      );
      await Future.delayed(Duration.zero);

      final dismissed = events.whereType<NotificationDismissed>().first;
      expect(dismissed.reason, DismissReason.userSwipe);
      await sub.cancel();
    });

    test('emits with reason=userTap', () async {
      final n = _widget();
      final events = <FnqEvent>[];
      final sub = FlutterNotificationQueue.events.listen(events.add);

      FlutterNotificationQueue.coordinator.emitEvent(
        NotificationDismissed(
          notification: n,
          reason: DismissReason.userTap,
        ),
      );
      await Future.delayed(Duration.zero);

      final dismissed = events.whereType<NotificationDismissed>().first;
      expect(dismissed.reason, DismissReason.userTap);
      await sub.cancel();
    });
  });

  // ── NotificationRelocated ─────────────────────────────────────────────────

  group('NotificationRelocated', () {
    test('emits NotificationRelocated with correct from/to positions', () async {
      FlutterNotificationQueue.configure(
        queues: {
          NotificationQueue.defaultQueue(position: QueuePosition.topLeft),
          NotificationQueue.defaultQueue(position: QueuePosition.topRight),
        },
      );

      final n = NotificationWidget(
        title: 'Relocate me',
        message: 'Relocate message',
        channelName: 'info',
        position: QueuePosition.topLeft,
      );

      final events = <FnqEvent>[];
      final sub = FlutterNotificationQueue.events.listen(events.add);

      FlutterNotificationQueue.coordinator.emitEvent(
        NotificationRelocated(
          notification: n,
          from: QueuePosition.topLeft,
          to: QueuePosition.topRight,
        ),
      );
      await Future.delayed(Duration.zero);

      final relocated = events.whereType<NotificationRelocated>();
      expect(relocated, isNotEmpty);
      final r = relocated.first;
      expect(r.from, QueuePosition.topLeft);
      expect(r.to, QueuePosition.topRight);
      await sub.cancel();
    });
  });

  // ── NotificationReordered ─────────────────────────────────────────────────

  group('NotificationReordered', () {
    test('emits with correct toIndex', () async {
      final n = _widget();
      final events = <FnqEvent>[];
      final sub =
          FlutterNotificationQueue.events.listen(events.add);

      // Reorder emits the event regardless of widget mount state
      FlutterNotificationQueue.coordinator.reorder(n, 2);
      await Future.delayed(Duration.zero);

      final reordered = events.whereType<NotificationReordered>().first;
      expect(reordered.toIndex, 2);
      expect(reordered.notification.id, n.id);
      await sub.cancel();
    });
  });

  // ── Stream integrity ──────────────────────────────────────────────────────

  group('Stream integrity', () {
    test('supports multiple concurrent listeners', () async {
      final a = <FnqEvent>[];
      final b = <FnqEvent>[];
      final subA = FlutterNotificationQueue.events.listen(a.add);
      final subB = FlutterNotificationQueue.events.listen(b.add);

      _widget().show();
      await Future.delayed(Duration.zero);

      expect(a, hasLength(1));
      expect(b, hasLength(1));
      await subA.cancel();
      await subB.cancel();
    });

    test('FlutterNotificationQueue.events is a broadcast stream',
        () {
      expect(
        FlutterNotificationQueue.events.isBroadcast,
        isTrue,
      );
    });
  });

  group('NotificationTapped', () {
    test('NotificationTapped carries correct behavior type via emitTapped', () async {
      final n = _widget(tapBehavior: const TapToExpand());
      final events = <FnqEvent>[];
      final sub = FlutterNotificationQueue.events.listen(events.add);

      FlutterNotificationQueue.coordinator.emitTapped(
        notification: n,
        behavior: const TapToExpand(),
      );
      await Future.delayed(Duration.zero);

      expect(events, hasLength(1));
      final tapped = events.first as NotificationTapped;
      expect(tapped.behavior, isA<TapToExpand>());
      expect(tapped.notification.id, n.id);
      await sub.cancel();
    });

    test('emitTapped emits for TapToAct with correct behavior', () async {
      final n = _widget(tapBehavior: TapToAct(onTap: () {}));
      final events = <FnqEvent>[];
      final sub = FlutterNotificationQueue.events.listen(events.add);

      FlutterNotificationQueue.coordinator.emitTapped(
        notification: n,
        behavior: TapToAct(onTap: () {}),
      );
      await Future.delayed(Duration.zero);

      final tapped = events.whereType<NotificationTapped>().first;
      expect(tapped.behavior, isA<TapToAct>());
      await sub.cancel();
    });
  });
}
