import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

/// UI-friendly enums for sealed class selection.
enum StyleType { filled, flat, outlined }

enum TransitionType { slide, fade, scale }

enum BehaviorType { dismiss, relocate, reorder, disabled }

enum CloseButtonType { alwaysVisible, visibleOnHover, hidden }

enum ActionType { none, button, onTap }

/// The immutable state of the NFQ Studio configurator.
class StudioState extends Equatable {
  const StudioState({
    this.queuePosition = QueuePosition.topCenter,
    this.styleType = StyleType.filled,
    this.styleOpacity = 0.7,
    this.styleElevation = 3.0,
    this.styleBorderRadius = 8.0,
    this.transitionType = TransitionType.slide,
    this.dragBehavior = BehaviorType.dismiss,
    this.longPressBehavior = BehaviorType.disabled,
    this.relocatePositions = const {},
    this.closeButton = CloseButtonType.alwaysVisible,
    this.maxStackSize = 3,
    this.spacing = 4.0,
    this.channelName = 'info',
    this.notificationTitle = 'Hello from NFQ',
    this.notificationMessage =
        'This notification was configured in NFQ Studio.',
    this.actionType = ActionType.none,
    this.actionLabel = 'ACTION',
    this.dismissDuration = 5,
    this.themeMode = ThemeMode.dark,
  });

  // ── Queue ──
  final QueuePosition queuePosition;
  final StyleType styleType;
  final double styleOpacity;
  final double styleElevation;
  final double styleBorderRadius;
  final TransitionType transitionType;
  final BehaviorType dragBehavior;
  final BehaviorType longPressBehavior;
  final Set<QueuePosition> relocatePositions;
  final CloseButtonType closeButton;
  final int maxStackSize;
  final double spacing;

  // ── Channel ──
  final String channelName;

  // ── Notification ──
  final String notificationTitle;
  final String notificationMessage;
  final ActionType actionType;
  final String actionLabel;
  final int? dismissDuration;
  final ThemeMode themeMode;

  StudioState copyWith({
    final QueuePosition? queuePosition,
    final StyleType? styleType,
    final double? styleOpacity,
    final double? styleElevation,
    final double? styleBorderRadius,
    final TransitionType? transitionType,
    final BehaviorType? dragBehavior,
    final BehaviorType? longPressBehavior,
    final Set<QueuePosition>? relocatePositions,
    final CloseButtonType? closeButton,
    final int? maxStackSize,
    final double? spacing,
    final String? channelName,
    final String? notificationTitle,
    final String? notificationMessage,
    final ActionType? actionType,
    final String? actionLabel,
    final int? Function()? dismissDuration,
    final ThemeMode? themeMode,
  }) =>
      StudioState(
        queuePosition: queuePosition ?? this.queuePosition,
        styleType: styleType ?? this.styleType,
        styleOpacity: styleOpacity ?? this.styleOpacity,
        styleElevation: styleElevation ?? this.styleElevation,
        styleBorderRadius: styleBorderRadius ?? this.styleBorderRadius,
        transitionType: transitionType ?? this.transitionType,
        dragBehavior: dragBehavior ?? this.dragBehavior,
        longPressBehavior: longPressBehavior ?? this.longPressBehavior,
        relocatePositions: relocatePositions ?? this.relocatePositions,
        closeButton: closeButton ?? this.closeButton,
        maxStackSize: maxStackSize ?? this.maxStackSize,
        spacing: spacing ?? this.spacing,
        channelName: channelName ?? this.channelName,
        notificationTitle: notificationTitle ?? this.notificationTitle,
        notificationMessage: notificationMessage ?? this.notificationMessage,
        actionType: actionType ?? this.actionType,
        actionLabel: actionLabel ?? this.actionLabel,
        dismissDuration:
            dismissDuration != null ? dismissDuration() : this.dismissDuration,
        themeMode: themeMode ?? this.themeMode,
      );

  @override
  List<Object?> get props => [
        queuePosition,
        styleType,
        styleOpacity,
        styleElevation,
        styleBorderRadius,
        transitionType,
        dragBehavior,
        longPressBehavior,
        relocatePositions,
        closeButton,
        maxStackSize,
        spacing,
        channelName,
        notificationTitle,
        notificationMessage,
        actionType,
        actionLabel,
        dismissDuration,
        themeMode,
      ];
}
