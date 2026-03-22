import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/notification_bloc.dart';
import '../bloc/setup_bloc.dart';
import 'configurator/channel_section.dart';
import 'configurator/preview_section.dart';
import 'configurator/queue_section.dart';

/// The left-side configurator panel with three sections:
/// 1. **Queues** — add/remove/edit queue setups per position
/// 2. **Channels** — manage notification channels
/// 3. **Preview** — compose and fire test notifications
class ConfiguratorPanel extends StatelessWidget {
  const ConfiguratorPanel({super.key});

  @override
  Widget build(final BuildContext context) =>
      BlocBuilder<SetupBloc, SetupState>(
        builder: (final context, final setupState) =>
            BlocBuilder<NotificationBloc, NotificationDraft>(
          builder: (final context, final draft) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Section 1: Queues ──
              QueueSection(setupState: setupState),
              const Divider(height: 32),

              // ── Section 2: Channels ──
              ChannelSection(setupState: setupState),
              const Divider(height: 32),

              // ── Section 3: Preview ──
              PreviewSection(
                setupState: setupState,
                draft: draft,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
}
