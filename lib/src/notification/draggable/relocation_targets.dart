part of '../notification.dart';

class RelocationQueueTargets extends StatelessWidget {
  const RelocationQueueTargets({
    required this.currentPosition,
    required this.screenSize,
    required this.passedThreshold,
    // required this.local,
    super.key,
  });

  // final Offset? local;
  final bool passedThreshold;
  final QueuePosition currentPosition;
  final Size screenSize;
  double get _screenWidth => screenSize.width;
  double get _screenHeight => screenSize.height;

  @override
  Widget build(final BuildContext context) => Stack(
        fit: StackFit.passthrough,
        children: [
          ...QueuePosition.values.map((final position) {
            if (position == currentPosition) {
              return const SizedBox.shrink();
            }
            return Align(
              alignment: position.alignment,
              child: Container(
                alignment: position.alignment,
                width: _screenWidth / 3,
                height: _screenHeight / 3,
                child: DragTarget<QueuePosition>(
                  onWillAcceptWithDetails: (final details) => true,
                  builder: (
                    final context,
                    final candidateData,
                    final rejectedData,
                  ) =>
                      AnimatedContainer(
                    alignment: position.alignment,
                    duration: const Duration(milliseconds: 200),
                    clipBehavior: Clip.none,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.blueAccent,
                          if (candidateData.isNotEmpty) Colors.blue,
                          if (passedThreshold) Colors.red,
                          Colors.transparent,
                        ],
                        center: position.alignment,
                        radius: passedThreshold
                            ? 1.4
                            : candidateData.isNotEmpty
                                ? 0.80
                                : 0.50,
                      ),
                      border: Border.all(
                        color: candidateData.isNotEmpty
                            ? Colors.blue.withValues(alpha: 0.7)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    // child: candidateData.isNotEmpty ? widget.content : null,
                  ),
                ),
              ),
            );
          }),
        ],
      );
}
