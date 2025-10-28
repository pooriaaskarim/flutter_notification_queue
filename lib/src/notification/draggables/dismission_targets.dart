part of '../notification.dart';

class _DismissionTargets extends StatelessWidget {
  const _DismissionTargets({
    required this.onAccept,
    required this.screenSize,
    required this.passedThreshold,
  });

  final void Function() onAccept;
  final bool passedThreshold;
  final Size screenSize;

  double get _screenWidth => screenSize.width;

  double get _screenHeight => screenSize.height;

  @override
  Widget build(final BuildContext context) {
    Alignment? candidateAlignment;
    return Stack(
      fit: StackFit.expand,
      children: [
        ...<Alignment>[
          Alignment.centerLeft,
          Alignment.centerRight,
        ].map((final alignment) => Align(
              alignment: alignment,
              child: DragTarget<AlignmentGeometry>(
                hitTestBehavior: HitTestBehavior.opaque,
                onWillAcceptWithDetails: (final details) => true,
                onMove: (final details) {
                  debugPrint('''
------------------DismissionTargets:::onMove---------------------------
--------------------|TargetData: ${details.data}
--------------------|TargetOffset: ${details.offset}
--------------------|PassedThreshold: $passedThreshold
--------------------|----> on: $candidateAlignment''');
                },
                onAcceptWithDetails: (final details) {
                  debugPrint('''
------------------DismissionTargets:::onAccept---------------------------
--------------------|PassedThreshold: $passedThreshold
--------------------|----> on: $candidateAlignment''');

                  if (passedThreshold) {
                    debugPrint('''
--------------------|----> Dismissing... .
''');
                    onAccept();
                  } else {
                    debugPrint('''
--------------------|----> Dismiss Skipped.
''');
                  }
                },
                builder: (
                  final context,
                  final candidateData,
                  final rejectedData,
                ) {
                  if (passedThreshold && candidateData.isNotEmpty) {
                    debugPrint('''
--------------------|----> CandidateAlignmentPosition: $candidateAlignment''');
                    candidateAlignment = alignment;
                  }
                  return AnimatedContainer(
                    alignment: alignment,
                    duration: const Duration(milliseconds: 200),
                    width: _screenWidth / 4,
                    height: _screenHeight,

                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black,
                          if (candidateData.isNotEmpty) Colors.black87,
                          if (candidateData.isNotEmpty && passedThreshold)
                            Colors.red,
                          Colors.transparent,
                        ],
                        begin: alignment,
                        end: Alignment.center,

                        // radius: candidateData.isNotEmpty && passedThreshold
                        //     ? 0.8
                        //     : candidateData.isNotEmpty
                        //         ? 0.6
                        //         : 0.5,
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
            )),
      ],
    );
  }
}
