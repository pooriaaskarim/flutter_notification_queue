import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_test/flutter_test.dart';

class CustomTransition extends NotificationTransition {
  const CustomTransition();

  @override
  Widget build(
    final BuildContext context,
    final Animation<double> animation,
    final QueuePosition position,
    final Widget child,
  ) =>
      ScaleTransition(scale: animation, child: child);
}

void main() {
  setUp(() {
    FlutterNotificationQueue.reset();
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
          transition: CustomTransition(),
        ),
      },
    );
  });

  testWidgets('NotificationWidget uses custom transition',
      (final tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        builder: FlutterNotificationQueue.builder,
        home: Scaffold(body: SizedBox()),
      ),
    );

    // Show notification
    NotificationWidget(message: 'Test').show();
    await tester.pump(); // Frame 1: Queue processing
    await tester.pump(); // Frame 2: Widget build

    // Verify ScaleTransition is present as an ancestor of NotificationWidget
    expect(
      find.ancestor(
        of: find.byType(NotificationWidget),
        matching: find.byType(ScaleTransition),
      ),
      findsAtLeastNWidgets(1),
    );

    // Verify SlideTransition is NOT present as an ancestor of
    // NotificationWidget
    expect(
      find.ancestor(
        of: find.byType(NotificationWidget),
        matching: find.byType(SlideTransition),
      ),
      findsNothing,
    );

    await tester.pumpAndSettle();
  });

  testWidgets('NotificationWidget uses default transition if not specified',
      (final tester) async {
    FlutterNotificationQueue.reset();
    FlutterNotificationQueue.configure(
      channels: {
        const NotificationChannel(
          name: 'default',
          position: QueuePosition.bottomCenter,
          defaultDismissDuration: null,
        ),
      },
      queues: {
        const BottomCenterQueue(),
      },
    );
    await tester.pumpWidget(
      const MaterialApp(
        builder: FlutterNotificationQueue.builder,
        home: Scaffold(body: SizedBox()),
      ),
    );

    NotificationWidget(
      message: 'Default',
      position: QueuePosition.bottomCenter,
    ).show();
    await tester.pump();
    await tester.pump();

    // Verify SlideTransition is present as an ancestor of NotificationWidget
    // (default SlideTransitionStrategy)
    expect(
      find.ancestor(
        of: find.byType(NotificationWidget),
        matching: find.byType(SlideTransition),
      ),
      findsOneWidget,
    );
  });

  testWidgets('NotificationWidget uses BuilderTransitionStrategy',
      (final tester) async {
    FlutterNotificationQueue.reset();
    FlutterNotificationQueue.configure(
      channels: {
        const NotificationChannel(
          name: 'default',
          position: QueuePosition.topCenter,
          defaultDismissDuration: null,
        ),
      },
      queues: {
        TopCenterQueue(
          transition: BuilderTransitionStrategy(
            (final context, final animation, final position, final child) =>
                RotationTransition(turns: animation, child: child),
          ),
        ),
      },
    );
    await tester.pumpWidget(
      const MaterialApp(
        builder: FlutterNotificationQueue.builder,
        home: Scaffold(body: SizedBox()),
      ),
    );

    NotificationWidget(
      message: 'Builder',
      position: QueuePosition.topCenter,
    ).show();
    await tester.pump();
    await tester.pump();

    // Verify RotationTransition is present as an ancestor of NotificationWidget
    expect(
      find.ancestor(
        of: find.byType(NotificationWidget),
        matching: find.byType(RotationTransition),
      ),
      findsOneWidget,
    );
  });

  tearDown(() {
    FlutterNotificationQueue.reset();
  });
}
