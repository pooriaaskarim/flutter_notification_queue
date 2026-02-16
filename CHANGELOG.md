# Changelog

## [0.4.3] - 2026-02-16

### Relocation Maturity
- **Automatic Group Expansion**: Added `_expandRelocationGroups` to `ConfigurationManager` to automatically generate sibling queues for all relocation targets.
- **Relocation Characteristics Inheritance**: Generated sibling queues now correctly inherit `style`, `transition`, `maxStackSize`, and `spacing` from the source queue.
- **Self-Relocation Support**: Every relocation group now automatically includes its own source position, allowing notifications to return to their home queue.
- **Cross-Group Validation**: Implemented strict validation to prevent a single position from belonging to multiple relocation groups, ensuring deterministic behavior.
- **Fixed Transition Forwarding**: Resolved a bug where `generateQueue` omitted the `transition` parameter, causing siblings to lose custom entrance/exit logic.
- **Queue-Preserving Copy**: Enhanced `NotificationWidget.copyToQueue` to use internal constructors, bypassing manager resolution and preserving existing queue instances.


## [0.4.2] - 2026-02-16

### Animation Harmony (UX Polish)
- **Managed State Pattern**: Refactored `QueueWidget` to use a managed state approach with individual `AnimationController`s per notification.
- **Synchronized Transitions**: Unified `SizeTransition` (layout) and `NotificationTransition` (fade/scale) for perfectly synchronized entry/exit.
- **Improved Layout Logic**: Fixed spacing inconsistencies and ensured correct cross-axis alignment for all queue positions.

### Decoupled Animation Strategy
- **New Feature**: Introduced `NotificationTransition` strategy pattern for custom entrance/exit animations.
- **Builder Support**: Added `BuilderTransitionStrategy` for inline custom animations via a callback.
- **Standard Transitions**: Added `SlideTransitionStrategy` (default), `ScaleTransitionStrategy`, and `FadeTransitionStrategy`.
- **Queue Integration**: `NotificationQueue` now accepts a `transition` property.

### Documentation
- **Documentation Overhaul**: Added documentations for NFQ system components and refreshed documentation tone/structure.
- **Animation Control**: Added detailed animation guide to `README.md`.

## [0.4.1] - 2026-02-13

### Standard Defaults System
- **Factory Methods**: Added factory methods to `NotificationChannel` (e.g., `successChannel`, `errorChannel`) and `NotificationQueue` for easier instantiation.
- **Unified Standard Channels**: Introduced `NotificationChannel.standardChannels()` to quickly generate a set of common channels (success, error, info, warning).
- **Default Queue Factory**: Added `NotificationQueue.defaultQueue()` for creating standard queue configurations without boilerplate.
- **Zero-Config Initialization**: `FlutterNotificationQueue.initialize()` can now be called with minimal or no arguments, utilizing sensible defaults.

### Architecture & Stability
- **Stateless Queues**: Fully refactored `NotificationQueue` to be immutable and stateless, moving logic to `QueueCoordinator`.
- **Relocation Fixes**: Improved notification relocation logic and resolved issues with global keys during drag operations.
- **Singleton Removal**: `QueueCoordinator` is no longer a singleton, allowing for better testability and lifecycle management.
- **Initialization Guard**: Internal checks to prevent accidental re-initialization of the facade.
- **Enhanced Debugging**: Implemented `toString()` overrides for `NotificationChannel` and `NotificationQueue` to provide clearer debug output.

### Documentation
- **Updated Examples**: Refactored example application to demonstrate the new "Standard Defaults" system.
- **API Reference**: Updated README with new factory methods and usage guides.

### Testing
- **Comprehensive Test Suite**: Added extensive unit, widget, and integration tests covering:
    - `QueueCoordinator` state logic.
    - `QueueWidget` rendering and animations.
    - `NotificationWidget` interactions.
    - `NotificationOverlay` integration with `builder`.

## [0.4.0] - 2026-02-12

### Architecture Overhaul (Unified Core Engine)

- **Unified Core Engine**: Replaced the global `NotificationManager` singleton with a modular core engine consisting of `QueueCoordinator`, `NotificationOverlay`, and `ConfigurationManager`.
- **Public Facade**: Introduced `FlutterNotificationQueue` as the primary entry point for initialization and `MaterialApp` integration.
- **Stateful Queue Rendering**: Refactored queue management into `QueueWidget` for reactive, widget-tree-native state handling.
- **Structured Logging**: Implemented package-wide structured logging using `LogBuffer` for enhanced diagnostics.
- **Component Decoupling**: Refactored `NotificationWidget` and `NotificationQueue` to remove direct dependencies on global singletons.
- **Directory Harmonization**: Consolidated internal core components into a unified barrel file structure (`core.dart`).

### Improvements & Fixes

- **Contextless Support**: Seamless integration with `MaterialApp.builder` via `FlutterNotificationQueue.builder`.
- **Reactive State**: Improved UI updates and animations through stateful queue widgets.
- **API Cleanup**: Harmonized exports and removed legacy managers.

### Breaking Changes

- `NotificationManager` has been removed.
- Initialization must now use `FlutterNotificationQueue.initialize()`.
- Apps must integrate via `MaterialApp.builder` using `FlutterNotificationQueue.builder`.

## [0.3.1] - 2025-01-28

### Bug Fixes

#### **State Management Improvements**

- **State Access**: Replaced direct state access with proper `GlobalKey.currentState` access
    - Updated all drag gesture handlers to use `widget.notification.key.currentState?.method()`
    - Ensures timer management (`ditchDismissTimer`, `initDismissTimer`) works on current mounted
      state
    - Prevents stale state references during drag interactions
- **Constructor Cleanup**: Removed unnecessary `super.key` from helper widget constructors
- **Code Quality**: Removed unused variables and unnecessary null checks

### Architecture Improvements

#### **NotificationWidget Refactoring**

- **Factory Constructor**: Converted to factory constructor pattern for better initialization
- **Immutable Properties**: Changed `late final` properties to `final` for better immutability
- **Stable Key Management**: `GlobalObjectKey` now created during factory construction
- **State Safety**: Removed mutable `state` property to prevent stale references

#### **Code Quality Enhancements**

- **Dead Code Removal**: Eliminated unused `brightness` variable in theme resolution
- **Null Check Optimization**: Removed unnecessary null check for notification ID
- **Better Encapsulation**: Factory pattern provides cleaner initialization logic

### Performance Improvements

- **Immutable Widgets**: More efficient widget rebuilds with immutable properties
- **Proper State Access**: Eliminates potential memory leaks from stale state references
- **Cleaner Initialization**: Factory constructor reduces object creation overhead

### Technical Details

#### **Breaking Changes**

- None - this is a patch release with backward compatibility maintained

#### **Files Modified**

- `lib/src/notification/notification.dart` - Major refactoring with factory constructor
- `lib/src/notification/draggables/draggable_transitions.dart` - State access fixes
- `lib/src/notification/draggables/relocation_targets.dart` - Constructor cleanup
- `lib/src/notification/draggables/dismission_targets.dart` - Constructor cleanup
- `lib/src/notification/theme/notification_theme.dart` - Unused variable removal
- `lib/src/notification_queue/queue_manager.dart` - Null check optimization

---

## [0.3.0] - 2025-01-27

### Major Features

#### **Enhanced Queue Management**

- **Multi-Queue Support**: Run multiple independent notification queues simultaneously
- **Queue Grouping**: Group related queues with shared behavior and styling
- **Queue Relocation**: Drag notifications between different queue positions
- **Smart Queue Routing**: Automatic queue selection based on channel and context

#### **Advanced Gesture System**

- **Multi-Directional Drag**: Support for complex drag patterns and gestures
- **Gesture Thresholds**: Configurable sensitivity for different interaction types
- **Long-Press Actions**: Rich long-press behaviors with customizable targets
- **Gesture Feedback**: Visual and haptic feedback for all interactions

### UI/UX Improvements

#### **Enhanced Visual Design**

- **Material 3 Integration**: Full support for Material 3 design system
- **Dynamic Theming**: Automatic theme adaptation based on system settings
- **Custom Queue Styles**: Three distinct visual styles (Flat, Filled, Outlined)
- **Responsive Breakpoints**: Intelligent layout adaptation for different screen sizes

#### **Animation System**

- **Smooth Transitions**: Enhanced entrance and exit animations
- **Gesture Animations**: Fluid drag and swipe animations with physics
- **Progress Indicators**: Animated progress bars for auto-dismiss timers
- **Expand/Collapse**: Smooth content expansion with auto-pause functionality

#### **Accessibility Enhancements**

- **Screen Reader Support**: Comprehensive accessibility labels and descriptions
- **Keyboard Navigation**: Full keyboard support for all interactions
- **High Contrast Mode**: Enhanced visibility in high contrast environments
- **Focus Management**: Proper focus handling for interactive elements

### Internationalization

#### **RTL Language Support**

- **Automatic Detection**: Smart text direction detection for RTL languages
- **Layout Adaptation**: Proper layout mirroring for RTL interfaces
- **Multi-Language Examples**: Comprehensive examples in 10+ languages
- **Cultural Adaptation**: Region-specific notification patterns and behaviors

#### **Localization Features**

- **Dynamic Language Switching**: Support for runtime language changes
- **Pluralization Support**: Proper handling of plural forms in different languages
- **Date/Time Formatting**: Locale-aware time and date formatting
- **Number Formatting**: Proper number and currency formatting per locale

### 🔧 Developer Experience

#### **Enhanced API**

- **Type Safety**: Comprehensive type definitions and null safety
- **Builder Pattern**: Fluent API for complex notification configurations
- **Context Extensions**: Convenient extension methods for common use cases
- **Debug Support**: Rich debugging tools and logging capabilities

#### **Configuration System**

- **Global Configuration**: Centralized configuration management
- **Runtime Updates**: Dynamic configuration changes without app restart
- **Configuration Validation**: Automatic validation of configuration parameters
- **Default Fallbacks**: Sensible defaults for all configuration options

#### **Testing Support**

- **Widget Testing**: Comprehensive widget testing utilities
- **Integration Testing**: End-to-end testing support
- **Mock Support**: Easy mocking for testing scenarios
- **Performance Testing**: Built-in performance monitoring tools

### 📱 Platform Support

#### **Cross-Platform Compatibility**

- **iOS**: Native iOS design patterns and behaviors
- **Android**: Material Design compliance and Android-specific features
- **Web**: Full web support with hover effects and keyboard navigation
- **Desktop**: Native desktop experience for Windows, macOS, and Linux

#### **Platform-Specific Features**

- **Haptic Feedback**: Platform-appropriate haptic feedback
- **Safe Areas**: Proper handling of notches, status bars, and system UI
- **Window Management**: Desktop window-aware positioning and behavior
- **Touch Optimization**: Optimized touch targets and gesture recognition

### 🚀 Performance Improvements

#### **Memory Management**

- **Efficient Rendering**: Single overlay system for optimal performance
- **Memory Leak Prevention**: Comprehensive cleanup and disposal patterns
- **Lazy Loading**: On-demand widget creation and rendering
- **Resource Optimization**: Minimal memory footprint and efficient resource usage

#### **Queue Performance**

- **O(1) Operations**: Constant-time queue operations for all operations
- **Batch Processing**: Efficient handling of multiple simultaneous notifications
- **Animation Optimization**: Hardware-accelerated animations and transitions
- **Gesture Performance**: Smooth 60fps gesture recognition and response

### 🛠️ Technical Improvements

#### **Architecture Enhancements**

- **Modular Design**: Clean separation of concerns and modular architecture
- **Dependency Injection**: Flexible dependency injection for testing and customization
- **Event System**: Comprehensive event system for notification lifecycle management
- **State Management**: Efficient state management with minimal rebuilds

#### **Code Quality**

- **Comprehensive Documentation**: Extensive API documentation and examples
- **Code Coverage**: High test coverage for all major functionality
- **Linting**: Strict linting rules and code quality enforcement
- **Type Safety**: Full type safety with comprehensive type definitions

### 📚 Documentation

#### **Comprehensive Guides**

- **Getting Started**: Step-by-step setup and basic usage guide
- **Advanced Configuration**: Detailed configuration and customization guide
- **API Reference**: Complete API documentation with examples
- **Migration Guide**: Smooth migration from previous versions

#### **Examples and Samples**

- **Demo Application**: Full-featured demo app with 20+ examples
- **Code Samples**: Comprehensive code samples for all features
- **Best Practices**: Recommended patterns and best practices
- **Troubleshooting**: Common issues and solutions guide

### 🔒 Security and Privacy

#### **Data Protection**

- **No Data Collection**: Zero data collection or tracking
- **Local Processing**: All processing happens locally on device
- **Privacy First**: Privacy-focused design with no external dependencies
- **Secure Defaults**: Secure configuration defaults and practices

### 🐛 Bug Fixes

- Fixed memory leaks in long-running applications
- Resolved gesture conflicts in complex UI scenarios
- Fixed RTL layout issues in certain languages
- Corrected animation timing inconsistencies
- Resolved queue management edge cases
- Fixed theme integration issues
- Corrected accessibility label generation
- Resolved platform-specific rendering issues

### ⚠️ Breaking Changes

- **API Refactoring**: Some method signatures have been updated for better consistency
- **Configuration Changes**: Configuration structure has been simplified and improved
- **Queue Management**: Queue management API has been enhanced with new capabilities
- **Channel System**: Channel system has been completely redesigned for better flexibility

### 📦 Dependencies

- **Flutter SDK**: Updated minimum requirement to Flutter 3.0.0+
- **Dart SDK**: Updated minimum requirement to Dart 3.0.0+
- **Zero Dependencies**: Still maintains zero external dependencies
- **Platform Support**: Full support for all Flutter-supported platforms

---
