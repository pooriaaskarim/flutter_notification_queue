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
      const g = QueueGroupingBehavior(enabled: true, maxBeforeGrouping: 3);
      expect(g.enabled, isTrue);
      expect(g.maxBeforeGrouping, equals(3));

      const gDefault = QueueGroupingBehavior();
      expect(gDefault.enabled, isFalse);
      expect(gDefault.maxBeforeGrouping, equals(2));
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
      expect(find.text('+2 More'), findsNothing);

      // Add second notification to the same group
      NotificationWidget(message: 'Msg 2', channelName: 'chat').show();
      await tester.pumpAndSettle();

      // Now we have 2 notifications in group 'chat'.
      // Since maxBeforeGrouping is 2, they should be grouped/bundled.
      // Collapsed by default, so only the latest notification (Msg 2)
      // is visible.
      expect(find.text('Msg 2'), findsOneWidget);
      expect(find.text('Msg 1'), findsNothing);

      // Verify toggle button "+2 More" is visible
      expect(find.text('+2 More'), findsOneWidget);
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
      await tester.tap(find.text('+2 More'));
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

    testWidgets(
        'Dismissing collapsed group header dismisses all items in group',
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

      // Dismiss the header programmatically via n2
      final dismissFuture = n2.dismiss();
      await tester.pumpAndSettle();
      await dismissFuture;

      // Verify both are gone from the queue
      expect(find.text('Msg 1'), findsNothing);
      expect(find.text('Msg 2'), findsNothing);
    });
  });
}
