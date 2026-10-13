import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import '../../bloc/setup_bloc.dart';
import '../../models/channel_setup.dart';
import '../../studio_theme.dart';
import '../../widgets/studio_color_selection_tile.dart';
import '../../widgets/studio_dropdown_tile.dart';
import '../../widgets/studio_slider_tile.dart';
import '../../widgets/studio_text_field.dart';
import '../../widgets/studio_toggle_tile.dart';

class ChannelTile extends StatelessWidget {
  const ChannelTile({
    required this.setup,
    required this.positions,
    super.key,
  });

  final ChannelSetup setup;
  final List<QueuePosition> positions;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = StudioTheme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: (setup.color ?? colorScheme.primary).withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: ExpansionTile(
        leading: Icon(
          setup.iconPreset.iconData ?? Icons.notifications_none,
          size: 18,
          color: setup.color ?? colorScheme.onSurface,
        ),
        title: Row(
          children: [
            Text(
              setup.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: colorScheme.onSurface.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 9,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    setup.position?.name.toUpperCase() ?? 'DEFAULT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline,
            size: 16,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          onPressed: () =>
              context.read<SetupBloc>().add(RemoveChannel(setup.name)),
          tooltip: 'Remove channel',
        ),
        children: [
          _TileContent(setup: setup, positions: positions),
        ],
      ),
    );
  }
}

class _TileContent extends StatelessWidget {
  const _TileContent({
    required this.setup,
    required this.positions,
  });

  final ChannelSetup setup;
  final List<QueuePosition> positions;

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            StudioTextField(
              label: 'DESCRIPTION',
              initial: setup.description ?? '',
              onChanged: (final v) => context.read<SetupBloc>().add(
                    UpdateChannel(
                      setup.name,
                      setup.copyWith(description: () => v),
                    ),
                  ),
            ),
            const SizedBox(height: 12),
            StudioDropdownTile<ChannelIconPreset>(
              label: 'ICON PRESET',
              value: setup.iconPreset,
              items: ChannelIconPreset.values,
              itemLabel: (final e) => e.name.toUpperCase(),
              onChanged: (final v) => context.read<SetupBloc>().add(
                    UpdateChannel(
                      setup.name,
                      setup.copyWith(iconPreset: v),
                    ),
                  ),
            ),
            const SizedBox(height: 12),
            // ── Inline Channel Chromatics ──
            _ChannelThemeConfigTile(setup: setup),
            const SizedBox(height: 12),
            StudioDropdownTile<QueuePosition?>(
              label: 'TARGET POSITION',
              value: setup.position,
              items: const [null, ...QueuePosition.values],
              itemLabel: (final e) => e?.name.toUpperCase() ?? 'SYSTEM DEFAULT',
              onChanged: (final v) => context.read<SetupBloc>().add(
                    UpdateChannel(
                      setup.name,
                      setup.copyWith(position: () => v),
                    ),
                  ),
            ),
            const SizedBox(height: 12),
            StudioSliderTile(
              label: 'DISMISS DELAY (SECONDS)',
              value: (setup.dismissSeconds ?? 0).toDouble(),
              min: 0,
              max: 30,
              divisions: 30,
              onChanged: (final v) => context.read<SetupBloc>().add(
                    UpdateChannel(
                      setup.name,
                      setup.copyWith(
                        dismissSeconds: () => v == 0 ? null : v.round(),
                      ),
                    ),
                  ),
            ),
            const SizedBox(height: 8),
            StudioToggleTile(
              label: 'ENABLED',
              value: setup.enabled,
              onChanged: (final v) => context.read<SetupBloc>().add(
                    UpdateChannel(
                      setup.name,
                      setup.copyWith(enabled: v),
                    ),
                  ),
            ),
          ],
        ),
      );
}

class _ChannelThemeConfigTile extends StatelessWidget {
  const _ChannelThemeConfigTile({required this.setup});
  final ChannelSetup setup;

  static const _semanticPresets = <(String, Color?)>[
    ('DEFAULT', null),
    ('SUCCESS', Color(0xFF2D7512)),
    ('ERROR', Color(0xFFD03332)),
    ('WARNING', Color(0xFFC97725)),
    ('INFO', Color(0xFF51B4F9)),
  ];

  void _applyColor(final BuildContext context, final Color? color) {
    final current =
        context.read<SetupBloc>().state.setup.channels[setup.name] ?? setup;
    context.read<SetupBloc>().add(
          UpdateChannel(
            setup.name,
            current.copyWith(
              theme: () =>
                  color != null ? NotificationThemeData(color: color) : null,
              color: () => color,
              foregroundColor: () => null,
              backgroundColor: () => null,
            ),
          ),
        );
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = StudioTheme.colorScheme;
    final effectiveColor = setup.theme?.color ?? setup.color;
    final hasCustomTheme = effectiveColor != null;

    final hexCode = effectiveColor != null
        ? '#${effectiveColor.toARGB32().toRadixString(16).substring(2)}'
            .toUpperCase()
        : 'INHERITED';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: effectiveColor ?? colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (effectiveColor ?? colorScheme.primary)
                          .withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasCustomTheme
                      ? 'CHROMATICS ($hexCode)'
                      : 'CHROMATICS (INHERITED DEFAULT)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (hasCustomTheme)
                IconButton(
                  icon: const Icon(Icons.restart_alt, size: 16),
                  tooltip: 'Reset to default theme',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _applyColor(context, null),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _semanticPresets.map((final preset) {
              final label = preset.$1;
              final color = preset.$2;
              final isSelected = color == null
                  ? effectiveColor == null
                  : effectiveColor?.toARGB32() == color.toARGB32();

              return InkWell(
                onTap: () => _applyColor(context, color),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (color ?? colorScheme.primary).withValues(alpha: 0.18)
                        : colorScheme.onSurface.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? (color ?? colorScheme.primary)
                          : colorScheme.onSurface.withValues(alpha: 0.1),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (color != null) ...[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          letterSpacing: 0.4,
                          color: isSelected
                              ? (color ?? colorScheme.primary)
                              : colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          StudioColorSelectionTile(
            label: 'PALETTE SWATCHES',
            value: effectiveColor,
            onChanged: (final v) => _applyColor(context, v),
          ),
        ],
      ),
    );
  }
}
