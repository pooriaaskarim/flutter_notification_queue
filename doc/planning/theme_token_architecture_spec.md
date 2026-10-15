# Theme Token Architecture Specification (v0.6.0 Target)

> **Category**: Architecture & Design System Integration  
> **Task ID**: `A-08`  
> **Status**: Approved Specification — Implementation in `v0.6.0`  
> **Related**: `doc/migration_v0_5.md`, `doc/roadmap.md`

---

## 1. Problem Statement

FNQ previously used loose, unvalidated scalar color properties on both `NotificationChannel` (`defaultColor`, `defaultBackgroundColor`, `defaultForegroundColor`) and `AppNotification` (`color`, `backgroundColor`, `foregroundColor`).

### Failures of Loose Colors
1. **Dark / Light Mode Blindness**: Static hex constants (e.g. `Color(0xFF2D7512)`) cannot react to ambient `Theme.of(context).brightness` or Material 3 dynamic color schemes.
2. **Contrast & Legibility Hazards**: Setting `backgroundColor: Colors.black` without matching `foregroundColor` introduces WCAG contrast failures.
3. **Design System Token Fragmentation**: Lacks unified tokens for border radius, shape, elevation, shadow color, and typography without endlessly adding scalar properties.

---

## 2. Design Model: `NotificationThemeData`

`NotificationThemeData` is an immutable, cohesive styling bundle:

```dart
@immutable
class NotificationThemeData {
  const NotificationThemeData({
    this.accentColor,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.elevation,
    this.shadowColor,
    this.titleTextStyle,
    this.messageTextStyle,
    this.iconTheme,
  });

  /// Primary accent color used for icons, progress bars, and status borders.
  final Color? accentColor;

  /// Card body surface color.
  final Color? backgroundColor;

  /// Primary text and icon color on top of [backgroundColor].
  final Color? foregroundColor;

  /// Card outline border color.
  final Color? borderColor;

  /// Card outline border stroke width.
  final double? borderWidth;

  /// Card corner border radius.
  final BorderRadiusGeometry? borderRadius;

  /// Shadow elevation depth.
  final double? elevation;

  /// Elevation drop shadow tint.
  final Color? shadowColor;

  /// Typography styling for the header title.
  final TextStyle? titleTextStyle;

  /// Typography styling for the message body.
  final TextStyle? messageTextStyle;

  /// Theme overrides for leading and trailing icons.
  final IconThemeData? iconTheme;
}
```

---

## 3. Ergonomic Presets & Dynamic Theme Factories

`NotificationThemeData` provides context-aware factory constructors that automatically resolve against `Theme.of(context)` / `ColorScheme`:

```dart
// Factory constructors that adapt to Dark/Light mode automatically:
NotificationThemeData.fromColorScheme(
  ColorScheme colorScheme, {
  NotificationPriority priority = NotificationPriority.normal,
});

NotificationThemeData.fromSeed({
  required Color seedColor,
  required Brightness brightness,
});

// Semantic preset helpers:
NotificationThemeData.success(BuildContext context);
NotificationThemeData.error(BuildContext context);
NotificationThemeData.warning(BuildContext context);
NotificationThemeData.info(BuildContext context);
```

---

## 4. Hierarchical Resolution Cascade

When rendering any notification card, tokens resolve in a strict 4-tier cascade:

$$\text{Notification-level Override} \longrightarrow \text{Channel Theme} \longrightarrow \text{Global } \texttt{NotificationTheme} \longrightarrow \text{Ambient } \texttt{Theme.of(context)}$$

```dart
NotificationThemeData resolveEffectiveTheme({
  required BuildContext context,
  required NotificationChannel channel,
  AppNotification? notification,
}) {
  final ambient = Theme.of(context);
  final global = NotificationTheme.maybeOf(context);
  final channelTheme = channel.theme;
  final notificationTheme = notification?.theme;

  return NotificationThemeData(
    accentColor: notificationTheme?.accentColor ??
        channelTheme?.accentColor ??
        global?.primaryColor ??
        ambient.colorScheme.primary,
    backgroundColor: notificationTheme?.backgroundColor ??
        channelTheme?.backgroundColor ??
        global?.cardColor ??
        ambient.colorScheme.surface,
    foregroundColor: notificationTheme?.foregroundColor ??
        channelTheme?.foregroundColor ??
        global?.textColor ??
        ambient.colorScheme.onSurface,
    // ...
  );
}
```

---

## 5. Usage in Code

### Channel Configuration (v0.6.0)
```dart
NotificationController(
  channels: {
    NotificationChannel(
      name: 'billing',
      theme: NotificationThemeData.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.dark,
      ),
    ),
  },
);
```

### Notification Override (v0.6.0)
```dart
controller.show(
  AppNotification(
    message: 'Spotify: Playing Track',
    theme: const NotificationThemeData(
      accentColor: Color(0xFF1DB954),
      backgroundColor: Color(0xFF121212),
      foregroundColor: Colors.white,
    ),
  ),
);
```
