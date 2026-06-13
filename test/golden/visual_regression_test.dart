import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_notification_queue/src/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FNQ Visual Regression Golden Tests', () {
    setUp(() {
      // Configuration will be overridden in individual test cases
    });

    tearDown(() {
      FlutterNotificationQueue.reset();
    });

    testWidgets('FlatQueueStyle Golden Test', (final tester) async {
      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'default',
            position: QueuePosition.topCenter,
            defaultDismissDuration: null,
          ),
        },
        queues: {
          const TopCenterQueue(
            style: FlatQueueStyle(opacity: 0.9),
            maxStackSize: 2,
          ),
        },
      );

      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          builder: FlutterNotificationQueue.builder,
          home: const Scaffold(
            body: Center(
              child: Text('App Content'),
            ),
          ),
        ),
      );

      NotificationWidget(
        id: 'n1',
        title: 'Flat Notification',
        message: 'This is a flat queue style notification.',
        icon: const Icon(Icons.info_outline, color: Colors.blue),
      ).show();

      await tester.pump();
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await expectLater(
        find.byType(NotificationOverlay),
        matchesGoldenFile('goldens/flat_queue_style.png'),
      );
    });

    testWidgets('FilledQueueStyle Golden Test', (final tester) async {
      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'default',
            position: QueuePosition.topCenter,
            defaultDismissDuration: null,
            defaultColor: Colors.deepPurple,
          ),
        },
        queues: {
          const TopCenterQueue(
            style: FilledQueueStyle(opacity: 0.95),
            maxStackSize: 2,
          ),
        },
      );

      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          builder: FlutterNotificationQueue.builder,
          home: const Scaffold(
            body: Center(
              child: Text('App Content'),
            ),
          ),
        ),
      );

      NotificationWidget(
        id: 'n1',
        title: 'Filled Notification',
        message: 'This is a filled queue style notification.',
        icon: const Icon(Icons.star, color: Colors.white),
      ).show();

      await tester.pump();
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await expectLater(
        find.byType(NotificationOverlay),
        matchesGoldenFile('goldens/filled_queue_style.png'),
      );
    });

    testWidgets('OutlinedQueueStyle Golden Test', (final tester) async {
      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'default',
            position: QueuePosition.topCenter,
            defaultDismissDuration: null,
            defaultColor: Colors.green,
          ),
        },
        queues: {
          const TopCenterQueue(
            style: OutlinedQueueStyle(elevation: 0),
            maxStackSize: 2,
          ),
        },
      );

      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          builder: FlutterNotificationQueue.builder,
          home: const Scaffold(
            body: Center(
              child: Text('App Content'),
            ),
          ),
        ),
      );

      NotificationWidget(
        id: 'n1',
        title: 'Outlined Notification',
        message: 'This is an outlined queue style notification.',
        icon: const Icon(Icons.check, color: Colors.green),
      ).show();

      await tester.pump();
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await expectLater(
        find.byType(NotificationOverlay),
        matchesGoldenFile('goldens/outlined_queue_style.png'),
      );
    });

    testWidgets(
      'Anchoring TopRight vs BottomCenter Golden Test',
      (final tester) async {
        FlutterNotificationQueue.configure(
          channels: {
            const NotificationChannel(
              name: 'ch_tr',
              position: QueuePosition.topRight,
              defaultDismissDuration: null,
            ),
            const NotificationChannel(
              name: 'ch_bc',
              position: QueuePosition.bottomCenter,
              defaultDismissDuration: null,
            ),
          },
          queues: {
            const TopRightQueue(),
            const BottomCenterQueue(),
          },
        );

        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(useMaterial3: true),
            builder: FlutterNotificationQueue.builder,
            home: const Scaffold(
              body: Center(
                child: Text('App Content'),
              ),
            ),
          ),
        );

        NotificationWidget(
          id: 'n_tr',
          message: 'Top Right Queue Position',
          channelName: 'ch_tr',
        ).show();

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        NotificationWidget(
          id: 'n_bc',
          message: 'Bottom Center Queue Position',
          channelName: 'ch_bc',
        ).show();

        await tester.pump();
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        await expectLater(
          find.byType(NotificationOverlay),
          matchesGoldenFile('goldens/queue_positions_anchoring.png'),
        );
      },
    );
  });
}
