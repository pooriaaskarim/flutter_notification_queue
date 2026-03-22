import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

/// Preset icon choices for a [ChannelSetup].
enum ChannelIconPreset {
  info(Icons.info, 'Info'),
  success(Icons.check_circle, 'Success'),
  warning(Icons.warning, 'Warning'),
  error(Icons.error, 'Error'),
  notification(Icons.notifications, 'Notification'),
  none(null, 'None');

  const ChannelIconPreset(this.iconData, this.label);
  final IconData? iconData;
  final String label;

  Widget? toWidget() => iconData != null ? Icon(iconData) : null;
}

/// The immutable setup for a single [NotificationChannel].
///
/// Extends [Equatable] for free change detection.
class ChannelSetup extends Equatable {
  const ChannelSetup({
    required this.name,
    this.description,
    this.color,
    this.foregroundColor,
    this.backgroundColor,
    this.position,
    this.dismissSeconds = 5,
    this.iconPreset = ChannelIconPreset.none,
    this.enabled = true,
  });

  /// Channel identifier (unique key).
  final String name;

  /// Human-readable description.
  final String? description;

  /// Accent color for icon, border, and filled styles.
  final Color? color;

  /// Text/button/progress foreground color.
  final Color? foregroundColor;

  /// Notification body background color.
  final Color? backgroundColor;

  /// Which queue position this channel's notifications bind to.
  /// `null` = use the system's default queue.
  final QueuePosition? position;

  /// Auto-dismiss duration in seconds. `null` = permanent.
  final int? dismissSeconds;

  /// Icon preset for this channel.
  final ChannelIconPreset iconPreset;

  /// Whether this channel is active.
  final bool enabled;

  ChannelSetup copyWith({
    final String? name,
    final String? Function()? description,
    final Color? Function()? color,
    final Color? Function()? foregroundColor,
    final Color? Function()? backgroundColor,
    final QueuePosition? Function()? position,
    final int? Function()? dismissSeconds,
    final ChannelIconPreset? iconPreset,
    final bool? enabled,
  }) =>
      ChannelSetup(
        name: name ?? this.name,
        description: description != null ? description() : this.description,
        color: color != null ? color() : this.color,
        foregroundColor:
            foregroundColor != null ? foregroundColor() : this.foregroundColor,
        backgroundColor:
            backgroundColor != null ? backgroundColor() : this.backgroundColor,
        position: position != null ? position() : this.position,
        dismissSeconds:
            dismissSeconds != null ? dismissSeconds() : this.dismissSeconds,
        iconPreset: iconPreset ?? this.iconPreset,
        enabled: enabled ?? this.enabled,
      );

  /// Builds the library [NotificationChannel] from this setup.
  NotificationChannel toNotificationChannel() => NotificationChannel(
        name: name,
        description: description,
        defaultColor: color,
        defaultForegroundColor: foregroundColor,
        defaultBackgroundColor: backgroundColor,
        position: position,
        defaultDismissDuration:
            dismissSeconds != null ? Duration(seconds: dismissSeconds!) : null,
        defaultIcon: iconPreset.toWidget(),
        enabled: enabled,
      );

  @override
  List<Object?> get props => [
        name,
        description,
        color,
        foregroundColor,
        backgroundColor,
        position,
        dismissSeconds,
        iconPreset,
        enabled,
      ];

  /// The 4 standard built-in channels.
  static Map<String, ChannelSetup> standardChannels() => {
        'info': const ChannelSetup(
          name: 'info',
          description: 'Info notification channel.',
          color: Color(0xFF51B4F9),
          iconPreset: ChannelIconPreset.info,
        ),
        'success': const ChannelSetup(
          name: 'success',
          description: 'Success notification channel.',
          color: Color(0xFF2D7512),
          iconPreset: ChannelIconPreset.success,
        ),
        'warning': const ChannelSetup(
          name: 'warning',
          description: 'Warning notification channel.',
          color: Color(0xFFC97725),
          iconPreset: ChannelIconPreset.warning,
        ),
        'error': const ChannelSetup(
          name: 'error',
          description: 'Error notification channel.',
          color: Color(0xFFD03332),
          iconPreset: ChannelIconPreset.error,
        ),
      };
}
