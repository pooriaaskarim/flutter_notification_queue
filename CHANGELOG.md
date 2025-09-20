## 0.2.0

### 🚀 New Features

* **Configuration System**: Introduced `InAppNotificationConfig` for global customization
    - Global theme configuration for notification appearance
    - Configurable notification positioning (top/bottom, start/center/end)
    - Customizable default colors for success, error, warning, and info states
    - Adjustable default dismiss duration and opacity settings
    - Configurable maximum stack size for concurrent notifications
    - Custom stack indicator builder support
* **Enhanced Manager Capabilities**:
    - Configuration management through `InAppNotificationManager.instance.config`
    - Dynamic configuration updates at runtime
    - Queue management with configurable stack limits

### 🎨 Improvements

* **Theming System**: Better integration with Flutter's theme system
    - Automatic fallback to theme colors when config colors are not specified
    - Improved color contrast and accessibility
* **API Consistency**: Streamlined configuration API
    - Centralized configuration through singleton pattern
    - Consistent naming conventions across all configuration options

### 📚 Documentation

* Updated README with configuration examples
* Added comprehensive API documentation for `InAppNotificationConfig`
* Configuration usage examples in demo app

### 🔧 Technical Improvements

* Better separation of concerns between manager and configuration
* Improved code organization with dedicated config management
* Enhanced type safety for configuration options

---

## 0.0.1

### 🎉 Initial Release

### ✨ Core Features

* **InAppNotification Widget**: Beautiful, customizable overlay notifications
    - Custom message and optional title support
    - Icon support with flexible widget system
    - Customizable background and foreground colors
    - Automatic dismiss with configurable duration
    - Permanent notifications with manual dismiss
    - Optional close button functionality
* **Predefined Notification Types**: Ready-to-use styled notifications
    - `InAppNotification.success()` - Success messages with green theme and check icon
    - `InAppNotification.error()` - Error messages with red theme and error icon
    - `InAppNotification.warning()` - Warning messages with orange theme and warning icon
    - `InAppNotification.info()` - Info messages with blue theme and info icon
* **Interactive Actions**: Multiple action types for user interaction
    - `InAppNotificationAction.button()` - Dedicated action button in notification
    - `InAppNotificationAction.onTap()` - Tap-to-action functionality on entire notification
    - Automatic notification dismissal after action execution
* **Advanced User Interactions**:
    - **Drag-to-Dismiss**: Swipe notifications away in any direction
    - **Expandable Content**: Tap arrow to expand for full message visibility
    - **Auto-pause on Expand**: Dismiss timer pauses when notification is expanded
    - **Timer Indicator**: Visual progress bar showing remaining dismiss time
* **Queue Management System**:
    - `InAppNotificationManager` singleton for centralized control
    - Automatic queue processing with stack size management
    - FIFO (First In, First Out) queue system
    - Stack overflow indicator ("+ N more" counter)
* **Accessibility & Internationalization**:
    - **RTL Language Support**: Automatic text direction detection for Arabic, Persian, Hebrew
    - **Responsive Design**: Adaptive layouts for phone, tablet, and desktop
    - **Multi-language Examples**: Comprehensive support for various languages
    - **Screen Size Adaptation**: Smart width constraints based on device type

### 🎨 Design Features

* **Material Design**: Full Material 3 design system integration
* **Smooth Animations**:
    - Entrance/exit animations with configurable curves
    - Expand/collapse animations for content
    - Drag feedback with opacity changes
    - Progress indicator animations
* **Customizable Styling**:
    - Border radius, elevation, and opacity controls
    - Color system with theme integration
    - Typography that respects system text scaling
    - Icon and widget flexibility
* **Layout Intelligence**:
    - Automatic content overflow handling with ellipsis
    - Dynamic positioning based on content
    - Gesture conflict resolution
    - Safe area integration

### 🛠️ Technical Architecture

* **Widget System**: Clean, composable widget architecture
    - Stateful widget with proper lifecycle management
    - ValueNotifier for reactive state management
    - Efficient dispose patterns preventing memory leaks
* **Overlay Integration**: Native Flutter overlay system
    - Dynamic overlay entry management
    - Automatic cleanup and resource management
    - Context-aware positioning
* **Gesture System**: Comprehensive gesture handling
    - Pan gesture detection for drag-to-dismiss
    - Threshold-based dismissal logic
    - Multi-directional swipe support
* **Performance Optimizations**:
    - Lazy widget building
    - Efficient queue processing
    - Memory-conscious notification disposal
    - Minimal rebuilds with targeted ValueNotifiers

### 🎯 Developer Experience

* **Simple API**: Intuitive, Flutter-idiomatic API design
    - Context extension for easy access: `context.showInAppNotification()`
    - Builder pattern for complex notifications
    - Sensible defaults for rapid development
* **Type Safety**: Full Dart type safety with comprehensive enums
* **Debugging Support**: Built-in debug logging for development
* **Example Application**: Comprehensive demo with 20+ notification examples
    - Multiple languages and use cases
    - Interactive examples for all features
    - Stress testing capabilities

### 📦 Package Structure

* **Core Library**: `lib/in_app_notifications.dart` - Main package entry point
* **Widget System**: Modular component architecture
    - `InAppNotification` - Main notification widget
    - `InAppNotificationManager` - Queue and lifecycle management
    - `InAppNotificationAction` - Action system
* **Utilities**: Helper classes for text direction, responsive design
* **Extensions**: Convenient context extensions for developer productivity

### 🌍 Platform Support

* **Flutter SDK**: Compatible with Flutter 3.0.0+
* **Dart SDK**: Supports Dart 2.18.0 to 4.0.0
* **Platforms**: iOS, Android, Web, Windows, macOS, Linux
* **Material Design**: Full Material 3 support

### 📋 Dependencies

* **Flutter**: Core framework dependency only
* **Zero External Dependencies**: Lightweight package with no third-party dependencies
* **Development Tools**: flutter_test, flutter_lints for quality assurance
