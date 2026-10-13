import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import 'setup_bloc.dart';

// ── Events ──

sealed class StudioNotificationEvent {
  const StudioNotificationEvent();
}

final class UpdateTitle extends StudioNotificationEvent {
  const UpdateTitle(this.title);
  final String title;
}

final class UpdateMessage extends StudioNotificationEvent {
  const UpdateMessage(this.message);
  final String message;
}

final class UpdateNotificationActionStyle extends StudioNotificationEvent {
  const UpdateNotificationActionStyle(this.style);
  final NotificationActionStyle style;
}

final class UpdateActionLabel extends StudioNotificationEvent {
  const UpdateActionLabel(this.label);
  final String label;
}

final class UpdateDismissDuration extends StudioNotificationEvent {
  const UpdateDismissDuration(this.seconds);
  final int? seconds;
}

final class SelectPreviewChannel extends StudioNotificationEvent {
  const SelectPreviewChannel(this.channelName);
  final String channelName;
}

final class SelectPreviewPosition extends StudioNotificationEvent {
  const SelectPreviewPosition(this.position);
  final QueuePosition? position;
}

final class UpdatePriority extends StudioNotificationEvent {
  const UpdatePriority(this.priority);
  final NotificationPriority? priority;
}

final class UpdateInitialIsPinned extends StudioNotificationEvent {
  const UpdateInitialIsPinned({required this.isPinned});
  final bool isPinned;
}

final class UpdateDragBehaviorOverride extends StudioNotificationEvent {
  const UpdateDragBehaviorOverride(this.type);
  final Type? type;
}

final class UpdateSnoozeDurationSeconds extends StudioNotificationEvent {
  const UpdateSnoozeDurationSeconds(this.seconds);
  final int seconds;
}

final class FirePreview extends StudioNotificationEvent {
  const FirePreview();
}

final class ResetDraft extends StudioNotificationEvent {
  const ResetDraft();
}

// ── State ──

/// What style of action to attach to the notification.
enum NotificationActionStyle { none, button, onTap }

class NotificationDraft {
  const NotificationDraft({
    this.title = 'Hello from NFQ',
    this.message = 'This notification was configured in NFQ Studio.',
    this.actionStyle = NotificationActionStyle.none,
    this.actionLabel = 'ACTION',
    this.dismissSeconds = 5,
    this.channelName = 'info',
    this.positionOverride,
    this.priority,
    this.initialIsPinned = false,
    this.dragBehaviorOverrideType,
    this.snoozeDurationSeconds = 5,
  });

  final String title;
  final String message;
  final NotificationActionStyle actionStyle;
  final String actionLabel;
  final int? dismissSeconds;

  /// Which channel to fire into.
  final String channelName;

  /// Override the channel's default position. `null` = use channel default.
  final QueuePosition? positionOverride;

  /// Priority rank override.
  final NotificationPriority? priority;

  /// Whether the notification starts pinned to the top.
  final bool initialIsPinned;

  /// Optional per-notification drag behavior override.
  final Type? dragBehaviorOverrideType;

  /// Duration to snooze for when Snooze is chosen.
  final int snoozeDurationSeconds;

  NotificationDraft copyWith({
    final String? title,
    final String? message,
    final NotificationActionStyle? actionStyle,
    final String? actionLabel,
    final int? Function()? dismissSeconds,
    final String? channelName,
    final QueuePosition? Function()? positionOverride,
    final NotificationPriority? Function()? priority,
    final bool? initialIsPinned,
    final Type? Function()? dragBehaviorOverrideType,
    final int? snoozeDurationSeconds,
  }) =>
      NotificationDraft(
        title: title ?? this.title,
        message: message ?? this.message,
        actionStyle: actionStyle ?? this.actionStyle,
        actionLabel: actionLabel ?? this.actionLabel,
        dismissSeconds:
            dismissSeconds != null ? dismissSeconds() : this.dismissSeconds,
        channelName: channelName ?? this.channelName,
        positionOverride: positionOverride != null
            ? positionOverride()
            : this.positionOverride,
        priority: priority != null ? priority() : this.priority,
        initialIsPinned: initialIsPinned ?? this.initialIsPinned,
        dragBehaviorOverrideType: dragBehaviorOverrideType != null
            ? dragBehaviorOverrideType()
            : this.dragBehaviorOverrideType,
        snoozeDurationSeconds:
            snoozeDurationSeconds ?? this.snoozeDurationSeconds,
      );
}

// ── Bloc ──

/// Composes and fires preview notifications.
///
/// Reads the current `StudioSetup` from `SetupBloc` to resolve
/// channels and queue positions.
class NotificationBloc
    extends Bloc<StudioNotificationEvent, NotificationDraft> {
  NotificationBloc({required this.setupBloc})
      : super(const NotificationDraft()) {
    on<UpdateTitle>(
      (final event, final emit) => emit(state.copyWith(title: event.title)),
    );
    on<UpdateMessage>(
      (final event, final emit) => emit(state.copyWith(message: event.message)),
    );
    on<UpdateNotificationActionStyle>(
      (final event, final emit) =>
          emit(state.copyWith(actionStyle: event.style)),
    );
    on<UpdateActionLabel>(
      (final event, final emit) =>
          emit(state.copyWith(actionLabel: event.label)),
    );
    on<UpdateDismissDuration>(
      (final event, final emit) =>
          emit(state.copyWith(dismissSeconds: () => event.seconds)),
    );
    on<SelectPreviewChannel>(
      (final event, final emit) =>
          emit(state.copyWith(channelName: event.channelName)),
    );
    on<SelectPreviewPosition>(
      (final event, final emit) =>
          emit(state.copyWith(positionOverride: () => event.position)),
    );
    on<UpdatePriority>(
      (final event, final emit) =>
          emit(state.copyWith(priority: () => event.priority)),
    );
    on<UpdateInitialIsPinned>(
      (final event, final emit) =>
          emit(state.copyWith(initialIsPinned: event.isPinned)),
    );
    on<UpdateDragBehaviorOverride>(
      (final event, final emit) => emit(
        state.copyWith(dragBehaviorOverrideType: () => event.type),
      ),
    );
    on<UpdateSnoozeDurationSeconds>(
      (final event, final emit) =>
          emit(state.copyWith(snoozeDurationSeconds: event.seconds)),
    );
    on<ResetDraft>(
      (final event, final emit) => emit(const NotificationDraft()),
    );
    on<FirePreview>(_onFirePreview);
  }

  final SetupBloc setupBloc;

  void _onFirePreview(
    final FirePreview event,
    final Emitter<NotificationDraft> emit,
  ) {
    final draft = state;

    // Build action
    NotificationAction? action;
    TapBehavior? tapBehavior;
    if (draft.actionStyle == NotificationActionStyle.button) {
      action = NotificationAction.button(
        label: draft.actionLabel,
        onPressed: () => debugPrint('[NFQ Studio] Button tapped'),
      );
    } else if (draft.actionStyle == NotificationActionStyle.onTap) {
      tapBehavior = TapToAct(
        onTap: () => debugPrint('[NFQ Studio] Notification tapped'),
      );
    }

    final channelSetup = setupBloc.state.setup.channels[draft.channelName];
    final effectiveLibraryPosition = channelSetup?.position;
    final resolvedPosition = draft.positionOverride ??
        effectiveLibraryPosition ??
        setupBloc.state.activeQueuePosition;

    // Resolve drag behavior override
    DragBehavior? dragBehavior;
    if (draft.dragBehaviorOverrideType == Snooze) {
      dragBehavior = Snooze(
        duration: Duration(seconds: draft.snoozeDurationSeconds),
      );
    } else if (draft.dragBehaviorOverrideType == Pin) {
      dragBehavior = const Pin();
    } else if (draft.dragBehaviorOverrideType == Dismiss) {
      dragBehavior = const Dismiss();
    } else if (draft.dragBehaviorOverrideType == Disabled) {
      dragBehavior = const Disabled();
    }

    // Fire notification via NotificationController
    setupBloc.controller.show(
      AppNotification(
        title: draft.title,
        message: draft.message,
        channelName: draft.channelName,
        position: resolvedPosition,
        priority: draft.priority,
        initialIsPinned: draft.initialIsPinned,
        dragBehavior: dragBehavior,
        action: action,
        tapBehavior: tapBehavior,
        dismissDuration: draft.dismissSeconds != null
            ? Duration(seconds: draft.dismissSeconds!)
            : null,
      ),
    );
  }
}
