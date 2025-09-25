part of '../notification.dart';

class _DraggableTransitions extends StatefulWidget {
  const _DraggableTransitions({
    required this.parent,
    required this.content,
    this.thresholdInPixels = 50,
    this.hapticFeedbackOnStart = true,
    this.enableDismiss = true,
    this.enableRelocation = true,
    super.key,
  });
  final _NotificationWidgetState parent;
  final Widget content;
  final bool enableRelocation;
  final bool enableDismiss;
  final int thresholdInPixels;

  final bool hapticFeedbackOnStart;

  // final Function(QueuePosition acceptedPosition) onRelocationAccepted;
  // final Function(QueuePosition? declinedPosition) onRelocationCanceled;
  // final void Function() onDragStarted;
  // final void Function() onDismissAccepted;
  // final void Function() onDismissCanceled;
  @override
  State<_DraggableTransitions> createState() => _DraggableTransitionsState();
}

class _DraggableTransitionsState extends State<_DraggableTransitions> {
  _InheritedNotificationWidget? _parent;
  late Size _screenSize;
  double get _screenHeight => _screenSize.height;
  double get _screenWidth => _screenSize.width;

  final ValueNotifier<OffsetPair?> _dragOffsetPairNotifier =
      ValueNotifier(null);
  @override
  void initState() {
    debugPrint('''
----------------Notification${_parent?.widget.key}:::_DraggableTransition:::initState------------
''');
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _parent = _InheritedNotificationWidget.of(context);
    debugPrint('''
----------------Notification${_parent?.widget.key}:::_DraggableTransition:::didChangeDependency------------
''');
    _screenSize = MediaQuery.of(context).size;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    debugPrint('''
----------------Notification${_parent?.widget.key}:::_DraggableTransition:::dispose------------
''');
    _queueTargetsOverlayEntry
      ?..remove()
      ..dispose();
    _queueTargetsOverlayEntry = null;

    _dragOffsetPairNotifier.dispose();

    super.dispose();
  }

  bool _passedThreshold(final Offset? globalOffset) {
    final passedVerticalThreshold = globalOffset != null &&
        (globalOffset.dy < widget.thresholdInPixels ||
            globalOffset.dy > _screenHeight - widget.thresholdInPixels);
    final passedHorizontalThreshold = globalOffset != null &&
        (globalOffset.dx < widget.thresholdInPixels ||
            globalOffset.dx > _screenWidth - widget.thresholdInPixels);
    final passedThreshold =
        passedVerticalThreshold || passedHorizontalThreshold;

    debugPrint('''
----------------Notification${_parent?.widget.key}:::_DraggableTransition:::_passedThreshold------------
------------------|Global Drag Offset: $globalOffset
------------------|ThresholdInPixels: ${widget.thresholdInPixels} Points
------------------|PassedThreshold: $passedThreshold
''');

    return passedThreshold;
  }

  QueuePosition? _getCandidatePosition(
    final Offset? globalOffset,
    final bool passedThreshold,
  ) {
    final QueuePosition? candidatePosition;
    if (!passedThreshold) {
      candidatePosition = null;
    } else {
      final widthThird = _screenWidth / 3;
      final heightThird = _screenHeight / 3;
      if (globalOffset == null) {
        return null;
      }
      final x = globalOffset.dx;
      final y = globalOffset.dy;

      if (y < heightThird) {
        if (x < widthThird) {
          candidatePosition = QueuePosition.topLeft;
        } else if (x < 2 * widthThird) {
          candidatePosition = QueuePosition.topCenter;
        } else {
          candidatePosition = QueuePosition.topRight;
        }
      } else if (y < 2 * heightThird) {
        if (x < widthThird) {
          candidatePosition = QueuePosition.centerLeft;
        } else if (x < 2 * widthThird) {
          candidatePosition = null;
        } else {
          candidatePosition = QueuePosition.centerRight;
        }
      } else {
        if (x < widthThird) {
          candidatePosition = QueuePosition.bottomLeft;
        } else if (x < 2 * widthThird) {
          candidatePosition = QueuePosition.bottomCenter;
        } else {
          candidatePosition = QueuePosition.bottomRight;
        }
      }
    }
    debugPrint('''
--------------Notification${_parent?.widget.key}:::_DraggableTransition:::_getCandidatePosition------------
----------------|GlobalDragOffset: $globalOffset
----------------|ThresholdInPixels: ${widget.thresholdInPixels} Points
----------------|PassedThreshold: $passedThreshold
----------------|CandidatePosition: $candidatePosition
''');

    return candidatePosition;
  }

  OverlayEntry? _queueTargetsOverlayEntry;

  @override
  Widget build(final BuildContext context) {
    debugPrint('''
------------Notification${_parent?.widget.key}:::_DraggableTransition:::Build------------
--------------|EnabledRelocation: ${widget.enableRelocation}
--------------|EnabledDismiss: ${widget.enableDismiss}''');

    return ValueListenableBuilder(
      valueListenable: _dragOffsetPairNotifier,
      builder: (final context, final dragOffsetPair, final child) {
        debugPrint('''
--------------Notification${_parent?.widget.key}:::_DraggableTransition:::InnerBuild--------------''');

        final passedThreshold = _passedThreshold(dragOffsetPair?.global);
        final candidatePosition = _queueTargetsOverlayEntry != null
            ? _getCandidatePosition(dragOffsetPair?.global, passedThreshold)
            : null;
        return LongPressDraggable<QueuePosition>(
          data: candidatePosition ?? _parent?.queue.position,
          axis: null,
          onDragStarted: () {
            debugPrint('''
--------------Notification${_parent?.widget.key}:::_DraggableTransition:::Relocating:::onDragStarted--------------''');
            _parent?.state.ditchDismissTimer();
            if (widget.enableRelocation) {
              _queueTargetsOverlayEntry = OverlayEntry(
                builder: (final context) => RelocationQueueTargets(
                  currentPosition: widget.parent.widget.queue.position,
                  passedThreshold: passedThreshold,
                  screenSize: _screenSize,
                ),
                maintainState: true,
              );
              Overlay.of(context).insert(_queueTargetsOverlayEntry!);
            }
          },
          onDragUpdate: (final details) {
            if (widget.enableRelocation) {
              _dragOffsetPairNotifier.value = OffsetPair(
                local: details.delta,
                global: details.globalPosition,
              );
            }
          },
          onDragEnd: (final details) {
            debugPrint('''
--------------Notification${_parent?.widget.key}:::_DraggableTransition:::Relocating:::onDragEnd--------------
----------------|EndOffset: ${dragOffsetPair?.global}
----------------|PassedThreshold: $passedThreshold
----------------|OriginalPosition: ${_parent?.queue.position}
----------------|EndPosition: $candidatePosition
----------------|------> ${passedThreshold ? 'Moving to new NotificationQueue' : 'Skipping position'}.
''');
            _queueTargetsOverlayEntry?.remove();
            _queueTargetsOverlayEntry?.dispose();
            _queueTargetsOverlayEntry = null;

            if (candidatePosition != null &&
                candidatePosition != _parent?.queue.position &&
                passedThreshold) {
              widget.parent.dismiss();
              widget.parent.widget.copyWith(candidatePosition).show(context);
            } else {
              _dragOffsetPairNotifier.value = null;
              widget.parent.initDismissTimer();
            }
          },
          maxSimultaneousDrags: 1,
          hapticFeedbackOnStart: widget.hapticFeedbackOnStart,
          childWhenDragging: const SizedBox.shrink(),
          feedback: _buildNotificationTransition(
            dragOffsetPair?.local,
            passedThreshold,
          ),
          child: Draggable(
            axis: Axis.horizontal,
            maxSimultaneousDrags: 1,
            onDragStarted: () {
              debugPrint('''
--------------Notification${_parent?.widget.key}:::_DraggableTransition:::Dismissing:::onDragStarted--------------''');
              widget.parent.ditchDismissTimer();
            },
            onDragUpdate: (final details) {
              if (widget.enableDismiss) {
                _dragOffsetPairNotifier.value = OffsetPair(
                  local: Offset(details.delta.dx, 0),
                  global: details.globalPosition,
                );
              }
            },
            onDragEnd: (final details) {
              debugPrint('''
--------------Notification${_parent?.widget.key}:::_DraggableTransition:::Dismissing:::onDragEnd--------------
----------------|EndOffset: ${dragOffsetPair?.global}
----------------|PassedThreshold: $passedThreshold
----------------|------> ${passedThreshold ? 'Dismissing' : 'Skipping Dismiss'}.
''');
              if (passedThreshold) {
                widget.parent.dismiss();
              } else {
                _dragOffsetPairNotifier.value = null;
                widget.parent.initDismissTimer();
              }
            },
            feedback: _buildNotificationTransition(
              dragOffsetPair?.local,
              passedThreshold,
            ),
            childWhenDragging: const SizedBox.shrink(),
            child: _buildContent(passedThreshold),
          ),
        );
      },
    );
  }

  Widget _buildNotificationTransition(
    final Offset? local,
    final bool passedThreshold,
  ) =>
      Transform.translate(
        offset: local ?? Offset.zero,
        child: _buildContent(passedThreshold),
      );

  AnimatedOpacity _buildContent(final bool passedThreshold) => AnimatedOpacity(
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOut,
        opacity: passedThreshold ? 0.2 : 1.0,
        child: widget.content,
      );
}
