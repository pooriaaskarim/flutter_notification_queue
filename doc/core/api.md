# API Reference

This document outlines the public API surface of FNQ.

## Philosophy
FNQ follows a philosophy of **Progressive Disclosure**. Simple use cases require minimal code, while complex configurations are available through descriptive declarative parameters.

## Public Components

### 1. FlutterNotificationQueue
The primary entry point and facade.

| Method | Description |
|---|---|
| `initialize()` | Global setup. Must be called in `main()`. Accepts `queues` and `channels`. |
| `builder()` | Integration method for `MaterialApp.builder`. Wraps the app in the required overlay. |
| `reset()` | **Testing Only**. Resets the singleton state. |

### 2. NotificationWidget
The main artifact for displaying notifications.

| Member | Description |
|---|---|
| `Constructor` | Creates a definition. Requires `message`. Optional `title`, `channelName`, `id`. |
| `show()` | Enqueues the notification. Does **not** require a `BuildContext`. |
| `dismiss()` | Programmatically dismisses the notification. |
| `relocateTo()` | Moves the active notification to a different queue position (e.g., during drag). |

### 3. Queue Configuration
Declarative configuration objects for layout and behavior. Use concrete classes for customization.

| Property | Description |
|---|---|
| `style` | Layout template (Filled, Flat, Outlined). |
| `behavior` | Interaction strategy (`Dismiss`, `Relocate`, `Disabled`). |
| `transition` | Entrance/Exit animation (`Slide`, `Scale`, `Fade`). |
| `maxStackSize` | Maximum concurrent notifications. |
| `spacing` | Gap between notifications. |

### 4. Behaviors
Determines how users interact with notifications.

| Behavior | Effect |
|---|---|
| `Dismiss` | Swipe to remove (directional). |
| `Relocate` | Drag to move between queues. |
| `Disabled` | Gestures are ignored. |

### 5. NotificationChannel
Semantic categories for notifications.

| Property | Description |
|---|---|
| `name` | Unique string ID (e.g., 'success'). |
| `defaultColor` | Base color for notifications in this channel. |
| `defaultIcon` | Icon widget to use if the individual notification doesn't provide one. |
| `position` | Optional override to force all channel notifications to a specific queue. |

## Internal Components (Hidden)
These components are part of the engine and are not exposed for public use to ensure stability.

- **ConfigurationManager**: Validates and stores immutable config.
- **QueueCoordinator**: Manages runtime state and the OverlayPortal.
- **NotificationOverlay**: The actual rendering surface.
