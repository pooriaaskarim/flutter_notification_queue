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
            position: QueuePosition.bottomLeft,
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
          const BottomLeftQueue(
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

    testWidgets(
        'Scenario 1: Multi-Group Lifecycle - Grouping, Isolated '
        'Expansion/Collapse, Priority Triage/Overflow, and Programmatic '
        'Dismissal', (final tester) async {
      // Configure with different positions and maxStackSize constraints to
      // test multiple layout settings
      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'chat',
            position: QueuePosition.topRight,
            defaultDismissDuration: null,
          ),
          const NotificationChannel(
            name: 'system',
            position: QueuePosition.bottomLeft,
            defaultDismissDuration: null,
          ),
        },
        queues: {
          const TopRightQueue(
            groupingBehavior: QueueGroupingBehavior(
              enabled: true,
              maxBeforeGrouping: 2,
            ),
            maxStackSize: 2,
          ),
          const BottomLeftQueue(
            groupingBehavior: QueueGroupingBehavior(
              enabled: true,
              maxBeforeGrouping: 2,
            ),
            maxStackSize: 2,
          ),
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(body: Center(child: Text('App Home'))),
        ),
      );

      // 1. Enqueue single 'chat' notification (c1) to Top Right
      NotificationWidget(
        id: 'c1',
        message: 'Chat 1',
        channelName: 'chat',
        priority: NotificationPriority.low,
      ).show();
      await tester.pumpAndSettle();

      // Verify c1 is active and visible as standard individual item.
      expect(find.text('Chat 1'), findsOneWidget);
      expect(find.text('+1'), findsNothing);

      // 2. Enqueue second 'chat' notification (c2) -> should activate
      // grouping automatically
      NotificationWidget(
        id: 'c2',
        message: 'Chat 2',
        channelName: 'chat',
      ).show();
      await tester.pumpAndSettle();

      // Grouping activates itself once threshold (2) is met.
      // Chat 2 is the representative. Chat 1 is hidden. Badge
      // indication '+1' is visible.
      expect(find.text('Chat 2'), findsOneWidget);
      expect(find.text('Chat 1'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('chat')),
          matching: find.text('+1'),
        ),
        findsOneWidget,
      );

      // 3. Enqueue first 'system' notification (s1) to Bottom Left
      NotificationWidget(
        id: 's1',
        message: 'System 1',
        channelName: 'system',
      ).show();
      await tester.pumpAndSettle();

      // Both queues are active concurrently. Sys 1 is visible at
      // bottom left; Chat 2 at top right.
      expect(find.text('Chat 2'), findsOneWidget);
      expect(find.text('System 1'), findsOneWidget);

      // 4. Enqueue second 'system' notification (s2) -> should activate
      // system grouping automatically
      NotificationWidget(
        id: 's2',
        message: 'System 2',
        channelName: 'system',
      ).show();
      await tester.pumpAndSettle();

      // System grouping is activated.
      // Since bottomLeft is bottom-anchored, the oldest card (System 1)
      // is the representative.
      // System 1 is visible, System 2 is hidden. Badge '+1' is visible
      // at Bottom Left.
      expect(find.text('Chat 2'), findsOneWidget);
      expect(find.text('System 1'), findsOneWidget);
      expect(find.text('Chat 1'), findsNothing);
      expect(find.text('System 2'), findsNothing);
      expect(find.text('+1'), findsNWidgets(2));

      // 5. Expand 'chat' group at Top Right
      final chatGroupFinder = find.byKey(const ValueKey('chat'));
      await tester
          .tap(find.descendant(of: chatGroupFinder, matching: find.text('+1')));
      await tester.pumpAndSettle();

      // 'chat' group expanded: Chat 2, Chat 1 and Collapse button are visible.
      expect(find.text('Chat 2'), findsOneWidget);
      expect(find.text('Chat 1'), findsOneWidget);
      expect(
        find.descendant(
          of: chatGroupFinder,
          matching: find.text('Collapse'),
        ),
        findsOneWidget,
      );

      // 'system' group remains collapsed at Bottom Left: System 2 is
      // hidden, System 1 + badge is visible
      final systemGroupFinder = find.byKey(const ValueKey('system'));
      expect(find.text('System 1'), findsOneWidget);
      expect(find.text('System 2'), findsNothing);
      expect(
        find.descendant(
          of: systemGroupFinder,
          matching: find.text('+1'),
        ),
        findsOneWidget,
      );

      // 6. Enqueue critical 'chat' notification (c3) to trigger
      // TopRightQueue overflow (maxStackSize: 2)
      // Since queue has c1 (low) and c2 (normal), adding c3 (high)
      // should evict c1.
      NotificationWidget(
        id: 'c3',
        message: 'Chat 3',
        channelName: 'chat',
        priority: NotificationPriority.high,
      ).show();
      await tester.pumpAndSettle();

      // Verify Chat 3 is visible, Chat 1 is evicted
      expect(find.text('Chat 3'), findsOneWidget);
      expect(find.text('Chat 1'), findsNothing);

      // 7. Collapse 'chat' group at Top Right
      await tester.tap(
        find.descendant(
          of: chatGroupFinder,
          matching: find.text('Collapse'),
        ),
      );
      await tester.pumpAndSettle();

      // Chat 3 is representative, Chat 2 is underneath
      expect(find.text('Chat 3'), findsOneWidget);
      expect(find.text('Chat 2'), findsNothing);

      // 8. Programmatic group dismissal for 'chat' queue
      FlutterNotificationQueue.coordinator.dismissGroup(
        QueuePosition.topRight,
        'chat',
      );
      await tester.pumpAndSettle();

      // Chat notifications are gone, system group remains at Bottom Left
      expect(find.text('Chat 3'), findsNothing);
      expect(find.text('Chat 2'), findsNothing);
      expect(find.text('System 1'), findsOneWidget);

      // 9. Programmatic item dismissal on System 1 representative
      final s1Widget = NotificationWidget(
        id: 's1',
        message: 'System 1',
        channelName: 'system',
      );
      final dismissFuture = s1Widget.dismiss();
      await tester.pumpAndSettle();
      await dismissFuture;

      // System 1 is gone, System 2 has surfaced and is now visible
      // at Bottom Left
      expect(find.text('System 1'), findsNothing);
      expect(find.text('System 2'), findsOneWidget);
    });

    testWidgets(
        'Scenario 2: Advanced Interactive Gestures - Drag-to-Peek, '
        'Swipe-to-Dismiss Config, and Expanded Swipe', (final tester) async {
      // Configuration with enableGroupSwipeDismiss = true on
      // Bottom Right Position
      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'chat',
            position: QueuePosition.bottomRight,
            defaultDismissDuration: null,
          ),
        },
        queues: {
          const BottomRightQueue(
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

      // Enqueue 2 notifications to bundle automatically on Bottom Right
      NotificationWidget(id: 'c1', message: 'Chat 1', channelName: 'chat')
          .show();
      NotificationWidget(id: 'c2', message: 'Chat 2', channelName: 'chat')
          .show();
      await tester.pumpAndSettle();

      // Bottom Right is bottom-anchored: oldest (Chat 1) is the representative
      expect(find.text('Chat 1'), findsOneWidget);
      expect(find.text('Chat 2'), findsNothing);

      // 1. Drag representative slightly to peek underneath
      final gesture =
          await tester.startGesture(tester.getCenter(find.text('Chat 1')));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      // During drag: both Chat 1 and Chat 2 (peeked) are visible
      expect(find.text('Chat 2'), findsOneWidget);

      // Cancel drag
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      // 2. Swipe to dismiss entire group (enableGroupSwipeDismiss = true)
      await tester.drag(find.text('Chat 1'), const Offset(300, 0));
      await tester.pumpAndSettle();

      // Both chat notifications dismissed
      expect(find.text('Chat 2'), findsNothing);
      expect(find.text('Chat 1'), findsNothing);

      // 3. Reconfigure with enableGroupSwipeDismiss = false on
      // Top Left Position
      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'chat',
            position: QueuePosition.topLeft,
            defaultDismissDuration: null,
          ),
        },
        queues: {
          const TopLeftQueue(
            dragBehavior: Dismiss(),
            groupingBehavior: QueueGroupingBehavior(
              enabled: true,
              maxBeforeGrouping: 2,
              enableGroupSwipeDismiss: false,
            ),
          ),
        },
      );

      // Enqueue 3 notifications
      NotificationWidget(id: 'c1', message: 'Chat 1', channelName: 'chat')
          .show();
      NotificationWidget(id: 'c2', message: 'Chat 2', channelName: 'chat')
          .show();
      NotificationWidget(id: 'c3', message: 'Chat 3', channelName: 'chat')
          .show();
      await tester.pumpAndSettle();

      // Top Left is top-anchored: newest (Chat 3) is the representative
      expect(find.text('Chat 3'), findsOneWidget);
      expect(find.text('Chat 2'), findsNothing);

      // 4. Swipe to dismiss representative (enableGroupSwipeDismiss = false)
      // Since it is topLeft, we swipe left (negative X offset) to dismiss
      await tester.drag(find.text('Chat 3'), const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Chat 3 is gone, Chat 2 surfaces, +1 badge visible
      // (Chat 2 & Chat 1 remain)
      expect(find.text('Chat 3'), findsNothing);
      expect(find.text('Chat 2'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('chat')),
          matching: find.text('+1'),
        ),
        findsOneWidget,
      );

      // 5. Expand remaining group
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('chat')),
          matching: find.text('+1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chat 2'), findsOneWidget);
      expect(find.text('Chat 1'), findsOneWidget);

      // 6. Swipe to dismiss one item in the expanded list (Chat 2)
      // Since it is topLeft, we swipe left (negative X offset) to dismiss
      await tester.drag(find.text('Chat 2'), const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Chat 2 is dismissed, Chat 1 remains visible.
      // Since only 1 notification remains, grouping controls are removed.
      expect(find.text('Chat 2'), findsNothing);
      expect(find.text('Chat 1'), findsOneWidget);
      expect(find.text('Collapse'), findsNothing);
      expect(find.text('+1'), findsNothing);
    });
  });
}
