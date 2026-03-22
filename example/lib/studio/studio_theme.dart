import 'dart:ui';

import 'package:flutter/material.dart';

/// Centralized theme and reusable widgets for NFQ Studio.
class StudioTheme {
  StudioTheme._();

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

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
