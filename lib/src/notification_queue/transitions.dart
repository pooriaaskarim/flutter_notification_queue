part of 'notification_queue.dart';

/// Defines the entrance and exit animation strategy for a notification.
///
/// Implement this interface to create custom transition effects (e.g., Blur,
/// Scale, Slide).
@immutable
//ignore: one_member_abstracts
abstract class NotificationTransition {
  const NotificationTransition();

  /// Builds the transition widget.
  ///
  /// [animation] drives both entrance (forward) and exit (reverse).
  /// [position] is the position of the queue, used for directional animations.
  /// [child] is the notification widget itself.
  Widget build(
    final BuildContext context,
    final Animation<double> animation,
    final QueuePosition position,
    final Widget child,
  );
}

/// A function signature for building custom notification transitions.
typedef NotificationTransitionBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  QueuePosition position,
  Widget child,
);

/// A transition strategy that delegates to a builder callback.
///
/// Use this to create one-off custom transitions without subclassing
/// [NotificationTransition].
class BuilderTransitionStrategy extends NotificationTransition {
  const BuilderTransitionStrategy(this.builder);

  final NotificationTransitionBuilder builder;

  @override
  Widget build(
    final BuildContext context,
    final Animation<double> animation,
    final QueuePosition position,
    final Widget child,
  ) =>
      builder(context, animation, position, child);
}

/// The standard transition: Slides in from the queue's specific offset
/// while fading in.
class SlideTransitionStrategy extends NotificationTransition {
  const SlideTransitionStrategy({
    this.slideOffset,
    this.curve = Curves.easeOutQuad,
    this.reverseCurve = Curves.easeInQuad,
  });

  /// The offset from which the notification slides in.
  ///
  /// If null, defaults to [QueuePosition.defaultSlideOffset].
  ///
  /// Examples:
  /// - `Offset(1, 0)`: Slides in from the right.
  /// - `Offset(-1, 0)`: Slides in from the left.
  /// - `Offset(0, -1)`: Slides in from the top.
  /// - `Offset(0, 1)`: Slides in from the bottom.
  final Offset? slideOffset;

  /// The curve for the entrance animation.
  final Curve curve;

  /// The curve for the exit animation.
  final Curve reverseCurve;

  @override
  Widget build(
    final BuildContext context,
    final Animation<double> animation,
    final QueuePosition position,
    final Widget child,
  ) {
    final begin = slideOffset ?? position.defaultSlideOffset;
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: curve,
          reverseCurve: reverseCurve,
        ),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: curve,
          reverseCurve: reverseCurve,
        ),
        child: child,
      ),
    );
  }
}

/// A simple Fade transition (Standard Opacity).
class FadeTransitionStrategy extends NotificationTransition {
  const FadeTransitionStrategy({
    this.curve = Curves.easeOutQuad,
    this.reverseCurve = Curves.easeInQuad,
  });

  /// The curve for the entrance animation.
  final Curve curve;

  /// The curve for the exit animation.
  final Curve reverseCurve;

  @override
  Widget build(
    final BuildContext context,
    final Animation<double> animation,
    final QueuePosition position,
    final Widget child,
  ) =>
      FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: curve,
          reverseCurve: reverseCurve,
        ),
        child: child,
      );
}

/// A Scale (Pop-in) transition.
class ScaleTransitionStrategy extends NotificationTransition {
  const ScaleTransitionStrategy({
    this.alignment = Alignment.center,
    this.initialScale = 0.8,
    this.curve = Curves.easeOutBack,
    this.reverseCurve = Curves.easeInBack,
  }) : assert(initialScale >= 0, 'Initial scale must be >= 0');

  /// The alignment of the scale transition.
  ///
  /// If null, defaults to the [QueuePosition.alignment] of the queue.
  final Alignment? alignment;

  /// The initial scale of the notification.
  ///
  /// Defaults to 0.8.
  final double initialScale;

  /// The curve for the entrance animation.
  final Curve curve;

  /// The curve for the exit animation.
  final Curve reverseCurve;

  @override
  Widget build(
    final BuildContext context,
    final Animation<double> animation,
    final QueuePosition position,
    final Widget child,
  ) =>
      ScaleTransition(
        scale: Tween<double>(
          begin: initialScale,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: curve,
            reverseCurve: reverseCurve,
          ),
        ),
        alignment: alignment ??
            position.alignment.resolve(Directionality.maybeOf(context)),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: curve,
            reverseCurve: reverseCurve,
          ),
          child: child,
        ),
      );
}
