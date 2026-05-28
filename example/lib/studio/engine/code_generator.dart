import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import '../bloc/notification_bloc.dart';
import '../models/channel_setup.dart';
import '../models/queue_setup.dart';
import '../models/studio_setup.dart';

/// Generates a copy-pasteable Dart code snippet from the current
/// [StudioSetup] and [NotificationDraft].
String generateCode({
  required final StudioSetup setup,
  required final NotificationDraft draft,
}) {
  final buf = StringBuffer('// NFQ Studio — Generated Code\n')
    ..writeln()
    ..writeln('FlutterNotificationQueue.configure(')
    ..writeln('  queues: {');

  for (final entry in setup.queues.entries) {
    _writeQueue(buf, entry.key, entry.value);
  }

  buf
    ..writeln('  },')
    ..writeln('  channels: {');

  for (final channel in setup.channels.values) {
    _writeChannel(buf, channel);
  }

  buf
    ..writeln('  },')
    ..writeln(');')
    ..writeln()

    // ── NotificationWidget ──

    ..writeln('// Fire a notification')
    ..writeln('NotificationWidget(')
    ..writeln("  title: '${draft.title}',")
    ..writeln("  message: '${draft.message}',")
    ..writeln("  channelName: '${draft.channelName}',");

  if (draft.positionOverride != null) {
    buf.writeln(
      '  position: QueuePosition.${draft.positionOverride!.name},',
    );
  }

  if (draft.actionStyle == NotificationActionStyle.button) {
    buf
      ..writeln('  action: NotificationAction.button(')
      ..writeln("    label: '${draft.actionLabel}',")
      ..writeln('    onPressed: () {},')
      ..writeln('  ),');
  } else if (draft.actionStyle == NotificationActionStyle.onTap) {
    buf
      ..writeln('  action: NotificationAction.onTap(')
      ..writeln('    onPressed: () {},')
      ..writeln('  ),');
  }

  if (draft.dismissSeconds != null) {
    buf.writeln(
      '  dismissDuration: '
      'const Duration(seconds: ${draft.dismissSeconds}),',
    );
  }

  buf
    ..writeln(').show();')
    ..writeln();

  return buf.toString();
}

void _writeQueue(
  final StringBuffer buf,
  final QueuePosition position,
  final QueueSetup q,
) {
  buf
    ..writeln('    NotificationQueue.defaultQueue(')
    ..writeln('      position: QueuePosition.${position.name},')
    ..writeln(
      '      style: ${_styleSnippet(q)},',
    )
    ..writeln(
      '      transition: ${_transitionSnippet(q.transitionType)},',
    )
    ..writeln('      maxStackSize: ${q.maxStackSize},')
    ..writeln('      spacing: ${q.spacing},')
    ..writeln(
      '      dragBehavior: ${_behaviorSnippet(q.dragBehaviorType, q, true)},',
    )
    ..writeln(
      '      longPressDragBehavior: '
      '${_behaviorSnippet(q.longPressBehaviorType, q, false)},',
    )
    ..writeln(
      '      closeButtonBehavior: '
      '${_closeButtonSnippet(q.closeButtonBehaviorType)},',
    )
    ..writeln(
      '      margin: const EdgeInsets.symmetric(\n'
      '        vertical: ${q.verticalMargin},\n'
      '        horizontal: ${q.horizontalMargin},\n'
      '      ),',
    )
    ..writeln('    ),');
}

void _writeChannel(final StringBuffer buf, final ChannelSetup c) {
  buf
    ..writeln('    NotificationChannel(')
    ..writeln("      name: '${c.name}',");
  if (c.description != null) {
    buf.writeln("      description: '${c.description}',");
  }
  if (c.color != null) {
    buf.writeln(
      '      defaultColor: '
      'Color(0x${c.color!.toARGB32().toRadixString(16).padLeft(8, '0')}'
      '),',
    );
  }
  if (c.foregroundColor != null) {
    buf.writeln(
      '      defaultForegroundColor: Color(0x'
      '${c.foregroundColor!.toARGB32().toRadixString(16).padLeft(8, '0')}'
      '),',
    );
  }
  if (c.backgroundColor != null) {
    buf.writeln(
      '      defaultBackgroundColor: Color(0x'
      '${c.backgroundColor!.toARGB32().toRadixString(16).padLeft(8, '0')}'
      '),',
    );
  }
  if (c.position != null) {
    buf.writeln(
      '      position: QueuePosition.${c.position!.name},',
    );
  }
  if (c.dismissSeconds != null) {
    buf.writeln(
      '      defaultDismissDuration: '
      'const Duration(seconds: ${c.dismissSeconds}),',
    );
  }
  if (c.iconPreset != ChannelIconPreset.none) {
    final iconName = switch (c.iconPreset) {
      ChannelIconPreset.info => 'info',
      ChannelIconPreset.success => 'check_circle',
      ChannelIconPreset.warning => 'warning',
      ChannelIconPreset.error => 'error',
      ChannelIconPreset.notification => 'notifications',
      ChannelIconPreset.none => '', // shouldn't happen
    };
    buf.writeln('      defaultIcon: Icon(Icons.$iconName),');
  }
  // Only emit `enabled: false` — omitting it implies true (the default).
  if (!c.enabled) {
    buf.writeln('      enabled: false,');
  }
  buf.writeln('    ),');
}

String _styleSnippet(final QueueSetup q) => '${q.styleType}(\n'
    '        opacity: ${q.opacity},\n'
    '        elevation: ${q.elevation},\n'
    '        borderRadius: '
    'BorderRadius.circular(${q.borderRadius}),\n'
    '      )';

String _transitionSnippet(final Type t) => 'const $t()';

String _behaviorSnippet(final Type t, final QueueSetup q, final bool isDrag) {
  final zone = isDrag ? q.dragDismissZone : q.longPressDismissZone;

  if (t == Dismiss) {
    return 'const Dismiss(zones: DismissZone.${zone.name})';
  }
  if (t == Relocate) {
    return q.relocateTargets.isEmpty
        ? 'Relocate.to({}) // ERROR: Relocation targets must not be empty!'
        : 'Relocate.to({${q.relocateTargets.map(
              (final p) => 'QueuePosition.${p.name}',
            ).join(', ')}})';
  }
  if (t == ReorderAndRelocate) {
    return q.relocateTargets.isEmpty
        ? 'ReorderAndRelocate.to(positions: {}) // ERROR: Relocation targets must not be empty!'
        : 'ReorderAndRelocate.to(\n'
          '        positions: {${q.relocateTargets.map(
                (final p) => 'QueuePosition.${p.name}',
              ).join(', ')}},\n'
          '      )';
  }
  if (t == Reorder) {
    return 'const Reorder()';
  }
  return 'const Disabled()';
}

String _closeButtonSnippet(final Type t) => 'const $t()';
