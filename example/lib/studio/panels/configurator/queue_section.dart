import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import '../../bloc/setup_bloc.dart';
import '../../models/queue_setup.dart';
import '../../studio_theme.dart';
import '../../widgets/studio_dropdown_tile.dart';
import '../../widgets/studio_section_header.dart';
import '../../widgets/studio_slider_tile.dart';
import 'relocation_selector.dart';

/// A section that manages the creation, deletion, and configuration of
/// [NotificationQueue] instances.
///
/// It provides a high-level selector for active queues and handles the "Add
/// Queue" logic, enforcing the rule that only "unused" positions (neither
/// Masters nor Slaves) can be configured.
class QueueSection extends StatelessWidget {
  const QueueSection({
    required this.setupState,
    super.key,
  });

  final SetupState setupState;

  @override
  Widget build(final BuildContext context) {
    final activeQueue =
        setupState.setup.queues[setupState.activeQueuePosition] ??
            const QueueSetup();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const StudioSectionHeader(title: 'QUEUES'),
            const Spacer(),
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                size: 18,
                color: StudioTheme.colorScheme.primary,
              ),
              tooltip: 'Add queue position',
              onPressed: () {
                final allSlaves = setupState.setup.queues.values
                    .expand((final q) => q.relocateTargets)
                    .toSet();
                final availablePositions = QueuePosition.values
                    .where(
                      (final p) =>
                          !setupState.setup.queues.containsKey(p) &&
                          !allSlaves.contains(p),
                    )
                    .toList();
                if (availablePositions.length == 1) {
                  context
                      .read<SetupBloc>()
                      .add(AddQueue(availablePositions.first));
                } else {
                  _showAddQueueDialog(context);
                }
              },
            ),
          ],
        ),
        StudioDropdownTile<QueuePosition>(
          label: 'ACTIVE QUEUE POSITION',
          value: setupState.activeQueuePosition,
          items: setupState.setup.queues.keys.toList(),
          itemLabel: (final e) => e.name.toUpperCase(),
          onChanged: (final v) =>
              context.read<SetupBloc>().add(SelectActiveQueue(v!)),
        ),
        const SizedBox(height: 16),
        _QueueEditor(
          position: setupState.activeQueuePosition,
          setup: activeQueue,
        ),
      ],
    );
  }

  /// Shows a dialog to select a new queue position to configure.
  ///
  /// Only positions that are not currently Masters (already have a queue)
  /// and are not Slaves (relocation targets for other queues) are shown.
  void _showAddQueueDialog(final BuildContext context) {
    final allSlaves = setupState.setup.queues.values
        .expand((final q) => q.relocateTargets)
        .toSet();
    showDialog(
      context: context,
      builder: (final ctx) => AlertDialog(
        title: const Text('Add Queue Position'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: QueuePosition.values
              .where(
                (final p) =>
                    !setupState.setup.queues.containsKey(p) &&
                    !allSlaves.contains(p),
              )
              .map(
                (final p) => ListTile(
                  title: Text(p.name.toUpperCase()),
                  onTap: () {
                    context.read<SetupBloc>().add(AddQueue(p));
                    Navigator.pop(ctx);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

/// A specialized editor for a single [QueueSetup].
class _QueueEditor extends StatelessWidget {
  const _QueueEditor({
    required this.position,
    required this.setup,
  });

  final QueuePosition position;
  final QueueSetup setup;

  static const _styleTypes = [
    FilledQueueStyle,
    FlatQueueStyle,
    OutlinedQueueStyle,
  ];
  static const _behaviorTypes = [Disabled, Dismiss, Reorder, Relocate];
  static const _closeButtonTypes = [AlwaysVisible, VisibleOnHover, Hidden];
  static const _transitionTypes = [
    SlideTransitionStrategy,
    FadeTransitionStrategy,
    ScaleTransitionStrategy,
  ];

  String _formatType(final Type t) => t
      .toString()
      .replaceAll('QueueStyle', '')
      .replaceAll('TransitionStrategy', '')
      .toUpperCase();

  @override
  Widget build(final BuildContext context) {
    final colorScheme = StudioTheme.colorScheme;
    final otherQueuesSlaves = context
        .watch<SetupBloc>()
        .state
        .setup
        .queues
        .entries
        .where((final entry) => entry.key != position)
        .expand((final entry) => entry.value.relocateTargets)
        .toSet();
    final activePositions =
        context.watch<SetupBloc>().state.setup.queues.keys.toSet();

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (setup.dragBehaviorType == setup.longPressBehaviorType &&
                setup.dragBehaviorType != Disabled) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Both gestures are set to '
                        '${_formatType(setup.dragBehaviorType)}. '
                        'You might want to use different behaviors for better '
                        'interaction.',
                        style: TextStyle(
                          color: colorScheme.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Icon(
                  Icons.settings_input_component,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${position.name.toUpperCase()} CONFIGURATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (position != QueuePosition.topCenter)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    onPressed: () =>
                        context.read<SetupBloc>().add(RemoveQueue(position)),
                    tooltip: 'Remove queue',
                  ),
              ],
            ),
            const Divider(height: 24),
            StudioSliderTile(
              label: 'MAX VISIBLE NOTIFICATIONS',
              value: setup.maxStackSize.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (final v) => context.read<SetupBloc>().add(
                    UpdateQueue(
                      position,
                      setup.copyWith(maxStackSize: v.round()),
                    ),
                  ),
            ),
            const SizedBox(height: 12),
            StudioDropdownTile<Type>(
              label: 'VISUAL STYLE',
              value: setup.styleType,
              items: _styleTypes,
              itemLabel: _formatType,
              onChanged: (final v) => context.read<SetupBloc>().add(
                    UpdateQueue(
                      position,
                      setup.copyWith(styleType: v),
                    ),
                  ),
            ),
            const SizedBox(height: 12),
            StudioDropdownTile<Type>(
              label: 'TRANSITION STRATEGY',
              value: setup.transitionType,
              items: _transitionTypes,
              itemLabel: _formatType,
              onChanged: (final v) => context.read<SetupBloc>().add(
                    UpdateQueue(
                      position,
                      setup.copyWith(transitionType: v),
                    ),
                  ),
            ),
            const SizedBox(height: 16),
            const StudioSectionHeader(title: 'BEHAVIOR'),
            StudioDropdownTile<Type>(
              label: 'DRAG BEHAVIOR',
              value: setup.dragBehaviorType,
              items: _behaviorTypes.where((final e) {
                if (e == Relocate) {
                  return activePositions.length < QueuePosition.values.length ||
                      setup.dragBehaviorType == Relocate;
                }
                return true;
              }).toList(),
              itemLabel: (final e) => e.toString().toUpperCase(),
              onChanged: (final v) => context.read<SetupBloc>().add(
                    UpdateQueue(
                      position,
                      setup.copyWith(dragBehaviorType: v),
                    ),
                  ),
            ),
            if (setup.dragBehaviorType == Relocate) ...[
              const SizedBox(height: 12),
              RelocationSelector(
                selected: setup.relocateTargets,
                activePositions: activePositions,
                otherQueuesSlaves: otherQueuesSlaves,
                onChanged: (final v) => context.read<SetupBloc>().add(
                      UpdateQueue(
                        position,
                        setup.copyWith(relocateTargets: v),
                      ),
                    ),
              ),
            ],
            const SizedBox(height: 12),
            StudioDropdownTile<Type>(
              label: 'LONG PRESS DRAG BEHAVIOR',
              value: setup.longPressBehaviorType,
              items: _behaviorTypes.where((final e) {
                if (e == Relocate) {
                  return activePositions.length < QueuePosition.values.length ||
                      setup.longPressBehaviorType == Relocate;
                }
                return true;
              }).toList(),
              itemLabel: (final e) => e.toString().toUpperCase(),
              onChanged: (final v) => context.read<SetupBloc>().add(
                    UpdateQueue(
                      position,
                      setup.copyWith(longPressBehaviorType: v),
                    ),
                  ),
            ),
            if (setup.longPressBehaviorType == Relocate) ...[
              const SizedBox(height: 12),
              RelocationSelector(
                selected: setup.relocateTargets,
                activePositions: activePositions,
                otherQueuesSlaves: otherQueuesSlaves,
                onChanged: (final v) => context.read<SetupBloc>().add(
                      UpdateQueue(
                        position,
                        setup.copyWith(relocateTargets: v),
                      ),
                    ),
              ),
            ],
            const SizedBox(height: 12),
            StudioDropdownTile<Type>(
              label: 'CLOSE BUTTON VISIBILITY',
              value: setup.closeButtonBehaviorType,
              items: _closeButtonTypes,
              itemLabel: (final e) => e.toString().toUpperCase(),
              onChanged: (final v) => context.read<SetupBloc>().add(
                    UpdateQueue(
                      position,
                      setup.copyWith(closeButtonBehaviorType: v),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
