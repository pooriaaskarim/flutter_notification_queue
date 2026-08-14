part of 'core.dart';

/// Top-level scope widget binding a [NotificationController] to the Flutter
/// widget tree.
///
/// Wraps its [child] with a [_NotificationScopeData] inherited widget and a
/// [NotificationOverlay] surface using the controller's [QueueCoordinator].
///
/// Usage:
/// ```dart
/// MaterialApp(
///   builder: (context, child) => NotificationScope(
///     controller: notificationController,
///     child: child!,
///   ),
/// );
/// ```
class NotificationScope extends StatefulWidget {
  const NotificationScope({
    required this.controller,
    required this.child,
    super.key,
  });

  /// The notification controller driving this scope.
  final NotificationController controller;

  /// The child widget subtree wrapped by this scope.
  final Widget child;

  /// Returns the nearest [NotificationController] bound in [context].
  ///
  /// Throws a [StateError] if no [NotificationScope] is found in ancestor
  /// tree.
  static NotificationController of(final BuildContext context) {
    final controller = maybeOf(context);
    if (controller == null) {
      throw StateError(
        'No NotificationScope found in context. '
        'Ensure NotificationScope is mounted above context in the widget tree.',
      );
    }
    return controller;
  }

  /// Returns the nearest [NotificationController] bound in [context], or
  /// `null` if none.
  static NotificationController? maybeOf(final BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_NotificationScopeData>()
      ?.controller;

  /// Returns the nearest [QueueCoordinator] bound in [context], or `null` if
  /// none.
  static QueueCoordinator? maybeCoordinatorOf(final BuildContext context) =>
      maybeOf(context)?.coordinator;

  @override
  State<NotificationScope> createState() => _NotificationScopeState();
}

class _NotificationScopeState extends State<NotificationScope> {
  late QueueCoordinator _coordinator;

  @override
  void initState() {
    super.initState();
    _coordinator = QueueCoordinator.fromController(widget.controller);
    widget.controller.attach(_coordinator);
  }

  @override
  void didUpdateWidget(final NotificationScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.detach();
      _coordinator.dispose();
      _coordinator = QueueCoordinator.fromController(widget.controller);
      widget.controller.attach(_coordinator);
    }
  }

  @override
  void dispose() {
    widget.controller.detach();
    _coordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => _NotificationScopeData(
        controller: widget.controller,
        child: NotificationOverlay(
          coordinator: _coordinator,
          child: widget.child,
        ),
      );
}

class _NotificationScopeData extends InheritedWidget {
  const _NotificationScopeData({
    required this.controller,
    required super.child,
  });

  final NotificationController controller;

  @override
  bool updateShouldNotify(final _NotificationScopeData oldWidget) =>
      controller != oldWidget.controller;
}
