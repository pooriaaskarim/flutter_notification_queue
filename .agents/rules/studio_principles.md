# Rule: NFQ Studio Example & Architecture Principles

When modifying, extending, or maintaining the `example/` package (NFQ Studio) in this repository, strictly adhere to the following principles:

## 1. Architectural Isomorphism (1:1 API Fidelity)
- Never create synthetic abstractions or wrapper concepts that do not exist in the public `flutter_notification_queue` API (e.g. no "templates").
- Every studio UI control must map directly to real constructor parameters on `NotificationController`, `NotificationQueue`, `NotificationChannel`, `QueueStyle`, `NotificationThemeData`, or `AppNotification`.

## 2. The Two-Gear Separation
- **Gear 1: Style Anatomy (`QueueStyle`)**: Geometry, borders, opacity, layout archetype (`FilledQueueStyle`, `OutlinedQueueStyle`, `FlatQueueStyle`).
- **Gear 2: Theme Chromatics (`NotificationThemeData`)**: Color tokens (`accentColor`, `backgroundColor`, `foregroundColor`, `borderRadius`, `elevation`).
- Never conflate them or allow style changes to mutate color tokens or vice-versa.

## 3. Cause-and-Effect Proximity (Zero Feedback Distance)
- Never use static dummy preview cards where real notifications can be spawned.
- Every trigger must call `setupBloc.controller.show(...)` and exercise real overlay mechanics.
- All lifecycle events must stream into `EventLogPanel` in real time.

## 4. Production-Grade Code Provenance
- Code generated in `CodeEditorPanel` must be 100% copy-pasteable into production apps.
- Provide scoped views: `Full Setup` (main.dart), `Dispatch Only` (controller.show), `Channels Only`, and `Queues Only`.

## 5. Mobile Ergonomics & Screen Budget
- On narrow screens (`maxWidth <= 1000`), use a single unified 56px AppBar with compact `⚡ FIRE` button and modal presets launcher (`QuickFireCockpit.showModal(context)`).
- Never render duplicate triggers (do not add a floating action button when an omnipresent header is present).
- In `ConfiguratorPanel`, use mobile sub-tabs (`Queues`, `Channels`, `Draft`, `Scenarios`, `Options`) to avoid monolithic 3,000px scrolling lists.
- Prevent any `RenderFlex` overflow down to 360px viewport widths.

## 6. Zero Lints & Full Test Coverage
- Always ensure `dart analyze .` returns 0 issues in both root and example.
- Keep all unit and widget tests green (`flutter test`).
