# Core Engine Overview

The **Core Engine** is the central nervous system of FNQ. It replaces the legacy singleton manager with a modular, testable architecture.

## Components

### 1. FlutterNotificationQueue (The Facade)
- **Role**: Public API Facade.
- **Responsibility**: Provides static methods for initialization and widget integration. It shields the internal machinery from the developer.
- **Key Methods**:
  - `initialize()`: Sets up the global configuration.
  - `builder()`: Integrates the overlay into `MaterialApp`.

### 2. ConfigurationManager (Configuration Registry)
- **Role**: Configuration Registry.
- **Responsibility**: Stores and retrieves `NotificationQueue` and `NotificationChannel` definitions.
- **Behavior**:
  - Validates configuration on startup.
  - Provides fallback logic (Standard Defaults) when requested items are missing.
  - Immutable after initialization.

### 3. QueueCoordinator (State Management)
- **Role**: State & Lifecycle Management.
- **Responsibility**: Connects logical queues to the visual overlay.
- **Behavior**:
  - Tracks which queues are active (have notifications).
  - Manages the `OverlayPortalController`.
  - Routes notifications to the correct `QueueWidget`.

### 4. NotificationOverlay (Rendering Surface)
- **Role**: Rendering Surface.
- **Responsibility**: Inserts the notification stack into the Flutter widget tree.
- **Behavior**:
  - Uses `OverlayPortal` for performant rendering over other widgets.
  - Supports contextless operation via `MaterialApp.builder`.
