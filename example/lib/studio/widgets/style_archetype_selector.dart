import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import '../studio_theme.dart';

/// A modular selector for configuring the physical style archetype (Gear 1).
///
/// Controls structure, border geometry, and visual weight:
/// - [FilledQueueStyle]: Solid container, 8px superellipse radius.
/// - [OutlinedQueueStyle]: 1px accent outline, 8px superellipse radius.
/// - [FlatQueueStyle]: 4px accent indicator stripe, 0px borderless.
class StyleArchetypeSelector extends StatelessWidget {
  const StyleArchetypeSelector({
    required this.selectedType,
    required this.onChanged,
    this.label = 'STYLE ARCHETYPE',
    this.badgeLabel,
    this.showInheritDefault = true,
    super.key,
  });

  /// Currently selected [QueueStyle] type (`null` indicates inherited default).
  final Type? selectedType;

  /// Callback when a style archetype is chosen.
  final ValueChanged<Type?> onChanged;

  /// Title label displayed above the selector.
  final String label;

  /// Optional contextual badge (e.g., 'QUEUE', 'CHANNEL', 'NOTIFICATION').
  final String? badgeLabel;

  /// Whether to include the "INHERIT" option.
  final bool showInheritDefault;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = StudioTheme.colorScheme;

    final options = <(Type?, String, IconData)>[
      if (showInheritDefault)
        (null, 'INHERIT', Icons.subdirectory_arrow_right_rounded),
      (FilledQueueStyle, 'FILLED', Icons.rectangle_rounded),
      (OutlinedQueueStyle, 'OUTLINED', Icons.crop_square_rounded),
      (FlatQueueStyle, 'FLAT', Icons.view_headline_rounded),
    ];

    final anatomyDescription = switch (selectedType) {
      == FilledQueueStyle =>
        'Solid surface fill • 8px superellipse radius • 3.0 elevation',
      == OutlinedQueueStyle =>
        '1px accent outline stroke • 8px superellipse radius • surface fill',
      == FlatQueueStyle =>
        '4px accent indicator stripe on start edge • 0px flat borderless',
      _ => 'Inheriting physical geometry and anatomy from upstream cascade',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.architecture_rounded,
              size: 14,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            if (badgeLabel != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeLabel!,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: options.map((final opt) {
            final isSelected = selectedType == opt.$1;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  onTap: () => onChanged(opt.$1),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.15)
                          : colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.1),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          opt.$3,
                          size: 16,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          opt.$2,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            letterSpacing: 0.5,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.info_outline_rounded,
                size: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                anatomyDescription,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
