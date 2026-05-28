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
        title: Text(
          setup.name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
            StudioColorSelectionTile(
              label: 'PRIMARY COLOR',
              value: setup.color,
              onChanged: (final v) => context.read<SetupBloc>().add(
                    UpdateChannel(
                      setup.name,
                      setup.copyWith(color: () => v),
                    ),
                  ),
            ),
            const SizedBox(height: 12),
            StudioColorSelectionTile(
              label: 'FOREGROUND COLOR',
              value: setup.foregroundColor,
              onChanged: (final v) => context.read<SetupBloc>().add(
                    UpdateChannel(
                      setup.name,
                      setup.copyWith(foregroundColor: () => v),
                    ),
                  ),
            ),
            const SizedBox(height: 12),
            StudioColorSelectionTile(
              label: 'BACKGROUND COLOR',
              value: setup.backgroundColor,
              onChanged: (final v) => context.read<SetupBloc>().add(
                    UpdateChannel(
                      setup.name,
                      setup.copyWith(backgroundColor: () => v),
                    ),
                  ),
            ),
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
