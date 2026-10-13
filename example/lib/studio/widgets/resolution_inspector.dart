import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import '../bloc/notification_bloc.dart';
import '../bloc/setup_bloc.dart';
import '../studio_theme.dart';

/// An interactive inspector displaying the two decoupled gears
/// (Structure & Chromatics) in action across the NFQ cascade.
class ResolutionInspector extends StatelessWidget {
  const ResolutionInspector({
    required this.setupState,
    required this.draft,
    super.key,
  });

  final SetupState setupState;
  final NotificationDraft draft;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = StudioTheme.colorScheme;

    // 1. Resolve Gear 1: Physical Style
    final channelSetup = setupState.setup.channels[draft.channelName];
    final queuePosition = draft.positionOverride ??
        channelSetup?.position ??
        setupState.activeQueuePosition;
    final queueSetup = setupState.setup.queues[queuePosition];

    final queueStyleType = queueSetup?.styleType ?? FilledQueueStyle;
    final String effectiveStyleName = _styleName(queueStyleType);
    final String styleResolutionSource = 'Queue (${queuePosition.name})';

    // 2. Resolve Gear 2: Chromatic Theme
    final hasNotificationAccent = draft.accentColorOverride != null;
    final hasChannelTheme = channelSetup?.theme != null;
    final channelColor = channelSetup?.color;

    final Color effectiveAccent = draft.accentColorOverride ??
        channelSetup?.theme?.color ??
        channelColor ??
        colorScheme.primary;

    final String themeResolutionSource;
    if (hasNotificationAccent) {
      themeResolutionSource = 'Notification (accentColor)';
    } else if (hasChannelTheme || channelColor != null) {
      themeResolutionSource = 'Channel (#${draft.channelName})';
    } else {
      themeResolutionSource = 'Ambient App Theme';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings_suggest_rounded,
                size: 15,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'CASCADE RESOLUTION PIPELINE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '2 ATTACHED GEARS',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Gear 1
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(
                  Icons.architecture_rounded,
                  size: 12,
                  color: colorScheme.primary,
                ),
              ),
              Text(
                'GEAR 1 (STRUCTURE):',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  '$effectiveStyleName '
                  '(r:${queueSetup?.borderRadius.toInt() ?? 8} '
                  'e:${queueSetup?.elevation.toInt() ?? 3})',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'from $styleResolutionSource',
                style: TextStyle(
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Gear 2
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: effectiveAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: effectiveAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: effectiveAccent.withValues(alpha: 0.4),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                'GEAR 2 (PALETTE):',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  _colorHex(effectiveAccent),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              Text(
                'from $themeResolutionSource',
                style: TextStyle(
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _styleName(final Type type) => switch (type) {
        == FilledQueueStyle => 'FilledQueueStyle',
        == OutlinedQueueStyle => 'OutlinedQueueStyle',
        == FlatQueueStyle => 'FlatQueueStyle',
        _ => type.toString(),
      };

  static String _colorHex(final Color c) {
    final hex =
        (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '#${hex.toUpperCase()}';
  }
}
