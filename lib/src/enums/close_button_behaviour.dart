part of 'enums.dart';

sealed class QueueCloseButtonBehavior {
  const QueueCloseButtonBehavior();

  /// Whether the button is visible initially.
  bool get initialVisibility;

  /// Returns the new visibility state when hovered.
  ///
  /// [isHovering] is true if the mouse is entering, false if exiting.
  bool onHover({required final bool isHovering});

  /// Returns the new visibility state when tapped (touch fallback).
  ///
  /// [currentVisibility] is the current state of the close button logic.
  bool onTap({required final bool currentVisibility});
}

final class AlwaysVisible extends QueueCloseButtonBehavior {
  const AlwaysVisible();

  @override
  bool get initialVisibility => true;

  @override
  bool onHover({required final bool isHovering}) => true;

  @override
  bool onTap({required final bool currentVisibility}) => true;
}

final class VisibleOnHover extends QueueCloseButtonBehavior {
  const VisibleOnHover();

  @override
  bool get initialVisibility => false;

  @override
  bool onHover({required final bool isHovering}) => isHovering;

  @override
  bool onTap({required final bool currentVisibility}) => !currentVisibility;
}

final class Hidden extends QueueCloseButtonBehavior {
  const Hidden();

  @override
  bool get initialVisibility => false;

  @override
  bool onHover({required final bool isHovering}) => false;

  @override
  bool onTap({required final bool currentVisibility}) => false;
}
