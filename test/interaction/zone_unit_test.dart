// Tests for the DropZone hierarchy.
//
// These are pure-math tests: no widgets, no Flutter framework, just coordinate
// logic. They validate the contract of isHit() and calculateProgress() before
// any behavior wiring is changed.
//
// Screen: 800 × 600. Threshold: 50.0 px.
// Alignments from QueuePosition:
//   topLeft     → Alignment(-1,-1) → anchor (0,   0  )
//   topCenter   → Alignment( 0,-1) → anchor (400, 0  )
//   topRight    → Alignment( 1,-1) → anchor (800, 0  )
//   centerLeft  → Alignment(-1, 0) → anchor (0,   300)
//   centerRight → Alignment( 1, 0) → anchor (800, 300)
//   bottomLeft  → Alignment(-1, 1) → anchor (0,   600)
//   bottomCenter→ Alignment( 0, 1) → anchor (400, 600)
//   bottomRight → Alignment( 1, 1) → anchor (800, 600)

import 'package:flutter/painting.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_notification_queue/src/notification/notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const screen = Size(800, 600);
  const threshold = 50.0;

  // ─── PositionDropZone ──────────────────────────────────────────────────────

  group('PositionDropZone', () {
    group('non-natural (isNatural = false)', () {
      const zone = PositionDropZone(position: QueuePosition.topLeft);
      // anchor = (0, 0)

      test('isHit: pointer exactly at anchor → true', () {
        expect(zone.isHit(Offset.zero, screen, threshold), isTrue);
      });

      test('isHit: pointer 14 px from anchor → true', () {
        // distance ≈ 14.1 px < 50
        expect(zone.isHit(const Offset(10, 10), screen, threshold), isTrue);
      });

      test('isHit: pointer exactly at threshold boundary → false', () {
        // distance = 50, progress = 0, 0 > 0.01 is false
        expect(zone.isHit(const Offset(50, 0), screen, threshold), isFalse);
      });

      test('isHit: pointer well beyond threshold → false', () {
        expect(zone.isHit(const Offset(100, 100), screen, threshold), isFalse);
      });

      test('calculateProgress: 1.0 at anchor', () {
        final p = zone.calculateProgress(Offset.zero, screen, 1.0 / threshold);
        expect(p, equals(1.0));
      });

      test('calculateProgress: 0.0 at threshold boundary', () {
        final p = zone.calculateProgress(
            const Offset(50, 0), screen, 1.0 / threshold);
        expect(p, equals(0.0));
      });

      test('calculateProgress: 0.0 beyond threshold (clamped)', () {
        final p = zone.calculateProgress(
            const Offset(100, 0), screen, 1.0 / threshold);
        expect(p, equals(0.0));
      });

      test('calculateProgress: intermediate value', () {
        // distance = 25, progress = 1 - 25/50 = 0.5
        final p = zone.calculateProgress(
            const Offset(25, 0), screen, 1.0 / threshold);
        expect(p, closeTo(0.5, 0.001));
      });
    });

    group('natural (isNatural = true, requires progress ≥ 0.7)', () {
      const zone =
          PositionDropZone(position: QueuePosition.topLeft, isNatural: true);
      // anchor = (0, 0), threshold = 50
      // 0.7 progress ↔ distance ≤ 15 px  (1 - d/50 ≥ 0.7 → d ≤ 15)

      test('isHit: 14 px from anchor → true (progress ≈ 0.72)', () {
        expect(zone.isHit(const Offset(14, 0), screen, threshold), isTrue);
      });

      test('isHit: exactly 15 px → true (progress = 0.7)', () {
        expect(zone.isHit(const Offset(15, 0), screen, threshold), isTrue);
      });

      test('isHit: 16 px → false (progress ≈ 0.68 < 0.7)', () {
        expect(zone.isHit(const Offset(16, 0), screen, threshold), isFalse);
      });
    });

    test('anchor for topRight is at (800, 0)', () {
      const zone = PositionDropZone(position: QueuePosition.topRight);
      expect(zone.isHit(const Offset(800, 0), screen, threshold), isTrue);
      expect(zone.isHit(const Offset(800, 60), screen, threshold), isFalse);
    });

    test('anchor for bottomCenter is at (400, 600)', () {
      const zone = PositionDropZone(position: QueuePosition.bottomCenter);
      expect(zone.isHit(const Offset(400, 600), screen, threshold), isTrue);
      expect(zone.isHit(const Offset(400, 540), screen, threshold), isFalse);
    });

    test('anchor for centerLeft is at (0, 300)', () {
      const zone = PositionDropZone(position: QueuePosition.centerLeft);
      expect(zone.isHit(const Offset(0, 300), screen, threshold), isTrue);
      expect(zone.isHit(const Offset(60, 300), screen, threshold), isFalse);
    });
  });

  // ─── EdgeDropZone subclasses ───────────────────────────────────────────────

  group('LeftEdgeDropZone', () {
    const zone = LeftEdgeDropZone();
    // progress = (1 - dx / threshold).clamp(0,1)  when dx < screenWidth/2

    test('isHit: dx=25 → true (progress=0.5)', () {
      expect(zone.isHit(const Offset(25, 300), screen, threshold), isTrue);
    });

    test('isHit: dx=0 → true (progress=1.0)', () {
      expect(zone.isHit(const Offset(0, 300), screen, threshold), isTrue);
    });

    test('isHit: dx=50 → false (progress=0, 0 > 0.01 is false)', () {
      expect(zone.isHit(const Offset(50, 300), screen, threshold), isFalse);
    });

    test('isHit: dx=500 → false (right half blocked by axis guard)', () {
      expect(zone.isHit(const Offset(500, 300), screen, threshold), isFalse);
    });

    test('natural: dx=14 → true (progress≈0.72)', () {
      const natural = LeftEdgeDropZone(isNatural: true);
      expect(natural.isHit(const Offset(14, 300), screen, threshold), isTrue);
    });

    test('natural: dx=16 → false (progress≈0.68)', () {
      const natural = LeftEdgeDropZone(isNatural: true);
      expect(natural.isHit(const Offset(16, 300), screen, threshold), isFalse);
    });

    test('calculateProgress at dx=0 → 1.0', () {
      final p =
          zone.calculateProgress(const Offset(0, 300), screen, 1.0 / threshold);
      expect(p, equals(1.0));
    });

    test('calculateProgress at dx=25 → 0.5', () {
      final p = zone.calculateProgress(
          const Offset(25, 300), screen, 1.0 / threshold);
      expect(p, closeTo(0.5, 0.001));
    });
  });

  group('RightEdgeDropZone', () {
    const zone = RightEdgeDropZone();
    // progress = (1 - (screenWidth - dx) / threshold).clamp(0,1)
    // screenWidth = 800

    test('isHit: dx=775 → true (screenWidth-dx=25, progress=0.5)', () {
      expect(zone.isHit(const Offset(775, 300), screen, threshold), isTrue);
    });

    test('isHit: dx=800 → true (at edge)', () {
      expect(zone.isHit(const Offset(800, 300), screen, threshold), isTrue);
    });

    test('isHit: dx=750 → false (screenWidth-dx=50, progress=0)', () {
      expect(zone.isHit(const Offset(750, 300), screen, threshold), isFalse);
    });

    test('isHit: dx=300 → false (left half blocked)', () {
      expect(zone.isHit(const Offset(300, 300), screen, threshold), isFalse);
    });
  });

  group('TopEdgeDropZone', () {
    const zone = TopEdgeDropZone();
    // progress = (1 - dy / threshold).clamp(0,1)  when dy < screenHeight/2

    test('isHit: dy=25 → true', () {
      expect(zone.isHit(const Offset(400, 25), screen, threshold), isTrue);
    });

    test('isHit: dy=0 → true', () {
      expect(zone.isHit(const Offset(400, 0), screen, threshold), isTrue);
    });

    test('isHit: dy=50 → false (progress=0)', () {
      expect(zone.isHit(const Offset(400, 50), screen, threshold), isFalse);
    });

    test('isHit: dy=400 → false (bottom half blocked)', () {
      expect(zone.isHit(const Offset(400, 400), screen, threshold), isFalse);
    });
  });

  group('BottomEdgeDropZone', () {
    const zone = BottomEdgeDropZone();
    // progress = (1 - (screenHeight - dy) / threshold).clamp(0,1)
    // screenHeight = 600

    test('isHit: dy=575 → true (screenHeight-dy=25, progress=0.5)', () {
      expect(zone.isHit(const Offset(400, 575), screen, threshold), isTrue);
    });

    test('isHit: dy=600 → true (at edge)', () {
      expect(zone.isHit(const Offset(400, 600), screen, threshold), isTrue);
    });

    test('isHit: dy=550 → false (screenHeight-dy=50, progress=0)', () {
      expect(zone.isHit(const Offset(400, 550), screen, threshold), isFalse);
    });

    test('isHit: dy=200 → false (top half blocked)', () {
      expect(zone.isHit(const Offset(400, 200), screen, threshold), isFalse);
    });
  });

  // ─── SlotDropZone ──────────────────────────────────────────────────────────

  group('SlotDropZone', () {
    test('isHit: returns false when anchor is not set', () {
      final zone = SlotDropZone(targetIndex: 0);
      expect(zone.isHit(const Offset(400, 300), screen, threshold), isFalse);
    });

    test('anchor: null before setTargetBounds', () {
      final zone = SlotDropZone(targetIndex: 0);
      expect(zone.anchor, isNull);
    });

    test('anchor: center of bounds after setTargetBounds', () {
      final zone = SlotDropZone(targetIndex: 0);
      // bounds: left=375, top=100, width=50, height=80 → center=(400,140)
      zone.setTargetBounds(const Rect.fromLTWH(375, 100, 50, 80));
      expect(zone.anchor, equals(const Offset(400, 140)));
    });

    test('isHit: true when pointer at anchor', () {
      final zone = SlotDropZone(targetIndex: 0);
      zone.setTargetBounds(const Rect.fromLTWH(375, 100, 50, 80));
      // center = (400, 140)
      expect(zone.isHit(const Offset(400, 140), screen, threshold), isTrue);
    });

    test('isHit: true within threshold', () {
      final zone = SlotDropZone(targetIndex: 1);
      zone.setTargetBounds(const Rect.fromLTWH(375, 100, 50, 80));
      // center = (400, 140), pointer at (420, 140) → distance=20 < 50
      expect(zone.isHit(const Offset(420, 140), screen, threshold), isTrue);
    });

    test('isHit: false beyond threshold', () {
      final zone = SlotDropZone(targetIndex: 1);
      zone.setTargetBounds(const Rect.fromLTWH(375, 100, 50, 80));
      // center = (400, 140), pointer at (460, 140) → distance=60 > 50
      expect(zone.isHit(const Offset(460, 140), screen, threshold), isFalse);
    });

    test('calculateProgress: 1.0 at anchor', () {
      final zone = SlotDropZone(targetIndex: 0);
      zone.setTargetBounds(const Rect.fromLTWH(375, 100, 50, 80));
      final p = zone.calculateProgress(const Offset(400, 140), 1.0 / threshold);
      expect(p, equals(1.0));
    });

    test('calculateProgress: 0.0 when anchor not set', () {
      final zone = SlotDropZone(targetIndex: 0);
      final p = zone.calculateProgress(const Offset(400, 300), 1.0 / threshold);
      expect(p, equals(0.0));
    });

    test('calculateProgress: 0.5 at half-threshold distance', () {
      final zone = SlotDropZone(targetIndex: 0);
      zone.setTargetBounds(const Rect.fromLTWH(375, 100, 50, 80));
      // center=(400,140), pointer=(425,140) → distance=25 → progress=0.5
      final p = zone.calculateProgress(const Offset(425, 140), 1.0 / threshold);
      expect(p, closeTo(0.5, 0.001));
    });

    test('isNatural=true: requires 0.7 progress (distance ≤ 15)', () {
      final zone = SlotDropZone(targetIndex: 0, isNatural: true);
      zone.setTargetBounds(const Rect.fromLTWH(375, 100, 50, 80));
      // center=(400,140), 15px away: (415,140) → distance=15 → progress=0.7
      expect(zone.isHit(const Offset(415, 140), screen, threshold), isTrue);
      // 16px: (416,140) → progress≈0.68 → false
      expect(zone.isHit(const Offset(416, 140), screen, threshold), isFalse);
    });
  });
}
