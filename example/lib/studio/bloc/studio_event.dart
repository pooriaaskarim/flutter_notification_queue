import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import 'studio_bloc.dart' show StudioBloc;
import 'studio_state.dart';

/// All events that can be dispatched to [StudioBloc].
sealed class StudioEvent extends Equatable {
  const StudioEvent();

  @override
  List<Object?> get props => [];
}

final class UpdateThemeMode extends StudioEvent {
  const UpdateThemeMode(this.themeMode);
  final ThemeMode themeMode;

  @override
  List<Object?> get props => [themeMode];
}

// ── Queue Configuration ──

final class UpdateQueuePosition extends StudioEvent {
  const UpdateQueuePosition(this.position);
  final QueuePosition position;

  @override
  List<Object?> get props => [position];
}

final class UpdateStyleType extends StudioEvent {
  const UpdateStyleType(this.styleType);
  final StyleType styleType;

  @override
  List<Object?> get props => [styleType];
}

final class UpdateStyleOpacity extends StudioEvent {
  const UpdateStyleOpacity(this.opacity);
  final double opacity;

  @override
  List<Object?> get props => [opacity];
}

final class UpdateStyleElevation extends StudioEvent {
  const UpdateStyleElevation(this.elevation);
  final double elevation;

  @override
  List<Object?> get props => [elevation];
}

final class UpdateStyleBorderRadius extends StudioEvent {
  const UpdateStyleBorderRadius(this.radius);
  final double radius;

  @override
  List<Object?> get props => [radius];
}

final class UpdateTransitionType extends StudioEvent {
  const UpdateTransitionType(this.transitionType);
  final TransitionType transitionType;

  @override
  List<Object?> get props => [transitionType];
}

final class UpdateMaxStackSize extends StudioEvent {
  const UpdateMaxStackSize(this.size);
  final int size;

  @override
  List<Object?> get props => [size];
}

final class UpdateSpacing extends StudioEvent {
  const UpdateSpacing(this.spacing);
  final double spacing;

  @override
  List<Object?> get props => [spacing];
}

// ── Drag & Close Behaviors ──

final class UpdateDragBehavior extends StudioEvent {
  const UpdateDragBehavior(this.behavior);
  final BehaviorType behavior;

  @override
  List<Object?> get props => [behavior];
}

final class UpdateLongPressBehavior extends StudioEvent {
  const UpdateLongPressBehavior(this.behavior);
  final BehaviorType behavior;

  @override
  List<Object?> get props => [behavior];
}

final class ToggleRelocatePosition extends StudioEvent {
  const ToggleRelocatePosition(this.position);
  final QueuePosition position;

  @override
  List<Object?> get props => [position];
}

final class UpdateCloseButton extends StudioEvent {
  const UpdateCloseButton(this.closeButton);
  final CloseButtonType closeButton;

  @override
  List<Object?> get props => [closeButton];
}

// ── Channel ──

final class UpdateChannelName extends StudioEvent {
  const UpdateChannelName(this.name);
  final String name;

  @override
  List<Object?> get props => [name];
}

// ── Notification Content ──

final class UpdateNotificationTitle extends StudioEvent {
  const UpdateNotificationTitle(this.title);
  final String title;

  @override
  List<Object?> get props => [title];
}

final class UpdateNotificationMessage extends StudioEvent {
  const UpdateNotificationMessage(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

final class UpdateActionType extends StudioEvent {
  const UpdateActionType(this.actionType);
  final ActionType actionType;

  @override
  List<Object?> get props => [actionType];
}

final class UpdateActionLabel extends StudioEvent {
  const UpdateActionLabel(this.label);
  final String label;

  @override
  List<Object?> get props => [label];
}

final class UpdateDismissDuration extends StudioEvent {
  const UpdateDismissDuration(this.seconds);
  final int? seconds;

  @override
  List<Object?> get props => [seconds];
}

// ── Actions ──

final class ResetToDefaults extends StudioEvent {
  const ResetToDefaults();
}

final class FirePreview extends StudioEvent {
  const FirePreview();
}
