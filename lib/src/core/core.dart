/// The FNQ core engine.
///
/// This barrel exports the three core components that power the notification
/// system:
///
/// - [ConfigurationManager] — stores queues and channels, resolves lookups.
/// - [QueueCoordinator] — bridges queue lifecycle with the rendering surface.
/// - [NotificationOverlay] — the rendering surface that mounts notifications
///   into the widget tree.
///
/// All three are internal. The public API is exposed exclusively through
/// [FlutterNotificationQueue] and [NotificationWidget].
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logd/logd.dart';

import '../enums/enums.dart';
import '../notification/notification.dart';
import '../notification_channel/notification_channel.dart';
import '../notification_queue/notification_queue.dart';

part 'configuration_manager.dart';
part 'facade.dart';
part 'notification_overlay.dart';
part 'queue_coordinator.dart';
