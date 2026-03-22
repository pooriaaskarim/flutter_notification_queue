import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import 'setup_bloc.dart';

// ── Events ──

sealed class NotificationEvent {
  const NotificationEvent();
}

final class UpdateTitle extends NotificationEvent {
  const UpdateTitle(this.title);
  final String title;
}

final class UpdateMessage extends NotificationEvent {
  const UpdateMessage(this.message);
  final String message;
}

final class UpdateNotificationActionStyle extends NotificationEvent {
  const UpdateNotificationActionStyle(this.style);
  final NotificationActionStyle style;
}

final class UpdateActionLabel extends NotificationEvent {
  const UpdateActionLabel(this.label);
  final String label;
}

final class UpdateDismissDuration extends NotificationEvent {
  const UpdateDismissDuration(this.seconds);
  final int? seconds;
}

final class SelectPreviewChannel extends NotificationEvent {
  const SelectPreviewChannel(this.channelName);
  final String channelName;
}

final class SelectPreviewPosition extends NotificationEvent {
  const SelectPreviewPosition(this.position);
  final QueuePosition? position;
}

final class FirePreview extends NotificationEvent {
  const FirePreview();
}

final class ResetDraft extends NotificationEvent {
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

  NotificationDraft copyWith({
    final String? title,
    final String? message,
    final NotificationActionStyle? actionStyle,
    final String? actionLabel,
    final int? Function()? dismissSeconds,
    final String? channelName,
    final QueuePosition? Function()? positionOverride,
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
      );
}

// ── Bloc ──

/// Composes and fires preview notifications.
///
/// Reads the current `StudioSetup` from `SetupBloc` to resolve
/// channels and queue positions.
class NotificationBloc extends Bloc<NotificationEvent, NotificationDraft> {
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
    if (draft.actionStyle == NotificationActionStyle.button) {
      action = NotificationAction.button(
        label: draft.actionLabel,
        onPressed: () => debugPrint('[NFQ Studio] Button tapped'),
      );
    } else if (draft.actionStyle == NotificationActionStyle.onTap) {
      action = NotificationAction.onTap(
        onPressed: () => debugPrint('[NFQ Studio] Notification tapped'),
      );
    }

    // Fire notification
    NotificationWidget(
      title: draft.title,
      message: draft.message,
      channelName: draft.channelName,
      position: draft.positionOverride,
      action: action,
      dismissDuration: draft.dismissSeconds != null
          ? Duration(seconds: draft.dismissSeconds!)
          : null,
    ).show();
  }
}
