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
    final NotificationWidget notification,
  ) {
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
      // Defer addition to next frame to avoid Duplicate GlobalKey error
      // if the source queue animates the exit (keeping the key alive).
      // Note: This effectively unmounts and remounts the widget, resetting
      // transient state. This is the trade-off for avoiding "Ghost" widgets
      // while preventing crashes.
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
    final key = _widgetStateKeys[notification.queue.position];
    key?.currentState?.reorder(notification, targetIndex);
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

  /// Exposed for overlay.
  /// Note: The overlay builder needs to use the GlobalKey we created.
  /// We need a way to look it up.
  GlobalKey<QueueWidgetState> getWidgetKey(final QueuePosition position) =>
      _widgetStateKeys[position]!;

  ValueListenable<Map<QueuePosition, NotificationQueue>> get activeQueues =>
      _activeQueuesNotifier;
}
