# Changelog

## [0.2.0] - 2026-07-19

### Consolidated API & Subclass Removal
- **Simplified NotificationQueue:** Removed all 8 specialized subclasses (`TopLeftQueue`, etc.) in favor of a single, highly configurable concrete `NotificationQueue` class with a `const` constructor.
- **QueuePosition Helpers:** Simplified `generateQueue()` on `QueuePosition` to directly build `NotificationQueue` instances, removing duplicate subclass-generation switch blocks.

### Internal State Decoupling
- **Introduced NotificationEntry:** Decoupled `NotificationWidget` configuration blueprint from active runtime state (dismiss timers, pinned lifecycle, resolved priority) by introducing the internal `NotificationEntry` wrapper class.
- **QueueCoordinator & Layout State:** Refactored state-storage maps and animation list managers to use `NotificationEntry`, preventing potential `GlobalKey` conflicts.

## [0.1.0] - 2026-07-10

### Initial Public Preview Baseline

All features from early pre-releases (`0.4.0` - `0.7.0`) consolidated into a single unified public baseline.

#### Interaction Engine (Physics & Reordering)
- **Reorder Behavior:** Users can pick up notifications and seamlessly rearrange them within their queue, empowering sophisticated inbox management.
- **Overlap Mechanics:** Replaced legacy gap-based targeting with a deeply physical "Overlap Target" model. The engine dynamically calculates the 2D bounding `Rect` of every active notification on the fly to yield precise target indices.
- **Perfect Deadband Hysteresis:** Implemented a "Gravity Well" (Target-Centric State) algorithm. The active drop zone applies a persistent 40-pixel magnetic lock to its own hit-test calculations, generating a flawless 80-pixel optical deadband that is 100% immune to pointer jitter, velocity spikes, and physical hand vibrations.
- **Premium Bounding Reticles:** Replaced the destructive horizontal center-line drop indicator with a Selection Reticle. Hovering over a card instantly frames its exterior in a glowing border while subtly darkening the interior (Recess Effect).
- **Self-Target Suppression:** The physics engine natively understands "cancel" drags. Hovering a payload over its own original starting slot visually suppresses all target feedback, rendering an empty placeholder hole so the user can comfortably drop the card back to safely abort.
- **Smooth Height & Spring Snapbacks:** Added dynamic height transitions when notifications expand or collapse, and physical spring snapback physics for aborted cancel drags.
- **Visual Grab Cursors:** Added grab and grabbing cursor states on draggable cards to improve desktop UX.

#### Layout, Grouping & Customization
- **Notification Grouping & Bundling:** Introduced dynamic stack configuration parameters (custom layer count, offsets, scales), recursive-safe swipe dismissals with reason propagation, and non-overlapping indicators with direction-aware tap-to-expand.
- **Visual Boundaries:** Added per-queue `maxWidth` constraints and layout collision delegate resolution.
- **Adaptive Close Button:** Opacity-based model (`0.0`–`1.0`) with subtle presence for touch devices (starts at `0.3` opacity for discoverability) and progressive enhancement (hidden until hover on desktop).
- **Hover-to-Pause Dismissal:** Hovering over a notification card pauses its auto-dismiss timer, which resumes smoothly when the pointer leaves.

#### Core API & Observability
- **Dynamic Channel Parking:** Introduced runtime routing updates where dragging/relocating a notification card dynamically updates the routing rules for all future notifications of its channel.
- **Event History Log:** Added an in-memory, LIFO bounded ring buffer (`maxHistoryEntries`) to capture notification events. Added `getHistory()` for querying with filters (channelName, dismissReason, since, limit) and `clearHistory()` for cache management.
- **Zero-overhead Disabling:** When disabled (`maxHistoryEntries` is set to `0` or less), the history subscription is completely cancelled and detached, guaranteeing zero runtime performance or memory overhead.
- **Logd Core Integration:** Upgraded logging package to `logd` version `^0.8.6` and integrated package-wide structured log handlers.
- **Stable Event Proxy:** Replaced transient event streams with a persistent broadcast proxy stream to prevent zombie listeners across configure/reset cycles.
- **Per-Notification Permanence:** Added `permanent: true` flag to individual `NotificationWidget`s to bypass channel-level default dismiss durations.
