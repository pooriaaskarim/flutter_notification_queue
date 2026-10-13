import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import '../studio_theme.dart';
import 'studio_color_selection_tile.dart';
import 'studio_section_header.dart';

/// A responsive Theme & Style Designer dialog / bottom sheet.
///
/// Provides a live interactive card preview alongside fine-grained controls
/// for [NotificationThemeData] and [QueueStyle] archetypes.
class ThemeDesignerDialog extends StatefulWidget {
  const ThemeDesignerDialog({
    required this.title,
    required this.initialTheme,
    this.onApplyTheme,
    this.initialStyleType,
    this.onApplyStyle,
    this.onApply,
    this.channelName,
    this.previewTitle = 'Payment Processed',
    this.previewMessage =
        'Invoice #1084 for \$140.00 was successfully charged.',
    this.previewIcon = const Icon(Icons.check_circle_outline, size: 20),
    this.isNotificationOverride = false,
    super.key,
  });

  /// The header title (e.g. `Configure Theme: #billing`).
  final String title;

  /// The name of the channel being configured, if any.
  final String? channelName;

  /// The existing or inherited [NotificationThemeData].
  final NotificationThemeData? initialTheme;

  /// Callback when the user confirms theme changes.
  final ValueChanged<NotificationThemeData?>? onApplyTheme;

  /// The existing or inherited [QueueStyle] archetype type.
  final Type? initialStyleType;

  /// Callback when the user changes the archetype style.
  final ValueChanged<Type?>? onApplyStyle;

  /// Unified callback when the user applies both theme and style changes.
  final void Function(NotificationThemeData? theme, Type? styleType)? onApply;

  /// Sample title displayed in the live preview card.
  final String previewTitle;

  /// Sample message displayed in the live preview card.
  final String previewMessage;

  /// Sample icon displayed in the live preview card.
  final Widget previewIcon;

  /// Whether this designer is configuring a one-off notification override.
  final bool isNotificationOverride;

  /// Shows the designer adaptively: bottom sheet on mobile, dialog on desktop.
  static Future<void> show(
    final BuildContext context, {
    required final String title,
    required final NotificationThemeData? initialTheme,
    final ValueChanged<NotificationThemeData?>? onApplyTheme,
    final Type? initialStyleType,
    final ValueChanged<Type?>? onApplyStyle,
    final void Function(NotificationThemeData? theme, Type? styleType)? onApply,
    final String? channelName,
    final String previewTitle = 'Payment Processed',
    final String previewMessage =
        'Invoice #1084 for \$140.00 was successfully charged.',
    final Widget previewIcon =
        const Icon(Icons.check_circle_outline, size: 20),
    final bool isNotificationOverride = false,
  }) async {
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    if (isMobile) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (final _) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (final _, final scrollController) => ThemeDesignerDialog(
            title: title,
            channelName: channelName,
            initialTheme: initialTheme,
            onApplyTheme: onApplyTheme,
            initialStyleType: initialStyleType,
            onApplyStyle: onApplyStyle,
            onApply: onApply,
            previewTitle: previewTitle,
            previewMessage: previewMessage,
            previewIcon: previewIcon,
            isNotificationOverride: isNotificationOverride,
          ),
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (final _) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880, maxHeight: 660),
            child: ThemeDesignerDialog(
              title: title,
              channelName: channelName,
              initialTheme: initialTheme,
              onApplyTheme: onApplyTheme,
              initialStyleType: initialStyleType,
              onApplyStyle: onApplyStyle,
              onApply: onApply,
              previewTitle: previewTitle,
              previewMessage: previewMessage,
              previewIcon: previewIcon,
              isNotificationOverride: isNotificationOverride,
            ),
          ),
        ),
      );
    }
  }

  @override
  State<ThemeDesignerDialog> createState() => _ThemeDesignerDialogState();
}

class _ThemeDesignerDialogState extends State<ThemeDesignerDialog> {
  late Color? _accentColor;
  late Type? _styleType;
  bool _previewDarkSurface = true;

  static const _seedPalette = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Crimson
    Color(0xFF8B5CF6), // Violet
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Pink
    Color(0xFF64748B), // Slate
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.initialTheme;
    _accentColor = t?.color;
    _styleType = widget.initialStyleType;
  }

  NotificationThemeData? _buildCurrentTheme() {
    if (_accentColor == null && widget.isNotificationOverride) {
      return null;
    }

    return NotificationThemeData(
      color: _accentColor,
    );
  }

  void _applySeedColor(final Color seed) {
    setState(() {
      _accentColor = seed;
    });
  }

  void _applyPreset(final String preset) {
    setState(() {
      switch (preset) {
        case 'success':
          _accentColor = const Color(0xFF2D7512);
        case 'error':
          _accentColor = const Color(0xFFD03332);
        case 'warning':
          _accentColor = const Color(0xFFC97725);
        case 'info':
          _accentColor = const Color(0xFF51B4F9);
      }
    });
  }

  void _testFire() {
    final theme = _buildCurrentTheme();
    final channelName = widget.channelName ?? 'default';

    NotificationScope.of(context).show(
      AppNotification(
        title: widget.previewTitle,
        message: widget.previewMessage,
        channelName: channelName,
        accentColor: theme?.accentColor,
        action: NotificationAction.button(
          label: 'DISMISS',
          onPressed: () {},
        ),
        dismissDuration: const Duration(seconds: 6),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification dispatched into active queue!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyCode() {
    final accentHex = _accentColor != null
        ? '0x${_accentColor!.toARGB32().toRadixString(16).padLeft(8, '0')}'
        : null;

    final buf = StringBuffer();
    if (_styleType != null) {
      final styleExpr = switch (_styleType) {
        == FilledQueueStyle => 'const FilledQueueStyle()',
        == OutlinedQueueStyle => 'const OutlinedQueueStyle()',
        == FlatQueueStyle => 'const FlatQueueStyle()',
        _ => 'const $_styleType()',
      };
      buf
        ..writeln('// Gear 1: Physical Style Archetype')
        ..writeln('final style = $styleExpr;\n');
    }

    buf
      ..writeln('// Gear 2: Chromatics Theme Tokens')
      ..writeln('const theme = NotificationThemeData(');
    if (accentHex != null) {
      buf.writeln('  color: Color($accentHex),');
    }
    buf.write(');');

    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied Style & Theme to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = StudioTheme.isDark;
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    return ClipRRect(
      borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: isDark ? 0.94 : 0.97),
            borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.25),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(colorScheme),
              Expanded(
                child: isMobile ? _buildMobileBody() : _buildDesktopBody(),
              ),
              _buildFooter(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(final ColorScheme colorScheme) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.palette_outlined,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.title.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (widget.channelName != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#${widget.channelName}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Fine-tune theme tokens, color palettes, '
                    'and style archetypes.',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Close',
            ),
          ],
        ),
      );

  Widget _buildDesktopBody() => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 16, 16),
              child: _buildControls(),
            ),
          ),
          Container(
            width: 1,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.08),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildPreviewPane(),
            ),
          ),
        ],
      );

  Widget _buildMobileBody() => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildCardPreviewOnly(),
          ),
          const Divider(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildControls(),
            ),
          ),
        ],
      );

  Widget _buildPreviewPane() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const StudioSectionHeader(title: 'LIVE CARD PREVIEW'),
              IconButton(
                icon: Icon(
                  _previewDarkSurface
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  size: 16,
                ),
                tooltip: 'Toggle preview canvas surface',
                onPressed: () => setState(
                  () => _previewDarkSurface = !_previewDarkSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: _buildCardPreviewOnly(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(double.infinity, 44),
            ),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text(
              'TEST FIRE INTO ACTIVE QUEUE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 11,
              ),
            ),
            onPressed: _testFire,
          ),
        ],
      );

  Widget _buildCardPreviewOnly() {
    final isDark = _previewDarkSurface;
    final accent = _accentColor ?? const Color(0xFF6366F1);
    final surfaceBg =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final surfaceFg =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    final Color cardBg;
    final Color cardFg;
    final Color iconColor;
    final ShapeBorder shapeBorder;
    final BoxBorder? directionalBorder;

    final resolvedRadius = _styleType == FlatQueueStyle
        ? BorderRadius.zero
        : const BorderRadius.all(Radius.circular(8));
    const resolvedElevation = 3.0;

    if (_styleType == FilledQueueStyle) {
      cardBg = accent;
      final autoFg =
          cardBg.computeLuminance() > 0.5 ? Colors.black : Colors.white;
      cardFg = autoFg;
      iconColor = cardFg;
      shapeBorder = RoundedSuperellipseBorder(borderRadius: resolvedRadius);
      directionalBorder = null;
    } else if (_styleType == FlatQueueStyle) {
      cardBg = surfaceBg;
      cardFg = surfaceFg;
      iconColor = accent;
      shapeBorder = RoundedRectangleBorder(borderRadius: resolvedRadius);
      directionalBorder = BorderDirectional(
        start: BorderSide(
          color: accent,
          width: 4.0,
        ),
      );
    } else {
      // OutlinedQueueStyle or default
      cardBg = surfaceBg;
      cardFg = surfaceFg;
      iconColor = accent;
      final borderCol = _styleType == OutlinedQueueStyle
          ? accent
          : (isDark ? Colors.white12 : Colors.black12);
      shapeBorder = RoundedRectangleBorder(
        borderRadius: resolvedRadius,
        side: BorderSide(color: borderCol, width: 1.0),
      );
      directionalBorder = null;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? StudioTheme.primaryColor.withValues(alpha: 0.85)
            : const Color(0xFFE2E8F0).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Material(
        elevation: resolvedElevation,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        color: cardBg,
        shape: shapeBorder,
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: directionalBorder,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconTheme(
                      data: IconThemeData(color: iconColor, size: 18),
                      child: widget.previewIcon,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.previewTitle,
                        style: TextStyle(
                          color: cardFg,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.close,
                      size: 14,
                      color: cardFg.withValues(alpha: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.previewMessage,
                  style: TextStyle(
                    color: cardFg.withValues(alpha: 0.8),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _styleType == FilledQueueStyle
                            ? cardFg.withValues(alpha: 0.15)
                            : accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ACTION',
                        style: TextStyle(
                          color:
                              _styleType == FilledQueueStyle ? cardFg : accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Presets & Seed Colors ──
          const StudioSectionHeader(title: 'COLOR PALETTE PRESETS'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _seedPalette.map((final c) {
            final isSelected = _accentColor == c;
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _applySeedColor(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: c.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _presetChip(
              'SUCCESS',
              const Color(0xFF2D7512),
              () => _applyPreset('success'),
            ),
            _presetChip(
              'ERROR',
              const Color(0xFFD03332),
              () => _applyPreset('error'),
            ),
            _presetChip(
              'WARNING',
              const Color(0xFFC97725),
              () => _applyPreset('warning'),
            ),
            _presetChip(
              'INFO',
              const Color(0xFF51B4F9),
              () => _applyPreset('info'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Chromatic Token (Gear 2) ──
        const StudioSectionHeader(title: 'CHROMATICS THEME TOKEN (GEAR 2)'),
        StudioColorSelectionTile(
          label: 'ACCENT / STATUS COLOR',
          value: _accentColor,
          onChanged: (final v) => setState(() => _accentColor = v),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: StudioTheme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: StudioTheme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: StudioTheme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Under the parametric model, the accent color drives '
                  'brand and status. The active QueueStyle archetype '
                  '(Filled, Outlined, Flat) deterministically distributes it '
                  'while guaranteeing WCAG contrast and ambient surface '
                  'consistency.',
                  style: TextStyle(
                    fontSize: 11,
                    color: StudioTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

  Widget _presetChip(
    final String label,
    final Color color,
    final VoidCallback onTap,
  ) {
    final colorScheme = StudioTheme.colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(final ColorScheme colorScheme) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
        ),
        child: Row(
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.code, size: 16),
              label: const Text('COPY CODE'),
              onPressed: _copyCode,
            ),
            const Spacer(),
            if (widget.isNotificationOverride)
              TextButton(
                onPressed: () {
                  widget.onApply?.call(null, null);
                  widget.onApplyTheme?.call(null);
                  widget.onApplyStyle?.call(null);
                  Navigator.of(context).pop();
                },
                child: const Text('RESET TO CHANNEL'),
              ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 16),
              onPressed: () {
                final newTheme = _buildCurrentTheme();
                widget.onApply?.call(newTheme, _styleType);
                widget.onApplyTheme?.call(newTheme);
                widget.onApplyStyle?.call(_styleType);
                Navigator.of(context).pop();
              },
              label: const Text(
                'APPLY THEME',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ],
        ),
      );
}
