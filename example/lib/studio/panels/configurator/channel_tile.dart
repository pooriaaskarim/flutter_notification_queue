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
import '../../widgets/style_archetype_selector.dart';
import '../../widgets/theme_designer_dialog.dart';

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
            StyleArchetypeSelector(
              selectedType: setup.styleType,
              badgeLabel: 'CHANNEL OVERRIDE',
              showInheritDefault: true,
              onChanged: (final v) => context.read<SetupBloc>().add(
                    UpdateChannel(
                      setup.name,
                      setup.copyWith(styleType: () => v),
                    ),
                  ),
            ),
            const SizedBox(height: 12),
            // ── Theme & Archetype Designer ──
            _ChannelThemeConfigTile(setup: setup),
            const SizedBox(height: 12),
            StudioColorSelectionTile(
              label: 'QUICK ACCENT COLOR',
              value: setup.color,
              onChanged: (final v) => context.read<SetupBloc>().add(
                    UpdateChannel(
                      setup.name,
                      setup.copyWith(color: () => v),
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

class _ChannelThemeConfigTile extends StatelessWidget {
  const _ChannelThemeConfigTile({required this.setup});
  final ChannelSetup setup;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = StudioTheme.colorScheme;
    final hasCustomTheme = setup.theme != null;
    final effectiveColor =
        setup.theme?.accentColor ?? setup.color ?? colorScheme.primary;

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
                  color: effectiveColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: effectiveColor.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasCustomTheme
                      ? 'CHROMATICS: CUSTOM PALETTE ACTIVE'
                      : 'CHROMATICS: CHANNEL PALETTE',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.palette_outlined, size: 15),
                  label: Text(
                    hasCustomTheme ? 'EDIT THEME' : 'CUSTOMIZE THEME',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => ThemeDesignerDialog.show(
                    context,
                    title: 'Configure Theme: #${setup.name}',
                    channelName: setup.name,
                    initialTheme:
                        setup.theme ?? setup.toNotificationChannel().theme,
                    initialStyleType: setup.styleType,
                    previewTitle: setup.name.toUpperCase(),
                    previewMessage:
                        setup.description ?? 'Channel notification preview.',
                    previewIcon: setup.iconPreset.toWidget() ??
                        const Icon(Icons.notifications_outlined),
                    onApply: (final newTheme, final newStyleType) {
                      final current = context
                              .read<SetupBloc>()
                              .state
                              .setup
                              .channels[setup.name] ??
                          setup;
                      context.read<SetupBloc>().add(
                            UpdateChannel(
                              setup.name,
                              current.copyWith(
                                theme: () => newTheme,
                                styleType: () => newStyleType,
                                color: () => newTheme?.accentColor,
                                foregroundColor: () =>
                                    newTheme?.foregroundColor,
                                backgroundColor: () =>
                                    newTheme?.backgroundColor,
                              ),
                            ),
                          );
                    },
                  ),
                ),
              ),
              if (hasCustomTheme) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.restart_alt, size: 18),
                  tooltip: 'Reset to default theme',
                  onPressed: () {
                    final current = context
                            .read<SetupBloc>()
                            .state
                            .setup
                            .channels[setup.name] ??
                        setup;
                    context.read<SetupBloc>().add(
                          UpdateChannel(
                            setup.name,
                            current.copyWith(
                              theme: () => null,
                              foregroundColor: () => null,
                              backgroundColor: () => null,
                            ),
                          ),
                        );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
