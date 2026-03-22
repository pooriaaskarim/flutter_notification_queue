import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import '../bloc/studio_bloc.dart';
import '../bloc/studio_event.dart';
import '../bloc/studio_state.dart';

/// The left-side configurator panel exposing all NFQ parameters.
class ConfiguratorPanel extends StatelessWidget {
  const ConfiguratorPanel({super.key});

  @override
  Widget build(final BuildContext context) =>
      BlocBuilder<StudioBloc, StudioState>(
        builder: (final context, final state) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionHeader(context, 'LAYOUT'),
            _dropdownTile<QueuePosition>(
              context,
              label: 'Anchor Position',
              value: state.queuePosition,
              items: QueuePosition.values,
              itemLabel: (final e) => e.displayName,
              onChanged: (final v) =>
                  context.read<StudioBloc>().add(UpdateQueuePosition(v!)),
            ),
            const SizedBox(height: 12),
            _dropdownTile<StyleType>(
              context,
              label: 'Visual Style',
              value: state.styleType,
              items: StyleType.values,
              itemLabel: (final e) => e.name.toUpperCase(),
              onChanged: (final v) =>
                  context.read<StudioBloc>().add(UpdateStyleType(v!)),
            ),
            const SizedBox(height: 8),
            _sliderTile(
              context,
              label: 'Opacity',
              value: state.styleOpacity,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              onChanged: (final v) =>
                  context.read<StudioBloc>().add(UpdateStyleOpacity(v)),
            ),
            _sliderTile(
              context,
              label: 'Elevation',
              value: state.styleElevation,
              min: 0,
              max: 16,
              divisions: 16,
              onChanged: (final v) =>
                  context.read<StudioBloc>().add(UpdateStyleElevation(v)),
            ),
            _sliderTile(
              context,
              label: 'Border Radius',
              value: state.styleBorderRadius,
              min: 0,
              max: 24,
              divisions: 24,
              onChanged: (final v) =>
                  context.read<StudioBloc>().add(UpdateStyleBorderRadius(v)),
            ),
            const SizedBox(height: 12),
            _dropdownTile<TransitionType>(
              context,
              label: 'Animation Strategy',
              value: state.transitionType,
              items: TransitionType.values,
              itemLabel: (final e) => e.name.toUpperCase(),
              onChanged: (final v) =>
                  context.read<StudioBloc>().add(UpdateTransitionType(v!)),
            ),
            const SizedBox(height: 8),
            _sliderTile(
              context,
              label: 'Max Stack Size',
              value: state.maxStackSize.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (final v) =>
                  context.read<StudioBloc>().add(UpdateMaxStackSize(v.round())),
            ),
            _sliderTile(
              context,
              label: 'Spacing',
              value: state.spacing,
              min: 0,
              max: 16,
              divisions: 16,
              onChanged: (final v) =>
                  context.read<StudioBloc>().add(UpdateSpacing(v)),
            ),
            const Divider(height: 32),

            // ── Behaviors ──
            _sectionHeader(context, 'INTERACTION BEHAVIORS'),
            _dropdownTile<BehaviorType>(
              context,
              label: 'Drag Behavior',
              value: state.dragBehavior,
              items: BehaviorType.values,
              itemLabel: (final e) => e.name.toUpperCase(),
              onChanged: (final v) =>
                  context.read<StudioBloc>().add(UpdateDragBehavior(v!)),
            ),
            const SizedBox(height: 12),
            _dropdownTile<BehaviorType>(
              context,
              label: 'Long-Press Behavior',
              value: state.longPressBehavior,
              items: BehaviorType.values,
              itemLabel: (final e) => e.name.toUpperCase(),
              onChanged: (final v) =>
                  context.read<StudioBloc>().add(UpdateLongPressBehavior(v!)),
            ),
            if (state.dragBehavior == BehaviorType.relocate ||
                state.longPressBehavior == BehaviorType.relocate) ...[
              const SizedBox(height: 12),
              _sectionHeader(context, 'RELOCATE TARGETS'),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: QueuePosition.values
                    .map(
                      (final pos) => FilterChip(
                        label: Text(
                          pos.displayName,
                          style: const TextStyle(fontSize: 11),
                        ),
                        selected: state.relocatePositions.contains(pos),
                        onSelected: (final _) => context
                            .read<StudioBloc>()
                            .add(ToggleRelocatePosition(pos)),
                        selectedColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3),
                        checkmarkColor: Theme.of(context).colorScheme.primary,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.05),
                        side: BorderSide(
                          color: state.relocatePositions.contains(pos)
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.1),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            _dropdownTile<CloseButtonType>(
              context,
              label: 'Close Button',
              value: state.closeButton,
              items: CloseButtonType.values,
              itemLabel: (final e) => switch (e) {
                CloseButtonType.alwaysVisible => 'ALWAYS VISIBLE',
                CloseButtonType.visibleOnHover => 'VISIBLE ON HOVER',
                CloseButtonType.hidden => 'HIDDEN',
              },
              onChanged: (final v) =>
                  context.read<StudioBloc>().add(UpdateCloseButton(v!)),
            ),
            const Divider(height: 32),

            // ── Notification ──
            _sectionHeader(context, 'NOTIFICATION CONTENT'),
            _dropdownTile<String>(
              context,
              label: 'Channel',
              value: state.channelName,
              items: const [
                'default',
                'info',
                'success',
                'warning',
                'error',
              ],
              itemLabel: (final e) => e.toUpperCase(),
              onChanged: (final v) =>
                  context.read<StudioBloc>().add(UpdateChannelName(v!)),
            ),
            const SizedBox(height: 12),
            _textField(
              context,
              label: 'Title',
              initial: state.notificationTitle,
              onChanged: (final v) =>
                  context.read<StudioBloc>().add(UpdateNotificationTitle(v)),
            ),
            const SizedBox(height: 12),
            _textField(
              context,
              label: 'Message',
              initial: state.notificationMessage,
              maxLines: 2,
              onChanged: (final v) =>
                  context.read<StudioBloc>().add(UpdateNotificationMessage(v)),
            ),
            const SizedBox(height: 12),
            _sliderTile(
              context,
              label: 'Dismiss Duration (seconds)',
              value: (state.dismissDuration ?? 0).toDouble(),
              min: 0,
              max: 30,
              divisions: 30,
              onChanged: (final v) => context.read<StudioBloc>().add(
                    UpdateDismissDuration(v.round() == 0 ? null : v.round()),
                  ),
            ),
            const Divider(height: 32),

            // ── Action ──
            _sectionHeader(context, 'ACTION'),
            _dropdownTile<ActionType>(
              context,
              label: 'Action Type',
              value: state.actionType,
              items: ActionType.values,
              itemLabel: (final e) => e.name.toUpperCase(),
              onChanged: (final v) =>
                  context.read<StudioBloc>().add(UpdateActionType(v!)),
            ),
            if (state.actionType == ActionType.button) ...[
              const SizedBox(height: 12),
              _textField(
                context,
                label: 'Button Label',
                initial: state.actionLabel,
                onChanged: (final v) =>
                    context.read<StudioBloc>().add(UpdateActionLabel(v)),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      );

  Widget _sectionHeader(final BuildContext context, final String title) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 3,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ),
        ),
      );

  Widget _dropdownTile<T>(
    final BuildContext context, {
    required final String label,
    required final T value,
    required final List<T> items,
    required final String Function(T) itemLabel,
    required final ValueChanged<T?> onChanged,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.1),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                dropdownColor: Theme.of(context).colorScheme.surface,
                items: items
                    .map(
                      (final item) => DropdownMenuItem(
                        value: item,
                        child: Text(itemLabel(item)),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      );

  Widget _sliderTile(
    final BuildContext context, {
    required final String label,
    required final double value,
    required final double min,
    required final double max,
    required final int divisions,
    required final ValueChanged<double> onChanged,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              Text(
                value == value.roundToDouble()
                    ? value.round().toString()
                    : value.toStringAsFixed(1),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Theme.of(context).colorScheme.primary,
              inactiveTrackColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.1),
              thumbColor: Theme.of(context).colorScheme.primary,
              overlayColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      );

  Widget _textField(
    final BuildContext context, {
    required final String label,
    required final String initial,
    required final ValueChanged<String> onChanged,
    final int maxLines = 1,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: initial,
            maxLines: maxLines,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            onChanged: onChanged,
          ),
        ],
      );
}
