# Architecture & API v1.0 Proposal: Evolution & Blueprint

## 1. Executive Summary

As the Flutter Notification Queue package matures towards a stable v1.0 release, it must transition from a functional, prototype-style architecture to a robust, idiomatic Flutter package. This document chronicles the architectural iterations, the flaws identified in each, the user-driven critiques, and the final v1.0 structural blueprint.

Our goal is an architecture that solves multi-tenant, multi-window, and sandboxed rendering *by design*, rather than through symptomatic workarounds.

---

## 2. The Original Architecture (v0.x)

The original implementation prioritized extreme convenience over structural scalability.

### How it worked:
- **Initialization:** A static `FlutterNotificationQueue.configure(queues: {...})` call injected a global `OverlayPortal` into the application.
- **Dispatching:** A widget acted as a command: `NotificationWidget(id: '123', channel: ...).show()`.
- **The Core Engine:** A singleton `QueueCoordinator` managed everything: configuration, event streaming, `OverlayPortal` state, and grouping.

### The Flaws:
- **Single-Tenant Constraint:** Because it relied on static singletons and a global `OverlayPortal`, it was impossible to run two independent queues (e.g., in a desktop multi-window app, or in isolated widget tests).
- **The Active Widget Anti-Pattern:** Flutter Widgets are immutable blueprints. Forcing a Widget to hold a `.show()` method conflated data intent with visual representation.

---

## 3. Iteration 1: The "Fallback" Proposal (Rejected)

To solve the multi-tenant constraint, an initial redesign (Phase 4 Draft) was proposed. 

### The Proposal:
- Introduce a `NotificationQueueScope(coordinator: customCoordinator)` InheritedWidget.
- Modify `NotificationWidget.show(BuildContext? context)` to accept a context.
- **The Logic:** When `.show()` is called, it tries `NotificationQueueScope.maybeOf(context)`. If a scope is found, it uses the local coordinator. If null, it falls back silently to the global singleton coordinator.
- **Event Forwarding:** A boolean flag `forwardToGlobalEvents` was proposed to push local events up to the global event stream.

### The Critique (Why it failed):
As correctly pointed out in the architectural review, this solution was **"immature and very shallow."** 
It attempted to patch a structurally coupled system with symptomatic workarounds:
1. **Implicit Fallbacks are Dangerous:** A structurally sound system does not rely on invisible "try local, then global" guessing games.
2. **Context Friction in BLoC:** Triggering notifications usually happens deep in service logic (BLoCs/Controllers) where `BuildContext` is unavailable. This design forced developers to drill context just for a fallback check.
3. **Lifecycle Leaks:** Relying on a UI widget (`NotificationQueueScope`) to trigger `autoDispose` on a non-UI `QueueCoordinator` created a leaky lifecycle abstraction.

*Conclusion: A well-designed system solves structural problems by design, not by occasional workarounds.*

---

## 4. Iteration 2: The Structural Redesign (Dispatcher/Surface)

To address the critique, the engine was fundamentally restructured to separate **Intent** (routing) from **Rendering** (the overlay lifecycle).

### The Proposal:
Replace the monolithic `QueueCoordinator` with two distinct concepts:
1. **`NotificationDispatcher` (Logical Router):** A pure Dart object responsible solely for holding configuration and routing events. No UI dependencies.
2. **`NotificationSurface` (Render Node):** A Flutter Widget that listens to a dispatcher and mounts the `OverlayPortal`.

### The Benefits:
- **No BuildContext Needed for Dispatch:** BLoCs simply call `myDispatcher.dispatch(payload)`. 
- **100% Isolation:** A Desktop Window 2 simply gets its own `NotificationDispatcher`. No `forwardToGlobalEvents` flag is needed; streams are naturally isolated to their dispatcher.
- **Clean Lifecycle:** When a window closes, Flutter unmounts the `NotificationSurface`, destroying the `OverlayPortal` via standard Flutter `dispose()`. No custom memory management required.

---

## 5. Iteration 3: The Public API Maturation (v1.0 Blueprint)

With the internal engine fixed (Iteration 2), the final iteration tackles the external developer experience, aligning it with Flutter's best practices (`go_router`, `provider`).

### The Blueprint:

#### 1. The Request (Data, not UI)
We rename `NotificationWidget` to `NotificationRequest` (or `NotificationData`). It represents the *payload* of intent, removing the "Active Widget" anti-pattern.
```dart
final request = NotificationRequest(
  id: 'order_123',
  channel: NotificationChannel.success,
  content: NotificationContent.standard(title: 'Success!', message: 'Saved.'),
);
```

#### 2. The Controller
Instead of a static `configure()`, the developer creates an explicit controller (which wraps the internal Dispatcher).
```dart
final notificationController = NotificationController(
  queues: { NotificationQueue(position: QueuePosition.topCenter) },
  channels: { NotificationChannel.success },
);
```

#### 3. Explicit Tree Injection
Magical global overlays are removed. Developers inject the engine explicitly using Flutter's standard `builder` pattern:
```dart
MaterialApp(
  builder: (context, child) => NotificationQueueScope(
    controller: notificationController,
    child: child!,
  ),
);
```

#### 4. Idiomatic Dispatching
Triggering notifications aligns with how developers use `ScaffoldMessenger` or `Navigator`.
```dart
// Context-based (Idiomatic UI)
NotificationQueueScope.of(context).show(request);

// Contextless (For BLoC/Services)
notificationController.show(request);
```

---

## 6. Conclusion

By chronicling this evolution, we arrive at an architecture that is not just a patch over a prototype, but a fundamentally scalable, idiomatic Flutter package. It removes static magic, separates UI from data, explicitly manages rendering lifecycles, and provides a predictable DX that mirrors the ecosystem's most respected packages.
