import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/notification_bloc.dart';
import '../bloc/setup_bloc.dart';
import '../engine/code_generator.dart';
import '../engine/dart_syntax_highlighter.dart';

/// The right-side code editor panel displaying generated Dart code
/// with copy, reset, and live preview actions.
///
/// Reads `StudioSetup` from `SetupBloc` and `NotificationDraft`
/// from `NotificationBloc`.
class CodeEditorPanel extends StatelessWidget {
  const CodeEditorPanel({super.key});

  @override
  Widget build(final BuildContext context) =>
      BlocBuilder<SetupBloc, SetupState>(
        builder: (final context, final setupState) =>
            BlocBuilder<NotificationBloc, NotificationDraft>(
          builder: (final context, final draft) {
            final code = generateCode(
              setup: setupState.setup,
              draft: draft,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.03),
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.code,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'GENERATED CODE',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.54),
                        ),
                      ),
                      const Spacer(),
                      _ActionChip(
                        icon: Icons.content_copy,
                        label: 'Copy',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Code copied to clipboard'),
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _ActionChip(
                        icon: Icons.refresh,
                        label: 'Reset',
                        onPressed: () {
                          context.read<SetupBloc>().add(const ResetSetup());
                          context
                              .read<NotificationBloc>()
                              .add(const ResetDraft());
                        },
                      ),
                    ],
                  ),
                ),

                // ── Hints ──
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.05),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _hintForState(setupState, draft),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Code Display (syntax highlighted) ──
                Expanded(
                  child: Container(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF0D1117)
                        : const Color(0xFFF6F8FA),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                      child: _HighlightedCodeView(code: code),
                    ),
                  ),
                ),

                // ── Preview Button ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.03),
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => context
                          .read<NotificationBloc>()
                          .add(const FirePreview()),
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: const Text(
                        'FIRE PREVIEW',
                        style: TextStyle(
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

  String _hintForState(
    final SetupState setupState,
    final NotificationDraft draft,
  ) {
    final queues = setupState.setup.queues;
    final channels = setupState.setup.channels;

    if (queues.length > 1) {
      return '💡 ${queues.length} queues configured. '
          'Each generates its own NotificationQueue block.';
    }
    if (channels.length > 4) {
      return '💡 ${channels.length} channels including custom ones. '
          'Nice!';
    }
    if (draft.dismissSeconds == null) {
      return '💡 Permanent notification — user must manually dismiss.';
    }
    return '💡 Adjust parameters in the configurator to see '
        'code update live.';
  }
}

/// Renders [code] with a line-number gutter and Dart syntax highlighting.
class _HighlightedCodeView extends StatefulWidget {
  const _HighlightedCodeView({required this.code});
  final String code;

  @override
  State<_HighlightedCodeView> createState() => _HighlightedCodeViewState();
}

class _HighlightedCodeViewState extends State<_HighlightedCodeView> {
  late TextSpan _highlightedCode;
  late List<String> _lines;
  String? _lastCode;

  void _updateHighlight() {
    if (_lastCode == widget.code) {
      return;
    }
    _lastCode = widget.code;
    _highlightedCode = DartSyntaxHighlighter.highlight(widget.code);
    _lines = widget.code.split('\n');
  }

  @override
  void initState() {
    super.initState();
    _updateHighlight();
  }

  @override
  void didUpdateWidget(covariant final _HighlightedCodeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateHighlight();
  }

  @override
  Widget build(final BuildContext context) {
    _updateHighlight();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gutterColor =
        isDark ? const Color(0xFF161B22) : const Color(0xFFEAECEF);
    final gutterTextColor =
        isDark ? const Color(0xFF484F58) : const Color(0xFFAFB8C1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Line number gutter ──
        Container(
          color: gutterColor,
          padding: const EdgeInsets.fromLTRB(12, 0, 10, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              _lines.length,
              (final i) => SizedBox(
                height: 20.8, // ~13px * 1.6 line-height
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.6,
                    color: gutterTextColor,
                  ),
                ),
              ),
            ),
          ),
        ),
        // ── Highlighted code ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: SelectableText.rich(
              _highlightedCode,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.54),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.54),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
