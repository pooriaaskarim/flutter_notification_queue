import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/setup_bloc.dart';
import '../../widgets/studio_section_header.dart';

class SystemOptionsSection extends StatelessWidget {
  const SystemOptionsSection({
    required this.setupState,
    super.key,
  });

  final SetupState setupState;

  @override
  Widget build(final BuildContext context) {
    final setup = setupState.setup;
    final enableDynamicParking = setup.enableDynamicChannelParking;
    final maxHistory = setup.maxHistoryEntries;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StudioSectionHeader(title: 'SYSTEM OPTIONS'),
        const SizedBox(height: 12),

        // Dynamic Channel Parking switch
        SwitchListTile(
          title: const Text(
            'Dynamic Parking',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Re-route channels dynamically when dragged to a new position.',
            style: TextStyle(
              fontSize: 9,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          value: enableDynamicParking,
          onChanged: (final value) {
            context.read<SetupBloc>().add(
                  UpdateGlobalConfig(enableDynamicChannelParking: value),
                );
          },
          contentPadding: EdgeInsets.zero,
          activeTrackColor: colorScheme.primary,
        ),

        const SizedBox(height: 8),

        // Bounded History Log limit
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Max History Entries',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Limit of historical events to keep in the memory log '
                        '(0 to disable).',
                        style: TextStyle(
                          fontSize: 9,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  maxHistory == 0 ? 'Disabled' : '$maxHistory',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: maxHistory == 0
                        ? colorScheme.onSurface.withValues(alpha: 0.4)
                        : colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: maxHistory.toDouble(),
              min: 0,
              max: 50,
              divisions: 10,
              label: maxHistory == 0 ? 'Disabled' : '$maxHistory',
              onChanged: (final val) {
                context.read<SetupBloc>().add(
                      UpdateGlobalConfig(maxHistoryEntries: val.toInt()),
                    );
              },
            ),
          ],
        ),
      ],
    );
  }
}
