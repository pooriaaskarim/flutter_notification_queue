# FlutterNotificationQueue

[![Pub Version](https://img.shields.io/pub/v/flutter_notification_queue)](https://pub.dev/packages/flutter_notification_queue)
[![Pub Likes](https://img.shields.io/pub/likes/flutter_notification_queue)](https://pub.dev/packages/flutter_notification_queue)
[![Pub Points](https://img.shields.io/pub/points/flutter_notification_queue)](https://pub.dev/packages/flutter_notification_queue)
[![License: BSD 3-Clause](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![Platform: Flutter](https://img.shields.io/badge/Platform-Flutter-blue?logo=flutter)](https://flutter.dev)

A powerful, feature-rich overlay-based notification system for Flutter applications.
FlutterNotificationQueue provides a comprehensive solution for displaying in-app notifications with
advanced queuing, interactive gestures, multi-language support, and extensive customization options.

## Key Features

### **Advanced Notification System**

- **Multiple Notification Types**: Success, Error, Warning, Info with predefined styling
- **Custom Notifications**: Full control over appearance, behavior, and content
- **Permanent Notifications**: Stay visible until manually dismissed
- **Auto-dismiss with Timer**: Visual progress indicator and configurable duration
- **Expandable Content**: Tap to expand long messages with auto-pause on expansion

### **Intelligent Queue Management**

- **Smart Queuing**: FIFO-based queue system with configurable stack limits
- **Multiple Queue Positions**: 8 different screen positions (top, center, bottom + left, center,
  right)
- **Stack Indicators**: Visual "+N more" badges for queued notifications
- **Channel System**: Organized notification channels with individual configurations
- **Dynamic Relocation**: Drag notifications between different queue positions

### **Rich Interactive Features**

- **Drag-to-Dismiss**: Swipe notifications away in any direction
- **Long-press Actions**: Relocate or dismiss with long-press gestures
- **Tap Actions**: Button actions or tap-anywhere functionality
- **Hover Effects**: Adaptive close button with [progressive enhancement](doc/queue/README.md#close-button-visibility)
- **Gesture Feedback**: Smooth opacity changes during interactions

### **Internationalization & Accessibility**

- **RTL Language Support**: Automatic text direction detection for Arabic, Persian, Hebrew, and more
- **Multi-language Examples**: Comprehensive support for 10+ languages
- **Responsive Design**: Adaptive layouts for phone, tablet, and desktop
- **Safe Area Integration**: Automatic handling of notches and status bars
- **Screen Reader Support**: Proper semantic labels and accessibility features

### **Extensive Customization**

- **Queue Styles**: Flat, Filled, and Outlined notification styles
- **Color Theming**: Custom colors for each notification type and channel
- **Animation Control**: Configurable entrance/exit animations and curves
- **Layout Customization**: Margins, spacing, elevation, and border radius
- **Custom Builders**: Override notification UI with custom widgets

## Installation

Add FlutterNotificationQueue to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_notification_queue: ^latest_version
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Initialize and Integrate

Initialize the system and integrate the `NotificationOverlay` into your `MaterialApp` using the
`builder` pattern. This enables contextless notification support throughout your app.

```dart
void main() {
  // 1. Initialize configuration
  FlutterNotificationQueue.configure(
    channels: {
      const NotificationChannel(
        name: 'success',
        position: QueuePosition.topCenter,
        defaultColor: Colors.green,
      ),
      // add another channel
      // const NotificationChannel(
      //   name: 'error',
      //   position: QueuePosition.topCenter,
      //   defaultColor: Colors.red,
      // ),
      // ...
    },
    queues: {
      const NotificationQueue(
        position: QueuePosition.topCenter,
        style: FilledQueueStyle(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          opacity: 0.9,
          elevation: 8,
        ),
      ),
      const NotificationQueue(
        position: QueuePosition.bottomCenter,
        style: FlatQueueStyle(),
      ),
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 2. Integrate the overlay builder
      builder: FlutterNotificationQueue.builder,
      home: const MyHomePage(),
    );
  }
}
```

### 2. Display Notifications

Use the `.show()` extension on any `NotificationWidget` to trigger a notification.

```dart
// Simple success notification
const NotificationWidget(
  message: 'Operation completed successfully!',
  title: 'Success',
  channelName: 'success',
).show();

// Error with retry action
NotificationWidget(
  channelName: 'error',
  message: 'Network connection failed. Please try again.',
  title: 'Connection Error',
  action: NotificationAction.button(
    label: 'Retry',
    onPressed: () => retryOperation(),
  ),
).show();
```

## Advanced Configuration

### Animation Control

FlutterNotificationQueue provides powerful built-in transitions and allows for full customization.

#### Standard Transitions
The system tries to be smart about defaults. For example, a `SlideTransitionStrategy` will automatically slide from the correct direction based on the queue's position.

```dart
// Auto-slide from TopCenter
NotificationQueue(position: QueuePosition.topCenter, transition: const SlideTransitionStrategy(), 
)

// Custom curve and duration
NotificationQueue(position: QueuePosition.bottomRight, transition: const SlideTransitionStrategy(
    curve: Curves.elasticOut,
    reverseCurve: Curves.easeOutExpo,
  ),
)
```

#### Customizing Properties
You can override standard properties like the slide offset or initial scale.

```dart
// Slide from the side instead of bottom
NotificationQueue(position: QueuePosition.bottomCenter, transition: const SlideTransitionStrategy(
    slideOffset: Offset(-1, 0), // Slide from left
  ),
)

// Pop-in with custom scale and alignment
NotificationQueue(position: QueuePosition.centerRight, transition: const ScaleTransitionStrategy(
    initialScale: 0.5, // Start/end at 50% size
    alignment: Alignment.centerLeft, // Expand from left
  ),
)
```

#### Custom Animations (Builder)
For complete control, use the `BuilderTransitionStrategy` to define any animation inline.

```dart
NotificationQueue(position: QueuePosition.topCenter, transition: BuilderTransitionStrategy(
    (context, animation, position, child) {
      return RotationTransition(
        turns: animation,
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  ),
)
```

### Custom Queue Styles

```dart
// Filled style with rounded corners
const FilledQueueStyle(
  borderRadius: BorderRadius.all(Radius.circular(12)),
  opacity: 0.9,
  elevation: 8,
)

// Flat style for minimal design
const FlatQueueStyle(
  borderRadius: BorderRadius.zero,
  opacity: 0.8,
  elevation: 2,
)

// Outlined style with borders
const OutlinedQueueStyle(
  borderRadius: BorderRadius.all(Radius.circular(8)),
  opacity: 0.7,
  elevation: 4,
)
```

### Drag and Gesture Behaviors

FNQ uses an **Intent-First interaction model**. Each queue independently declares what a drag or long-press means:

*   **`Dismiss`**: Swipe to dismiss. Configurable zones: `DismissZone.sideEdges` or `DismissZone.naturalDirection`.
*   **`Reorder`**: Drag-to-reorder within the current stack. Live-shifting layout with hysteresis-based slot targeting.
*   **`Relocate`**: Drag to relocate a card to a different queue position (e.g. park to a corner).
*   **`ReorderAndRelocate`**: Reorder within the stack by default; drag past a configurable escape threshold to relocate.
*   **`Disabled`**: No drag interaction.

```dart
NotificationQueue(
  position: QueuePosition.topRight,
  dragBehavior: const Dismiss(),
  longPressDragBehavior: Relocate.to({QueuePosition.bottomRight}),
)

NotificationQueue(
  position: QueuePosition.topLeft,
  dragBehavior: const Reorder(),
  longPressDragBehavior: ReorderAndRelocate.to(
    positions: {QueuePosition.bottomLeft},
  ),
)
```

> [!TIP]
> **Relocation Intelligence**: When you define `Relocate.to({...})` or `ReorderAndRelocate.to(positions: {...})` for a queue, the system automatically:
> 1. Registers sibling queues for all target positions (no need to define them manually).
> 2. Clones all characteristics (style, transition, spacing, maxStackSize) from the source queue to siblings.
> 3. Adds the source position to the target set so notifications can be dragged back home.

### Interaction Details

*   **Reorder with Hysteresis**: When using `Reorder` or `ReorderAndRelocate`, the insertion slot targeting uses a gravity-well algorithm — the active target zone holds a larger magnetic hit area, preventing accidental slot switches from minor pointer wobble during drags.
*   **Selection Reticle**: The current insertion target is highlighted with a glowing border and a subtle background dimming so the drop slot is always visually clear.
*   **Self-Drop Suppression**: Dragging a card back to its original position suppresses all insertion feedback and shows an empty placeholder, making it easy to cancel a reorder.
*   **Hover-to-Pause**: On desktop, hovering over a notification with an active auto-dismiss timer pauses the countdown. The timer resumes when the pointer leaves.
*   **Spring Snapback**: Releasing a drag that did not cross the activation threshold returns the card to its starting position using configurable spring physics (`SpringPhysicsConfiguration`).

### Close Button Behaviors

```dart
const AlwaysVisible() // Always visible
const VisibleOnHover() // Adaptive visibility (shows subtle opacity for touch, fully hidden on desktop until hover)
const Hidden() // Never show close button (gesture/tap-only dismissal)
```

### Architecture Concepts: Channels vs. Queues

FNQ decouples the **what** (styling and intent defaults) from the **where** (spatial layout and gestures):

*   **`NotificationQueue`**: A spatial layout container fixed to a specific `QueuePosition` (e.g. `topLeft`, `bottomCenter`). It governs **behavior and constraints**: entrance/exit animations, max stack sizes, drag-to-relocate destinations, drag-to-dismiss behavior, and stack overflow strategies.
*   **`NotificationChannel`**: A logical category for messages (e.g. `success`, `chat_burst`). It governs **visual defaults**: colors, icons, default priority, and default dismiss durations. Each channel routes to a specific `QueuePosition`.

> [!NOTE]
> When a notification is shown, it maps to a channel. The channel's `position` decides which queue it goes to. If the queue configuration specifies an override for styling/gestures, the queue's configuration takes precedence.

### Notification Grouping (Bundling)

To prevent visual clutter when multiple notifications from the same source arrive rapidly, FNQ supports automatic stacking and group collapse/expansion:

```dart
// Configure queue with grouping behavior
NotificationQueue(
  position: QueuePosition.topCenter,
  groupingBehavior: QueueGroupingBehavior(
    enabled: true,
    maxBeforeGrouping: 3, // Collapse after 3 notifications arrive
    maxStackedLayers: 2, // Number of background card decks to show
    stackStepOffset: 6.0, // Vertical spacing between card decks
    stackScaleMultiplier: 0.05, // Scale reduction per stacked deck
    enableGroupSwipeDismiss: true, // Dismiss the whole group on swipe
    groupDismissThreshold: 0.4, // Swipe displacement ratio to dismiss group
  ),
)
```

Notifications sharing a `groupKey` (which defaults to the `channelName`) will automatically bundle. The user can tap the bundle indicator to expand or collapse it.

### Priority Triage

FNQ evaluates notifications using semantic priorities:

*   `NotificationPriority.low`
*   `NotificationPriority.normal`
*   `NotificationPriority.high`
*   `NotificationPriority.critical`

If a queue is full (exceeds `maxStackSize`) and a higher-priority notification arrives, the priority triage engine automatically evicts the lowest-priority active notification (triggering a `DismissReason.evicted` event) and places the incoming card immediately. Evicted notifications are pushed back to the pending queue to be re-displayed when higher-priority ones clear.

### Backpressure & Overflow Strategy

Configure how a queue handles backpressure when the pending queue limit is reached:

```dart
NotificationQueue(position: QueuePosition.topCenter, maxStackSize: 3,
  maxPendingSize: 10,
  overflowStrategy: QueueOverflowStrategy.discardOldest, // or discardNewest
)
```

*   `QueueOverflowStrategy.discardOldest`: Drops the oldest notification of the lowest priority in the pending queue.
*   `QueueOverflowStrategy.discardNewest`: Rejects the incoming notification immediately if the pending list is full.

### Observability (FnqEvent Stream)

Observe the lifecycle of all notifications in real-time by subscribing to the global event stream. This stream is stable across reconfiguration calls:

```dart
FlutterNotificationQueue.events.listen((event) {
  switch (event) {
    case NotificationQueued(:final notification):
      analytics.track('notif_displayed', id: notification.id);
    case NotificationDismissed(:final notification, :final reason):
      if (reason == DismissReason.timeout) {
        analytics.track('notif_timeout', id: notification.id);
      }
    case NotificationTapped(:final notification, :final behavior):
      analytics.track('notif_tapped', id: notification.id);
    case NotificationRelocated(:final notification, :final from, :final to):
      analytics.track('notif_relocated', from: from.name, to: to.name);
    case NotificationReordered(:final notification, :final toIndex):
    case QueueOverflowed(:final queue, :final dropped):
    // Group-specific events:
    case NotificationGroupExpanded():
    case NotificationGroupCollapsed():
    case NotificationGroupDismissed():
    default:
      break;
  }
});
```

#### Event History Log

You can configure an in-memory, bounded LIFO ring buffer to automatically log past events. Query the cache or clear it on demand:

```dart
// 1. Opt-in by specifying maxHistoryEntries
FlutterNotificationQueue.configure(
  maxHistoryEntries: 50,
);

// 2. Query history with optional filters (channelName, dismissReason, since, limit)
List<FnqEvent> logs = FlutterNotificationQueue.getHistory(
  channelName: 'error',
  limit: 10,
);

// 3. Clear history logs programmatically
FlutterNotificationQueue.clearHistory();
```

> [!TIP]
> **Performance & Disabling**: Set `maxHistoryEntries` to `0` (the default) or less to completely disable history logging. This cancels all internal stream subscriptions and releases the in-memory cache, ensuring **zero runtime CPU or memory overhead**.

#### Dynamic Channel Parking

Dynamic Channel Parking allows notification channels to update their target queues dynamically based on drag-and-drop gestures:

```dart
FlutterNotificationQueue.configure(
  enableDynamicChannelParking: true,
);
```

When enabled:
* If a user drags a notification belonging to a channel (e.g. `info`) from its default position and relocates it into another queue position, the system dynamically updates the routing rule for that channel.
* All future notifications dispatched on the `info` channel will automatically be delivered to the new queue position.


## 🌍 Multi-language Support

FlutterNotificationQueue automatically detects text direction and supports RTL languages:

```dart
// Arabic notification
NotificationWidget(
  title: 'إشعار هام',
  message: 'تم تحديث التطبيق بنجاح. يرجى إعادة تشغيل التطبيق.',
  action: NotificationAction.button(
    label: 'إعادة التشغيل',
    onPressed: () => restartApp(),
  ),
).show();

// Persian notification
NotificationWidget(
  title: 'اطلاعیه',
  message: 'عملیات با موفقیت انجام شد! سیستم آماده استفاده است.',
  action: NotificationAction.button(
    label: 'تأیید',
    onPressed: () => confirmAction(),
  ),
).show();
```

## Platform-Specific Features

### Mobile (iOS/Android)

- Native gesture recognition
- Haptic feedback support
- Safe area integration
- Optimized touch targets

### Web

- Hover effects and interactions
- Keyboard navigation support
- Close button always available
- Responsive breakpoints

### Desktop (Windows/macOS/Linux)

- Mouse drag support
- Keyboard shortcuts
- Window-aware positioning
- High DPI support

## Use Cases

### Success Messages

```dart
NotificationWidget(
  message: 'File saved successfully!',
  title: 'Success',
  channelName: 'success',
  dismissDuration: Duration(seconds: 3),
).show();
```

### Error Handling

```dart
NotificationWidget(
  message: 'Failed to connect to server. Please check your internet connection.',
  title: 'Connection Error',
  channelName: 'error',
  action: NotificationAction.button(
    label: 'Retry',
    onPressed: () => retryConnection(),
  ),
).show();
```

### Warning Notifications

```dart
NotificationWidget(
  message: 'Low storage space detected. Tap to manage.',
  title: 'Storage Warning',
  channelName: 'warning',
  action: NotificationAction.onTap(
    onPressed: () => openStorageSettings(),
  ),
).show();
```

### Info Messages

```dart
NotificationWidget(
  message: 'New features available! Check out our latest update.',
  title: 'App Update',
  channelName: 'info',
  action: NotificationAction.button(
    label: 'Learn More',
    onPressed: () => showUpdateDetails(),
  ),
).show();
```

### Permanent & Pinned Notifications

By default, the notification's auto-dismiss timer is determined by the channel default. You can override it to be permanent (staying on screen indefinitely) in two ways:

1.  **Setting `permanent: true`**: Keep a notification on screen even if the channel has an auto-dismiss duration.
2.  **Setting `dismissDuration: null`**: Backward-compatible way to mark a notification as permanent.

```dart
// Keep a notification on screen indefinitely
NotificationWidget(
  message: 'Ongoing file sync in progress...',
  permanent: true,
).show();
```


## API Reference

### Core Components

- **`FlutterNotificationQueue`**: The primary entry point.
    - `configure()`: Configures global queues and channels.
    - `builder`: Integration hook for `MaterialApp.builder`.
    - `events`: The stable global broadcast stream of lifecycle events.
- **`NotificationWidget`**: The main configuration for individual notifications.
    - `permanent`: Keep notification on screen regardless of channel defaults.
- **`NotificationChannel`**: Defines shared behavior and styling for groups of notifications.
    - `standardChannels()`: Returns a set of standard channels (success, error, info, warning).
    - `successChannel()`, `errorChannel()`, etc.: Factory methods for common channel types.
- **`NotificationQueue`**: Manages the lifecycle and rendering constraints of a specific screen
  position.
    - `NotificationQueue()`: Default constructor for creating a standard queue configuration.
- **`NotificationAction`**: Definable user interactions (buttons, taps, gestures).

### Queue Positions

- `QueuePosition.topLeft`
- `QueuePosition.topCenter`
- `QueuePosition.topRight`
- `QueuePosition.centerLeft`
- `QueuePosition.centerRight`
- `QueuePosition.bottomLeft`
- `QueuePosition.bottomCenter`
- `QueuePosition.bottomRight`

### Action Types

```dart
// Button action
NotificationAction.button(
  label: 'Action Label',
  onPressed: () => handleAction(),
);

// Tap action
NotificationAction.onTap(
  onPressed: () => handleTap(),
);
```

## Customization Examples

### Custom Notification Builder

```dart
NotificationWidget(
  message: 'Custom styled notification',
  builder: (context, notification) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.purple, Colors.blue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.star, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                notification.message,
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    ),
  ),
).show();
```

### Custom Queue Indicator

```dart
NotificationQueue(position: QueuePosition.topCenter, queueIndicatorBuilder: (context, count, config) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.red,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      '+$count',
      style: const TextStyle(color: Colors.white, fontSize: 12),
    ),
  ),
)
```

## Performance Features

- **Efficient Rendering**: Single overlay for all notifications
- **Memory Management**: Automatic cleanup and disposal
- **Lazy Loading**: Notifications built only when needed
- **Gesture Optimization**: Smooth 60fps interactions
- **Queue Efficiency**: O(1) queue operations

## 📈 Migration Guide

### From 0.1.x to 0.2.0

Version 0.2.0 consolidates the API and removes position-specific queue subclasses to simplify integration.

**Key Changes:**

*   **Subclass Removal / Unified `NotificationQueue`**: All position-specific subclasses of `NotificationQueue` (e.g. `TopLeftQueue`, `TopCenterQueue`, `BottomCenterQueue`) have been removed. Use the single concrete `NotificationQueue` class directly and specify its `position` parameter.
    
    ```diff
    // Old (deprecated in 0.1.0, removed in 0.2.0)
    -const TopLeftQueue(
    -  style: FlatQueueStyle(),
    -)
    
    // New (v0.2.0+)
    +const NotificationQueue(
    +  position: QueuePosition.topLeft,
    +  style: FlatQueueStyle(),
    +)
    ```

*   **Simplified `QueuePosition` Helpers**: `QueuePosition.generateQueue(...)` and `QueuePosition.generateQueueFrom(...)` now directly construct and return a concrete `NotificationQueue` instance rather than a subclass.

*   **Internal State Decoupling**: Configuration blueprints in `NotificationWidget` are now separated from active runtime state (dismiss timers, pinned states, priority) using the internal `NotificationEntry` class, preventing any `GlobalKey` conflicts.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open
an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for
details.

