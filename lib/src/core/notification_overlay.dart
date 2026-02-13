part of 'core.dart';

/// The rendering surface for the notification system.
///
/// Mounts notifications into the widget tree using a dual rendering strategy:
///
/// 1. **OverlayPortal** — when an [Overlay] ancestor exists (e.g. used as a
///    child inside [MaterialApp]), notifications are rendered via
///    [OverlayPortal] for proper layering above all app content.
///
/// 2. **Stack fallback** — when no [Overlay] ancestor exists (e.g. used in
///    [MaterialApp.builder] where the Navigator's Overlay is a descendant),
///    a [Stack] with a local [Overlay] is used instead.
///
/// ## Integration
///
/// Users should not instantiate this widget directly. Instead, use:
/// ```dart
/// MaterialApp(
///   builder: FlutterNotificationQueue.builder,
/// )
/// ```
class NotificationOverlay extends StatefulWidget {
  const NotificationOverlay({
    required this.child,
    super.key,
  });

  /// The app's root widget (e.g., [MaterialApp]).
  final Widget child;

  /// Static router method for use in [MaterialApp.builder].
  ///
  /// Usage:
  /// ```dart
  /// MaterialApp(
  ///   builder: NotificationOverlay.router,
  /// );
  /// ```
  static Widget router(final BuildContext context, final Widget? child) =>
      NotificationOverlay(
        child: child ?? const SizedBox.shrink(),
      );

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay> {
  static final _logger = Logger.get('fnq.Core.Overlay');
  final OverlayPortalController _overlayPortalController =
      OverlayPortalController();

  @override
  void initState() {
    super.initState();

    // Guard: ensure ConfigurationManager has been configured.
    if (!FlutterNotificationQueue.isInitialized) {
      throw StateError(
        'FlutterNotificationQueue has not been initialized. '
        'Call FlutterNotificationQueue.initialize() in your main() function '
        'before using the NotificationOverlay.',
      );
    }

    // Attach QueueCoordinator immediately.
    // It's safe to pass the controller even if not yet attached to the
    // OverlayPortal.
    FlutterNotificationQueue.coordinator.attach(_overlayPortalController);

    _logger.debugBuffer
      ?..writeAll(['NotificationOverlay created state.'])
      ..sink();
  }

  @override
  void dispose() {
    FlutterNotificationQueue.coordinator.detach();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    // Dual Strategy:
    // 1. If Overlay exists (e.g. used inside MaterialApp), use OverlayPortal.
    // 2. If Overlay is missing (e.g. used in MaterialApp.builder), use Stack.
    final hasOverlay = Overlay.maybeOf(context) != null;

    if (hasOverlay) {
      return OverlayPortal(
        controller: _overlayPortalController,
        overlayChildBuilder: (final context) => const _NotificationQueueStack(),
        overlayLocation: OverlayChildLocation.rootOverlay,
        child: widget.child,
      );
    } else {
      // When used in MaterialApp.builder, the Navigator's Overlay is a
      // descendant (inside widget.child), not an ancestor. Notification
      // widgets contain LongPressDraggable which requires an Overlay
      // ancestor. We provide a minimal one here.
      return Stack(
        textDirection: TextDirection.ltr,
        children: [
          widget.child,
          Positioned.fill(
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (final context) => const _NotificationQueueStack(),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}

/// Renders the stack of active [NotificationQueue] widgets.
///
/// Listens to [QueueCoordinator.activeQueues] and rebuilds whenever the
/// set of active queues changes. Each active queue provides its own
/// [QueueWidget] which handles positioning, spacing, and notification
/// rendering.
class _NotificationQueueStack extends StatelessWidget {
  const _NotificationQueueStack();

  static final _logger = Logger.get('fnq.Core.Overlay.Stack');

  @override
  Widget build(final BuildContext context) =>
      ValueListenableBuilder<Map<QueuePosition, NotificationQueue>>(
        valueListenable: FlutterNotificationQueue.coordinator.activeQueues,
        builder: (final context, final activeQueues, final child) {
          _logger.debug(
            'QueueCoordinator rebuild with ${activeQueues.length} queues',
          );
          return Stack(
            children: activeQueues.values
                .map(
                  (final queue) => QueueWidget(
                    key: FlutterNotificationQueue.coordinator
                        .getWidgetKey(queue.position),
                    queue: queue,
                  ),
                )
                .toList(),
          );
        },
      );
}
