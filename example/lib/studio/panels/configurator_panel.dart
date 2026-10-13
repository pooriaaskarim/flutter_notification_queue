import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/notification_bloc.dart';
import '../bloc/setup_bloc.dart';
import 'configurator/channel_section.dart';
import 'configurator/preview_section.dart';
import 'configurator/queue_section.dart';
import 'configurator/scenarios_section.dart';
import 'configurator/system_options_section.dart';

/// The left-side configurator panel with four collapsible sections:
/// 1. **Queues** — add/remove/edit queue setups per position (with position map)
/// 2. **Channels** — manage notification channels
/// 3. **Preview** — compose and fire test notifications
/// 4. **Scenarios** — one-click realistic demo flows
/// The sub-tabs available in mobile mode for the configurator.
enum ConfigSubTab {
  queues('Queues', Icons.view_quilt_outlined),
  channels('Channels', Icons.tune_outlined),
  preview('Draft', Icons.send_outlined),
  scenarios('Scenarios', Icons.bolt_outlined),
  options('Options', Icons.settings_outlined);

  const ConfigSubTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// The configurator panel.
///
/// On **desktop**, displays collapsible sections simultaneously.
/// On **mobile**, renders a segmented sub-bar for instant, scroll-free access.
class ConfiguratorPanel extends StatefulWidget {
  const ConfiguratorPanel({super.key});

  @override
  State<ConfiguratorPanel> createState() => _ConfiguratorPanelState();
}

class _ConfiguratorPanelState extends State<ConfiguratorPanel> {
  ConfigSubTab _selectedSubTab = ConfigSubTab.queues;

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
        builder: (final context, final constraints) {
          final isMobile = constraints.maxWidth <= 640;

          return BlocBuilder<SetupBloc, SetupState>(
            builder: (final context, final setupState) =>
                BlocBuilder<NotificationBloc, NotificationDraft>(
              builder: (final context, final draft) {
                if (isMobile) {
                  return Column(
                    children: [
                      _buildMobileSubBar(),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          children: [
                            _buildMobileContent(setupState, draft),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return ListView(
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

                    // ── Section 2.5: System Options ──
                    _StudioExpansionSection(
                      title: 'SYSTEM OPTIONS',
                      icon: Icons.settings_outlined,
                      initiallyExpanded: false,
                      child: SystemOptionsSection(setupState: setupState),
                    ),

                    // ── Section 3: Notification Draft ──
                    _StudioExpansionSection(
                      title: 'NOTIFICATION DRAFT',
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
                );
              },
            ),
          );
        },
      );

  Widget _buildMobileSubBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ConfigSubTab.values.map((final tab) {
            final isSelected = _selectedSubTab == tab;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: () => setState(() => _selectedSubTab = tab),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.16)
                        : colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.35)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: 13,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileContent(
    final SetupState setupState,
    final NotificationDraft draft,
  ) =>
      switch (_selectedSubTab) {
        ConfigSubTab.queues => QueueSection(setupState: setupState),
        ConfigSubTab.channels => ChannelSection(setupState: setupState),
        ConfigSubTab.preview => PreviewSection(
            setupState: setupState,
            draft: draft,
          ),
        ConfigSubTab.scenarios => const ScenariosSection(),
        ConfigSubTab.options =>
          SystemOptionsSection(setupState: setupState),
      };
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
