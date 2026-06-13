import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_notification_queue_example/studio/bloc/notification_bloc.dart';
import 'package:flutter_notification_queue_example/studio/bloc/setup_bloc.dart';
import 'package:flutter_notification_queue_example/studio/engine/code_generator.dart';
import 'package:flutter_notification_queue_example/studio/models/queue_setup.dart';
import 'package:flutter_notification_queue_example/studio/models/studio_setup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
  });

  group('CodeGenerator maxWidth Snippet Tests', () {
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

    setUp(() {
      FlutterNotificationQueue.reset();
      FlutterNotificationQueue.configure();
      setupBloc = SetupBloc();
      notificationBloc = NotificationBloc(setupBloc: setupBloc);
    });

    tearDown(() {
      setupBloc.close();
      notificationBloc.close();
      FlutterNotificationQueue.reset();
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
      final events = <FnqEvent>[];
      final sub = FlutterNotificationQueue.events.listen(events.add);

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
      final events = <FnqEvent>[];
      final sub = FlutterNotificationQueue.events.listen(events.add);

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
}
