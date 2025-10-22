part of '../notification.dart';

class DraggableTransitions extends StatefulWidget {
  const DraggableTransitions({
    required this.notification,
    this.hapticFeedbackOnStart = true,
    this.enableDismiss = true,
    this.enableRelocation = true,
    super.key,
  });
  final NotificationWidget notification;
  final bool enableRelocation;
  final bool enableDismiss;

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
  ) {
    final thresholdInPixels =
        widget.notification.queue.relocationBehaviour.thresholdInPixels;
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
  Widget build(final BuildContext context) => longPressDraggableOrDraggable();

  Widget longPressDraggableOrDraggable() {
    if (widget.notification.queue.relocationBehaviour
        is LongPressRelocationBehaviour) {
      return LongPressDraggable<QueuePosition>(
        data: widget.notification.queue.position,
        axis: null,
        onDragStarted: () {
          //         debugPrint('''
          // --------------Notification${widget.notification.key}:::DraggableTransition:::Relocation:::onDragStarted--------------''');
          widget.notification.state?.ditchDismissTimer();
          if (widget.enableRelocation) {
            _overlayPortalController.show();
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
          _dragOffsetPairNotifier.value = null;
          widget.notification.state?.initDismissTimer();
          _overlayPortalController.hide();
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
            );

            return OverlayPortal.overlayChildLayoutBuilder(
              controller: _overlayPortalController,
              overlayChildBuilder: (
                final context,
                final layoutInfo,
              ) =>
                  _RelocationTargets(
                relocationPositions:
                    widget.notification.queue.relocationBehaviour.positions,
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
        child: draggableOrNotification(),
      );
    } else if (widget.notification.queue.dismissBehaviour
        is LongPressDismissBehaviour) {
      return LongPressDraggable<AlignmentGeometry>(
        data: widget.notification.queue.position.alignment,
        hapticFeedbackOnStart: widget.hapticFeedbackOnStart,
        axis: Axis.horizontal,
        maxSimultaneousDrags: 1,
        onDragStarted: () {
          //           debugPrint('''
          // --------------Notification${widget.notification.key}:::DraggableTransition:::Dismission:::onDragStarted--------------''');
          widget.notification.state?.ditchDismissTimer();
          _overlayPortalController.show();
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
          //           debugPrint('''
          // --------------Notification${widget.notification.key}:::DraggableTransition:::Dismission:::onDragEnd--------------
          // ----------------|EndOffset: ${dragOffsetPair?.global}
          // ----------------|PassedThreshold: $passedThreshold
          // ----------------|------> ${passedThreshold ? 'Dismissing' : 'Skipping Dismiss'}.
          // ''');

          _dragOffsetPairNotifier.value = null;
          widget.notification.state?.initDismissTimer();
          _overlayPortalController.hide();
        },
        feedback: ValueListenableBuilder(
          valueListenable: _dragOffsetPairNotifier,
          builder: (final _, final dragOffestPair, final child) {
            final passedThreshold = _passedThreshold(
              dragOffestPair?.global,
            );
            return OverlayPortal.overlayChildLayoutBuilder(
              controller: _overlayPortalController,
              overlayChildBuilder: (
                final _,
                final layoutInfo,
              ) =>
                  _DismissionTargets(
                onAccept: () {
                  widget.notification.state?.dismiss();
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
        childWhenDragging: const SizedBox.shrink(),
        child: draggableOrNotification(),
      );
    } else {
      return draggableOrNotification();
    }
  }

  Widget draggableOrNotification() {
    if (widget.notification.queue.relocationBehaviour
        is DragRelocationBehaviour) {
      return Draggable<QueuePosition>(
        data: widget.notification.queue.position,
        axis: null,
        onDragStarted: () {
          //         debugPrint('''
          // --------------Notification${widget.notification.key}:::DraggableTransition:::Relocation:::onDragStarted--------------''');
          widget.notification.state?.ditchDismissTimer();
          if (widget.enableRelocation) {
            _overlayPortalController.show();
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
          _dragOffsetPairNotifier.value = null;
          widget.notification.state?.initDismissTimer();
          _overlayPortalController.hide();
        },
        maxSimultaneousDrags: 1,
        hitTestBehavior: HitTestBehavior.deferToChild,
        childWhenDragging: const SizedBox.shrink(),
        feedback: ValueListenableBuilder(
          valueListenable: _dragOffsetPairNotifier,
          builder: (final context, final dragOffestPair, final child) {
            final passedThreshold = _passedThreshold(
              dragOffestPair?.global,
            );

            return OverlayPortal.overlayChildLayoutBuilder(
              controller: _overlayPortalController,
              overlayChildBuilder: (
                final context,
                final layoutInfo,
              ) =>
                  _RelocationTargets(
                relocationPositions:
                    widget.notification.queue.relocationBehaviour.positions,
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
      );
    } else if (widget.notification.queue.dismissBehaviour
        is DragDismissBehaviour) {
      return Draggable<AlignmentGeometry>(
        data: widget.notification.queue.position.alignment,
        axis: Axis.horizontal,
        maxSimultaneousDrags: 1,
        onDragStarted: () {
          //           debugPrint('''
          // --------------Notification${widget.notification.key}:::DraggableTransition:::Dismission:::onDragStarted--------------''');
          widget.notification.state?.ditchDismissTimer();
          _overlayPortalController.show();
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
          //           debugPrint('''
          // --------------Notification${widget.notification.key}:::DraggableTransition:::Dismission:::onDragEnd--------------
          // ----------------|EndOffset: ${dragOffsetPair?.global}
          // ----------------|PassedThreshold: $passedThreshold
          // ----------------|------> ${passedThreshold ? 'Dismissing' : 'Skipping Dismiss'}.
          // ''');

          _dragOffsetPairNotifier.value = null;
          widget.notification.state?.initDismissTimer();
          _overlayPortalController.hide();
        },
        feedback: ValueListenableBuilder(
          valueListenable: _dragOffsetPairNotifier,
          builder: (final _, final dragOffestPair, final child) {
            final passedThreshold = _passedThreshold(
              dragOffestPair?.global,
            );
            return OverlayPortal.overlayChildLayoutBuilder(
              controller: _overlayPortalController,
              overlayChildBuilder: (
                final _,
                final layoutInfo,
              ) =>
                  _DismissionTargets(
                onAccept: () {
                  widget.notification.state?.dismiss();
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
        childWhenDragging: const SizedBox.shrink(),
        child: widget.notification,
      );
    } else {
      return widget.notification;
    }
  }
}
