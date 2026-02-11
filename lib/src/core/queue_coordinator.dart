part of 'core.dart';

/// The lifecycle bridge between [NotificationQueue]s and the rendering surface.
///
/// Owns the single [OverlayPortalController] and maintains a registry of
/// active queues. When a queue has notifications to display, it registers
/// itself here via [activateQueue]. When it empties, it unregisters via
/// [deactivateQueue]. The coordinator then signals the NotificationOverlay
/// to show or hide accordingly.
///
/// ## Lifecycle
///
/// 1. [attach] is called by `NotificationOverlay.initState`, binding
///    the overlay's [OverlayPortalController] to this coordinator.
/// 2. [NotificationQueue]s call [activateQueue] / [deactivateQueue]
///    as their notification count changes.
/// 3. [detach] is called by `NotificationOverlay.dispose`, clearing all
///    state and releasing the controller.
///
/// ## Rendering Contract
///
/// The [activeQueues] listenable is consumed by `_NotificationQueueStack`
/// inside the overlay to rebuild the notification stack whenever the set
/// of active queues changes.
class QueueCoordinator {
  QueueCoordinator._();

  static final instance = QueueCoordinator._();

  static final _logger = Logger.get('fnq.Core.Coordinator');

  OverlayPortalController? _controller;
  final _activeQueues = <QueuePosition, NotificationQueue>{};
  final _activeQueuesNotifier =
      ValueNotifier<Map<QueuePosition, NotificationQueue>>({});

  /// Binds the overlay's [OverlayPortalController] to this coordinator.
  ///
  /// Called by `NotificationOverlay.initState`.
  void attach(final OverlayPortalController controller) {
    _logger.debugBuffer
      ?..writeAll(['Attaching OverlayPortalController...'])
      ..sink();
    _controller = controller;
  }

  /// Releases the controller and clears all active queue state.
  ///
  /// Called by `NotificationOverlay.dispose`.
  void detach() {
    _logger.debugBuffer
      ?..writeAll(['Detaching OverlayPortalController...'])
      ..sink();
    _controller = null;
    _activeQueues.clear();
    _activeQueuesNotifier.value = {};
  }

  /// Registers [queue] as active, triggering the overlay to rebuild
  /// and include this queue's widget in the notification stack.
  ///
  /// No-op if the queue's position is already active.
  void activateQueue(final NotificationQueue queue) {
    if (_activeQueues.containsKey(queue.position)) {
      return;
    }

    _logger.debugBuffer
      ?..writeAll([
        'Activating Queue: ${queue.position}',
        'Queue: $queue',
      ])
      ..sink();

    _activeQueues[queue.position] = queue;
    _notify();
    _controller?.show();
  }

  /// Unregisters the queue at [position]. If no queues remain active,
  /// the overlay is hidden.
  void deactivateQueue(final QueuePosition position) {
    if (!_activeQueues.containsKey(position)) {
      return;
    }

    _activeQueues.remove(position);
    _notify();

    if (_activeQueues.isEmpty) {
      _controller?.hide();
    }
  }

  /// Moves the queue at [position] to the top of the rendering stack.
  void bringToFront(final QueuePosition position) {
    if (!_activeQueues.containsKey(position)) {
      return;
    }
    final queue = _activeQueues.remove(position)!;

    _logger.debugBuffer
      ?..writeAll([
        'Bringing Queue to front: $position',
        'Queue: $queue',
      ])
      ..sink();
    _activeQueues[position] = queue; // Re-insert at end (top of stack)
    _notify();
  }

  void _notify() {
    _activeQueuesNotifier.value = Map.of(_activeQueues);
  }

  /// The set of currently active queues, exposed as a [ValueListenable]
  /// for the notification stack to rebuild against.
  ValueListenable<Map<QueuePosition, NotificationQueue>> get activeQueues =>
      _activeQueuesNotifier;

  // Future: coordinate drag-hold across a relocation group
  void holdGroup(final Set<QueuePosition> group) {
    /* pause timers in group */
  }

  void releaseGroup(final Set<QueuePosition> group) {
    /* resume timers */
  }
}
