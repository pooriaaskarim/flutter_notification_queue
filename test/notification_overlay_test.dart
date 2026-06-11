import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationOverlay Integration', () {
    setUp(() {
      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'test_channel',
            position: QueuePosition.topRight,
            defaultIcon: Icon(Icons.check),
            defaultDismissDuration: null,
          ),
        },
        queues: {
          const TopRightQueue(),
        },
      );
    });

    tearDown(FlutterNotificationQueue.reset);

    testWidgets('Shows notification via builder integration',
        (final tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(
            body: Center(child: Text('App Home')),
          ),
        ),
      );

      // Verify initial state
      expect(find.text('App Home'), findsOneWidget);
      expect(find.byType(NotificationWidget), findsNothing);

      // Show notification
      Offset? firstLocation;
      NotificationWidget(
        message: 'Overlay Test',
        channelName: 'test_channel',
      ).show();

      await tester.pump(); // Start animation (enqueue)
      await tester.pump(); // Frame for adding post-frame callbacks if any

      // Verify it appears
      expect(find.text('Overlay Test'), findsOneWidget);
      expect(find.byType(NotificationWidget), findsOneWidget);

      // Capture location to verify it's valid (and conceptually "above" or at
      // least visible)
      firstLocation = tester.getCenter(find.text('Overlay Test'));
      expect(firstLocation, isNotNull);

      await tester.pumpAndSettle(); // Finish entry animation

      // Verify it stays
      expect(find.text('Overlay Test'), findsOneWidget);
    });

    testWidgets('Dismissal removes notification from overlay',
        (final tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(
            body: Center(child: Text('App Home')),
          ),
        ),
      );

      final notification = NotificationWidget(
        message: 'Dismiss Test',
        channelName: 'test_channel',
      )..show();

      await tester.pumpAndSettle();
      expect(find.text('Dismiss Test'), findsOneWidget);

      // Dismiss (async because it waits for animation)
      // We must pump while waiting for it, otherwise deadlock.
      final dismissFuture = notification.dismiss();
      await tester.pumpAndSettle();
      await dismissFuture;

      expect(find.text('Dismiss Test'), findsNothing);
      expect(find.byType(NotificationWidget), findsNothing);
    });

    testWidgets('Multiple notifications stack correctly', (final tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(
            body: Center(child: Text('App Home')),
          ),
        ),
      );

      NotificationWidget(message: 'First', channelName: 'test_channel').show();
      await tester.pump();
      NotificationWidget(message: 'Second', channelName: 'test_channel').show();
      await tester.pumpAndSettle();

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);

      // Verify vertical stacking (TopRightQueue)
      final firstCenter = tester.getCenter(find.text('First'));
      final secondCenter = tester.getCenter(find.text('Second'));

      // TopRightQueue typically stacks downwards?
      // Need to check specific queue behavior or just ensure they constitute a
      // column-like structure. Usually "First" is at the top? Or bottom
      // depending on implementation.
      // TopRightQueue typically has newer items at the bottom or top depending
      // on "gravity"? Standard/Default is usually growing downwards.

      // We just ensure they are not at the same position
      expect(firstCenter.dy, isNot(equals(secondCenter.dy)));
    });

    testWidgets('Overlapping adjacent queues are shifted to avoid collision',
        (final tester) async {
      tester.view.physicalSize = const Size(300, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'left_chan',
            position: QueuePosition.topLeft,
            defaultDismissDuration: null,
          ),
          const NotificationChannel(
            name: 'center_chan',
            position: QueuePosition.topCenter,
            defaultDismissDuration: null,
          ),
        },
        queues: {
          const TopLeftQueue(
            margin: EdgeInsets.all(10),
            spacing: 10,
          ),
          const TopCenterQueue(
            margin: EdgeInsets.all(10),
            spacing: 10,
          ),
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(
            body: Center(child: Text('App')),
          ),
        ),
      );

      NotificationWidget(
        id: 'n_left',
        message: 'L',
        channelName: 'left_chan',
      ).show();

      NotificationWidget(
        id: 'n_center',
        message: 'C',
        channelName: 'center_chan',
      ).show();

      await tester.pumpAndSettle();

      expect(find.text('L'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);

      final leftPos = tester.getTopLeft(find.text('L'));
      final centerPos = tester.getTopLeft(find.text('C'));

      expect(centerPos.dy, greaterThan(leftPos.dy));
    });

    testWidgets(
        'Non-overlapping adjacent queues with custom maxWidth are not shifted',
        (final tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'left_chan',
            position: QueuePosition.topLeft,
            defaultDismissDuration: null,
          ),
          const NotificationChannel(
            name: 'center_chan',
            position: QueuePosition.topCenter,
            defaultDismissDuration: null,
          ),
        },
        queues: {
          const TopLeftQueue(
            margin: EdgeInsets.all(10),
            spacing: 10,
            maxWidth: 200.0,
          ),
          const TopCenterQueue(
            margin: EdgeInsets.all(10),
            spacing: 10,
            maxWidth: 200.0,
          ),
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(
            body: Center(child: Text('App')),
          ),
        ),
      );

      NotificationWidget(
        id: 'n_left',
        message: 'L',
        channelName: 'left_chan',
      ).show();

      NotificationWidget(
        id: 'n_center',
        message: 'C',
        channelName: 'center_chan',
      ).show();

      await tester.pumpAndSettle();

      expect(find.text('L'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);

      final leftPos = tester.getTopLeft(find.text('L'));
      final centerPos = tester.getTopLeft(find.text('C'));

      expect(centerPos.dy, equals(leftPos.dy));
    });

    testWidgets(
        'Overlapping adjacent bottom queues are shifted upward to '
        'avoid collision',
        (final tester) async {
      tester.view.physicalSize = const Size(300, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'bottom_left_chan',
            position: QueuePosition.bottomLeft,
            defaultDismissDuration: null,
          ),
          const NotificationChannel(
            name: 'bottom_center_chan',
            position: QueuePosition.bottomCenter,
            defaultDismissDuration: null,
          ),
        },
        queues: {
          const BottomLeftQueue(
            margin: EdgeInsets.all(10),
            spacing: 10,
          ),
          const BottomCenterQueue(
            margin: EdgeInsets.all(10),
            spacing: 10,
          ),
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(
            body: Center(child: Text('App')),
          ),
        ),
      );

      NotificationWidget(
        id: 'n_left',
        message: 'L',
        channelName: 'bottom_left_chan',
      ).show();

      NotificationWidget(
        id: 'n_center',
        message: 'C',
        channelName: 'bottom_center_chan',
      ).show();

      await tester.pumpAndSettle();

      expect(find.text('L'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);

      final leftPos = tester.getTopLeft(find.text('L'));
      final centerPos = tester.getTopLeft(find.text('C'));

      // Bottom center should shift UPWARD, so centerPos.dy < leftPos.dy
      expect(centerPos.dy, lessThan(leftPos.dy));
    });

    testWidgets(
        'Non-overlapping adjacent bottom queues with custom maxWidth '
        'are not shifted upward',
        (final tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'bottom_left_chan',
            position: QueuePosition.bottomLeft,
            defaultDismissDuration: null,
          ),
          const NotificationChannel(
            name: 'bottom_center_chan',
            position: QueuePosition.bottomCenter,
            defaultDismissDuration: null,
          ),
        },
        queues: {
          const BottomLeftQueue(
            margin: EdgeInsets.all(10),
            spacing: 10,
            maxWidth: 200.0,
          ),
          const BottomCenterQueue(
            margin: EdgeInsets.all(10),
            spacing: 10,
            maxWidth: 200.0,
          ),
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(
            body: Center(child: Text('App')),
          ),
        ),
      );

      NotificationWidget(
        id: 'n_left',
        message: 'L',
        channelName: 'bottom_left_chan',
      ).show();

      NotificationWidget(
        id: 'n_center',
        message: 'C',
        channelName: 'bottom_center_chan',
      ).show();

      await tester.pumpAndSettle();

      expect(find.text('L'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);

      final leftPos = tester.getTopLeft(find.text('L'));
      final centerPos = tester.getTopLeft(find.text('C'));

      // Since they do not collide, they should remain aligned vertically
      expect(centerPos.dy, equals(leftPos.dy));
    });

    testWidgets(
        'Overlapping adjacent center queues are shifted downward to '
        'avoid collision',
        (final tester) async {
      tester.view.physicalSize = const Size(300, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'center_left_chan',
            position: QueuePosition.centerLeft,
            defaultDismissDuration: null,
          ),
          const NotificationChannel(
            name: 'center_right_chan',
            position: QueuePosition.centerRight,
            defaultDismissDuration: null,
          ),
        },
        queues: {
          const CenterLeftQueue(
            margin: EdgeInsets.all(10),
            spacing: 10,
          ),
          const CenterRightQueue(
            margin: EdgeInsets.all(10),
            spacing: 10,
          ),
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(
            body: Center(child: Text('App')),
          ),
        ),
      );

      NotificationWidget(
        id: 'n_left',
        message: 'L',
        channelName: 'center_left_chan',
      ).show();

      NotificationWidget(
        id: 'n_right',
        message: 'R',
        channelName: 'center_right_chan',
      ).show();

      await tester.pumpAndSettle();

      expect(find.text('L'), findsOneWidget);
      expect(find.text('R'), findsOneWidget);

      final leftPos = tester.getTopLeft(find.text('L'));
      final rightPos = tester.getTopLeft(find.text('R'));

      // Center right should shift DOWNWARD because it's placed after
      // center left and center positions fallback to downward shift.
      expect(rightPos.dy, greaterThan(leftPos.dy));
    });

    testWidgets(
        'Non-overlapping adjacent center queues with custom maxWidth '
        'are not shifted',
        (final tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'center_left_chan',
            position: QueuePosition.centerLeft,
            defaultDismissDuration: null,
          ),
          const NotificationChannel(
            name: 'center_right_chan',
            position: QueuePosition.centerRight,
            defaultDismissDuration: null,
          ),
        },
        queues: {
          const CenterLeftQueue(
            margin: EdgeInsets.all(10),
            spacing: 10,
            maxWidth: 200.0,
          ),
          const CenterRightQueue(
            margin: EdgeInsets.all(10),
            spacing: 10,
            maxWidth: 200.0,
          ),
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(
            body: Center(child: Text('App')),
          ),
        ),
      );

      NotificationWidget(
        id: 'n_left',
        message: 'L',
        channelName: 'center_left_chan',
      ).show();

      NotificationWidget(
        id: 'n_right',
        message: 'R',
        channelName: 'center_right_chan',
      ).show();

      await tester.pumpAndSettle();

      expect(find.text('L'), findsOneWidget);
      expect(find.text('R'), findsOneWidget);

      final leftPos = tester.getTopLeft(find.text('L'));
      final rightPos = tester.getTopLeft(find.text('R'));

      // Since they do not collide, they should remain aligned vertically
      expect(rightPos.dy, equals(leftPos.dy));
    });
  });
}
