import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import '../../bloc/setup_bloc.dart';
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
  final void Function(BuildContext context) onFire;
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
    onFire: (final _) {
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
    onFire: (final _) {
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
    onFire: (final _) {
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
    onFire: (final _) {
      NotificationWidget(
        title: '\u26a0 Unrecognised Sign-In Attempt',
        message: 'Login from Lagos, Nigeria \u00b7 Chrome on Windows. '
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
    onFire: (final _) {
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
    onFire: (final _) {
      _stagger(
        [
          // 1 — TapToDismiss (explicit, same as default)
          NotificationWidget(
            title: 'Tap \u2192 Dismiss',
            message: 'TapToDismiss: tap anywhere on this card to close it '
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
    onFire: (final _) {
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

  // ── 8. Priority Triage Storm ──
  _Scenario(
    title: 'Priority Triage Storm',
    subtitle: 'Showcases priority-aware auto-sorting & preemption eviction',
    icon: Icons.sort_rounded,
    color: const Color(0xFFF43F5E),
    onFire: (final _) {
      // 1. Enqueue 2 low priority notifications staggered
      _stagger(
        [
          NotificationWidget(
            title: 'Low Priority: Disk Cleanup',
            message: 'Background disk cleanup started.',
            channelName: 'info',
            priority: NotificationPriority.low,
            dismissDuration: const Duration(seconds: 10),
          ),
          NotificationWidget(
            title: 'Low Priority: Syncing Logs',
            message: 'Diagnostic log sync in progress.',
            channelName: 'info',
            priority: NotificationPriority.low,
            dismissDuration: const Duration(seconds: 10),
          ),
        ],
        const Duration(milliseconds: 350),
      );

      // 2. Enqueue Normal priority notification that will auto-sort and push
      // to the front of pending queue
      Future.delayed(const Duration(milliseconds: 1000), () {
        NotificationWidget(
          title: 'Normal Priority: Package Update',
          message: 'System package updates available.',
          channelName: 'warning',
          priority: NotificationPriority.normal,
          dismissDuration: const Duration(seconds: 6),
        ).show();
      });

      // 3. Enqueue a Critical notification that will immediately evict the
      // lowest priority active notification
      Future.delayed(const Duration(milliseconds: 2000), () {
        NotificationWidget(
          title: 'CRITICAL: Database Offline!',
          message: 'Primary database connection lost! '
              'Evicting low priority tasks.',
          channelName: 'error',
          priority: NotificationPriority.critical,
          dismissDuration: const Duration(seconds: 6),
        ).show();
      });
    },
  ),

  // ── 9. Queue Collision Storm ──
  _Scenario(
    title: 'Queue Collision Storm',
    subtitle: 'Fires to topLeft, topCenter, & topRight. Stacks them '
        'vertically to avoid overlap on narrow screens.',
    icon: Icons.grid_view_rounded,
    color: const Color(0xFF6366F1),
    onFire: (final context) {
      final setupBloc = context.read<SetupBloc>();
      // Activate the three queues if not already configured
      if (!setupBloc.state.setup.queues.containsKey(QueuePosition.topLeft)) {
        setupBloc.add(const AddQueue(QueuePosition.topLeft));
      }
      if (!setupBloc.state.setup.queues.containsKey(QueuePosition.topCenter)) {
        setupBloc.add(const AddQueue(QueuePosition.topCenter));
      }
      if (!setupBloc.state.setup.queues.containsKey(QueuePosition.topRight)) {
        setupBloc.add(const AddQueue(QueuePosition.topRight));
      }

      _stagger(
        [
          NotificationWidget(
            title: 'Top Left Queue',
            message: 'Fired into topLeft queue.',
            channelName: 'info',
            position: QueuePosition.topLeft,
            dismissDuration: const Duration(seconds: 12),
          ),
          NotificationWidget(
            title: 'Top Center Queue',
            message: 'Fired into topCenter queue.',
            channelName: 'warning',
            position: QueuePosition.topCenter,
            dismissDuration: const Duration(seconds: 12),
          ),
          NotificationWidget(
            title: 'Top Right Queue',
            message: 'Fired into topRight queue.',
            channelName: 'error',
            position: QueuePosition.topRight,
            dismissDuration: const Duration(seconds: 12),
          ),
        ],
        const Duration(milliseconds: 200),
      );
    },
  ),

  // ── 10. Chat Burst (Single-Card Dismiss) ──
  _Scenario(
    title: 'Chat Burst (Grouping)',
    subtitle: '4 messages collapse into a bundle. Swipe the top card — '
        'only that one exits. The next hidden message surfaces automatically.',
    icon: Icons.mark_chat_unread_outlined,
    color: const Color(0xFF0EA5E9),
    onFire: (final _) {
      _stagger(
        [
          NotificationWidget(
            title: 'Alice',
            message: 'Hey, are you free this afternoon?',
            channelName: 'chat',
            dismissDuration: const Duration(seconds: 30),
          ),
          NotificationWidget(
            title: 'Alice',
            message: 'I have some updates on the design sprint.',
            channelName: 'chat',
            dismissDuration: const Duration(seconds: 30),
          ),
          NotificationWidget(
            title: 'Alice',
            message: 'The stakeholders moved the review to Friday!',
            channelName: 'chat',
            dismissDuration: const Duration(seconds: 30),
          ),
          NotificationWidget(
            title: 'Alice',
            message: 'Let me know if you need the deck beforehand.',
            channelName: 'chat',
            dismissDuration: const Duration(seconds: 30),
          ),
        ],
        const Duration(milliseconds: 500),
      );
    },
  ),

  // ── 11. Group Dismiss ──
  _Scenario(
    title: 'Group Dismiss',
    subtitle: 'Fires a chat burst, then calls dismissGroup() after 3 s '
        'to clear the entire bundle at once via the explicit API.',
    icon: Icons.layers_clear_outlined,
    color: const Color(0xFF06B6D4),
    onFire: (final context) {
      // Fire the same chat burst as scenario #10.
      const groupKey = 'chat';
      _stagger(
        [
          NotificationWidget(
            title: 'Bob',
            message: 'Build pipeline started.',
            channelName: groupKey,
            dismissDuration: const Duration(seconds: 60),
          ),
          NotificationWidget(
            title: 'Bob',
            message: 'Unit tests: all 312 passed.',
            channelName: groupKey,
            dismissDuration: const Duration(seconds: 60),
          ),
          NotificationWidget(
            title: 'Bob',
            message: 'Integration tests: passed.',
            channelName: groupKey,
            dismissDuration: const Duration(seconds: 60),
          ),
          NotificationWidget(
            title: 'Bob',
            message: '🚀 Deploy to staging complete.',
            channelName: groupKey,
            dismissDuration: const Duration(seconds: 60),
          ),
        ],
        const Duration(milliseconds: 400),
      );
      // Snapshot position *before* the async gap to avoid BuildContext
      // across async gaps lint.
      final position =
          context.read<SetupBloc>().state.setup.queues.keys.firstOrNull ??
          QueuePosition.topRight;
      // After the burst has settled, dismiss the whole bundle at once.
      Future.delayed(const Duration(seconds: 3), () {
        FlutterNotificationQueue.coordinator.dismissGroup(
          position,
          groupKey,
        );
      });
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
        onTap: () => scenario.onFire(context),
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
