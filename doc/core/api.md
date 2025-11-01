# FNQ — API Surface

## 🧭 Philosophy
FNQ follows a philosophy of **Progressive Disclosure**. Simple use cases require almost zero code, while complex configurations are available through descriptive declarative parameters.

---

## 💎 Public API Surface

### 1. Integration: `FlutterNotificationQueue`
The primary entry point.

| Member | Usage |
|---|---|
| `initialize()` | Global configuration (Mandatory). Call in `main()`. |
| `builder()` | Integration with `MaterialApp.builder`. Requires prior initialization. |

### 2. Usage: `NotificationWidget`
The primary interaction point.

| Member | Usage |
|---|---|
| Constructor | Create a notification with a `message`. Auto-resolves its own channel/queue. |
| `show()` | Enqueue and display the notification. |
| `dismiss()` | Perform an animated dismissal and removal from queue. |
| `relocateTo()` | Move the notification to a different `QueuePosition` (e.g., Drag & Drop). |

### 3. Configuration: `NotificationQueue` & `NotificationChannel`
Declarative units of organization.

-   **Queues**: Define position-specific behavior (Max stack, drag behavior, style).
-   **Channels**: Define semantic categories (Success, Error) with shared visual overrides.

---

## 🔒 Internal Components (Hidden)
The following core components are **explicitly hidden** from the public API to ensure structural integrity:

-   `ConfigurationManager`: Managed via `initialize()`.
-   `QueueCoordinator`: Internal lifecycle bridge.
-   `NotificationOverlay`: Hosted via `builder()`. Exposed only for manual wrapper usage.
-   `QueueWidget`: Internal rendering implementation.

---

## 🛠️ Design Rules
1.  **Immutability**: Notification configurations (Channels/Queues) should be immutable after initialization.
2.  **No Contextual Leaks**: Showing a notification does not require a `BuildContext` (handled by the singleton hierarchy).
3.  **Self-Regulating**: The API surface does not provide "Close All" or manual overlay toggles; these are automated by the system lifecycle.
