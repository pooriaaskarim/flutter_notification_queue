import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import '../bloc/studio_state.dart';

/// Generates a copy-pasteable Dart code snippet from the current
/// [StudioState]. Omits parameters that match their defaults for
/// cleaner output.
String generateCode(final StudioState s) {
  final buf = StringBuffer()
    // ── Initialization snippet ──
    ..writeln('// 1. Initialize NFQ in main()')
    ..writeln('FlutterNotificationQueue.configure(')
    ..writeln('  queues: {')
    ..writeln('    NotificationQueue.defaultQueue(')
    ..writeln(
      '      position: QueuePosition.${s.queuePosition.name},',
    )
    ..writeln('      style: ${_styleCode(s)},')
    ..writeln(
      '      transition: ${_transitionCode(s)},',
    );

  if (s.maxStackSize != 3) {
    buf.writeln('      maxStackSize: ${s.maxStackSize},');
  }
  if (s.spacing != 4.0) {
    buf.writeln('      spacing: ${s.spacing},');
  }

  buf
    ..writeln(
      '      dragBehavior: ${_behaviorCode(s.dragBehavior, s)},',
    )
    ..writeln(
      '      longPressDragBehavior: '
      '${_behaviorCode(s.longPressBehavior, s)},',
    )
    ..writeln(
      '      closeButtonBehavior: ${_closeButtonCode(s)},',
    )
    ..writeln('    ),')
    ..writeln('  },')
    ..writeln(');')
    ..writeln()

    // ── Notification snippet ──
    ..writeln('// 2. Fire a notification')
    ..writeln('NotificationWidget(');

  if (s.notificationTitle.isNotEmpty) {
    buf.writeln("  title: '${_escape(s.notificationTitle)}',");
  }

  buf.writeln("  message: '${_escape(s.notificationMessage)}',");

  if (s.channelName != 'default') {
    buf.writeln("  channelName: '${s.channelName}',");
  }
  if (s.queuePosition != QueuePosition.topCenter) {
    buf.writeln(
      '  position: QueuePosition.${s.queuePosition.name},',
    );
  }
  if (s.dismissDuration != null) {
    buf.writeln(
      '  dismissDuration: '
      'const Duration(seconds: ${s.dismissDuration}),',
    );
  }
  if (s.actionType == ActionType.button) {
    buf
      ..writeln('  action: NotificationAction.button(')
      ..writeln("    label: '${_escape(s.actionLabel)}',")
      ..writeln('    onPressed: () {},')
      ..writeln('  ),');
  } else if (s.actionType == ActionType.onTap) {
    buf
      ..writeln('  action: NotificationAction.onTap(')
      ..writeln('    onPressed: () {},')
      ..writeln('  ),');
  }
  buf.writeln(').show();');

  return buf.toString();
}

String _styleCode(final StudioState s) {
  final name = switch (s.styleType) {
    StyleType.filled => 'FilledQueueStyle',
    StyleType.flat => 'FlatQueueStyle',
    StyleType.outlined => 'OutlinedQueueStyle',
  };

  final params = <String>[];
  if (s.styleOpacity != 0.7) {
    params.add('opacity: ${s.styleOpacity}');
  }
  if (s.styleElevation != 3.0) {
    params.add('elevation: ${s.styleElevation}');
  }
  if (s.styleBorderRadius != 8.0) {
    params.add(
      'borderRadius: '
      'BorderRadius.all(Radius.circular(${s.styleBorderRadius}))',
    );
  }

  if (params.isEmpty) {
    return 'const $name()';
  }
  return 'const $name(${params.join(', ')})';
}

String _transitionCode(final StudioState s) => switch (s.transitionType) {
      TransitionType.slide => 'const SlideTransitionStrategy()',
      TransitionType.fade => 'const FadeTransitionStrategy()',
      TransitionType.scale => 'const ScaleTransitionStrategy()',
    };

String _behaviorCode(
  final BehaviorType type,
  final StudioState s,
) =>
    switch (type) {
      BehaviorType.dismiss => 'const Dismiss()',
      BehaviorType.relocate => _relocateCode(s),
      BehaviorType.reorder => 'const Reorder()',
      BehaviorType.disabled => 'const Disabled()',
    };

String _relocateCode(final StudioState s) {
  if (s.relocatePositions.isEmpty) {
    return 'Relocate.to({QueuePosition.topCenter})';
  }
  final positions =
      s.relocatePositions.map((final p) => 'QueuePosition.${p.name}');
  return 'Relocate.to({${positions.join(', ')}})';
}

String _closeButtonCode(final StudioState s) => switch (s.closeButton) {
      CloseButtonType.alwaysVisible => 'const AlwaysVisible()',
      CloseButtonType.visibleOnHover => 'const VisibleOnHover()',
      CloseButtonType.hidden => 'const Hidden()',
    };

String _escape(final String input) => input.replaceAll("'", "\\'");
