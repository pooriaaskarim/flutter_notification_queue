part of '../notification.dart';

class DraggableTransitions extends StatefulWidget {
  const DraggableTransitions({
    required this.notification,
    this.hapticFeedbackOnStart = true,
    super.key,
  });

  final NotificationWidget notification;

  final bool hapticFeedbackOnStart;

  @override
  State<DraggableTransitions> createState() => DraggableTransitionsState();
}

class DraggableTransitionsState extends State<DraggableTransitions> {
  late Size _screenSize;

  double get _screenHeight => _screenSize.height;

  double get _screenWidth => _screenSize.width;

  final ValueNotifier<OffsetPair?> _dragOffsetPairNotifier =
      ValueNotifier(null);

  @override
  void initState() {
    debugPrint('''
----------------Notification${widget.notification.key}:::DraggableTransition:::initState------------
''');
    super.initState();
  }

  @override
  void didChangeDependencies() {
    debugPrint('''
----------------Notification${widget.notification.key}:::DraggableTransition:::didChangeDependency------------
''');
    _screenSize = MediaQuery.of(context).size;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    debugPrint('''
----------------Notification${widget.notification.key}:::DraggableTransition:::dispose------------
''');

    _dragOffsetPairNotifier.dispose();

    super.dispose();
  }

  bool _passedThreshold(
    final Offset? globalOffset,
    final int thresholdInPixels,
  ) {
    final passedVerticalThreshold = globalOffset != null &&
        (globalOffset.dy < thresholdInPixels ||
            globalOffset.dy > _screenHeight - thresholdInPixels);
    final passedHorizontalThreshold = globalOffset != null &&
        (globalOffset.dx < thresholdInPixels ||
            globalOffset.dx > _screenWidth - thresholdInPixels);
    final passedThreshold =
        passedVerticalThreshold || passedHorizontalThreshold;

//     debugPrint('''
// ----------------Notification${widget.notification.key}:::DraggableTransition:::_passedThreshold------------
// ------------------|Global Drag Offset: $globalOffset
// ------------------|ThresholdInPixels: ${widget.thresholdInPixels} Points
// ------------------|PassedThreshold: $passedThreshold
// ''');

    return passedThreshold;
  }

  final OverlayPortalController _overlayPortalController =
      OverlayPortalController();

  @override
  Widget build(final BuildContext context) => longPressWidget();

  Widget longPressWidget() =>
      switch (widget.notification.queue.longPressDragBehavior) {
        Relocate() => LongPressDraggable<QueuePosition>(
            data: widget.notification.queue.position,
            axis: null,
            onDragStarted: () {
              //         debugPrint('''
              // --------------Notification${widget.notification.key}:::DraggableTransition:::Relocation:::onDragStarted--------------''');
              widget.notification.key.currentState?.ditchDismissTimer();
              if (widget.notification.queue.longPressDragBehavior
                  is! Disabled) {
                _overlayPortalController.show();
              }
            },
            onDragUpdate: (final details) {
              if (widget.notification.queue.longPressDragBehavior
                  is! Disabled) {
                _dragOffsetPairNotifier.value = OffsetPair(
                  local: details.delta,
                  global: details.globalPosition,
                );
              }
            },
            onDragEnd: (final details) {
              _dragOffsetPairNotifier.value = null;
              widget.notification.key.currentState?.initDismissTimer();
              if (widget.notification.queue.longPressDragBehavior
                  is! Disabled) {
                _overlayPortalController.hide();
              }
            },
            maxSimultaneousDrags: 1,
            hapticFeedbackOnStart: widget.hapticFeedbackOnStart,
            hitTestBehavior: HitTestBehavior.deferToChild,
            childWhenDragging: const SizedBox.shrink(),
            feedback: ValueListenableBuilder(
              valueListenable: _dragOffsetPairNotifier,
              builder: (final context, final dragOffestPair, final child) {
                final passedThreshold = _passedThreshold(
                  dragOffestPair?.global,
                  (widget.notification.queue.longPressDragBehavior as Relocate)
                      .thresholdInPixels,
                );

                return OverlayPortal.overlayChildLayoutBuilder(
                  controller: _overlayPortalController,
                  overlayChildBuilder: (
                    final context,
                    final layoutInfo,
                  ) =>
                      _RelocationTargets(
                    targets: (widget.notification.queue.longPressDragBehavior
                            as Relocate)
                        .positions,
                    currentPosition: widget.notification.queue.position,
                    onAccept: (final candidatePosition) {
                      NotificationManager.instance.relocate(
                        widget.notification,
                        candidatePosition,
                        context,
                      );
                    },
                    screenSize: layoutInfo.overlaySize,
                    passedThreshold: passedThreshold,
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 480),
                    curve: Curves.easeOut,
                    opacity: passedThreshold ? 0.3 : 1.0,
                    child: widget.notification,
                  ),
                );
              },
            ),
            child: draggable(),
          ),
        Dismiss() => LongPressDraggable<AlignmentGeometry>(
            data: widget.notification.queue.position.alignment,
            axis: null,
            onDragStarted: () {
              //         debugPrint('''
              // --------------Notification${widget.notification.key}:::DraggableTransition:::Relocation:::onDragStarted--------------''');
              widget.notification.key.currentState?.ditchDismissTimer();
              if (widget.notification.queue.longPressDragBehavior
                  is! Disabled) {
                _overlayPortalController.show();
              }
            },
            onDragUpdate: (final details) {
              if (widget.notification.queue.longPressDragBehavior
                  is! Disabled) {
                _dragOffsetPairNotifier.value = OffsetPair(
                  local: details.delta,
                  global: details.globalPosition,
                );
              }
            },
            onDragEnd: (final details) {
              _dragOffsetPairNotifier.value = null;
              widget.notification.key.currentState?.initDismissTimer();
              if (widget.notification.queue.longPressDragBehavior
                  is! Disabled) {
                _overlayPortalController.hide();
              }
            },
            maxSimultaneousDrags: 1,
            hapticFeedbackOnStart: widget.hapticFeedbackOnStart,
            hitTestBehavior: HitTestBehavior.deferToChild,
            childWhenDragging: const SizedBox.shrink(),
            feedback: ValueListenableBuilder(
              valueListenable: _dragOffsetPairNotifier,
              builder: (final context, final dragOffestPair, final child) {
                final passedThreshold = _passedThreshold(
                  dragOffestPair?.global,
                  (widget.notification.queue.longPressDragBehavior as Dismiss)
                      .thresholdInPixels,
                );

                return OverlayPortal.overlayChildLayoutBuilder(
                  controller: _overlayPortalController,
                  overlayChildBuilder: (
                    final context,
                    final layoutInfo,
                  ) =>
                      _DismissionTargets(
                    onAccept: () {
                      widget.notification.key.currentState?.dismiss();
                    },
                    screenSize: layoutInfo.overlaySize,
                    passedThreshold: passedThreshold,
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 480),
                    curve: Curves.easeOut,
                    opacity: passedThreshold ? 0.3 : 1.0,
                    child: widget.notification,
                  ),
                );
              },
            ),
            child: draggable(),
          ),
        Disabled() => draggable(),
      };

  Widget draggable() => switch (widget.notification.queue.dragBehavior) {
        Relocate() => Draggable<QueuePosition>(
            data: widget.notification.queue.position,
            axis: null,
            onDragStarted: () {
              //         debugPrint('''
              // --------------Notification${widget.notification.key}:::DraggableTransition:::Relocation:::onDragStarted--------------''');
              widget.notification.key.currentState?.ditchDismissTimer();
              if (widget.notification.queue.dragBehavior is! Disabled) {
                _overlayPortalController.show();
              }
            },
            onDragUpdate: (final details) {
              if (widget.notification.queue.dragBehavior is! Disabled) {
                _dragOffsetPairNotifier.value = OffsetPair(
                  local: details.delta,
                  global: details.globalPosition,
                );
              }
            },
            onDragEnd: (final details) {
              _dragOffsetPairNotifier.value = null;
              widget.notification.key.currentState?.initDismissTimer();
              if (widget.notification.queue.dragBehavior is! Disabled) {
                _overlayPortalController.hide();
              }
            },
            maxSimultaneousDrags: 1,
            childWhenDragging: const SizedBox.shrink(),
            feedback: ValueListenableBuilder(
              valueListenable: _dragOffsetPairNotifier,
              builder: (final context, final dragOffestPair, final child) {
                final passedThreshold = _passedThreshold(
                  dragOffestPair?.global,
                  (widget.notification.queue.dragBehavior as Relocate)
                      .thresholdInPixels,
                );

                return OverlayPortal.overlayChildLayoutBuilder(
                  controller: _overlayPortalController,
                  overlayChildBuilder: (
                    final context,
                    final layoutInfo,
                  ) =>
                      _RelocationTargets(
                    targets:
                        (widget.notification.queue.dragBehavior as Relocate)
                            .positions,
                    currentPosition: widget.notification.queue.position,
                    onAccept: (final candidatePosition) {
                      NotificationManager.instance.relocate(
                        widget.notification,
                        candidatePosition,
                        context,
                      );
                    },
                    screenSize: layoutInfo.overlaySize,
                    passedThreshold: passedThreshold,
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 480),
                    curve: Curves.easeOut,
                    opacity: passedThreshold ? 0.3 : 1.0,
                    child: widget.notification,
                  ),
                );
              },
            ),
            child: widget.notification,
          ),
        Dismiss() => Draggable<AlignmentGeometry>(
            data: widget.notification.queue.position.alignment,
            axis: null,
            onDragStarted: () {
              //         debugPrint('''
              // --------------Notification${widget.notification.key}:::DraggableTransition:::Relocation:::onDragStarted--------------''');
              widget.notification.key.currentState?.ditchDismissTimer();
              if (widget.notification.queue.dragBehavior is! Disabled) {
                _overlayPortalController.show();
              }
            },
            onDragUpdate: (final details) {
              if (widget.notification.queue.dragBehavior is! Disabled) {
                _dragOffsetPairNotifier.value = OffsetPair(
                  local: details.delta,
                  global: details.globalPosition,
                );
              }
            },
            onDragEnd: (final details) {
              _dragOffsetPairNotifier.value = null;
              widget.notification.key.currentState?.initDismissTimer();
              if (widget.notification.queue.longPressDragBehavior
                  is! Disabled) {
                _overlayPortalController.hide();
              }
            },
            maxSimultaneousDrags: 1,
            childWhenDragging: const SizedBox.shrink(),
            feedback: ValueListenableBuilder(
              valueListenable: _dragOffsetPairNotifier,
              builder: (final context, final dragOffestPair, final child) {
                final passedThreshold = _passedThreshold(
                  dragOffestPair?.global,
                  (widget.notification.queue.dragBehavior as Dismiss)
                      .thresholdInPixels,
                );

                return OverlayPortal.overlayChildLayoutBuilder(
                  controller: _overlayPortalController,
                  overlayChildBuilder: (
                    final context,
                    final layoutInfo,
                  ) =>
                      _DismissionTargets(
                    onAccept: () {
                      widget.notification.key.currentState?.dismiss();
                    },
                    screenSize: layoutInfo.overlaySize,
                    passedThreshold: passedThreshold,
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 480),
                    curve: Curves.easeOut,
                    opacity: passedThreshold ? 0.3 : 1.0,
                    child: widget.notification,
                  ),
                );
              },
            ),
            child: widget.notification,
          ),
        Disabled() => widget.notification,
      };
}
