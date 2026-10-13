import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import '../bloc/notification_bloc.dart';
import '../bloc/setup_bloc.dart';
import '../studio_theme.dart';

/// A persistent, tactile quick-action toolbar that allows developers to
/// fire the current draft, quick presets, bursts, or clear the stage
/// from anywhere in NFQ Studio without scrolling.
class QuickFireCockpit extends StatelessWidget {
  const QuickFireCockpit({super.key});

  @override
  Widget build(final BuildContext context) {
    final colorScheme = StudioTheme.colorScheme;
    final isDark = StudioTheme.isDark;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.92)
            : colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        children: [
          // ── Primary Action: Fire Draft ──
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.bolt_rounded, size: 16),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'FIRE DRAFT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '⌘↵',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () =>
                context.read<NotificationBloc>().add(const FirePreview()),
          ),
          const SizedBox(width: 10),

          VerticalDivider(
            width: 1,
            indent: 4,
            endIndent: 4,
            color: colorScheme.onSurface.withValues(alpha: 0.12),
          ),
          const SizedBox(width: 10),

          // ── Quick Presets ──
          _CockpitChip(
            label: 'Info',
            icon: Icons.info_outline,
            accentColor: const Color(0xFF51B4F9),
            onTap: () => _fireQuickPreset(
              context,
              channelName: 'info',
              title: 'System Information',
              message: 'Background synchronization completed cleanly.',
            ),
          ),
          const SizedBox(width: 6),
          _CockpitChip(
            label: 'Success',
            icon: Icons.check_circle_outline,
            accentColor: const Color(0xFF2D7512),
            onTap: () => _fireQuickPreset(
              context,
              channelName: 'success',
              title: 'Payment Confirmed',
              message: 'Invoice #1084 settled for \$140.00.',
            ),
          ),
          const SizedBox(width: 6),
          _CockpitChip(
            label: 'Warning',
            icon: Icons.warning_amber_rounded,
            accentColor: const Color(0xFFC97725),
            onTap: () => _fireQuickPreset(
              context,
              channelName: 'warning',
              title: 'Storage Warning',
              message: 'Disk volume reached 92% capacity.',
            ),
          ),
          const SizedBox(width: 6),
          _CockpitChip(
            label: 'Critical',
            icon: Icons.error_outline,
            accentColor: const Color(0xFFD03332),
            onTap: () => _fireQuickPreset(
              context,
              channelName: 'error',
              priority: NotificationPriority.high,
              title: 'Database Outage',
              message: 'Connection pool exhausted on replica 2.',
            ),
          ),
          const SizedBox(width: 6),
          _CockpitChip(
            label: 'Pinned',
            icon: Icons.push_pin_outlined,
            accentColor: const Color(0xFF8B5CF6),
            onTap: () => _fireQuickPreset(
              context,
              channelName: 'info',
              permanent: true,
              title: 'Update In Progress',
              message: 'Applying firmware update 2.4.0. Stays until dismissed.',
            ),
          ),
          const SizedBox(width: 10),

          VerticalDivider(
            width: 1,
            indent: 4,
            endIndent: 4,
            color: colorScheme.onSurface.withValues(alpha: 0.12),
          ),
          const SizedBox(width: 10),

          // ── Stacking & Stress Test ──
          _CockpitChip(
            label: 'Burst 3x',
            icon: Icons.auto_awesome_motion_rounded,
            accentColor: const Color(0xFFEC4899),
            onTap: () => _fireBurst(context),
          ),
          const SizedBox(width: 6),

          // ── Stage Utility: Clear All ──
          IconButton(
            icon: const Icon(Icons.clear_all_rounded, size: 18),
            tooltip: 'Dismiss all active notifications',
            style: IconButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
            ),
            onPressed: () {
              context.read<SetupBloc>().controller.dismissAll();
            },
          ),
        ],
      ),
    );
  }

  static void _fireQuickPreset(
    final BuildContext context, {
    required final String channelName,
    required final String title,
    required final String message,
    final NotificationPriority? priority,
    final bool permanent = false,
  }) {
    final setupBloc = context.read<SetupBloc>();
    final channelSetup = setupBloc.state.setup.channels[channelName];
    final targetPosition =
        channelSetup?.position ?? setupBloc.state.activeQueuePosition;

    setupBloc.controller.show(
      AppNotification(
        title: title,
        message: message,
        channelName: channelName,
        priority: priority,
        permanent: permanent,
        dismissDuration: permanent ? null : const Duration(seconds: 5),
      ),
      targetPosition: targetPosition,
    );
  }

  static void _fireBurst(final BuildContext context) {
    final setupBloc = context.read<SetupBloc>();
    final targetPosition = setupBloc.state.activeQueuePosition;

    final samples = [
      ('Synchronizing cache...', 'info'),
      ('Validated integrity hashes', 'success'),
      ('Live reload triggered', 'warning'),
    ];

    for (var i = 0; i < samples.length; i++) {
      final sample = samples[i];
      Timer(Duration(milliseconds: i * 160), () {
        setupBloc.controller.show(
          AppNotification(
            title: 'Burst alert #${i + 1}',
            message: sample.$1,
            channelName: sample.$2,
            dismissDuration: const Duration(seconds: 6),
          ),
          targetPosition: targetPosition,
        );
      });
    }
  }
}

class _CockpitChip extends StatelessWidget {
  const _CockpitChip({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = StudioTheme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: accentColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
