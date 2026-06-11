# FNQ Unified Development Roadmap & Tracking Board

This document tracks planned improvements, technical blueprints, and completion statuses for `flutter_notification_queue`, organized by priority phases and complexity tiers.

---

## 📊 Status Board & Complexity Matrix

```
Priority Tiers:
🔴 P0 (Critical) : Blocks library maturity or correctness; must fix before release.
🟡 P1 (High)     : High-value features, crucial for standard production use.
🟢 P2 (Medium)   : Nice-to-have features or major quality-of-life adjustments.
🔵 P3 (Low)      : Future considerations or micro-optimizations.

Complexity Tiers:
🟢 Low    : Styling, minor parameter additions, or basic unit tests.
🟡 Medium : State machine updates, layout mathematics, or local file integrations.
🔴 High   : Canvas rendering, cross-boundary gesture tracking, or custom multi-child positioning.
```

### 🧭 Active Feature Tracking Matrix

| ID | Feature / Job Name | Phase | Priority | Complexity | Status | Target Files |
|---|---|---|---|---|---|---|
| **F-01** | Drag-to-Reorder within Queue | Phase 2 | 🟡 P1 | 🔴 High | 📅 Pending | `lib/src/notification_queue/queue_widget.dart` |
| **F-02** | Pin-to-Edge Interaction (Pinning) | Phase 2 | 🟡 P1 | 🟡 Medium | 📅 Pending | `lib/src/notification/notification.dart` |
| **F-03** | Desktop Parking & Runtime Config | Phase 2 | 🟢 P2 | 🟡 Medium | 📅 Pending | `lib/src/core/queue_coordinator.dart` |
| **F-04** | Notification Grouping (Bundling) | Phase 3 | 🟡 P1 | 🔴 High | 📅 Pending | `lib/src/notification_queue/queue_widget.dart` |
| **F-05** | Persistent History Log Database | Phase 3 | 🟢 P2 | 🟡 Medium | 📅 Pending | `lib/src/core/history_logger.dart` |
| **F-06** | Focus Traversal & Accessibility | Phase 5 | 🟢 P2 | 🟢 Low | 📅 Pending | `lib/src/core/notification_overlay.dart` |
| **F-07** | Context Menu Support (Right-click) | Phase 5 | 🔵 P3 | 🟢 Low | 📅 Pending | `lib/src/notification/notification.dart` |
| **F-08** | L-Shaped Unified Corner Bars | Phase 2 | 🔵 P3 | 🟡 Medium | 📅 Pending | `lib/src/notification/interaction/overlays/dismissal_targets.dart` |
| **F-09** | Smart Layout & Overlap Avoidance | Phase 3 | *Completed* | 🔴 High | ✅ Completed | `lib/src/core/notification_overlay.dart` |
| **F-10** | Keyboard Shortcuts (`Esc` / `Shift+Esc`)| Phase 5 | *Completed* | 🟡 Medium | ✅ Completed | `lib/src/core/notification_overlay.dart` |
| **F-11** | Visual Golden Verification Suite | Phase 4 | *Completed* | 🟡 Medium | ✅ Completed | `test/golden/visual_regression_test.dart` |

---

## 🛠️ Feature Deep Dive: Implementation Blueprints

### F-01: Drag-to-Reorder / Arbitrary Index Insertion
* **Category**: Phase 2 (UX & Interaction Polish)
* **Complexity**: 🔴 High
* **Technical Challenges**:
  * Switching `QueueWidget` items from a sequential list animation to a coordinate-based drag detection.
  * Intercepting active index position during standard drag moves inside `GestureStateMachine`.
  * Dynamically shifting neighboring items up/down to show visual insertion gaps.
* **Verification Criteria**:
  * Widget tests dragging index 2 to index 0, asserting correct list updates.
  * Verifying animations resolve stably without list rebuild glitches.

---

### F-02: Pin-to-Edge Interaction (Pinning)
* **Category**: Phase 2 (UX & Interaction Polish)
* **Complexity**: 🟡 Medium
* **Technical Challenges**:
  * Extending `NotificationWidget` parameters to hold an active `isPinned` state.
  * Inhibiting standard drag-to-dismiss behavior when pinned.
  * Modifying the dismissal layout delegate to skip auto-dismissal timers for pinned notifications.
* **Verification Criteria**:
  * Verify pinned notifications do not dismiss when auto-timer expires.
  * Assert `dismiss()` calls are ignored or trigger warning callbacks unless unpinned.

---

### F-03: Desktop Relocation (Parking & Runtime Config)
* **Category**: Phase 2 (UX & Interaction Polish)
* **Complexity**: 🟡 Medium
* **Technical Challenges**:
  * Storing channel-to-position mappings in a runtime configuration register.
  * Dynamically updating `ConfigurationManager` bindings on drag release into target zones.
* **Verification Criteria**:
  * Verify that dragging a channel `A` notification from `topLeft` to `topRight` causes subsequent channel `A` notifications to pop up directly at `topRight`.

---

### F-04: Gmail-Style Notification Grouping (Bundling)
* **Category**: Phase 3 (Advanced Layout Engine)
* **Complexity**: 🔴 High
* **Technical Challenges**:
  * Decoupling the visual presentation of a "Group Header" from standard notification cards.
  * Tracking maximum active count per group before collapsing cards behind a stack profile.
  * Managing hover/tap expansion transitions to lay out member cards within the viewport.
* **Verification Criteria**:
  * Integration test sending 5 messages under group `"auth_alerts"`, verifying only 1 header is visible with a "+4" badge.

---

### F-05: Persistent Notification Log (In-App History)
* **Category**: Phase 3 (Advanced Layout Engine)
* **Complexity**: 🟡 Medium
* **Technical Challenges**:
  * Intercepting all coordinator lifecycle events and dumping them into a local ring-buffer or file system database.
  * Designing a queryable controller to retrieve dismissed cards.
* **Verification Criteria**:
  * Verify querying history after 10 dismissals yields the exact matching entries.

---

### F-06: Focus Traversal & Semantic Keyboard Support
* **Category**: Phase 5 (Platform Perfection)
* **Complexity**: 🟢 Low
* **Technical Challenges**:
  * Ensuring focus remains accessible to screen readers when overlays display.
  * Integrating standard tab focus behavior through `FocusNode` chains.
* **Verification Criteria**:
  * Verify screen reader accessibility focus tree traversal via semantic tester logs.

---

### F-07: Context Menu Support (Right-Click Actions)
* **Category**: Phase 5 (Platform Perfection)
* **Complexity**: 🟢 Low
* **Technical Challenges**:
  * Intercepting right-clicks or long presses to spawn a native desktop popup menu containing quick dismiss, snooze, or priority triage options.
* **Verification Criteria**:
  * Verify clicking menu options correctly dispatches actions to target items.

---

### F-08: L-Shaped Unified Corner Bars (Dismissal UI)
* **Category**: Phase 2 (UX & Interaction Polish)
* **Complexity**: 🟡 Medium
* **Technical Challenges**:
  * Determining when neighboring edge dismissal targets are visible and drawing a seamless, unified border/overlay that covers both screen edges.
* **Verification Criteria**:
  * Render verification via golden tests on desktop sizes.

---

## ✅ Completed Milestones

| Item | Version | Summary | Target Files |
|------|---------|---------|---|
| **F-09: Smart Layout** | v0.5.1 | Custom `_QueueOverlayLayoutDelegate` dynamically shifts adjacent colliding queues under layout space constraints (using `CustomMultiChildLayout`). | `lib/src/core/notification_overlay.dart` |
| **F-10: Keyboard Shortcuts** | v0.5.0 | Global overlay-level keyboard listeners to dismiss individual or all active cards programmatically (`Esc` / `Shift+Esc`). | `lib/src/core/notification_overlay.dart` |
| **F-11: Visual Golden Tests** | v0.5.0 | Added native `flutter_test` golden tests for Flat, Filled, and Outlined styles, and queue anchoring. | `test/golden/visual_regression_test.dart` |
| **Adaptive Close Button** | v0.4.4 | Opacity-based close model with progressive enhancement for touch/mouse adaptation. | `lib/src/notification/notification.dart` |
| **Relocation Maturity** | v0.4.3 | Automated group expansion, validation, and characteristic inheritance for relocation. | `lib/src/core/queue_coordinator.dart` |
| **Decoupled Animations** | v0.4.2 | Introduced `NotificationTransition` strategy pattern with Slide, Scale, Fade, and Builder support. | `lib/src/notification/animation/` |
| **Animation Harmony** | v0.4.2 | Refactored `QueueWidget` to Managed State for synchronized layout animations. | `lib/src/notification_queue/queue_widget.dart` |
| **Stateless Queues** | v0.4.0 | Moved queue state out of configuration objects. | `lib/src/notification_queue/notification_queue.dart` |
| **Unified Core Engine** | v0.4.0 | Replaced `NotificationManager` singleton with `QueueCoordinator`. | `lib/src/core/queue_coordinator.dart` |
