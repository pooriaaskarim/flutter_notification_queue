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
  ) =>
      _SlideAndFadeTransition(
        animation: animation,
        slideOffset: slideOffset ?? position.defaultSlideOffset,
        curve: curve,
        reverseCurve: reverseCurve,
        child: child,
      );
}

/// Internal [AnimatedWidget] that drives the slide + fade transition.
///
/// By extending [AnimatedWidget], the [CurvedAnimation] is created once
/// and stored in [listenable], completely eliminating the build-time listener
/// accumulation that would otherwise cause pumpAndSettle deadlocks.
class _SlideAndFadeTransition extends AnimatedWidget {
  _SlideAndFadeTransition({
    required final Animation<double> animation,
    required this.slideOffset,
    required this.curve,
    required this.reverseCurve,
    required this.child,
  }) : super(
          listenable: CurvedAnimation(
            parent: animation,
            curve: curve,
            reverseCurve: reverseCurve,
          ),
        );

  final Offset slideOffset;
  final Curve curve;
  final Curve reverseCurve;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final curvedAnimation = listenable as Animation<double>;
    return SlideTransition(
      position: Tween<Offset>(
        begin: slideOffset,
        end: Offset.zero,
      ).animate(curvedAnimation),
      child: FadeTransition(
        opacity: curvedAnimation,
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
      _FadeTransitionWidget(
        animation: animation,
        curve: curve,
        reverseCurve: reverseCurve,
        child: child,
      );
}

/// Internal [AnimatedWidget] for the fade-only transition.
class _FadeTransitionWidget extends AnimatedWidget {
  _FadeTransitionWidget({
    required final Animation<double> animation,
    required final Curve curve,
    required final Curve reverseCurve,
    required this.child,
  }) : super(
          listenable: CurvedAnimation(
            parent: animation,
            curve: curve,
            reverseCurve: reverseCurve,
          ),
        );

  final Widget child;

  @override
  Widget build(final BuildContext context) => FadeTransition(
        opacity: listenable as Animation<double>,
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
      _ScaleAndFadeTransition(
        animation: animation,
        initialScale: initialScale,
        alignment: alignment ??
            position.alignment.resolve(Directionality.maybeOf(context)),
        curve: curve,
        reverseCurve: reverseCurve,
        child: child,
      );
}

/// Internal [AnimatedWidget] for the scale + fade transition.
class _ScaleAndFadeTransition extends AnimatedWidget {
  _ScaleAndFadeTransition({
    required final Animation<double> animation,
    required this.initialScale,
    required this.alignment,
    required final Curve curve,
    required final Curve reverseCurve,
    required this.child,
  }) : super(
          listenable: CurvedAnimation(
            parent: animation,
            curve: curve,
            reverseCurve: reverseCurve,
          ),
        );

  final double initialScale;
  final Alignment? alignment;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final curvedAnimation = listenable as Animation<double>;
    return ScaleTransition(
      scale: Tween<double>(
        begin: initialScale,
        end: 1.0,
      ).animate(curvedAnimation),
      alignment: alignment ?? Alignment.center,
      child: FadeTransition(
        opacity: curvedAnimation,
        child: child,
      ),
    );
  }
}
