import 'package:flutter/material.dart';
import '../studio_theme.dart';

class StudioColorSelectionTile extends StatelessWidget {
  const StudioColorSelectionTile({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final Color? value;
  final ValueChanged<Color?> onChanged;

  @override
  Widget build(final BuildContext context) {
    final theme = StudioTheme.theme;
    final colorScheme = StudioTheme.colorScheme;
    final colors = [
      null,
      const Color(0xFF51B4F9),
      const Color(0xFF2D7512),
      const Color(0xFFC97725),
      const Color(0xFFD03332),
      const Color(0xFF9C27B0),
      const Color(0xFF009688),
      const Color(0xFF607D8B),
      const Color(0xFF000000),
      const Color(0xFFFFFFFF),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: colors.length,
            separatorBuilder: (final _, final __) => const SizedBox(width: 8),
            itemBuilder: (final ctx, final index) {
              final color = colors[index];
              final isSelected = color == value;

              return GestureDetector(
                onTap: () => onChanged(color),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color ?? Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: color == null
                      ? Icon(
                          Icons.close,
                          size: 14,
                          color: colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        )
                      : isSelected
                          ? Icon(
                              Icons.check,
                              size: 14,
                              color: color.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                            )
                          : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
