import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import '../../studio_theme.dart';
import '../../widgets/studio_section_header.dart';

/// A curated set of one-click demo scenarios that showcase different FNQ
/// features in realistic use cases.
///
/// Each scenario fires a specific combination of notifications to demonstrate
/// a distinct feature set. They fire into whatever configuration is currently
/// active in the studio — no configuration change is needed.
class ScenariosSection extends StatelessWidget {
  const ScenariosSection({super.key});

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StudioSectionHeader(title: 'SCENARIOS'),
          const SizedBox(height: 4),
          Text(
            'One-click demos — fires into your current configuration.',
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: StudioTheme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 12),
          ..._scenarios.map(
            (final s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ScenarioTile(scenario: s),
            ),
          ),
        ],
      );
}

class _Scenario {
  const _Scenario({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onFire,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onFire;
}

// Fires with a short stagger to show stacking behaviour
void _stagger(
  final List<NotificationWidget> widgets, [
  final Duration delay = const Duration(milliseconds: 600),
]) {
  for (var i = 0; i < widgets.length; i++) {
    Future.delayed(delay * i, widgets[i].show);
  }
}

final _scenarios = [
  // ── 1. System Health ──
  _Scenario(
    title: 'System Health',
    subtitle: 'Permanent error + timed warning — multi-position demo',
    icon: Icons.monitor_heart_outlined,
    color: const Color(0xFFEF4444),
    onFire: () {
      _stagger([
        NotificationWidget(
          title: 'Service Degraded',
          message: 'Database connection pool exhausted. '
              'Manual intervention required.',
          channelName: 'error',
          dismissDuration: null, // permanent
          action: NotificationAction.button(
            label: 'DIAGNOSE',
            onPressed: () => debugPrint('[Scenario] Diagnose tapped'),
          ),
        ),
        NotificationWidget(
          title: 'High Memory Usage',
          message: 'Instance is at 89% memory. Consider scaling up.',
          channelName: 'warning',
          dismissDuration: const Duration(seconds: 8),
        ),
      ]);
    },
  ),

  // ── 2. Social Activity ──
  _Scenario(
    title: 'Social Activity',
    subtitle: '3 staggered notifications — tests maxStackSize overflow',
    icon: Icons.people_outline,
    color: const Color(0xFF38BDF8),
    onFire: () {
      _stagger(
        [
          NotificationWidget(
            title: 'Alex liked your post',
            message: '"Beautiful sunset photo!"',
            channelName: 'info',
            dismissDuration: const Duration(seconds: 4),
          ),
          NotificationWidget(
            title: 'Mia commented',
            message: '"This is stunning, where was this taken?"',
            channelName: 'info',
            dismissDuration: const Duration(seconds: 4),
            action: NotificationAction.button(
              label: 'REPLY',
              onPressed: () => debugPrint('[Scenario] Reply tapped'),
            ),
          ),
          NotificationWidget(
            title: '5 new followers',
            message: 'Your account is trending in Photography.',
            channelName: 'info',
            dismissDuration: const Duration(seconds: 5),
          ),
        ],
        const Duration(milliseconds: 400),
      );
    },
  ),

  // ── 3. File Sync Complete ──
  _Scenario(
    title: 'File Sync Complete',
    subtitle: 'Success with action button — bottomCenter queue',
    icon: Icons.cloud_done_outlined,
    color: const Color(0xFF22C55E),
    onFire: () {
      NotificationWidget(
        title: 'Sync Complete',
        message: '142 files synced to cloud. 2.3 GB transferred.',
        channelName: 'success',
        dismissDuration: const Duration(seconds: 6),
        action: NotificationAction.button(
          label: 'VIEW FILES',
          onPressed: () => debugPrint('[Scenario] View Files tapped'),
        ),
      ).show();
    },
  ),

  // ── 4. Security Alert ──
  _Scenario(
    title: 'Security Alert',
    subtitle: 'TapToAct — permanent card, tap to review, manual dismiss',
    icon: Icons.security_outlined,
    color: const Color(0xFFF97316),
    onFire: () {
      NotificationWidget(
        title: '\u26a0 Unrecognised Sign-In Attempt',
        message:
            'Login from Lagos, Nigeria \u00b7 Chrome on Windows. '
            'Tap to review.',
        channelName: 'warning',
        dismissDuration: null,
        tapBehavior: TapToAct(
          onTap: () => debugPrint('[Scenario] Security alert tapped'),
          dismissOnAct: false,
        ),
      ).show();
    },
  ),

  // ── 5. Notification Storm ──
  _Scenario(
    title: 'Notification Storm',
    subtitle: '10 rapid notifications — stress tests queue overflow',
    icon: Icons.bolt_outlined,
    color: const Color(0xFFA855F7),
    onFire: () {
      final channels = ['info', 'success', 'warning', 'error'];
      final messages = [
        ('Build #47 passed', 'All 312 tests green in 4.2s.'),
        ('PR Review Ready', 'feature/auth-refresh is ready to merge.'),
        ('Deploy triggered', 'Staging environment updating.'),
        ('Coverage dropped', 'Line coverage fell to 72%. Check new code.'),
        ('Disk alert', '/var/log is at 95% capacity.'),
        ('New comment', 'Jamie left feedback on your PR.'),
        ('Backup complete', 'Daily snapshot stored successfully.'),
        ('Rate limit warning', 'API at 80% of hourly quota.'),
        ('Cache cleared', 'CDN purge completed globally.'),
        ('Cert renewal', 'TLS certificate auto-renewed for 90 days.'),
      ];
      for (var i = 0; i < messages.length; i++) {
        final (title, message) = messages[i];
        Future.delayed(Duration(milliseconds: 250 * i), () {
          NotificationWidget(
            title: title,
            message: message,
            channelName: channels[i % channels.length],
            dismissDuration: Duration(seconds: 4 + (i % 3)),
          ).show();
        });
      }
    },
  ),

  // ── 6. TapBehavior Showcase ──
  _Scenario(
    title: 'Tap Behavior Showcase',
    subtitle:
        'All 4 tap behaviors — dismiss, expand, act, disabled — staggered',
    icon: Icons.touch_app_outlined,
    color: const Color(0xFF14B8A6),
    onFire: () {
      _stagger(
        [
          // 1 — TapToDismiss (explicit, same as default)
          NotificationWidget(
            title: 'Tap \u2192 Dismiss',
            message:
                'TapToDismiss: tap anywhere on this card to close it '
                'immediately.',
            channelName: 'info',
            dismissDuration: null,
            tapBehavior: const TapToDismiss(),
          ),
          // 2 — TapToExpand
          NotificationWidget(
            title: 'Tap \u2192 Expand',
            message:
                'TapToExpand: tap the card surface to toggle the full details '
                'panel. The entire card is now the expand affordance.',
            channelName: 'info',
            dismissDuration: null,
            tapBehavior: const TapToExpand(),
          ),
          // 3 — TapToAct
          NotificationWidget(
            title: 'Tap \u2192 Act',
            message: 'TapToAct: tap fires a callback. '
                'Check the console for the log output.',
            channelName: 'success',
            dismissDuration: null,
            tapBehavior: TapToAct(
              onTap: () => debugPrint('[Showcase] TapToAct callback fired!'),
            ),
          ),
          // 4 — TapDisabled
          NotificationWidget(
            title: 'Tap \u2192 Disabled',
            message: 'TapDisabled: tapping this card does nothing. '
                'Use the close button to dismiss.',
            channelName: 'warning',
            dismissDuration: null,
            tapBehavior: const TapDisabled(),
          ),
        ],
        const Duration(milliseconds: 700),
      );
    },
  ),

  // ── 7. Sticky Alert (Override) ──
  _Scenario(
    title: 'Sticky Alert (Override)',
    subtitle: 'un-swipeable card inside swipeable queue — override demo',
    icon: Icons.pin_drop_outlined,
    color: const Color(0xFFF59E0B),
    onFire: () {
      NotificationWidget(
        title: 'CRITICAL SECURITY UPDATE',
        message: 'This notification has dragBehavior: Disabled override. '
            'It cannot be swiped away, but other notifications in this queue '
            'can!',
        channelName: 'error',
        dismissDuration: null,
        dragBehavior: const Disabled(),
        action: NotificationAction.button(
          label: 'OK',
          onPressed: () {
            debugPrint('[Scenario] Sticky Alert OK tapped');
          },
        ),
      ).show();
    },
  ),
];

class _ScenarioTile extends StatelessWidget {
  const _ScenarioTile({required this.scenario});
  final _Scenario scenario;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = StudioTheme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: scenario.onFire,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: scenario.color.withValues(alpha: 0.2),
            ),
            color: scenario.color.withValues(alpha: 0.06),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: scenario.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  scenario.icon,
                  size: 16,
                  color: scenario.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scenario.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      scenario.subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.play_arrow_rounded,
                size: 18,
                color: scenario.color.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
