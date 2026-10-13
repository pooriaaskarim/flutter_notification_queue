# NFQ Studio — Design & Architectural Principles

This document defines the core principles, mental models, and architectural guardrails that govern the `flutter_notification_queue` showcase workbench (**NFQ Studio**).

---

## 1. Mission & Mental Model

An open-source library example app is not merely a debug panel—**it is the developer’s primary mental-model engine**. 

A developer exploring the studio must intuitively understand how the library operates within 60 seconds.

### The NFQ Mental Model Chain

```
 ┌──────────────────────────────────────────────────────────────┐
 │                  THE NFQ ARCHITECTURAL PIPELINE              │
 │                                                              │
 │   1. DISPATCH                   2. ROUTE          3. DISPLAY │
 │  ┌─────────────────┐           ┌─────────┐       ┌─────────┐ │
 │  │ AppNotification ├─(channel)─► Channel ├──(pos)►  Queue  │ │
 │  └─────────────────┘           └─────────┘       └─────────┘ │
 └──────────────────────────────────────────────────────────────┘
```

1. **`AppNotification` (The Payload)**:
   - Contains content (`title`, `message`), priorities (`high`, `normal`, `low`), optional duration (`dismissDuration`), permanent flag, and optional local chromatic override (`theme`).
2. **`NotificationChannel` (The Routing Engine)**:
   - Categorizes alerts by domain (`info`, `billing`, `orders`, `security`).
   - Declares the default target `QueuePosition` and parking policies.
   - Supplies shared channel theme and archetype defaults.
3. **`NotificationQueue` (The Spatial Container)**:
   - Anchored to one of the 9 screen positions (`QueuePosition.topLeft`, `topCenter`, etc.).
   - Governs stack capacity (`maxStackSize`), physics, spacing, margins, and gesture behaviors (`Dismiss`, `Snooze`, `Pin`, `Relocate`).
4. **`NotificationController` & `NotificationScope` (The Surface Owner)**:
   - `NotificationController` owns the reactive state and contextless dispatch API.
   - `NotificationScope` attaches to the widget tree and manages overlay portals.

---

## 2. The 5 Core Principles

### Principle I: Architectural Isomorphism (1:1 API Fidelity)
*The studio must reflect the public API structure—never invent synthetic abstractions.*
- If a concept does not exist in the public API (e.g., there is no concept of a "Template"), the studio must not invent it.
- Every studio control must correspond 1:1 to a real constructor parameter on `NotificationController`, `NotificationQueue`, `NotificationChannel`, `QueueStyle`, `NotificationThemeData`, or `AppNotification`.
- Developers must never have to "unlearn" studio vocabulary when writing production code.

### Principle II: The Two-Gear Separation (Anatomy vs. Chromatics)
*Structural layout and chromatic skinning must remain strictly decoupled.*
- **Gear 1: Style Anatomy (`QueueStyle`)**:
  - Controls geometry, borders, opacity, layout archetypes (`FilledQueueStyle`, `OutlinedQueueStyle`, `FlatQueueStyle`).
  - Set at the queue level (baseline) or overridden at channel scope (semantic domain archetype).
- **Gear 2: Theme Chromatics (`NotificationThemeData`)**:
  - Controls color tokens: `accentColor`, `backgroundColor`, `foregroundColor`, `borderRadius`, `elevation`.
  - Driven by the channel or inherited globally, with one-off chromatic overrides supported on `AppNotification`.
- The Studio must enforce this separation: changing color palettes never resets layout geometry, and switching archetypes never breaks color tokens.

### Principle III: Cause-and-Effect Proximity (Zero Feedback Distance)
*Actions must produce immediate, tangible physical manifestations on screen.*
- The Studio must never use static mocked cards where real notifications can be fired.
- Toggling a gesture (e.g., `DragBehavior: Snooze(5s)`) must allow the user to immediately swipe the spawned notification, watch it disappear, count down in the live Event Log, and resurface.
- Learning occurs when developers physically feel the gesture physics and observe corresponding lifecycle events in real time.

### Principle IV: Production-Grade Code Provenance (Copy-Paste Fidelity)
*Generated code must be ready for production `lib/` without cleanup.*
- The code editor must produce clean, idiomatic, lint-free Dart matching current best practices.
- Code should be segmented by architectural role:
  - **`Full Setup`**: Complete `NotificationScope` mounting in `main.dart`.
  - **`Dispatch Only`**: Clean `controller.show(...)` contextless call for feature services and BLoCs.
  - **`Channels Only`**: Standalone channel configuration tables.
  - **`Queues Only`**: Standalone spatial queue definitions.

### Principle V: Progressive Disclosure & Responsive Ergonomics
*Simple out of the box, deeply configurable on demand.*
- Essential actions (fire draft, quick presets) must be accessible from anywhere in the app without scrolling.
- Avoid the "waterfall of sliders": group configuration controls into focused cognitive concerns:
  - *Anatomy & Bounds*
  - *Gestures & Interactions*
  - *Grouping & Advanced*
- **Mobile First-Class Citizen**:
  - Single unified 56px AppBar on narrow viewports; avoid double-decker stacked toolbars.
  - No redundant triggers (e.g., never pair an omnipresent header with a floating action button).
  - Use native bottom sheets for presets on mobile devices.
  - Sub-segmented tabs (`Queues`, `Channels`, `Draft`, `Scenarios`) prevent endless 3,000px scrolling.

---

## 3. Engineering & Quality Guardrails

1. **Zero Mocking Policy**:
   All UI triggers must route through `SetupBloc.controller` and the active `NotificationScope`.
2. **0-Lint Invariant**:
   `dart analyze .` in both root and example packages must return 0 issues at all times.
3. **Test Integrity**:
   Every model mapping, code generator scope, and widget interaction in the studio must be verified with automated widget and unit tests.
4. **Layout Safety**:
   Every toolbar, row, and card must be safe against narrow viewport constraints (tested down to 360px–500px widths).
