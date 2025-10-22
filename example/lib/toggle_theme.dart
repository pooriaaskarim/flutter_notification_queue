import 'package:flutter/material.dart';

import 'main.dart';

extension ThemeModeExtension on ThemeMode {
  IconData get icon {
    switch (this) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.brightness_7_sharp;
      case ThemeMode.dark:
        return Icons.brightness_4_outlined;
    }
  }
}

class AppThemeToggleButton extends StatelessWidget {
  const AppThemeToggleButton({super.key});

  @override
  Widget build(final BuildContext context) {
    final appState = NotificationQueueExample.of(context);
    if (appState == null) {
      return const SizedBox();
    }
    return IconButton(
      onPressed: appState.toggleTheme,
      icon: Icon(appState.themeMode.icon),
    );
  }
}
