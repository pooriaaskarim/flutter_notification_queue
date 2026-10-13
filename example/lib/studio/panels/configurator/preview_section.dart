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
import '../../widgets/studio_toggle_tile.dart';

class PreviewSection extends StatelessWidget {
  const PreviewSection({
    required this.setupState,
    required this.draft,
    super.key,
  });

  final SetupState setupState;
  final NotificationDraft draft;

  static const _dragOverrideTypes = [
    null,
    Dismiss,
    Snooze,
    Pin,
    Disabled,
  ];

  String _formatDragOverride(final Type? t) => switch (t) {
        null => 'CHANNEL DEFAULT',
        == Dismiss => 'DISMISS (SWIPE AWAY)',
        == Snooze => 'SNOOZE (DRAG TO SNOOZE)',
        == Pin => 'PIN (LOCK TO QUEUE)',
        == Disabled => 'DISABLED (STICKY CARD)',
        _ => t.toString().toUpperCase(),
      };

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
          onChanged: (final v) =>
              context.read<NotificationBloc>().add(SelectPreviewPosition(v)),
        ),
        const SizedBox(height: 12),

        // ── Priority ──
        StudioDropdownTile<NotificationPriority?>(
          label: 'PRIORITY TRIAGE',
          value: draft.priority,
          items: const [null, ...NotificationPriority.values],
          itemLabel: (final e) =>
              e == null ? 'CHANNEL DEFAULT' : e.name.toUpperCase(),
          onChanged: (final v) =>
              context.read<NotificationBloc>().add(UpdatePriority(v)),
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

        // ── Drag Gesture Override ──
        StudioDropdownTile<Type?>(
          label: 'DRAG BEHAVIOR OVERRIDE',
          value: draft.dragBehaviorOverrideType,
          items: _dragOverrideTypes,
          itemLabel: _formatDragOverride,
          onChanged: (final v) => context
              .read<NotificationBloc>()
              .add(UpdateDragBehaviorOverride(v)),
        ),
        if (draft.dragBehaviorOverrideType == Snooze) ...[
          const SizedBox(height: 12),
          StudioSliderTile(
            label: 'SNOOZE DURATION: ${draft.snoozeDurationSeconds}s',
            value: draft.snoozeDurationSeconds.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            onChanged: (final v) => context
                .read<NotificationBloc>()
                .add(UpdateSnoozeDurationSeconds(v.round())),
          ),
        ],
        const SizedBox(height: 12),

        // ── Initial Pin State ──
        StudioToggleTile(
          label: 'PIN INITIALLY (PREVENTS SWIPE & TIMEOUT)',
          value: draft.initialIsPinned,
          onChanged: (final v) => context.read<NotificationBloc>().add(
                UpdateInitialIsPinned(isPinned: v),
              ),
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
  AppNotification? _activeDemo;
  bool _isPinned = false;

  void _fireDemo() {
    final id = 'demo_${DateTime.now().millisecondsSinceEpoch}';
    final channelName = widget.setupState.setup.channels.keys.first;
    final n = AppNotification(
      id: id,
      title: 'Programmatic Demo',
      message: 'Keep an eye on me! I can be snoozed, pinned, or relocated.',
      channelName: channelName,
      dismissDuration: const Duration(seconds: 20),
    );
    NotificationScope.of(context).show(n);
    setState(() {
      _activeDemo = n;
      _isPinned = false;
    });
  }

  void _dismissDemo() {
    if (_activeDemo != null) {
      NotificationScope.of(context).dismiss(_activeDemo!);
      setState(() {
        _activeDemo = null;
        _isPinned = false;
      });
    }
  }

  void _snoozeDemo() {
    if (_activeDemo != null) {
      NotificationScope.of(context).snooze(
        _activeDemo!,
        const Duration(seconds: 5),
      );
    }
  }

  void _togglePinDemo() {
    if (_activeDemo == null) {
      return;
    }
    final scope = NotificationScope.of(context);
    if (_isPinned) {
      scope.unpin(_activeDemo!);
      setState(() => _isPinned = false);
    } else {
      scope.pin(_activeDemo!);
      setState(() => _isPinned = true);
    }
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
    final currentPos = _activeDemo!.position ?? queues.first;
    final targetPos = queues.firstWhere(
      (final q) => q != currentPos,
      orElse: () => queues.last,
    );

    NotificationScope.of(context).relocate(_activeDemo!, targetPos);
    setState(() {
      _activeDemo = _activeDemo!.copyWith(position: targetPos);
    });
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: StudioTheme.colorScheme.error,
                ),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('DISMISS'),
                onPressed: _dismissDemo,
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFB7185), // rose/snooze color
                ),
                icon: const Icon(Icons.snooze_rounded, size: 16),
                label: const Text('SNOOZE 5s'),
                onPressed: _snoozeDemo,
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF59E0B), // amber
                ),
                icon: Icon(
                  _isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  size: 16,
                ),
                label: Text(_isPinned ? 'UNPIN' : 'PIN'),
                onPressed: _togglePinDemo,
              ),
              if (canRelocate)
                OutlinedButton.icon(
                  icon: const Icon(Icons.multiple_stop, size: 16),
                  label: const Text('RELOCATE'),
                  onPressed: _relocateDemo,
                ),
            ],
          ),
      ],
    );
  }
}
