import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/studio_bloc.dart';
import '../bloc/studio_event.dart';
import '../bloc/studio_state.dart';
import '../engine/code_generator.dart';

/// The right-side code editor panel displaying generated Dart code
/// with copy, reset, and live preview actions.
class CodeEditorPanel extends StatelessWidget {
  const CodeEditorPanel({super.key});

  @override
  Widget build(final BuildContext context) =>
      BlocBuilder<StudioBloc, StudioState>(
        builder: (final context, final state) {
          final code = generateCode(state);
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
                      onPressed: () => context
                          .read<StudioBloc>()
                          .add(const ResetToDefaults()),
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
                        _hintForState(state),
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              Theme.of(context).colorScheme.primary.withValues(
                                    alpha: 0.7,
                                  ),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Code Display ──
              Expanded(
                child: Container(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF0D1117)
                      : const Color(0xFFF6F8FA),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: SelectableText(
                      code,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.6,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFE6EDF3)
                            : const Color(0xFF24292F),
                      ),
                    ),
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
                    onPressed: () =>
                        context.read<StudioBloc>().add(const FirePreview()),
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
      );

  String _hintForState(final StudioState state) {
    if (state.closeButton == CloseButtonType.hidden &&
        state.dragBehavior == BehaviorType.disabled &&
        state.longPressBehavior == BehaviorType.disabled) {
      return '⚠️ Hidden close button with no drag '
          'behavior = zombie notifications!';
    }
    if (state.dragBehavior == BehaviorType.relocate &&
        state.relocatePositions.isEmpty) {
      return '💡 Select relocate target positions in the configurator.';
    }
    if (state.dismissDuration == null) {
      return '💡 Permanent notification — user must manually dismiss.';
    }
    return '💡 Adjust parameters in the configurator to see code update live.';
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
                Icon(icon,
                    size: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.54)),
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
