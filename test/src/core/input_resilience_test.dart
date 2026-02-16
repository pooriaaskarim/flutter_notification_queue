import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_notification_queue/src/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Input Resilience', () {
    // 1. Zombie Prevention
    test('Zombie Prevention: Throws if no interactive dismissal method exists',
        () {
      expect(
        () => ConfigurationManager(
          queues: {
            const TopRightQueue(
              dragBehavior: Disabled(),
              longPressDragBehavior: Disabled(),
              closeButtonBehavior: Hidden(),
            ),
          },
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    // Relocate is NOT a dismissal method.
    test('Zombie Prevention: Throws if only Relocate is enabled (no dismissal)',
        () {
      expect(
        () => ConfigurationManager(
          queues: {
            TopRightQueue(
              dragBehavior: Relocate.to({QueuePosition.bottomLeft}),
              longPressDragBehavior: const Disabled(),
              closeButtonBehavior: const Hidden(),
            ),
          },
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Zombie Prevention: Allows if at least one gesture is Dismiss', () {
      expect(
        () => ConfigurationManager(
          queues: {
            const TopRightQueue(
              dragBehavior: Dismiss(), // Interactive!
              longPressDragBehavior: Disabled(),
              closeButtonBehavior: Hidden(),
            ),
          },
        ),
        returnsNormally,
      );
    });

    test('Zombie Prevention: Allows if close button is visible', () {
      expect(
        () => ConfigurationManager(
          queues: {
            const TopRightQueue(
              dragBehavior: Disabled(),
              longPressDragBehavior: Disabled(),
              closeButtonBehavior: AlwaysVisible(), // Interactive!
            ),
          },
        ),
        returnsNormally,
      );
    });

    // onHover is considered interactive because of the touch fallback we
    // implemented
    test('Zombie Prevention: Allows onHover close button', () {
      expect(
        () => ConfigurationManager(
          queues: {
            const TopRightQueue(
              dragBehavior: Disabled(),
              longPressDragBehavior: Disabled(),
              closeButtonBehavior: VisibleOnHover(), // Interactive via fallback
            ),
          },
        ),
        returnsNormally,
      );
    });
  });
}
