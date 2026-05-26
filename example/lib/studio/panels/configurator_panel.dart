import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/notification_bloc.dart';
import '../bloc/setup_bloc.dart';
import 'configurator/channel_section.dart';
import 'configurator/preview_section.dart';
import 'configurator/queue_section.dart';
import 'configurator/scenarios_section.dart';

/// The left-side configurator panel with four collapsible sections:
/// 1. **Queues** — add/remove/edit queue setups per position (with position map)
/// 2. **Channels** — manage notification channels
/// 3. **Preview** — compose and fire test notifications
/// 4. **Scenarios** — one-click realistic demo flows
class ConfiguratorPanel extends StatelessWidget {
  const ConfiguratorPanel({super.key});

  @override
  Widget build(final BuildContext context) =>
      BlocBuilder<SetupBloc, SetupState>(
        builder: (final context, final setupState) =>
            BlocBuilder<NotificationBloc, NotificationDraft>(
          builder: (final context, final draft) => ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // ── Section 1: Queues ──
              _StudioExpansionSection(
                title: 'QUEUES',
                icon: Icons.view_quilt_outlined,
                initiallyExpanded: true,
                child: QueueSection(setupState: setupState),
              ),

              // ── Section 2: Channels ──
              _StudioExpansionSection(
                title: 'CHANNELS',
                icon: Icons.tune_outlined,
                initiallyExpanded: true,
                child: ChannelSection(setupState: setupState),
              ),

              // ── Section 3: Preview ──
              _StudioExpansionSection(
                title: 'PREVIEW',
                icon: Icons.send_outlined,
                initiallyExpanded: true,
                child: PreviewSection(
                  setupState: setupState,
                  draft: draft,
                ),
              ),

              // ── Section 4: Scenarios ──
              const _StudioExpansionSection(
                title: 'SCENARIOS',
                icon: Icons.bolt_outlined,
                initiallyExpanded: false,
                child: ScenariosSection(),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      );
}

/// A premium collapsible section used throughout the configurator panel.
///
/// Uses [ExpansionTile] with custom styling to provide expand/collapse
/// affordance with a consistent studio aesthetic.
class _StudioExpansionSection extends StatelessWidget {
  const _StudioExpansionSection({
    required this.title,
    required this.icon,
    required this.child,
    this.initiallyExpanded = true,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Theme(
      // Override the divider that ExpansionTile normally inserts
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        leading: Icon(icon, size: 16, color: colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        iconColor: colorScheme.primary,
        collapsedIconColor: colorScheme.onSurface.withValues(alpha: 0.4),
        children: [child],
      ),
    );
  }
}
