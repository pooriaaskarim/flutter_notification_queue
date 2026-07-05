# FNQ Release Stabilization Plan

> **Target**: `flutter_notification_queue` v1.0 public release on pub.dev
> **Current version**: 0.5.0
> **Scope**: UX/DX critique, real-world use case validation, and platform performance hardening.
> **Baseline**: `dart analyze` — no issues. `flutter test` — 177/177 passed.

---

## Overview

This plan is split into two major tracks that run in phases:

| Track | Focus | Deliverable | Status |
|---|---|---|---|
| **Track A — Critique** | UX + DX stability & practicality | [UX & DX Critique Report](ux_dx_critique.md) | ✅ Complete |
| **Track B — Performance** | Platform perf on all supported targets | [Performance Audit](performance_audit.md) | ✅ B1–B3 Complete, B4 Pending |

---

## Track A — UX & DX Critique

The goal is to identify friction, confusion, and gaps by simulating how real teams integrate FNQ.

### Phase A1 — Real-World Use Case Research

Research common in-app notification patterns across popular app categories to build a realistic test matrix.

**Deliverable**: A use-case matrix that maps common real-world scenarios to FNQ's API surface.

#### Step A1.1 — Identify Target App Archetypes

Research the following app categories and document their typical notification requirements:

| Archetype | Typical Notifications |
|---|---|
| E-commerce | Order status, flash sale, cart abandonment, payment |
| Productivity / SaaS | Task assigned, comment received, sync status, errors |
| Social / Chat | New message, reaction, mention, follow |
| Finance / Banking | Transaction alerts, security warnings, rate changes |
| Health / Fitness | Workout reminder, goal reached, sync complete |
| Developer Tools | Build status, CI results, deploy alerts |

**Research sources:**
- pub.dev: audit competitor packages (`flutter_local_notifications`, `overlay_support`, `another_flushbar`, `oktoast`)
- GitHub issues on competing packages (what users ask for)
- Flutter community Discord & Reddit — what notification patterns are most discussed
- Apple HIG & Material 3 guidelines for notification UX standards

#### Step A1.2 — Build the Scenario Playbook

For each archetype, document: the notification type, required FNQ configuration, and expected behavior.

Example entries:

| Scenario | Config Required | Expected Behavior |
|---|---|---|
| "Payment successful" toast | `dismissDuration: 3s`, `channelName: 'success'`, top-center | Auto-dismiss, no action needed |
| "Network error — Retry" | `TapToAct`, no auto-dismiss, `priority: high` | Stays until tapped; retry fires |
| "New message" with badge | `maxStackSize: 3` + queue overflow badge | Queues 3, overflows to `+N` badge |
| "File sync in progress" | `dismissDuration: null` (permanent), `Pin` behavior | Stays pinned, progress bar or spinner |
| "Critical security alert" | `priority: critical`, swipe disabled | Cannot be swiped away; only action-dismissible |
| Chat message burst (10/sec) | `maxPendingSize`, `discardOldest` | Backpressure kicks in, no memory leak |

---

### Phase A2 — UX Critique

Walk through each scenario in the playbook hands-on, then score friction points.

#### Step A2.1 — Zero-Config Onboarding Audit

**Test**: Integrate FNQ from scratch in a blank Flutter app with **zero prior knowledge** of the API.

| Checkpoint | Pass Criteria |
|---|---|
| Installation & setup | README accurately describes setup; no undocumented steps |
| First notification fires | `FlutterNotificationQueue.builder` + `.show()` works without `configure()` |
| Default visual is acceptable | Defaults look reasonable without any custom config |
| Lazy init behavior | `configure()` called lazily on first access — is the warning clear in the logs? |

> [!WARNING]
> **Known gap**: The README still references `initialize()` in the quick-start but the actual API uses `configure()`. This is a DX regression — migrate the docs.

#### Step A2.2 — API Ergonomics Critique

Systematically review the public API surface (`lib/flutter_notification_queue.dart`) for:

1. **Naming consistency**: Are names intuitive and consistent? (`configure` vs `initialize`, `show()` vs queue?)
2. **Missing factory shortcuts**: Does the API make the 80% case easy? Are common patterns ergonomic?
3. **Error messages**: What happens when misconfigured? Are assertions and exceptions clear?
4. **Builder boilerplate**: Is `MaterialApp.builder` the cleanest possible integration point?
5. **Channel vs Queue mental model**: Is the distinction between `NotificationChannel` and `NotificationQueue` clear to a new user? (Research finding: this is a common confusion point in competing packages)

**Specific API points to audit:**

| API Point | Question |
|---|---|
| `NotificationWidget.show()` | Is calling `.show()` on a const widget surprising? Does it feel right? |
| `channelName: 'success'` (string) | Should this be typed / validated at compile time rather than a raw string? |
| `QueuePosition` enum | 9 positions — is `centerLeft`/`centerRight` documented well enough? |
| `Relocate.to({...})` auto-sibling generation | Is the magic documented clearly? Could it surprise users? |
| `NotificationQueue.defaultQueue()` | Is the default position (topCenter) appropriate? |
| `TapBehavior` sealed class hierarchy | Are `TapToDismiss`, `TapToExpand`, `TapToAct`, `TapDisabled` names intuitive? |
| `FnqEvent` stream | Is the stream lifecycle (broadcast, no close) clearly documented? |
| `captureFlutterErrors` flag | Should this be opt-in or opt-out? Is the default correct? |

#### Step A2.3 — Real Integration Critique (Simulated)

Build three mini-apps simulating real integrations:

1. **Basic toast app**: A simple e-commerce confirmation screen that fires success/error notifications.
2. **Pinned + dismissible mix**: A productivity app with one permanent pinned notification (sync status) and ephemeral success toasts.
3. **High-frequency burst**: A social app mock that sends 20 notifications in 2 seconds to stress-test backpressure, queue overflow, and visual clarity.

Record friction points (anything requiring >30 seconds of head-scratching from a typical Flutter dev).

#### Step A2.4 — DX Tooling Critique

| DX Area | Questions |
|---|---|
| **Logd integration** | Are FNQ log messages actionable? Noisy? Is `logLevel` documented? |
| **Assert messages** | Do validation errors (e.g., `Hidden` close + no dismiss gesture) point to the cause clearly? |
| **`@visibleForTesting reset()`** | Is the test reset pattern documented? Is it discoverable? |
| **No hot-reload issues** | Does state survive hot-reload correctly? Does `configure()` re-running cause duplicate overlays? |
| **IDE autocomplete** | Are all classes well-documented with dartdoc? Do factory constructors show up cleanly? |
| **Error propagation** | When a bad `channelName` is used, what happens? Silently dropped? Exception? Logged? |

---

### Phase A3 — DX Stability Audit

This phase checks whether the API contracts are stable, consistent, and production-safe.

#### Step A3.1 — Public API Contract Review

Walk the exported symbols in `lib/flutter_notification_queue.dart` and answer:

- Is every exported symbol intentional?
- Are internal helpers properly hidden (`hide` combinators)?
- Are any types over-exposed (too many details leaked)?
- Are any necessary types under-exposed (missing from exports)?

**Known issue to investigate**: `QueueCoordinator` is exported. Is this intentional? Should it be `@internal`?

#### Step A3.2 — Lifecycle & State Consistency

| Scenario | Expected | Needs Verification |
|---|---|---|
| `configure()` called twice | Preserves coordinator, replaces config | ✅ |
| `reset()` called mid-display | Cleans up overlay, no orphaned entries | Needs test |
| App background → foreground | Notifications still visible, timers resumed | Needs test |
| Hot-restart in debug mode | Clean slate, no duplicate overlays | Needs manual test |
| `Navigator.push` overlay stack | FNQ overlay survives route changes | Needs test |

#### Step A3.3 — Edge Case & Error Path Inventory

| Edge Case | Handling Today | Action |
|---|---|---|
| `show()` before `builder` in tree | Queued, displayed when overlay mounts | Verify timing |
| `channelName` not found | Unknown — needs audit | Add clear assert/log |
| Duplicate notification IDs | Unknown — needs audit | Document behavior |
| `dismissDuration: Duration.zero` | Likely immediate dismiss — verify | Add test |
| Notification with `null` message AND `null` builder | Likely renders empty widget | Add defensive assert |
| Relocate to own position | Handled (self-target included automatically) | Verify with test |
| `maxStackSize: 0` | Unknown | Add validation |

---

### Phase A4 — Documentation Audit

| Doc Area | Gap Found | Action |
|---|---|---|
| README Quick Start | Uses `initialize()` — wrong API name | Fix to `configure()` |
| README: `NotificationChannel` vs `NotificationQueue` | No conceptual explanation | Add an "Architecture" section |
| README: Gesture behaviors | Missing `TapBehavior` docs | Add section |
| README: `FnqEvent` stream | Missing docs entirely | Add observability section |
| README: Overflow / backpressure | Missing | Add section |
| API docs (dartdoc) | Coverage unknown | Run `dart doc` and audit |
| Migration guide | Only 0.3→0.4, missing 0.4→0.5 | Write 0.4→0.5 migration section |
| CHANGELOG 0.5.0 | Detailed; good | — |

---

## Track B — Performance

The goal is to quantify and fix performance regressions on each supported platform under realistic load.

### Phase B1 — Platform Support Baseline

Establish what "supported" means for FNQ at v1.0:

| Platform | Support Level | Notes |
|---|---|---|
| Android | Primary | Haptics, safe area, touch gestures |
| iOS | Primary | Haptics, safe area, touch gestures |
| Web (Chrome/Firefox) | Secondary | Hover effects, no haptics |
| macOS | Secondary | Mouse drag, keyboard |
| Linux | Secondary | Mouse drag |
| Windows | Secondary | Mouse drag |

### Phase B2 — Performance Benchmarks

Define measurable, reproducible benchmark scenarios using Flutter DevTools and the performance overlay.

#### Step B2.1 — Frame Budget Targets

| Scenario | Target FPS | Acceptable Drop |
|---|---|---|
| Idle (notifications on screen, no interaction) | 60fps | ≤1 dropped frame/sec |
| Notification entry animation | 60fps | ≤2 dropped frames |
| Drag-to-dismiss gesture | 60fps (120 on supported) | ≤3 dropped frames |
| Reorder drag at 120Hz input | 120fps | ≤5 dropped frames |
| Notification burst (10 in 1sec) | 60fps | ≤5 dropped frames |

#### Step B2.2 — Memory Benchmarks

| Scenario | Target |
|---|---|
| 100 notifications shown & dismissed sequentially | No memory growth after GC |
| Permanent notification (pinned 10min) | Flat memory profile |
| Notification burst with overflow discard | Bounded memory (respects `maxPendingSize`) |
| After `reset()` | Memory returns to baseline |

#### Step B2.3 — Benchmark Methodology

1. Run `flutter run --profile` on a mid-tier Android device (e.g., Pixel 4a or equivalent).
2. Use `flutter_driver` or Integration Test to automate notification firing.
3. Capture frame timings via DevTools Timeline.
4. Compare against baseline (blank app doing nothing).

### Phase B3 — Identified Performance Risk Areas

Based on the KI architecture review and lessons learned, these areas are the highest risk:

#### Risk 1 — `ValueListenableBuilder` Propagation at 120Hz

- **Risk**: If `activeDragPointer` is not properly isolated, drag updates can bleed into unrelated widget rebuilds.
- **Audit**: Profile rebuild count with `debugProfileBuildsEnabled = true` during an active reorder drag.
- **Fix**: Verify `RepaintBoundary` placement around notification cards and feedback overlays.

#### Risk 2 — Gesture FSM State Transitions Under Load

- **Risk**: With multiple queues active simultaneously (e.g., 3 queues, each with 3 cards), the FSM processes gesture events across all active instances. Verify no O(n²) scaling.
- **Audit**: Run the burst scenario with all 9 positions active.
- **Fix**: Ensure each queue's gesture state is fully isolated.

#### Risk 3 — Overlay Stack Depth

- **Risk**: FNQ uses `MaterialApp.builder` to insert a single `NotificationOverlay`. If the overlay inserts deeply nested widgets per notification, the render tree depth grows proportionally.
- **Audit**: Inspect widget tree depth in Flutter DevTools inspector during peak load.
- **Fix**: Flatten widget trees where possible; use `const` constructors.

#### Risk 4 — Spring Physics CPU Load

- **Risk**: Continuous `SpringSimulation` tickers during drag gestures may consume excessive CPU on lower-tier devices, causing thermal throttling over extended sessions.
- **Audit**: Monitor CPU usage during a 60-second continuous drag test on a mid-tier Android device.
- **Fix**: Ensure spring simulations are properly disposed; gate physics on gesture activity state.

#### Risk 5 — `FnqEvent` Stream Listener Leaks

- **Risk**: The broadcast stream has no closing mechanism. If consumers don't cancel subscriptions, this is a silent memory leak.
- **Audit**: Instrument stream listener count. Check if `QueueCoordinator.detach()` properly closes the stream controller.
- **Fix**: Document the listener cancellation pattern clearly. Add a `Finalizer` or warn in dartdoc.

#### Risk 6 — Animation Controller Disposal

- **Risk**: `QueueWidget` manages one `AnimationController` per notification card. On high-frequency bursts, rapid mount/unmount cycles may miss disposal.
- **Audit**: Run the burst scenario and check for `AnimationController was disposed while an active ticking TickerProvider` errors in debug console.
- **Fix**: Add robust disposal guards in `QueueWidgetState._removeItem`.

#### Risk 7 — Web Platform Rendering

- **Risk**: Web uses CanvasKit or HTML renderer. Custom painters and `RepaintBoundary` behavior differs significantly from native.
- **Audit**: Run the full gesture test suite on Chrome with CanvasKit renderer.
- **Fix**: Conditional rendering strategies for web if needed.

### Phase B4 — Platform-Specific Performance Tests

#### Mobile (Android/iOS)

- [ ] Drag-to-dismiss latency: pointer-down to first visual feedback < 16ms
- [ ] Reorder animation: maintained at 60fps on a Pixel 4a
- [ ] Haptic feedback fires on correct FSM transitions (not extra, not missing)
- [ ] Safe area integration correct on notched devices

#### Web

- [ ] Hover state transitions: no jank on `MouseRegion` enter/leave
- [ ] `VisibleOnHover` close button: correct fade at `400ms` with `easeOutCubic`
- [ ] Keyboard: Tab navigation between notifications (if implemented)
- [ ] CORS/isolation: FNQ has no network calls — verify no unexpected `dart:html` imports

#### Desktop

- [ ] Mouse drag behaves identically to touch drag
- [ ] `LongPressDraggable` threshold is appropriate for mouse (may need separate tuning vs. touch)
- [ ] Window resize does not break overlay positioning
- [ ] High-DPI (2x/3x scaling) renders correctly

---

## Execution Plan

### Ordering & Dependencies

```
Phase A1 (Research)
    ↓
Phase A2 (UX Critique) ← runs in parallel with Phase B1
    ↓
Phase A3 (DX Stability)     Phase B2 (Benchmarks)
    ↓                           ↓
Phase A4 (Docs Audit)       Phase B3 (Risk Fixes)
    ↓                           ↓
          ← Remediation Sprint →
                    ↓
             Phase B4 (Platform Tests)
                    ↓
               v1.0 Release
```

### Sprint Structure (Actual)

| Sprint | Work | Status |
|---|---|---|
| **Sprint 1** | A1 use-case research + A2 onboarding & API audit + A3 lifecycle audit + A4 docs audit + B1–B3 perf analysis | ✅ Done |
| **Sprint 2** | Implement all 🔴 CRITICAL fixes (5 items) | ✅ Done |
| **Sprint 3** | Implement all 🔸 IMPORTANT fixes + perf fixes Risk-1/2 | ✅ Done |
| **Sprint 4** | Documentation overhaul (README rewrite + new sections) | ✅ Done |
| **Sprint 5** | B4 platform-specific testing (Android device + Chrome + Linux) | 🔄 In Progress |
| **Sprint 6** | Changelog, version bump to 1.0.0, `pana` score check, publish | 🔲 Queued |


---

## Release Readiness Checklist

Before publishing v1.0:

### API Stability
- [x] Public API frozen (no breaking changes after this point without major version bump)
- [x] All exported symbols are intentional and documented
- [x] `QueueCoordinator` export decision made
- [x] `channelName` string validation improved (assert + clear error)

### Documentation
- [x] README uses correct API names (`configure`, not `initialize`)
- [x] README has "Architecture" section explaining Channel vs Queue mental model
- [x] README documents `FnqEvent` observability
- [x] README documents backpressure / overflow
- [ ] Migration guide updated (0.4→0.5, and 0.5→1.0 if breaking)
- [ ] All public classes have complete dartdoc

### Testing
- [x] `dart analyze` reports zero warnings/errors
- [x] All existing tests pass (`flutter test`)
- [x] New tests added for: `reset()` mid-display, `channelName` not found, `maxStackSize: 0`, duplicate IDs
- [ ] Integration tests pass on Android and Chrome
- [ ] No `AnimationController` leak warnings in debug console during burst test

### Performance
- [ ] 60fps maintained on mid-tier Android during all standard interactions
- [ ] Memory stable after 100 notification cycle
- [ ] Spring simulation CPU acceptable on low-tier device
- [ ] `FnqEvent` stream subscription cleanup documented and verified

### pub.dev Quality
- [x] `flutter pub publish --dry-run` passes with no issues
- [ ] `pana` score ≥ 140/160 (aim for 160)
- [ ] Example app compiles and runs on all primary platforms
- [ ] Topics, description, repository, license all set in `pubspec.yaml`


---

> [!NOTE]
> This plan should be treated as a living document. Findings from each phase will update the backlog for subsequent phases. Use `/goal` to run any phase as a long-running focused task.
