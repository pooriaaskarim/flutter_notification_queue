import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/setup_bloc.dart';
import '../../models/channel_setup.dart';
import '../../studio_theme.dart';
import '../../widgets/studio_section_header.dart';
import 'channel_tile.dart';

class ChannelSection extends StatelessWidget {
  const ChannelSection({
    required this.setupState,
    super.key,
  });

  final SetupState setupState;

  @override
  Widget build(final BuildContext context) {
    final channels = setupState.setup.channels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const StudioSectionHeader(title: 'CHANNELS'),
            const Spacer(),
            IconButton(
              icon: Icon(
                Icons.auto_fix_high_outlined,
                size: 18,
                color: StudioTheme.colorScheme.primary,
              ),
              tooltip: 'Add standard presets',
              onPressed: () =>
                  context.read<SetupBloc>().add(const AddStandardPresets()),
            ),
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                size: 18,
                color: StudioTheme.colorScheme.primary,
              ),
              tooltip: 'Add channel',
              onPressed: () => _showAddChannelDialog(context),
            ),
          ],
        ),
        if (channels.isEmpty)
          const _EmptyChannelFeedback()
        else
          ...channels.entries.map(
            (final e) => ChannelTile(
              setup: e.value,
              positions: setupState.setup.queues.keys.toList(),
            ),
          ),
      ],
    );
  }

  void _showAddChannelDialog(final BuildContext context) {
    String name = '';
    ChannelIconPreset icon = ChannelIconPreset.info;
    Color color = const Color(0xFF51B4F9);

    showDialog(
      context: context,
      builder: (final ctx) => StatefulBuilder(
        builder: (final context, final setState) => AlertDialog(
          title: const Text('Add New Channel'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Channel Name'),
                onChanged: (final v) => name = v,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ChannelIconPreset>(
                initialValue: icon,
                decoration: const InputDecoration(labelText: 'Icon Preset'),
                items: ChannelIconPreset.values
                    .map(
                      (final e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (final v) => setState(() => icon = v!),
              ),
              const SizedBox(height: 16),
              const Text('Initial Color'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  const Color(0xFF51B4F9),
                  const Color(0xFF2D7512),
                  const Color(0xFFC97725),
                  const Color(0xFFD03332),
                ].map((final c) {
                  final isSelected = c == color;
                  return GestureDetector(
                    onTap: () => setState(() => color = c),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (name.isNotEmpty) {
                  context.read<SetupBloc>().add(
                        AddChannel(
                          ChannelSetup(
                            name: name,
                            iconPreset: icon,
                            color: color,
                          ),
                        ),
                      );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChannelFeedback extends StatelessWidget {
  const _EmptyChannelFeedback();

  @override
  Widget build(final BuildContext context) {
    final colorScheme = StudioTheme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 32,
              color: colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 8),
            Text(
              'No custom channels configured',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'NFQ will use the fallback system default.',
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
