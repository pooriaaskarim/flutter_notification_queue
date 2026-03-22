# NFQ Studio: Example Application Guidelines

The NFQ (Notification Flutter Queue) Studio is the official showcase for the library. It must adhere to the following principles to provide a premium, educational, and professional experience.

## 1. Professional Identity (NFQ)
- **Branding**: Exclusively use "NFQ" branding. Avoid generic or disconnected names (e.g., "Apex").
- **Aesthetic**: Maintain a high-end, dark-mode visual style using glassmorphism and the established `StudioTheme`.
- **Copywriting**: Keep all text professional, concise, and focused on library functionality.

## 2. Interactive Functional Exploration
- **Live Configuration**: Users must be able to change queue positions, styles, and transitions in real-time.
- **Immediate Feedback**: Every configuration change should be testable via a "Preview" or "Trigger" action.
- **Feature Depth**: Showcase advanced features specifically, such as `Relocate` behaviors and custom `NotificationTransition` strategies.

## 3. Contextual Demonstration
- **Scenario-Based**: Use realistic use cases (e.g., security alerts, progress syncing, social interactions) rather than dummy text.
- **Physical Interaction**: Clearly demonstrate gesture-based features (dragging, dismissing) through dedicated sections.

## 4. Reference Architecture
- **Modularity**: The example code should be modular and easy to read, serving as a template for developers.
- **Best Practices**: Use standard Flutter patterns (e.g., `Provider` for state, clear widget separation).
- **No Refactor Left Behind**: Ensure legacy example files are removed or updated to prevent confusion.

## 5. Performance & Quality
- **Zero Lints**: Maintain a clean, warning-free codebase.
- **Fluidity**: Ensure all animations and blurs perform at 60/120 FPS on supported hardware.
