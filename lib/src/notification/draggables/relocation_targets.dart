part of '../notification.dart';

class _RelocationTargets extends StatelessWidget {
  const _RelocationTargets({
    required this.onAccept,
    required this.currentPosition,
    required this.targets,
    required this.screenSize,
    required this.passedThreshold,
  });

  final void Function(QueuePosition candidatePosition) onAccept;
  final Set<QueuePosition> targets;
  final bool passedThreshold;
  final QueuePosition currentPosition;
  final Size screenSize;

  double get _screenWidth => screenSize.width;

  double get _screenHeight => screenSize.height;

  @override
  Widget build(final BuildContext context) {
    QueuePosition? candidatePosition;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        ...targets.map((final position) {
          if (position == currentPosition) {
            return const SizedBox.shrink();
          }
          return Align(
            alignment: position.alignment,
            child: DragTarget<QueuePosition>(
              hitTestBehavior: HitTestBehavior.opaque,
              onWillAcceptWithDetails: (final details) => true,
              onMove: (final details) {
                final b = LogBuffer.d
                  ?..writeAll([
                    'PassedThreshold: $passedThreshold',
                    '----> on: $candidatePosition',
                  ])
                  ..flush();
              },
              onAcceptWithDetails: (final details) {
                final b = LogBuffer.d
                  ?..writeAll([
                    'CandidatePosition: $candidatePosition',
                    'PassedThreshold(Parent): $passedThreshold',
                  ]);

                if (candidatePosition != null) {
                  b?.writeAll(['----> Relocating to $candidatePosition... .']);
                  onAccept(candidatePosition!);
                } else {
                  b?.writeAll(['No Candidates.', '----> Skipped Relocation.']);
                }
                b?.flush();
              },
              builder: (
                final context,
                final candidateData,
                final rejectedData,
              ) {
                if (passedThreshold && candidateData.isNotEmpty) {
                  candidatePosition = position;
                }
                return AnimatedContainer(
                  alignment: position.alignment,
                  duration: const Duration(milliseconds: 200),
                  width: _screenWidth / 3,
                  height: _screenHeight / 3,
                  clipBehavior: Clip.none,

                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.blueAccent,
                        if (candidateData.isNotEmpty) Colors.blue,
                        if (candidateData.isNotEmpty && passedThreshold)
                          Colors.green,
                        Colors.transparent,
                      ],
                      center: position.alignment,
                      radius: candidateData.isNotEmpty && passedThreshold
                          ? 0.8
                          : candidateData.isNotEmpty
                              ? 0.6
                              : 0.5,
                    ),
                    // border: Border.all(
                    //   color: candidateData.isNotEmpty
                    //       ? Colors.blue.withValues(alpha: 0.7)
                    //       : Colors.transparent,
                    //   width: 2,
                    // ),
                  ),
                  // child: candidateData.isNotEmpty ? content : null,
                );
              },
            ),
          );
        }),
      ],
    );
  }
}
