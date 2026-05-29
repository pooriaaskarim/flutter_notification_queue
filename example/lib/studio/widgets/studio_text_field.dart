import 'package:flutter/material.dart';
import '../studio_theme.dart';

class StudioTextField extends StatelessWidget {
  const StudioTextField({
    required this.label,
    required this.initial,
    required this.onChanged,
    this.maxLines = 1,
    super.key,
  });

  final String label;
  final String initial;
  final ValueChanged<String> onChanged;
  final int maxLines;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = StudioTheme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: initial,
          maxLines: maxLines,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: colorScheme.surface.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: colorScheme.primary,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
