# FNQ Roadmap

This document tracks planned improvements, known issues, and TODO items for `flutter_notification_queue`, organized by priority and phased for dependency-aware implementation.

---

## Priority System

- 🔴 **P0 (Critical)**: Blocks maturity, must fix before v1.0
- 🟡 **P1 (High)**: Important for production use, correctness issues
- 🟢 **P2 (Medium)**: Nice-to-have, quality-of-life improvements
- 🔵 **P3 (Low)**: Future considerations, micro-optimizations

---

## Phase 1 — Architectural Maturity

Refining the "Unified Core" to be fully agnostic of visual implementation.

### 🟡 P1: Decoupled Animation Strategy (Completed)

*Moved to Completed section.*

---

## Phase 2 — UX & Interaction Polish
 
Focusing on the "Feel" and "Value" of interactions.
 
### 🟡 P1: Relocation & Interaction Maturity
 
**Issue**: Relocation feels "immature" and lacks clear utility (especially on Desktop). Dismiss/Relocate UI is incomplete.
 
**TODO**:
- [x] **Relocation Engine & Validation**:
  - [x] **Self-Inclusion**: Auto-add source to target set.
  - [x] **Expansion**: Auto-generate sibling queues.
  - [x] **Cross-Group Validation**: Prevent position conflicts at init.
  - [x] **Characteristic Inheritance**: Clones style, transition, and constraints.
- [ ] **Interaction Refinement**:
  - [x] **Corner Interaction**: Independent edge hit detection and distinct axis feedback.
  - [ ] **Unified Corner Bars**: Cohesive L-shaped visual for adjacent dismissal zones (Future Consideration).
- [ ] **Relocation Purpose**:
  - [ ] Research/Define Desktop value (e.g., "Park" notification in a corner).
  - [ ] **Pinning**: "Pin to Edge" functionality for deferred action.
  - [ ] **Runtime Config**: Drag-to-move permanently updates channel config?
- [ ] **Sorting & Reordering**:
  - [ ] Implement drag-to-reorder within the same queue.
  - [ ] **Structural Enhancements**: data structures to support arbitrary index insertion.
- [ ] **Target UI**:
  - [ ] Replace "Placeholder" Drop Zones with production-grade UI (blur, scale, icons).
- [x] **Input Resilience** (Zombie Prevention):
  - [x] Handle `CloseButtonBehavior.never` + Touch Screen (adaptive opacity fallback).
  - [x] Ensure no notification becomes "undismissable" due to config/platform mismatch.
  - [x] **Progressive Enhancement**: Evidence-based mouse detection for hybrid devices.
 
### 🟡 P1: Animation Harmony (Completed)
 
*Moved to Completed section.*
 
---
 
## Phase 3 — Advanced Layout Engine
 
Solving complex rendering problems.
 
### 🟢 P2: Smart Layout & Collision
 
**Issue**: On small screens, neighbor positions (e.g., `TopCenter` vs `TopRight`) collide/overlap.
 
**TODO**:
- [ ] **Collision Detection**: Calculate screen width vs Widget width to detect overlaps.
- [ ] **Responsive Constraints**: Dynamic `maxWidth` allocation based on available screen real estate and active neighbors.
 
### 🟢 P2: Notification Bundling (Grouping)
- [ ] "Gmail-style" bundling for high-frequency channels.
 
### 🟢 P2: Persistent History
- [ ] In-app notification log/history viewer.

---
 
## Phase 4 — Robustness & Verification
 
Ensuring the UI library doesn't regress visually.
 
### 🟡 P1: Visual Regression (Golden) Tests (Completed)
 
**Issue**: Current tests cover logic (`ConfigurationManager`), but FNQ is a UI library. We have no protection against CSS-like regressions (e.g., shadow clipping, border radius failures).
 
**TODO**:
- [x] Integrate `golden_toolkit` or `flutter_test` goldens
- [x] Create Golden tests for all standard `QueueStyle`s:
  - [x] `FilledQueueStyle`
  - [x] `FlatQueueStyle`
  - [x] `OutlinedQueueStyle`
- [x] Create Golden tests for all `QueuePosition`s (ensure correct anchoring)

---
 
## Phase 5 — Platform Perfection
 
### 🔵 P3: Desktop & Web Polish
 
**Issue**: Native feel on non-mobile platforms.
 
**TODO**:
- [ ] **Keyboard Navigation**: Focus traversal for notifications
- [x] **Shortcuts**: `Esc` to dismiss top, `Shift+Esc` to dismiss all
- [ ] **Mouse Support**: Right-click context menus (optional)

---

## Completed ✅

| Item | Version | Summary |
|------|---------|---------|
| Unified Core Engine | v0.4.0 | Replaced `NotificationManager` singleton with `QueueCoordinator` |
| Stateless Queues | v0.4.0 | Moved queue state out of configuration objects |
| Documentation Overhaul | v0.4.2 | Refined tone, added API reference and concrete examples |
| Animation Harmony | v0.4.2 | Refactored `QueueWidget` to Managed State for synchronized layout animations |
| Decoupled Animations | v0.4.2 | Introduced `NotificationTransition` strategy pattern with Slide, Scale, Fade, and Builder support |
| Relocation Maturity | v0.4.3 | Automated group expansion, validation, and characteristic inheritance for relocation |
| Adaptive Close Button | v0.4.4 | Opacity-based model with progressive enhancement for touch/mouse adaptation |
| Visual Regression Goldens | v0.5.0 | Added native flutter_test golden tests for Flat, Filled, and Outlined styles, and queue anchoring |
| Keyboard Shortcuts | v0.5.0 | Implemented Esc and Shift+Esc keys to dismiss newest/all notifications |

---

## How to Contribute

1. **Claim**: Comment on GitHub issue
2. **Branch**: `feat/<item-name>`
3. **Test**: Add tests before implementation
4. **Document**: Update docs alongside code
5. **Update**: Check off item and move to Completed
