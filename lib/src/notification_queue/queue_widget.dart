part of 'notification_queue.dart';

class QueueWidget extends StatefulWidget {
  const QueueWidget._({
    required this.parentQueue,
    required final GlobalKey<QueueWidgetState> key,
  }) : _key = key;
  final GlobalKey<QueueWidgetState> _key;

  @override
  GlobalKey<QueueWidgetState> get key => _key;
  final NotificationQueue parentQueue;

  @override
  State<StatefulWidget> createState() => QueueWidgetState();
}

class QueueWidgetState extends State<QueueWidget> {
  static final _logger = Logger.get('fnq.Queue.Widget');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      _logger
          .debug('Post-frame: Processing any pre-mount pending notifications.');
      widget.parentQueue._processPending();
    });
  }

  @override
  void dispose() {
    widget.parentQueue._cachedWidget = null;
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) =>
      ValueListenableBuilder<LinkedHashSet<NotificationWidget>>(
        valueListenable: widget.parentQueue._activeNotifications,
        builder: (final context, final activeNotifications, final child) {
          final pendingCount = widget.parentQueue._pendingNotifications.length;
          final activeList = activeNotifications.toList();
          return SafeArea(
            child: Container(
              alignment: widget.parentQueue.position.alignment,
              margin: widget.parentQueue.margin,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height *
                      0.6, // Bound overall height
                ),
                child: Column(
                  spacing: widget.parentQueue.spacing,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: widget.parentQueue.mainAxisAlignment,
                  crossAxisAlignment: widget.parentQueue.crossAxisAlignment,
                  verticalDirection: widget.parentQueue.verticalDirection,
                  children: [
                    widget.parentQueue.queueIndicatorBuilder
                            ?.call(pendingCount) ??
                        const SizedBox.shrink(),
                    ...activeList.asMap().entries.map((final entry) {
                      final index = entry.key;
                      final notification = entry.value;
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        reverseDuration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeInOut,
                        switchOutCurve: Curves.easeOut,
                        // Custom layout: don't keep previous children around.
                        // The default layoutBuilder uses a Stack, which:
                        //  (a) gets infinite height from the parent Column
                        //  (b) keeps old GlobalKey'd widgets alive, causing
                        //      duplicate GlobalKey crashes when notifications
                        //      shift positions during LIFO swap.
                        // TODO: Replace per-slot AnimatedSwitcher with
                        //  AnimatedList for proper entry/exit animations.
                        layoutBuilder:
                            (final currentChild, final previousChildren) =>
                                currentChild ?? const SizedBox.shrink(),
                        child: KeyedSubtree(
                          key: ValueKey('${notification.id}_$index'),
                          // Unique by id + position
                          child: DraggableTransitions(
                            notification: notification,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      );
}
