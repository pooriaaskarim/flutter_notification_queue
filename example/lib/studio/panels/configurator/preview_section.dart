import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/notification_bloc.dart';
import '../../bloc/setup_bloc.dart';
import '../../studio_theme.dart';
import '../../widgets/studio_dropdown_tile.dart';
import '../../widgets/studio_section_header.dart';
import '../../widgets/studio_text_field.dart';

class PreviewSection extends StatelessWidget {
  const PreviewSection({
    required this.setupState,
    required this.draft,
    super.key,
  });

  final SetupState setupState;
  final NotificationDraft draft;

  @override
  Widget build(final BuildContext context) {
    final channelNames = setupState.setup.channels.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StudioSectionHeader(title: 'PREVIEW'),
        const SizedBox(height: 8),
        if (channelNames.isNotEmpty)
          StudioDropdownTile<String>(
            label: 'SELECT CHANNEL',
            value: channelNames.contains(draft.channelName)
                ? draft.channelName
                : channelNames.first,
            items: channelNames,
            itemLabel: (final e) => e.toUpperCase(),
            onChanged: (final v) =>
                context.read<NotificationBloc>().add(SelectPreviewChannel(v!)),
          ),
        if (!channelNames.contains(draft.channelName))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  Icons.help_outline,
                  size: 14,
                  color: StudioTheme.colorScheme.primary.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Channel "${draft.channelName}" not configured. '
                    'NFQ will use the system default fallback.',
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: StudioTheme.colorScheme.onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        StudioTextField(
          label: 'NOTIFICATION TITLE',
          initial: draft.title,
          onChanged: (final v) =>
              context.read<NotificationBloc>().add(UpdateTitle(v)),
        ),
        const SizedBox(height: 12),
        StudioTextField(
          label: 'MESSAGE BODY',
          initial: draft.message,
          maxLines: 3,
          onChanged: (final v) =>
              context.read<NotificationBloc>().add(UpdateMessage(v)),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: StudioTheme.colorScheme.primaryContainer,
              foregroundColor: StudioTheme.colorScheme.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text(
              'FIRE NOTIFICATION',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            onPressed: () =>
                context.read<NotificationBloc>().add(const FirePreview()),
          ),
        ),
      ],
    );
  }
}
