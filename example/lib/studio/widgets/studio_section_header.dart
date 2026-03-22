import 'package:flutter/material.dart';
import '../studio_theme.dart';

class StudioSectionHeader extends StatelessWidget {
  const StudioSectionHeader({
    required this.title,
    super.key,
  });

  final String title;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = StudioTheme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 3,
          fontWeight: FontWeight.w900,
          color: colorScheme.primary.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
