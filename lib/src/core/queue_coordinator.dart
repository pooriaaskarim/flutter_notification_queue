part of 'core.dart';

/// The lifecycle bridge between [NotificationQueue]s and the rendering surface.
///
/// Owns the [OverlayPortalController] and manages the lifecycle of queue
/// widgets.
///
/// Refactored to delegate state management to [QueueWidgetState] via
/// [GlobalKey]s, using a "startup mailbox" pattern to pass initial data to
/// newly mounting widgets.
class QueueCoordinator {
  QueueCoordinator();

  static final _logger = Logger.get('fnq.Core.Coordinator');

  OverlayPortalController? _controller;

  /// Broadcast stream of all notification lifecycle events.
  final _eventController = StreamController<FnqEvent>.broadcast();

  /// A broadcast stream of all notification lifecycle events.
  ///
  /// Subscribe to observe queued, dismissed, tapped, relocated, and reordered
  /// events without coupling to library internals. Multiple listeners are
  /// supported simultaneously.
  ///
  /// Prefer accessing this via [FlutterNotificationQueue.events].
  Stream<FnqEvent> get events => _eventController.stream;

  /// Adds [event] directly to the event stream.
  ///
  /// Only intended for use in unit tests that need to verify stream consumers
  /// without spinning up a full widget tree.
  @visibleForTesting
  void emitEvent(final FnqEvent event) => _eventController.add(event);

  /// Registry of keys to communicate with active queue widgets.
  final _widgetStateKeys = <QueuePosition, GlobalKey<QueueWidgetState>>{};

  /// Holds notifications for queues that are initializing (mounting).
  ///
  /// This bridges the gap between a logical enqueue request and the visual
  /// mount of the [QueueWidget]. When a queue is requested but not yet mounted,
  /// items are stored here.
  final _initializationQueue = <QueuePosition, List<NotificationWidget>>{};

  /// The set of currently active queues (those with visible notifications).
  final _activeQueuesNotifier =
      ValueNotifier<Map<QueuePosition, NotificationQueue>>({});

  void attach(final OverlayPortalController controller) {
    _logger.debug('Attaching OverlayPortalController...');
    _controller = controller;
  }

  void detach() {
    _logger.debug('Detaching OverlayPortalController...');
    _controller = null;
    _widgetStateKeys.clear();
    _initializationQueue.clear();
    _activeQueuesNotifier.value = {};
    _eventController.close();
  }

  /// Retrieves and clears pending initialization items for a queue.
  /// Called by [QueueWidgetState.initState].
  List<NotificationWidget> consumeInitializationQueue(
    final QueuePosition position,
  ) =>
      _initializationQueue.remove(position) ?? [];

  /// Registers a queue's key. Called by [QueueWidget] constructor/build?
  /// Typically we create the key here and pass it to the widget.
  GlobalKey<QueueWidgetState> _getKey(final QueuePosition position) =>
      _widgetStateKeys.putIfAbsent(
        position,
        () => GlobalKey<QueueWidgetState>(),
      );

  // --- Actions ---

  void queue(
    final NotificationWidget notification,
  ) {
    if (!notification.channel.enabled) {
      return;
    }

    _eventController.add(NotificationQueued(notification: notification));

    final notificationQueue = notification.queue;
    final key = _widgetStateKeys[notificationQueue.position];
    final isMounted = key?.currentState != null;

    if (isMounted) {
      // Widget is alive, delegate directly.
      key!.currentState!.enqueue(notification);
    } else {
      // Widget is not alive. Schedule startup.
      _initializationQueue
          .putIfAbsent(notificationQueue.position, () => [])
          .add(notification);
      _mountQueue(notificationQueue);
    }
  }

  void dismiss(
    final NotificationWidget notification, {
    final DismissReason reason = DismissReason.programmatic,
  }) {
    _eventController.add(
      NotificationDismissed(notification: notification, reason: reason),
    );

    final notificationQueue = notification.queue;
    final key = _widgetStateKeys[notificationQueue.position];
    if (key?.currentState != null) {
      key!.currentState!.dismiss(notification);
    } else {
      // If not mounted, check initialization queue (rare race condition where
      // we dismiss before mount?)
      _initializationQueue[notificationQueue.position]
          ?.removeWhere((final n) => n.id == notification.id);

      // If we emptied the init queue before it even mounted, cancel mount?
      if (_initializationQueue[notificationQueue.position]?.isEmpty ?? false) {
        _unmountQueue(notificationQueue.position);
      }
    }
  }

  NotificationWidget? relocate(
    final NotificationWidget notification,
    final QueuePosition newPosition,
  ) {
    final notificationQueue = notification.queue;
    NotificationWidget? newNotification;
    final sourceKey = _widgetStateKeys[notificationQueue.position];

    // 1. Remove from source
    bool removed = false;
    if (sourceKey?.currentState != null) {
      removed = sourceKey!.currentState!.remove(notification);
    } else {
      // Check initialization queue
      final initQueue = _initializationQueue[notificationQueue.position];
      if (initQueue != null) {
        final initialLen = initQueue.length;
        initQueue.removeWhere((final n) => n.id == notification.id);
        removed = initQueue.length < initialLen;
      }
    }

    // 2. Add to target if removed
    if (removed) {
      final targetQueue = newPosition.generateQueueFrom(notification.queue);
      newNotification = notification.copyToQueue(targetQueue);
      _eventController.add(
        NotificationRelocated(
          notification: newNotification,
          from: notificationQueue.position,
          to: newPosition,
        ),
      );
      // Defer addition to next frame to avoid Duplicate GlobalKey error
      // if the source queue animates the exit (keeping the key alive).
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        queue(newNotification!);
      });
    }

    return newNotification;
  }

  /// Reorders [notification] to [targetIndex] within its current queue.
  void reorder(
    final NotificationWidget notification,
    final int targetIndex,
  ) {
    _eventController.add(
      NotificationReordered(notification: notification, toIndex: targetIndex),
    );
    final key = _widgetStateKeys[notification.queue.position];
    key?.currentState?.reorder(notification, targetIndex);
  }

  /// Snoozes [notification] for [duration]. Dismisses the current instance
  /// and automatically schedules it to re-enqueue.
  void snooze(
    final NotificationWidget notification,
    final Duration duration,
  ) {
    // 1. Remove from active queue
    final notificationQueue = notification.queue;
    final key = _widgetStateKeys[notificationQueue.position];
    if (key?.currentState != null) {
      key!.currentState!.remove(notification);
    } else {
      _initializationQueue[notificationQueue.position]
          ?.removeWhere((final n) => n.id == notification.id);
    }

    // 2. Emit NotificationSnoozed event
    _eventController.add(
      NotificationSnoozed(notification: notification, duration: duration),
    );

    // 3. Schedule auto-re-queue
    Timer(duration, () {
      final freshCopy = notification.copyForRequeue(snoozedAt: null);
      queue(freshCopy);
    });
  }

  /// Pins [notification], making it persistent and immune to swipe gestures.
  void pin(final NotificationWidget notification) {
    final stateKey = GlobalObjectKey<NotificationWidgetState>(notification.id);
    final state = stateKey.currentState;
    if (state != null) {
      state.widget.isPinned = true;
    } else {
      notification.isPinned = true;
    }
    _eventController.add(
      NotificationPinned(notification: state?.widget ?? notification),
    );
  }

  /// Unpins [notification], restoring its dismissible/interactive swipe status.
  void unpin(final NotificationWidget notification) {
    final stateKey = GlobalObjectKey<NotificationWidgetState>(notification.id);
    final state = stateKey.currentState;
    if (state != null) {
      state.widget.isPinned = false;
    } else {
      notification.isPinned = false;
    }
    _eventController.add(
      NotificationUnpinned(notification: state?.widget ?? notification),
    );
  }

  /// Triggers a developer-defined custom action on [notification].
  void triggerCustomAction(
    final NotificationWidget notification,
    final String actionName,
  ) {
    _eventController.add(
      NotificationCustomActionTriggered(
        notification: notification,
        actionName: actionName,
      ),
    );
  }

  void bringToFront(final QueuePosition position) {
    if (!_activeQueuesNotifier.value.containsKey(position)) {
      return;
    }
    final currentMap = Map.of(_activeQueuesNotifier.value);
    final queue = currentMap.remove(position)!;
    currentMap[position] = queue;
    _activeQueuesNotifier.value = currentMap;
  }

  /// Called by QueueWidgetState when it's empty to self-destruct.
  void unmountQueue(final QueuePosition position) {
    _unmountQueue(position);
  }

  // --- Helpers ---

  void _mountQueue(final NotificationQueue queue) {
    if (_activeQueuesNotifier.value.containsKey(queue.position)) {
      return;
    }

    _getKey(queue.position); // Ensure key exists
    final newMap = Map.of(_activeQueuesNotifier.value);
    newMap[queue.position] = queue;
    _activeQueuesNotifier.value = newMap;
    _controller?.show();
  }

  void _unmountQueue(final QueuePosition position) {
    if (!_activeQueuesNotifier.value.containsKey(position)) {
      return;
    }

    final newMap = Map.of(_activeQueuesNotifier.value)..remove(position);
    _activeQueuesNotifier.value = newMap;

    // We can clean up the key too if we want fresh state next time
    // (which we do, since the widget is disposing)
    _widgetStateKeys.remove(position);
    _initializationQueue.remove(position);

    if (newMap.isEmpty) {
      _controller?.hide();
    }
  }

  /// Emits a [NotificationTapped] event.
  ///
  /// Called by [NotificationWidgetState] which lives in a separate library
  /// and cannot access the private [_eventController] directly.
  void emitTapped({
    required final NotificationWidget notification,
    required final TapBehavior behavior,
  }) =>
      _eventController.add(
        NotificationTapped(notification: notification, behavior: behavior),
      );

  /// Emits a [QueueOverflowed] event.
  ///
  /// Called by [QueueWidgetState] when a notification is dropped.
  void emitOverflowed({
    required final NotificationQueue queue,
    required final NotificationWidget dropped,
  }) =>
      _eventController.add(QueueOverflowed(queue: queue, dropped: dropped));

  /// Exposed for overlay.
  /// Note: The overlay builder needs to use the GlobalKey we created.
  /// We need a way to look it up.
  GlobalKey<QueueWidgetState> getWidgetKey(final QueuePosition position) =>
      _widgetStateKeys[position]!;

  ValueListenable<Map<QueuePosition, NotificationQueue>> get activeQueues =>
      _activeQueuesNotifier;

  /// Returns a list of all currently active notifications across all active
  /// queues.
  List<NotificationWidget> get activeNotifications {
    final list = <NotificationWidget>[];
    for (final key in _widgetStateKeys.values) {
      final state = key.currentState;
      if (state != null) {
        list.addAll(state.activeNotifications);
      }
    }
    return list;
  }

  /// Dismisses the newest active notification across all active queues.
  void dismissNewest() {
    final active = activeNotifications;
    if (active.isEmpty) {
      return;
    }
    // Sort by createdAt descending to find the newest
    active.sort((final a, final b) => b.createdAt.compareTo(a.createdAt));
    dismiss(active.first, reason: DismissReason.programmatic);
  }

  /// Dismisses all active notifications across all active queues.
  void dismissAll() {
    final active = activeNotifications;
    for (final notification in active) {
      dismiss(notification, reason: DismissReason.programmatic);
    }
  }
}
