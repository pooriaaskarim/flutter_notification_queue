import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Notification Grouping / Bundling (F-04)', () {
    setUp(() {
      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'chat',
            position: QueuePosition.topRight,
            defaultDismissDuration: null,
          ),
          const NotificationChannel(
            name: 'system',
            position: QueuePosition.topRight,
            defaultDismissDuration: null,
          ),
        },
        queues: {
          const TopRightQueue(
            groupingBehavior: QueueGroupingBehavior(
              enabled: true,
              maxBeforeGrouping: 2,
            ),
          ),
        },
      );
    });

    tearDown(FlutterNotificationQueue.reset);

    test('QueueGroupingBehavior defaults and custom properties', () {
      const g = QueueGroupingBehavior(
        enabled: true,
        maxBeforeGrouping: 3,
        maxStackedLayers: 4,
        stackStepOffset: 8.0,
        stackScaleMultiplier: 0.08,
        enableGroupSwipeDismiss: true,
        groupDismissThreshold: 0.5,
      );
      expect(g.enabled, isTrue);
      expect(g.maxBeforeGrouping, equals(3));
      expect(g.maxStackedLayers, equals(4));
      expect(g.stackStepOffset, equals(8.0));
      expect(g.stackScaleMultiplier, equals(0.08));
      expect(g.enableGroupSwipeDismiss, isTrue);
      expect(g.groupDismissThreshold, equals(0.5));

      const gDefault = QueueGroupingBehavior();
      expect(gDefault.enabled, isFalse);
      expect(gDefault.maxBeforeGrouping, equals(2));
      expect(gDefault.maxStackedLayers, equals(2));
      expect(gDefault.stackStepOffset, equals(6.0));
      expect(gDefault.stackScaleMultiplier, equals(0.05));
      expect(gDefault.enableGroupSwipeDismiss, isFalse);
      expect(gDefault.groupDismissThreshold, equals(0.4));
    });

    testWidgets('resolvedGroupKey returns custom key or channelName',
        (final tester) async {
      final n1 = NotificationWidget(
        message: 'Hello',
        channelName: 'chat',
      );
      expect(n1.resolvedGroupKey, equals('chat'));

      final n2 = NotificationWidget(
        message: 'World',
        channelName: 'chat',
        groupKey: 'custom_group',
      );
      expect(n2.resolvedGroupKey, equals('custom_group'));
    });

    testWidgets('Notifications are grouped when count >= maxBeforeGrouping',
        (final tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(body: Center(child: Text('App Home'))),
        ),
      );

      // Add first notification
      NotificationWidget(message: 'Msg 1', channelName: 'chat').show();
      await tester.pumpAndSettle();

      // Grouping behavior requires 2 notifications. Since we only have 1,
      // it should be rendered individually (no _GroupBundleWidget).
      expect(find.text('Msg 1'), findsOneWidget);
      expect(find.text('+1'), findsNothing);

      // Add second notification to the same group
      NotificationWidget(message: 'Msg 2', channelName: 'chat').show();
      await tester.pumpAndSettle();

      // Now we have 2 notifications in group 'chat'.
      // Since maxBeforeGrouping is 2, they should be grouped/bundled.
      // Collapsed by default, so only the latest notification (Msg 2)
      // is visible.
      expect(find.text('Msg 2'), findsOneWidget);
      expect(find.text('Msg 1'), findsNothing);

      // Verify toggle button "+1" is visible (1 item hidden)
      expect(find.text('+1'), findsOneWidget);
    });

    testWidgets('Expand and collapse group via toggle button',
        (final tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(body: Center(child: Text('App Home'))),
        ),
      );

      NotificationWidget(message: 'Msg 1', channelName: 'chat').show();
      NotificationWidget(message: 'Msg 2', channelName: 'chat').show();
      await tester.pumpAndSettle();

      // Collapsed: only Msg 2 is visible
      expect(find.text('Msg 2'), findsOneWidget);
      expect(find.text('Msg 1'), findsNothing);

      // Tap the expand button
      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();

      // Expanded: both Msg 1 and Msg 2 are visible
      expect(find.text('Msg 1'), findsOneWidget);
      expect(find.text('Msg 2'), findsOneWidget);
      expect(find.text('Collapse'), findsOneWidget);

      // Tap the collapse button
      await tester.tap(find.text('Collapse'));
      await tester.pumpAndSettle();

      // Collapsed again: only Msg 2 is visible
      expect(find.text('Msg 2'), findsOneWidget);
      expect(find.text('Msg 1'), findsNothing);
    });

    testWidgets('Dismissing collapsed group representative surfaces next item',
        (final tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(body: Center(child: Text('App Home'))),
        ),
      );

      NotificationWidget(message: 'Msg 1', channelName: 'chat').show();
      final n2 = NotificationWidget(message: 'Msg 2', channelName: 'chat')
        ..show();
      await tester.pumpAndSettle();

      expect(find.text('Msg 2'), findsOneWidget);
      expect(find.text('Msg 1'), findsNothing);

      // Dismiss the representative programmatically via n2
      final dismissFuture = n2.dismiss();
      await tester.pumpAndSettle();
      await dismissFuture;

      // Verify that n2 (Msg 2) is gone, but n1 (Msg 1) has surfaced
      // and is now visible
      expect(find.text('Msg 2'), findsNothing);
      expect(find.text('Msg 1'), findsOneWidget);
    });

    testWidgets('dismissGroup dismisses all items in the group',
        (final tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(body: Center(child: Text('App Home'))),
        ),
      );

      NotificationWidget(message: 'Msg 1', channelName: 'chat').show();
      NotificationWidget(message: 'Msg 2', channelName: 'chat').show();
      await tester.pumpAndSettle();

      expect(find.text('Msg 2'), findsOneWidget);
      expect(find.text('Msg 1'), findsNothing);

      // Dismiss the entire group
      FlutterNotificationQueue.coordinator.dismissGroup(
        QueuePosition.topRight,
        'chat',
      );
      await tester.pumpAndSettle();

      // Verify both items are gone
      expect(find.text('Msg 2'), findsNothing);
      expect(find.text('Msg 1'), findsNothing);
    });

    testWidgets(
        'Swiping collapsed group representative dismisses all items '
        'when enableGroupSwipeDismiss is true', (final tester) async {
      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'chat',
            position: QueuePosition.topRight,
            defaultDismissDuration: null,
          ),
        },
        queues: {
          const TopRightQueue(
            dragBehavior: Dismiss(),
            groupingBehavior: QueueGroupingBehavior(
              enabled: true,
              maxBeforeGrouping: 2,
              enableGroupSwipeDismiss: true,
            ),
          ),
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(body: Center(child: Text('App Home'))),
        ),
      );

      NotificationWidget(message: 'Msg 1', channelName: 'chat').show();
      NotificationWidget(message: 'Msg 2', channelName: 'chat').show();
      await tester.pumpAndSettle();

      expect(find.text('Msg 2'), findsOneWidget);
      expect(find.text('Msg 1'), findsNothing);

      // Swipe to dismiss Msg 2 (the representative)
      await tester.drag(find.text('Msg 2'), const Offset(300, 0));
      await tester.pumpAndSettle();

      // Since enableGroupSwipeDismiss is true, the entire group is dismissed
      expect(find.text('Msg 2'), findsNothing);
      expect(find.text('Msg 1'), findsNothing);
    });

    testWidgets(
        'Swiping collapsed group representative dismisses only representative '
        'when enableGroupSwipeDismiss is false', (final tester) async {
      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'chat',
            position: QueuePosition.topRight,
            defaultDismissDuration: null,
          ),
        },
        queues: {
          const TopRightQueue(
            dragBehavior: Dismiss(),
            groupingBehavior: QueueGroupingBehavior(
              enabled: true,
              maxBeforeGrouping: 2,
              enableGroupSwipeDismiss: false,
            ),
          ),
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(body: Center(child: Text('App Home'))),
        ),
      );

      NotificationWidget(message: 'Msg 1', channelName: 'chat').show();
      NotificationWidget(message: 'Msg 2', channelName: 'chat').show();
      await tester.pumpAndSettle();

      expect(find.text('Msg 2'), findsOneWidget);
      expect(find.text('Msg 1'), findsNothing);

      // Swipe to dismiss Msg 2
      await tester.drag(find.text('Msg 2'), const Offset(300, 0));
      await tester.pumpAndSettle();

      // Since enableGroupSwipeDismiss is false, only Msg 2 is dismissed and
      // Msg 1 surfaces
      expect(find.text('Msg 2'), findsNothing);
      expect(find.text('Msg 1'), findsOneWidget);
    });

    testWidgets(
        'Dragging collapsed group representative reveals the peek card '
        '(underneath notification) during drag', (final tester) async {
      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'chat',
            position: QueuePosition.topRight,
            defaultDismissDuration: null,
          ),
        },
        queues: {
          const TopRightQueue(
            dragBehavior: Dismiss(),
            groupingBehavior: QueueGroupingBehavior(
              enabled: true,
              maxBeforeGrouping: 2,
            ),
          ),
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(body: Center(child: Text('App Home'))),
        ),
      );

      NotificationWidget(message: 'Msg 1', channelName: 'chat').show();
      NotificationWidget(message: 'Msg 2', channelName: 'chat').show();
      await tester.pumpAndSettle();

      // Before drag, Msg 2 is visible, Msg 1 is hidden
      expect(find.text('Msg 2'), findsOneWidget);
      expect(find.text('Msg 1'), findsNothing);

      // Start dragging Msg 2
      final gesture =
          await tester.startGesture(tester.getCenter(find.text('Msg 2')));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      // During drag: both Msg 2 (in feedback/drag) and Msg 1
      // (revealed underneath) should be visible!
      expect(find.text('Msg 1'), findsOneWidget);

      // Finish drag
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
