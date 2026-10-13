import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import '../../bloc/notification_bloc.dart';
import '../../bloc/setup_bloc.dart';
import '../../studio_theme.dart';
import '../../widgets/resolution_inspector.dart';
import '../../widgets/studio_dropdown_tile.dart';
import '../../widgets/studio_section_header.dart';
import '../../widgets/studio_slider_tile.dart';
import '../../widgets/studio_text_field.dart';
import '../../widgets/studio_toggle_tile.dart';
import '../../widgets/style_archetype_selector.dart';
import '../../widgets/theme_designer_dialog.dart';

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

        // ── Cascade Resolution Inspector (Gears) ──
        ResolutionInspector(
          setupState: setupState,
          draft: draft,
        ),
        const SizedBox(height: 12),

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

        // ── Dispatch Target Position ──
        StudioDropdownTile<QueuePosition?>(
          label: 'DISPATCH TARGET POSITION (targetPosition)',
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
        // ── Gear 1: Notification Style Archetype Override ──
        StyleArchetypeSelector(
          label: 'ALERT STYLE ARCHETYPE',
          badgeLabel: 'ALERT OVERRIDE',
          selectedType: draft.styleOverride,
          showInheritDefault: true,
          onChanged: (final v) =>
              context.read<NotificationBloc>().add(UpdateStyleOverride(v)),
        ),
        const SizedBox(height: 12),

        // ── Gear 2: Notification Theme Override ──
        _NotificationThemeOverrideTile(
          draft: draft,
          setupState: setupState,
        ),
        const SizedBox(height: 12),
        StudioToggleTile(
          label: 'PERMANENT (STAYS UNTIL DISMISSED)',
          value: draft.permanent,
          onChanged: (final v) => context.read<NotificationBloc>().add(
                UpdatePermanent(permanent: v),
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

class _NotificationThemeOverrideTile extends StatelessWidget {
  const _NotificationThemeOverrideTile({
    required this.draft,
    required this.setupState,
  });

  final NotificationDraft draft;
  final SetupState setupState;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = StudioTheme.colorScheme;
    final hasOverride = draft.themeOverride != null;
    final channelSetup = setupState.setup.channels[draft.channelName];
    final baseTheme =
        channelSetup?.theme ?? channelSetup?.toNotificationChannel().theme;
    final effectiveAccent = draft.themeOverride?.accentColor ??
        baseTheme?.accentColor ??
        colorScheme.primary;

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
                  color: effectiveAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: effectiveAccent.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasOverride
                      ? 'CHROMATICS: CUSTOM PALETTE ACTIVE'
                      : 'CHROMATICS: INHERITED FROM #${draft.channelName}',
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
                    hasOverride ? 'EDIT PALETTE' : 'CUSTOMIZE PALETTE',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => ThemeDesignerDialog.show(
                    context,
                    title: 'Notification Theme Override',
                    channelName: draft.channelName,
                    initialTheme: draft.themeOverride ?? baseTheme,
                    initialStyleType:
                        draft.styleOverride ?? channelSetup?.styleType,
                    previewTitle: draft.title.isNotEmpty
                        ? draft.title
                        : 'Preview Notification',
                    previewMessage: draft.message.isNotEmpty
                        ? draft.message
                        : 'Custom styled notification card preview.',
                    isNotificationOverride: true,
                    onApplyTheme: (final newTheme) {
                      context
                          .read<NotificationBloc>()
                          .add(UpdateThemeOverride(newTheme));
                    },
                  ),
                ),
              ),
              if (hasOverride) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.restart_alt, size: 18),
                  tooltip: 'Reset to channel theme',
                  onPressed: () => context
                      .read<NotificationBloc>()
                      .add(const UpdateThemeOverride(null)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
