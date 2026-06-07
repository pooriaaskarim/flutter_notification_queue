// ignore_for_file: cascade_invocations

import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPriority unit tests', () {
    test('NotificationWidget priority fields store values correctly', () {
      final n = NotificationWidget(
        message: 'Priority test',
        priority: NotificationPriority.critical,
      );

      expect(n.priority, NotificationPriority.critical);
      expect(n.resolvedPriority, NotificationPriority.critical);
    });

    test('resolvedPriority falls back to channel default', () {
      final defaultChannel = NotificationChannel.defaultChannel();
      final nDefault = NotificationWidget(
        message: 'Default channel test',
        channelName: defaultChannel.name,
      );
      expect(nDefault.resolvedPriority, NotificationPriority.normal);

      final infoChannel = NotificationChannel.infoChannel();
      final nInfo = NotificationWidget(
        message: 'Info channel test',
        channelName: infoChannel.name,
      );
      expect(nInfo.resolvedPriority, NotificationPriority.low);

      final errorChannel = NotificationChannel.errorChannel();
      final nError = NotificationWidget(
        message: 'Error channel test',
        channelName: errorChannel.name,
      );
      expect(nError.resolvedPriority, NotificationPriority.high);
    });

    test('NotificationWidget custom priority override takes precedence', () {
      final n = NotificationWidget(
        message: 'Override test',
        channelName: 'info',
        priority: NotificationPriority.critical,
      );

      expect(n.resolvedPriority, NotificationPriority.critical);
    });

    test('copyToQueue preserves custom priority overrides', () {
      final n = NotificationWidget(
        message: 'Override test',
        priority: NotificationPriority.high,
      );

      final copy = n.copyToQueue(const TopRightQueue());

      expect(copy.priority, NotificationPriority.high);
      expect(copy.resolvedPriority, NotificationPriority.high);
    });
  });

  group('Priority Triage integration tests', () {
    setUp(() {
      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'test',
            position: QueuePosition.topRight,
            defaultPriority: NotificationPriority.normal,
            defaultDismissDuration: null,
          ),
          const NotificationChannel(
            name: 'high_ch',
            position: QueuePosition.topRight,
            defaultPriority: NotificationPriority.high,
            defaultDismissDuration: null,
          ),
          const NotificationChannel(
            name: 'low_ch',
            position: QueuePosition.topRight,
            defaultPriority: NotificationPriority.low,
            defaultDismissDuration: null,
          ),
        },
        queues: {
          const TopRightQueue(
            maxStackSize: 2,
          ),
        },
      );
    });

    tearDown(() {
      FlutterNotificationQueue.reset();
    });

    testWidgets(
      'auto-sorting promotes high priority items ahead of low priority ones',
      (final tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            builder: FlutterNotificationQueue.builder,
            home: Scaffold(
              body: SizedBox.expand(),
            ),
          ),
        );

        // Enqueue low and then high into the coordinator before starting
        final low = NotificationWidget(
          id: 'low_auto',
          message: 'Low priority',
          channelName: 'low_ch',
        );
        final high = NotificationWidget(
          id: 'high_auto',
          message: 'High priority',
          channelName: 'high_ch',
        );

        low.show();
        high.show();

        await tester.pumpAndSettle();

        // Since the queue limit is 2, both will be promoted, but let's test
        // auto-sorting by using 3 notifications in a queue of limit 2.
        final extraLow = NotificationWidget(
          id: 'extra_low_auto',
          message: 'Extra Low priority',
          channelName: 'low_ch',
        );

        extraLow.show();
        await tester.pumpAndSettle();

        // Active items should be the two highest priority ones: High & Low.
        // Extra Low should be pending in the queue because of the limit of 2.
        expect(find.text('High priority'), findsOneWidget);
        expect(find.text('Low priority'), findsOneWidget);
        expect(find.text('Extra Low priority'), findsNothing);
      },
    );

    testWidgets(
      'critical notification evicts active low priority notification when full',
      (final tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            builder: FlutterNotificationQueue.builder,
            home: Scaffold(
              body: SizedBox.expand(),
            ),
          ),
        );

        final firstLow = NotificationWidget(
          id: 'low_1',
          message: 'First Low',
          channelName: 'low_ch',
        );
        final secondLow = NotificationWidget(
          id: 'low_2',
          message: 'Second Low',
          channelName: 'low_ch',
        );

        firstLow.show();
        secondLow.show();
        await tester.pumpAndSettle();

        // Both active low-priority notifications are showing
        expect(find.text('First Low'), findsOneWidget);
        expect(find.text('Second Low'), findsOneWidget);

        // Enqueue a High priority notification
        final criticalAlert = NotificationWidget(
          id: 'high_1',
          message: 'Critical Alert',
          channelName: 'high_ch',
        );

        criticalAlert.show();

        // Pump once to start the reverse animation of one of the low items,
        // and then settle to complete the exit and subsequent enter animations.
        await tester.pump();
        await tester.pumpAndSettle();

        // The critical high-priority alert must have evicted one low item
        expect(find.text('Critical Alert'), findsOneWidget);
        // At least one of the low ones was evicted. Let's assert:
        expect(
          find.text('First Low').evaluate().length +
              find.text('Second Low').evaluate().length,
          1,
        );
      },
    );

    testWidgets(
      'evicted notification automatically resumes once '
      'critical alert is dismissed',
      (final tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            builder: FlutterNotificationQueue.builder,
            home: Scaffold(
              body: SizedBox.expand(),
            ),
          ),
        );

        final firstLow = NotificationWidget(
          id: 'low_1_resume',
          message: 'First Low',
          channelName: 'low_ch',
        );
        final secondLow = NotificationWidget(
          id: 'low_2_resume',
          message: 'Second Low',
          channelName: 'low_ch',
        );

        firstLow.show();
        secondLow.show();
        await tester.pumpAndSettle();

        // Enqueue high priority alert
        final criticalAlert = NotificationWidget(
          id: 'high_1_resume',
          message: 'Critical Alert',
          channelName: 'high_ch',
        );
        criticalAlert.show();
        await tester.pump();
        await tester.pumpAndSettle();

        // Dismiss the critical alert
        final dismissFuture = criticalAlert.dismiss();
        await tester.pump();
        await tester.pumpAndSettle();
        await dismissFuture;

        // The critical alert is gone, and both low priority items must return
        expect(find.text('Critical Alert'), findsNothing);
        expect(find.text('First Low'), findsOneWidget);
        expect(find.text('Second Low'), findsOneWidget);
      },
    );
  });
}
