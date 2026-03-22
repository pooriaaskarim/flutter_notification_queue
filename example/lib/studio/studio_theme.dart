import 'dart:ui';

import 'package:flutter/material.dart';

/// Centralized theme and reusable widgets for NFQ Studio.
class StudioTheme {
  StudioTheme._();

  static late ThemeData _theme;
  static late ColorScheme _colorScheme;
  static late bool _isDark;

  static ThemeData get theme => _theme;
  static ColorScheme get colorScheme => _colorScheme;
  static bool get isDark => _isDark;

  /// Updates the global static theme state.
  /// Should be called at the root of the app (e.g. in MaterialApp.builder).
  static void update(final BuildContext context) {
    _theme = Theme.of(context);
    _colorScheme = _theme.colorScheme;
    _isDark = _theme.brightness == Brightness.dark;
  }

  /// Force-rebuilds all descendants of the given context.
  ///
  /// Used to ensure that leaf widgets using static theme access refresh
  /// when the theme changes, bypassing const optimizations.
  static void rebuildDescendantChildren(final BuildContext context) {
    void rebuild(final Element el) {
      el
        ..markNeedsBuild()
        ..visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  static const primaryColor = Color(0xFF0F172A);
  static const surfaceColor = Color(0xFF1E293B);
  static const accentColor = Color(0xFF38BDF8);

  static const lightPrimaryColor = Color(0xFFF8FAFC);
  static const lightSurfaceColor = Color(0xFFFFFFFF);
  static const lightAccentColor = Color(0xFF0EA5E9);

  static ThemeData light() => ThemeData.light().copyWith(
        scaffoldBackgroundColor: lightPrimaryColor,
        colorScheme: const ColorScheme.light(
          primary: lightAccentColor,
          surface: lightSurfaceColor,
          onSurface: Color(0xFF0F172A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
      );

  static ThemeData dark() => ThemeData.dark().copyWith(
        scaffoldBackgroundColor: primaryColor,
        colorScheme: const ColorScheme.dark(
          primary: accentColor,
          surface: surfaceColor,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
      );
}

/// A frosted-glass card widget for premium UI elements.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 16.0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(final BuildContext context) {
    final isDark = StudioTheme.isDark;
    final colorScheme = StudioTheme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : colorScheme.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
