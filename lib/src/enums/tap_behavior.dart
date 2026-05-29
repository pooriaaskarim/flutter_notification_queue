part of 'enums.dart';

/// Defines the tap interaction behavior for notifications.
///
/// Set at the `NotificationQueue` level to establish a default for all
/// notifications in that queue. Individual `NotificationWidget`s can override
/// this via their own `tapBehavior` field.
///
/// Available behaviors:
/// - [TapToDismiss] — tapping dismisses the notification (default)
/// - [TapToExpand] — tapping toggles the expanded/collapsed state
/// - [TapToAct] — tapping fires a developer-provided callback
/// - [TapDisabled] — tapping produces no effect
sealed class TapBehavior {
  const TapBehavior();
}

/// Tapping the notification dismisses it.
///
/// This is the backward-compatible default, preserving the behavior that
/// previously existed when using `NotificationAction.onTap`.
final class TapToDismiss extends TapBehavior {
  const TapToDismiss();
}

/// Tapping the notification toggles its expanded/collapsed state.
///
/// When active, the entire card surface becomes the expand/collapse affordance,
/// providing a much larger touch target than the chevron button alone.
/// The expand button remains as an explicit alternative.
///
/// The notification is **not** dismissed on tap.
final class TapToExpand extends TapBehavior {
  const TapToExpand();
}

/// Tapping the notification fires a developer-provided callback.
///
/// The notification is **not** automatically dismissed — the developer controls
/// lifecycle explicitly. To dismiss after the callback, use the notification
/// reference from the outer scope, or call `notification.dismiss()` if you
/// have access to it.
///
/// Example:
/// ```dart
/// final myNotification = NotificationWidget(message: 'Hello');
///
/// // In your queue setup:
/// NotificationQueue.defaultQueue(
///   tapBehavior: TapToAct(onTap: () {
///     openDetailSheet();
///     myNotification.dismiss();
///   }),
/// )
/// ```
final class TapToAct extends TapBehavior {
  const TapToAct({
    required this.onTap,
    this.dismissOnAct = true,
  });

  /// Called when the user taps the notification.
  final VoidCallback onTap;

  /// Whether the notification should be dismissed automatically after `onTap`
  /// fires.
  ///
  /// Defaults to `true` to align with standard mobile and desktop operating
  /// system behavior, where taking action on a notification card dismisses it
  /// from the screen.
  final bool dismissOnAct;
}

/// Tapping the notification produces no effect.
///
/// Use this when the notification card is purely informational and should not
/// respond to user taps at all.
final class TapDisabled extends TapBehavior {
  const TapDisabled();
}
