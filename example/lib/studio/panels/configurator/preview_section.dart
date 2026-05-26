import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import '../../bloc/notification_bloc.dart';
import '../../bloc/setup_bloc.dart';
import '../../studio_theme.dart';
import '../../widgets/studio_dropdown_tile.dart';
import '../../widgets/studio_section_header.dart';
import '../../widgets/studio_slider_tile.dart';
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
    final colorScheme = StudioTheme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StudioSectionHeader(title: 'PREVIEW'),
        const SizedBox(height: 8),

        // ── Channel Selector ──
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
                  color: colorScheme.primary.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Channel "${draft.channelName}" not configured. '
                    'NFQ will use the system default fallback.',
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),

        // ── Position Override ──
        StudioDropdownTile<QueuePosition?>(
          label: 'POSITION OVERRIDE',
          value: draft.positionOverride,
          items: const [null, ...QueuePosition.values],
          itemLabel: (final e) =>
              e == null ? 'CHANNEL DEFAULT' : e.name.toUpperCase(),
          onChanged: (final v) => context
              .read<NotificationBloc>()
              .add(SelectPreviewPosition(v)),
        ),
        const SizedBox(height: 12),

        // ── Content ──
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
        const SizedBox(height: 12),

        // ── Action ──
        StudioDropdownTile<NotificationActionStyle>(
          label: 'ACTION TYPE',
          value: draft.actionStyle,
          items: NotificationActionStyle.values,
          itemLabel: (final e) => e.name.toUpperCase(),
          onChanged: (final v) => context
              .read<NotificationBloc>()
              .add(UpdateNotificationActionStyle(v!)),
        ),
        if (draft.actionStyle == NotificationActionStyle.button) ...[
          const SizedBox(height: 12),
          StudioTextField(
            label: 'BUTTON LABEL',
            initial: draft.actionLabel,
            onChanged: (final v) =>
                context.read<NotificationBloc>().add(UpdateActionLabel(v)),
          ),
        ],
        if (draft.actionStyle == NotificationActionStyle.onTap)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  size: 14,
                  color: colorScheme.primary.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tapping anywhere on the notification fires the action.',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),

        // ── Auto-Dismiss ──
        StudioSliderTile(
          label: draft.dismissSeconds == null
              ? 'AUTO-DISMISS: PERMANENT'
              : 'AUTO-DISMISS: ${draft.dismissSeconds}s',
          value: (draft.dismissSeconds ?? 0).toDouble(),
          min: 0,
          max: 30,
          divisions: 30,
          onChanged: (final v) => context.read<NotificationBloc>().add(
                UpdateDismissDuration(v == 0 ? null : v.round()),
              ),
        ),
        if (draft.dismissSeconds == null)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 13,
                  color: colorScheme.secondary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  'Permanent — user must dismiss manually. '
                  'Requires a dismiss gesture or close button.',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),

        // ── Fire Button ──
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
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
        const SizedBox(height: 24),
        
        // ── Programmatic Control ──
        _ProgrammaticControls(setupState: setupState),
      ],
    );
  }
}

class _ProgrammaticControls extends StatefulWidget {
  const _ProgrammaticControls({required this.setupState});

  final SetupState setupState;

  @override
  State<_ProgrammaticControls> createState() => _ProgrammaticControlsState();
}

class _ProgrammaticControlsState extends State<_ProgrammaticControls> {
  NotificationWidget? _activeDemo;

  void _fireDemo() {
    final id = 'demo_${DateTime.now().millisecondsSinceEpoch}';
    final n = NotificationWidget(
      id: id,
      title: 'Programmatic Demo',
      message: 'Keep an eye on me! I can be controlled programmatically.',
      channelName: widget.setupState.setup.channels.keys.first,
      dismissDuration: const Duration(seconds: 15),
    )..show();
    setState(() {
      _activeDemo = n;
    });
  }

  void _dismissDemo() {
    _activeDemo?.dismiss();
    setState(() {
      _activeDemo = null;
    });
  }

  void _relocateDemo() {
    if (_activeDemo == null) {
      return;
    }
    
    final queues = widget.setupState.setup.queues.keys.toList();
    if (queues.length < 2) {
      return;
    }
    
    // Find a queue that is different from current
    final currentPos = _activeDemo!.queue.position;
    final targetPos = queues.firstWhere(
      (final q) => q != currentPos,
      orElse: () => queues.last,
    );
    
    final updatedDemo = _activeDemo!.relocateTo(targetPos);
    if (updatedDemo != null) {
      setState(() {
        _activeDemo = updatedDemo;
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    final queues = widget.setupState.setup.queues.keys.toList();
    final canRelocate = queues.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StudioSectionHeader(title: 'PROGRAMMATIC CONTROL'),
        const SizedBox(height: 12),
        if (_activeDemo == null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.code),
              label: const Text('FIRE PROGRAMMATIC DEMO'),
              onPressed: _fireDemo,
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: StudioTheme.colorScheme.error,
                  ),
                  icon: const Icon(Icons.close),
                  label: const Text('DISMISS'),
                  onPressed: _dismissDemo,
                ),
              ),
              if (canRelocate) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.multiple_stop),
                    label: const Text('RELOCATE'),
                    onPressed: _relocateDemo,
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}
