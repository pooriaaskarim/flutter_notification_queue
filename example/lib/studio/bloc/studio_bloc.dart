import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import 'studio_event.dart';
import 'studio_state.dart';

class StudioBloc extends Bloc<StudioEvent, StudioState> {
  StudioBloc() : super(const StudioState()) {
    on<UpdateThemeMode>(
      (final event, final emit) =>
          emit(state.copyWith(themeMode: event.themeMode)),
    );
    // Queue
    on<UpdateQueuePosition>(
      (final event, final emit) =>
          emit(state.copyWith(queuePosition: event.position)),
    );
    on<UpdateStyleType>(
      (final event, final emit) =>
          emit(state.copyWith(styleType: event.styleType)),
    );
    on<UpdateStyleOpacity>(
      (final event, final emit) =>
          emit(state.copyWith(styleOpacity: event.opacity)),
    );
    on<UpdateStyleElevation>(
      (final event, final emit) =>
          emit(state.copyWith(styleElevation: event.elevation)),
    );
    on<UpdateStyleBorderRadius>(
      (final event, final emit) =>
          emit(state.copyWith(styleBorderRadius: event.radius)),
    );
    on<UpdateTransitionType>(
      (final event, final emit) =>
          emit(state.copyWith(transitionType: event.transitionType)),
    );
    on<UpdateMaxStackSize>(
      (final event, final emit) =>
          emit(state.copyWith(maxStackSize: event.size)),
    );
    on<UpdateSpacing>(
      (final event, final emit) => emit(state.copyWith(spacing: event.spacing)),
    );

    // Behaviors
    on<UpdateDragBehavior>(
      (final event, final emit) =>
          emit(state.copyWith(dragBehavior: event.behavior)),
    );
    on<UpdateLongPressBehavior>(
      (final event, final emit) =>
          emit(state.copyWith(longPressBehavior: event.behavior)),
    );
    on<ToggleRelocatePosition>((final event, final emit) {
      final updated = Set<QueuePosition>.from(state.relocatePositions);
      if (updated.contains(event.position)) {
        updated.remove(event.position);
      } else {
        updated.add(event.position);
      }
      emit(state.copyWith(relocatePositions: updated));
    });
    on<UpdateCloseButton>(
      (final event, final emit) =>
          emit(state.copyWith(closeButton: event.closeButton)),
    );

    // Channel
    on<UpdateChannelName>(
      (final event, final emit) =>
          emit(state.copyWith(channelName: event.name)),
    );

    // Notification content
    on<UpdateNotificationTitle>(
      (final event, final emit) =>
          emit(state.copyWith(notificationTitle: event.title)),
    );
    on<UpdateNotificationMessage>(
      (final event, final emit) =>
          emit(state.copyWith(notificationMessage: event.message)),
    );
    on<UpdateActionType>(
      (final event, final emit) =>
          emit(state.copyWith(actionType: event.actionType)),
    );
    on<UpdateActionLabel>(
      (final event, final emit) =>
          emit(state.copyWith(actionLabel: event.label)),
    );
    on<UpdateDismissDuration>(
      (final event, final emit) =>
          emit(state.copyWith(dismissDuration: () => event.seconds)),
    );

    // Actions
    on<ResetToDefaults>(
      (final event, final emit) => emit(const StudioState()),
    );
    on<FirePreview>(_onFirePreview);
  }

  void _onFirePreview(
    final FirePreview event,
    final Emitter<StudioState> emit,
  ) {
    final s = state;

    // 1. Re-initialize NFQ to reflect "Architect" settings in the preview
    FlutterNotificationQueue.configure(
      queues: {
        NotificationQueue.defaultQueue(
          position: s.queuePosition,
          style: _mapStyle(s),
          transition: _mapTransition(s),
          maxStackSize: s.maxStackSize,
          spacing: s.spacing,
          dragBehavior: switch (s.dragBehavior) {
            BehaviorType.dismiss => const Dismiss(),
            BehaviorType.relocate => Relocate.to(
                s.relocatePositions.isEmpty
                    ? {QueuePosition.topCenter}
                    : s.relocatePositions,
              ),
            BehaviorType.reorder => const Reorder(),
            BehaviorType.disabled => const Disabled(),
          },
          longPressDragBehavior: switch (s.longPressBehavior) {
            BehaviorType.dismiss => const Dismiss(),
            BehaviorType.relocate => Relocate.to(
                s.relocatePositions.isEmpty
                    ? {QueuePosition.topCenter}
                    : s.relocatePositions,
              ),
            BehaviorType.reorder => const Reorder(),
            BehaviorType.disabled => const Disabled(),
          },
          closeButtonBehavior: _mapCloseButton(s),
        ),
      },
      // Ensure standard channels are preserved
      channels: NotificationChannel.standardChannels(),
    );

    // 2. Prepare action
    NotificationAction? action;
    if (s.actionType == ActionType.button) {
      action = NotificationAction.button(
        label: s.actionLabel,
        onPressed: () => debugPrint('[NFQ Studio] Button tapped'),
      );
    } else if (s.actionType == ActionType.onTap) {
      action = NotificationAction.onTap(
        onPressed: () => debugPrint('[NFQ Studio] Notification tapped'),
      );
    }

    // 3. Fire notification
    NotificationWidget(
      title: s.notificationTitle,
      message: s.notificationMessage,
      channelName: s.channelName,
      position: s.queuePosition,
      action: action,
      dismissDuration: s.dismissDuration != null
          ? Duration(seconds: s.dismissDuration!)
          : null,
    ).show();
  }

  QueueStyle _mapStyle(final StudioState s) {
    final opacity = s.styleOpacity;
    final elevation = s.styleElevation;
    final borderRadius = BorderRadius.circular(s.styleBorderRadius);

    return switch (s.styleType) {
      StyleType.filled => FilledQueueStyle(
          opacity: opacity,
          elevation: elevation,
          borderRadius: borderRadius,
        ),
      StyleType.flat => FlatQueueStyle(
          opacity: opacity,
          elevation: elevation,
          borderRadius: borderRadius,
        ),
      StyleType.outlined => OutlinedQueueStyle(
          opacity: opacity,
          elevation: elevation,
          borderRadius: borderRadius,
        ),
    };
  }

  NotificationTransition _mapTransition(final StudioState s) =>
      switch (s.transitionType) {
        TransitionType.slide => const SlideTransitionStrategy(),
        TransitionType.fade => const FadeTransitionStrategy(),
        TransitionType.scale => const ScaleTransitionStrategy(),
      };

  QueueCloseButtonBehavior _mapCloseButton(final StudioState s) =>
      switch (s.closeButton) {
        CloseButtonType.alwaysVisible => const AlwaysVisible(),
        CloseButtonType.visibleOnHover => const VisibleOnHover(),
        CloseButtonType.hidden => const Hidden(),
      };
}
