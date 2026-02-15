# Notification Lifecycle

Understanding the lifecycle of a notification is essential for debugging and advanced customization.

## The 5 Stages

### 1. Creation (`NotificationWidget.show`)
- The user requests a notification.
- The request is validated against the `ConfigurationManager`.
- If valid, a `NotificationWidget` instance is created.

### 2. Enqueueing
- The widget is passed to the `QueueCoordinator`.
- The Coordinator checks if the target queue is active (mounted).
  - **If Active**: The notification is added directly to the existing `QueueWidget`.
  - **If Inactive**: The notification is buffered, and the `QueueWidget` is mounted.

### 3. Mounting & Display
- The `QueueWidget` initializes.
- It consumes any buffered notifications from the Coordinator.
- The notification enters via an **Entrance Animation** (slide/fade).

### 4. Interaction (Active State)
- The notification sits in the queue.
- Users can interact (tap, dismiss, drag).
- **Auto-Dismiss**: If configured, a timer counts down.

### 5. Dismissal & Cleanup
- **Trigger**: Timer ends, user swipes, or programmatic dismissal.
- **Exit Animation**: The notification animates out.
- **Garbage Collection**: Once the animation completes, the widget is removed from the tree.
- **Queue Unmount**: If the queue becomes empty, the `QueueWidget` itself unmounts to free resources.
