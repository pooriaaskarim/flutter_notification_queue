import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_notification_queue/src/core/core.dart';
import 'package:flutter_notification_queue_example/studio/bloc/notification_bloc.dart';
import 'package:flutter_notification_queue_example/studio/bloc/setup_bloc.dart';
import 'package:flutter_notification_queue_example/studio/bloc/studio_bloc.dart';
import 'package:flutter_notification_queue_example/studio/engine/code_generator.dart';
import 'package:flutter_notification_queue_example/studio/models/channel_setup.dart';
import 'package:flutter_notification_queue_example/studio/models/queue_setup.dart';
import 'package:flutter_notification_queue_example/studio/models/studio_setup.dart';
import 'package:flutter_notification_queue_example/studio/studio_home.dart';
import 'package:flutter_notification_queue_example/studio/studio_theme.dart';
import 'package:flutter_notification_queue_example/studio/widgets/theme_designer_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChannelSetup Model & Mapping Tests', () {
    test('toNotificationChannel propagates theme and style override', () {
      const channelSetup = ChannelSetup(
        name: 'billing',
        color: Color(0xFF6366F1),
        foregroundColor: Color(0xFFFFFFFF),
        backgroundColor: Color(0xFF1E1B4B),
        styleType: FilledQueueStyle,
      );
      final channel = channelSetup.toNotificationChannel();
      expect(channel.theme, isNotNull);
      expect(channel.theme!.accentColor, equals(const Color(0xFF6366F1)));
      expect(channel.theme!.foregroundColor, equals(const Color(0xFFFFFFFF)));
      expect(channel.theme!.backgroundColor, equals(const Color(0xFF1E1B4B)));
      expect(channel.style, isA<FilledQueueStyle>());
    });
  });

  group('QueueSetup Model & Mapping Tests', () {
    test('default constructor sets maxWidth to null', () {
      const setup = QueueSetup();
      expect(setup.maxWidth, isNull);
    });

    test('copyWith updates maxWidth correctly', () {
      const setup = QueueSetup();
      final updated = setup.copyWith(maxWidth: 450.0);
      expect(updated.maxWidth, equals(450.0));
      expect(updated.copyWith(clearMaxWidth: true).maxWidth, isNull);
    });

    test('toNotificationQueue propagates maxWidth correctly', () {
      const setup = QueueSetup(maxWidth: 250.0);
      final queue = setup.toNotificationQueue(QueuePosition.topLeft);
      expect(queue.maxWidth, equals(250.0));
    });
    test('toNotificationQueue builds Snooze and Pin behaviors correctly', () {
      const snoozeSetup = QueueSetup(
        dragBehaviorType: Snooze,
        dragSnoozeSeconds: 8,
        longPressBehaviorType: Pin,
      );
      final queue = snoozeSetup.toNotificationQueue(QueuePosition.topLeft);
      expect(queue.dragBehavior, isA<Snooze>());
      expect(
        (queue.dragBehavior as Snooze).duration,
        equals(const Duration(seconds: 8)),
      );
      expect(queue.longPressDragBehavior, isA<Pin>());
    });
  });

  group('CodeGenerator maxWidth & Behavior Snippet Tests', () {
    test('generateCode includes maxWidth property when set', () {
      const queueSetup = QueueSetup(maxWidth: 280.0);
      const studioSetup = StudioSetup(
        queues: {
          QueuePosition.topLeft: queueSetup,
        },
        channels: {},
      );
      const draft = NotificationDraft(
        title: 'Test',
        message: 'Hello',
        channelName: 'test',
      );

      final codeSnippet = generateCode(
        setup: studioSetup,
        draft: draft,
      );

      expect(codeSnippet, contains('maxWidth: 280.0,'));
    });

    test('generateCode emits Snooze, Priority, and permanent snippets', () {
      const queueSetup = QueueSetup(
        dragBehaviorType: Snooze,
        dragSnoozeSeconds: 10,
      );
      const studioSetup = StudioSetup(
        queues: {
          QueuePosition.topRight: queueSetup,
        },
        channels: {
          'billing': ChannelSetup(
            name: 'billing',
            color: Color(0xFF6366F1),
            styleType: FilledQueueStyle,
          ),
        },
      );
      const draft = NotificationDraft(
        title: 'Snooze Draft',
        message: 'Testing Snooze',
        channelName: 'billing',
        priority: NotificationPriority.critical,
        permanent: true,
        positionOverride: QueuePosition.bottomRight,
      );

      final codeSnippet = generateCode(
        setup: studioSetup,
        draft: draft,
      );

      expect(
        codeSnippet,
        contains('const Snooze(duration: Duration(seconds: 10))'),
      );
      expect(codeSnippet, contains('priority: NotificationPriority.critical,'));
      expect(codeSnippet, contains('permanent: true,'));
      expect(
        codeSnippet,
        contains('targetPosition: QueuePosition.bottomRight,'),
      );
      expect(codeSnippet, contains('NotificationThemeData('));
      expect(codeSnippet, contains('const FilledQueueStyle()'));
    });

    test('generateCode emits notification payload theme override when set', () {
      const studioSetup = StudioSetup(
        queues: {
          QueuePosition.topRight: QueueSetup(),
        },
        channels: {
          'info': ChannelSetup(name: 'info'),
        },
      );
      const draft = NotificationDraft(
        title: 'Theme Override Test',
        message: 'Has custom notification tokens',
        channelName: 'info',
        themeOverride: NotificationThemeData(
          accentColor: Color(0xFF10B981),
          elevation: 6,
        ),
      );

      final codeSnippet = generateCode(
        setup: studioSetup,
        draft: draft,
      );

      expect(codeSnippet, contains('accentColor: Color(0xff10b981),'));
      expect(codeSnippet, contains('elevation: 6.0,'));
    });

    test('generateCode omits maxWidth property when null', () {
      const queueSetup = QueueSetup(maxWidth: null);
      const studioSetup = StudioSetup(
        queues: {
          QueuePosition.topLeft: queueSetup,
        },
        channels: {},
      );
      const draft = NotificationDraft(
        title: 'Test',
        message: 'Hello',
        channelName: 'test',
      );

      final codeSnippet = generateCode(
        setup: studioSetup,
        draft: draft,
      );

      expect(codeSnippet, isNot(contains('maxWidth:')));
    });
  });

  group('NotificationBloc Preview Routing Tests', () {
    late SetupBloc setupBloc;
    late NotificationBloc notificationBloc;
    late QueueCoordinator coordinator;
    setUp(() {
      setupBloc = SetupBloc();
      notificationBloc = NotificationBloc(setupBloc: setupBloc);
      coordinator = QueueCoordinator.fromController(setupBloc.controller);
      // ignore: invalid_use_of_internal_member
      setupBloc.controller.attach(coordinator);
    });

    tearDown(() {
      coordinator.dispose();
      notificationBloc.close();
      setupBloc.close();
    });

    test('FirePreview routes to active queue position by default', () async {
      // 1. Set the active queue in setupBloc to QueuePosition.topLeft
      setupBloc.add(const AddQueue(QueuePosition.topLeft));

      // Allow setupBloc state update to propagate
      await Future.delayed(Duration.zero);
      expect(
        setupBloc.state.activeQueuePosition,
        equals(QueuePosition.topLeft),
      );

      // 2. Listen for NotificationQueued event
      final events = <NotificationEvent>[];
      final sub = coordinator.events.listen(events.add);

      // 3. Fire the preview notification
      notificationBloc.add(const FirePreview());

      // Let microtasks run
      await Future.delayed(Duration.zero);

      expect(events, hasLength(1));
      final queuedEvent = events.first as NotificationQueued;
      expect(
        queuedEvent.notification.queue.position,
        equals(QueuePosition.topLeft),
      );

      await sub.cancel();
    });

    test('FirePreview respects positionOverride when explicitly set', () async {
      // 1. Set the active queue in setupBloc to QueuePosition.topLeft
      setupBloc.add(const AddQueue(QueuePosition.topLeft));

      // 2. Set an explicit position override in notificationBloc draft
      notificationBloc.add(
        const SelectPreviewPosition(QueuePosition.bottomRight),
      );

      await Future.delayed(Duration.zero);

      // 3. Listen for NotificationQueued event
      final events = <NotificationEvent>[];
      final sub = coordinator.events.listen(events.add);

      // 4. Fire the preview notification
      notificationBloc.add(const FirePreview());

      await Future.delayed(Duration.zero);

      expect(events, hasLength(1));
      final queuedEvent = events.first as NotificationQueued;
      expect(
        queuedEvent.notification.queue.position,
        equals(QueuePosition.bottomRight),
      );

      await sub.cancel();
    });
  });

  group('StudioHome FAB Widget Tests', () {
    testWidgets(
      'Renders FAB on narrow screens and triggers notification on tap',
      (final tester) async {
        tester.view.physicalSize = const Size(500, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final setupBloc = SetupBloc();
        final notificationBloc = NotificationBloc(setupBloc: setupBloc);
        final studioBloc = StudioBloc();

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider.value(value: setupBloc),
              BlocProvider.value(value: notificationBloc),
              BlocProvider.value(value: studioBloc),
            ],
            child: MaterialApp(
              theme: StudioTheme.dark(),
              builder: (final context, final child) {
                StudioTheme.update(context);
                return NotificationScope(
                  controller: setupBloc.controller,
                  child: child!,
                );
              },
              home: const StudioHome(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);
        expect(find.byTooltip('Fire Notification'), findsOneWidget);

        addTearDown(() {
          notificationBloc.close();
          setupBloc.close();
          studioBloc.close();
        });

        await tester.tap(fabFinder);
        await tester.pump();
        expect(find.byType(NotificationWidget), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
      },
    );
  });

  group('ThemeDesignerDialog Widget Tests', () {
    testWidgets('Opens ThemeDesignerDialog and calls onApplyTheme on submit',
        (final tester) async {
      NotificationThemeData? appliedTheme;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (final context) => ElevatedButton(
                onPressed: () => ThemeDesignerDialog.show(
                  context,
                  title: 'Configure Theme',
                  initialTheme: const NotificationThemeData(
                    accentColor: Color(0xFF6366F1),
                  ),
                  onApplyTheme: (final t) => appliedTheme = t,
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('CONFIGURE THEME'), findsOneWidget);
      expect(find.text('LIVE CARD PREVIEW'), findsOneWidget);
      expect(find.text('APPLY THEME'), findsOneWidget);

      await tester.tap(find.text('APPLY THEME'));
      await tester.pumpAndSettle();

      expect(appliedTheme, isNotNull);
      expect(appliedTheme!.accentColor, equals(const Color(0xFF6366F1)));
    });

    testWidgets('ThemeDesignerDialog triggers unified onApply with styleType',
        (final tester) async {
      NotificationThemeData? appliedTheme;
      Type? appliedStyleType;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (final context) => ElevatedButton(
                onPressed: () => ThemeDesignerDialog.show(
                  context,
                  title: 'Configure Channel Theme',
                  channelName: 'orders',
                  initialTheme: const NotificationThemeData(
                    accentColor: Color(0xFF10B981),
                  ),
                  initialStyleType: FilledQueueStyle,
                  onApply: (final theme, final styleType) {
                    appliedTheme = theme;
                    appliedStyleType = styleType;
                  },
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('CONFIGURE CHANNEL THEME'), findsOneWidget);

      await tester.tap(find.text('APPLY THEME'));
      await tester.pumpAndSettle();

      expect(appliedTheme, isNotNull);
      expect(appliedStyleType, equals(FilledQueueStyle));
    });
  });
}
