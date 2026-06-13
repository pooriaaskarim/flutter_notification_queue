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
  final OverlayPortalController _overlayPortalController =
      OverlayPortalController();
  late final QueueCoordinator _attachedCoordinator;

  @override
  void initState() {
    super.initState();

    // Ensure system is initialized (lazy fallback triggered if needed)
    _attachedCoordinator = FlutterNotificationQueue.coordinator;
    _attachedCoordinator.attach(_overlayPortalController);
  }

  @override
  void dispose() {
    _attachedCoordinator.detach();
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
class _NotificationQueueStack extends StatefulWidget {
  const _NotificationQueueStack();

  @override
  State<_NotificationQueueStack> createState() =>
      _NotificationQueueStackState();
}

class _NotificationQueueStackState extends State<_NotificationQueueStack> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) =>
      ValueListenableBuilder<Map<QueuePosition, NotificationQueue>>(
        valueListenable: FlutterNotificationQueue.coordinator.activeQueues,
        builder: (final context, final activeQueues, final child) {
          final hasActive = activeQueues.isNotEmpty;
          if (hasActive) {
            WidgetsBinding.instance.addPostFrameCallback((final _) {
              if (_focusNode.canRequestFocus && !_focusNode.hasFocus) {
                _focusNode.requestFocus();
              }
            });
          }

          final padding = MediaQuery.paddingOf(context);
          final layout = CustomMultiChildLayout(
            delegate: _QueueOverlayLayoutDelegate(
              activePositions: activeQueues.keys.toList(),
              padding: padding,
              activeQueues: activeQueues,
            ),
            children: activeQueues.values
                .map(
                  (final queue) => LayoutId(
                    id: queue.position,
                    child: QueueWidget(
                      key: FlutterNotificationQueue.coordinator
                          .getWidgetKey(queue.position),
                      queue: queue,
                      isEmbeddedInLayout: true,
                    ),
                  ),
                )
                .toList(),
          );

          if (!hasActive) {
            return layout;
          }

          return Focus(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: (final node, final event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.escape) {
                  final isShiftPressed =
                      HardwareKeyboard.instance.isShiftPressed;
                  if (isShiftPressed) {
                    FlutterNotificationQueue.coordinator.dismissAll();
                  } else {
                    FlutterNotificationQueue.coordinator.dismissNewest();
                  }
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: layout,
          );
        },
      );
}

class _QueueOverlayLayoutDelegate extends MultiChildLayoutDelegate {
  _QueueOverlayLayoutDelegate({
    required this.activePositions,
    required this.padding,
    required this.activeQueues,
  });

  final List<QueuePosition> activePositions;
  final EdgeInsets padding;
  final Map<QueuePosition, NotificationQueue> activeQueues;

  @override
  void performLayout(final Size size) {
    final Map<QueuePosition, Size> childSizes = {};
    for (final position in activePositions) {
      if (hasChild(position)) {
        final queue = activeQueues[position];
        final horizontalConstraints = Utils.horizontalConstraintsForWidth(
          size.width,
          queue?.maxWidth,
        );
        final constraints = BoxConstraints(
          minWidth: 0.0,
          maxWidth: horizontalConstraints.maxWidth,
          minHeight: 0.0,
          maxHeight: size.height,
        );
        childSizes[position] = layoutChild(position, constraints);
      }
    }

    final Map<QueuePosition, Rect> nominalRects = {};
    for (final position in activePositions) {
      final childSize = childSizes[position];
      if (childSize == null) {
        continue;
      }

      final queue = activeQueues[position];
      final margin =
          (queue?.margin ?? EdgeInsets.zero).resolve(TextDirection.ltr);

      double x = 0;
      double y = 0;

      final leftBoundary = padding.left + margin.left;
      final rightBoundary = size.width - padding.right - margin.right;
      final topBoundary = padding.top + margin.top;
      final bottomBoundary = size.height - padding.bottom - margin.bottom;

      switch (position) {
        case QueuePosition.topLeft:
          x = leftBoundary;
          y = topBoundary;
        case QueuePosition.topCenter:
          x = (size.width - childSize.width) / 2;
          y = topBoundary;
        case QueuePosition.topRight:
          x = rightBoundary - childSize.width;
          y = topBoundary;
        case QueuePosition.centerLeft:
          x = leftBoundary;
          y = (size.height - childSize.height) / 2;
        case QueuePosition.centerRight:
          x = rightBoundary - childSize.width;
          y = (size.height - childSize.height) / 2;
        case QueuePosition.bottomLeft:
          x = leftBoundary;
          y = bottomBoundary - childSize.height;
        case QueuePosition.bottomCenter:
          x = (size.width - childSize.width) / 2;
          y = bottomBoundary - childSize.height;
        case QueuePosition.bottomRight:
          x = rightBoundary - childSize.width;
          y = bottomBoundary - childSize.height;
      }

      nominalRects[position] =
          Rect.fromLTWH(x, y, childSize.width, childSize.height);
    }

    final List<QueuePosition> sortedPositions = List.from(activePositions)
      ..sort((final a, final b) => a.index.compareTo(b.index));

    final Map<QueuePosition, Offset> finalOffsets = {};
    final List<Rect> placedRects = [];

    for (final position in sortedPositions) {
      final nominal = nominalRects[position];
      if (nominal == null) {
        continue;
      }

      final double currentX = nominal.left;
      double currentY = nominal.top;

      final isTopAnchored = position == QueuePosition.topLeft ||
          position == QueuePosition.topCenter ||
          position == QueuePosition.topRight;

      final isBottomAnchored = position == QueuePosition.bottomLeft ||
          position == QueuePosition.bottomCenter ||
          position == QueuePosition.bottomRight;

      final queue = activeQueues[position];
      final spacing = queue?.spacing ?? 8.0;

      var currentRect =
          Rect.fromLTWH(currentX, currentY, nominal.width, nominal.height);

      bool hasCollision = true;
      int iterations = 0;
      while (hasCollision && iterations < 10) {
        hasCollision = false;
        for (final placed in placedRects) {
          if (currentRect.overlaps(placed)) {
            hasCollision = true;
            if (isTopAnchored) {
              currentY = placed.bottom + spacing;
            } else if (isBottomAnchored) {
              currentY = placed.top - nominal.height - spacing;
            } else {
              currentY = placed.bottom + spacing;
            }
            currentRect = Rect.fromLTWH(
              currentX,
              currentY,
              nominal.width,
              nominal.height,
            );
            break;
          }
        }
        iterations++;
      }

      finalOffsets[position] = Offset(currentX, currentY);
      placedRects.add(currentRect);
    }

    for (final position in activePositions) {
      if (hasChild(position)) {
        final offset = finalOffsets[position] ?? Offset.zero;
        positionChild(position, offset);
      }
    }
  }

  @override
  bool shouldRelayout(
    covariant final _QueueOverlayLayoutDelegate oldDelegate,
  ) =>
      activePositions != oldDelegate.activePositions ||
      padding != oldDelegate.padding ||
      activeQueues != oldDelegate.activeQueues;
}
