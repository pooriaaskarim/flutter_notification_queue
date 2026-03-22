import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

/// A specialized selector for managing relocation target positions.
///
/// This widget enforces the library's requirement for disjoint relocation
/// groups by filtering out:
/// 1.  **Masters**: Positions that are already configured as a Master queue.
/// 2.  **Other Slaves**: Positions already claimed as relocation targets by
///     different queues.
///
/// It provides a validation banner if no targets are selected.
class RelocationSelector extends StatelessWidget {
  const RelocationSelector({
    required this.selected,
    required this.onChanged,
    required this.activePositions,
    required this.otherQueuesSlaves,
    super.key,
  });

  /// The set of queue positions that are currently selected for relocation
  /// by the active queue being edited.
  final Set<QueuePosition> selected;

  /// Callback invoked when the relocation target set is modified.
  final ValueChanged<Set<QueuePosition>> onChanged;

  /// The set of queue positions that currently host a Master queue.
  /// A Master position cannot be a relocation target for any queue.
  final Set<QueuePosition> activePositions;

  /// The set of queue positions that are already relocation targets (Slaves)
  /// for *other* queues in the system.
  final Set<QueuePosition> otherQueuesSlaves;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final availablePool = QueuePosition.values
        .where(
          (final p) =>
              !activePositions.contains(p) && !otherQueuesSlaves.contains(p),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected.isEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No targets selected. Relocation will be disabled.',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        const Text(
          'TARGET POSITIONS',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        if (availablePool.isEmpty && selected.isEmpty)
          const Text(
            'No available positions found in the 3x3 grid.',
            style: TextStyle(color: Colors.white24, fontSize: 11),
          )
        else
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: QueuePosition.values.map((final p) {
              final isMaster = activePositions.contains(p);
              final isOtherSlave = otherQueuesSlaves.contains(p);
              final isSelected = selected.contains(p);

              // We only show it if it's available or already selected
              if (isMaster || (isOtherSlave && !isSelected)) {
                return const SizedBox.shrink();
              }

              return FilterChip(
                label: Text(
                  p.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    color: isSelected ? Colors.white : Colors.white38,
                  ),
                ),
                selected: isSelected,
                onSelected: (final v) {
                  final newSelected = Set<QueuePosition>.from(selected);
                  if (v) {
                    newSelected.add(p);
                  } else {
                    newSelected.remove(p);
                  }
                  onChanged(newSelected);
                },
              );
            }).toList(),
          ),
      ],
    );
  }
}
