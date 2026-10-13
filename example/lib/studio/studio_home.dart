import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/notification_bloc.dart';
import 'bloc/studio_bloc.dart';
import 'panels/code_editor_panel.dart';
import 'panels/configurator_panel.dart';
import 'panels/event_log_panel.dart';
import 'studio_theme.dart';
import 'widgets/project_info_dialog.dart';
import 'widgets/quick_fire_cockpit.dart';

/// The root layout for NFQ Studio.
///
/// Provides [StudioBloc] and renders a responsive split-pane layout:
/// - **Wide screens**: Configurator (left) + Code Editor (right)
/// - **Narrow screens**: Tabbed view with bottom navigation & preview FAB
class StudioHome extends StatelessWidget {
  const StudioHome({super.key});

  @override
  Widget build(final BuildContext context) => const _StudioShell();
}

class _StudioShell extends StatefulWidget {
  const _StudioShell();

  @override
  State<_StudioShell> createState() => _StudioShellState();
}

class _StudioShellState extends State<_StudioShell> {
  int _tabIndex = 0;

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
        builder: (final context, final constraints) {
          final isNarrow = constraints.maxWidth <= 1000;
          final colorScheme = Theme.of(context).colorScheme;

          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.enter, meta: true): () {
                context.read<NotificationBloc>().add(const FirePreview());
              },
              const SingleActivator(LogicalKeyboardKey.enter, control: true):
                  () {
                context.read<NotificationBloc>().add(const FirePreview());
              },
            },
            child: Scaffold(
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isNarrow ? 'NFQ' : 'NFQ STUDIO',
                      style: TextStyle(
                        letterSpacing: isNarrow ? 1.2 : 3,
                        fontWeight: FontWeight.w900,
                        fontSize: isNarrow ? 16 : 18,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const _VersionBadge(),
                  ],
                ),
                centerTitle: !isNarrow,
                backgroundColor: colorScheme.surface.withValues(alpha: 0.88),
                elevation: 0,
                actions: [
                  if (isNarrow) ...[
                    // Mobile Primary CTA: Fire Draft
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.bolt_rounded, size: 15),
                      label: const Text(
                        'FIRE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      onPressed: () => context
                          .read<NotificationBloc>()
                          .add(const FirePreview()),
                    ),
                    const SizedBox(width: 4),
                    // Mobile Presets Launcher
                    Tooltip(
                      message: 'Quick Presets',
                      child: IconButton(
                        icon: const Icon(Icons.flash_on_outlined, size: 20),
                        onPressed: () => QuickFireCockpit.showModal(context),
                      ),
                    ),
                  ],
                  IconButton(
                    onPressed: () => ProjectInfoDialog.show(context),
                    icon: const Icon(Icons.info_outline, size: 20),
                    tooltip: 'About & Project Info',
                  ),
                  BlocBuilder<StudioBloc, StudioState>(
                    builder: (final context, final state) => IconButton(
                      onPressed: () {
                        context.read<StudioBloc>().add(const ToggleTheme());
                      },
                      icon: Icon(
                        state.themeMode == ThemeMode.dark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        size: 20,
                      ),
                      tooltip: 'Toggle Theme',
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
              body: Stack(
                children: [
                  const _StudioBackground(),
                  SafeArea(
                    child: Column(
                      children: [
                        if (!isNarrow) const QuickFireCockpit(),
                        Expanded(
                          child: isNarrow ? _narrowLayout() : _wideLayout(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: isNarrow
                  ? BottomNavigationBar(
                      currentIndex: _tabIndex,
                      onTap: (final i) => setState(() => _tabIndex = i),
                      backgroundColor: StudioTheme.colorScheme.surface,
                      selectedItemColor: StudioTheme.colorScheme.primary,
                      unselectedItemColor: StudioTheme.colorScheme.onSurface
                          .withValues(alpha: 0.38),
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.tune),
                          label: 'Configure',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.code),
                          label: 'Code',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.stream_rounded),
                          label: 'Events',
                        ),
                      ],
                    )
                  : null,
            ),
          );
        },
      );

  Widget _wideLayout() => Row(
        children: [
          const Expanded(child: ConfiguratorPanel()),
          Container(
            width: 1,
            color: StudioTheme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
          const Expanded(child: CodeEditorPanel()),
          Container(
            width: 1,
            color: StudioTheme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
          const SizedBox(width: 280, child: EventLogPanel()),
        ],
      );

  Widget _narrowLayout() => IndexedStack(
        index: _tabIndex,
        children: const [
          ConfiguratorPanel(),
          CodeEditorPanel(),
          EventLogPanel(),
        ],
      );
}

class _StudioBackground extends StatelessWidget {
  const _StudioBackground();

  @override
  Widget build(final BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.8, -0.8),
            radius: 1.5,
            colors: [
              StudioTheme.colorScheme.surface,
              StudioTheme.theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -120,
              child: Container(
                width: 450,
                height: 450,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      StudioTheme.colorScheme.primary.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF8B5CF6).withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _VersionBadge extends StatefulWidget {
  const _VersionBadge();

  @override
  State<_VersionBadge> createState() => _VersionBadgeState();
}

class _VersionBadgeState extends State<_VersionBadge> {
  late final Future<String?> _versionFuture;

  @override
  void initState() {
    super.initState();
    _versionFuture = _loadVersion();
  }

  static Future<String?> _loadVersion() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assetKeys = manifest.listAssets();
      for (final key in assetKeys.where(
        (final k) => k.contains('pubspec.yaml'),
      )) {
        try {
          final content = await rootBundle.loadString(key);
          final match =
              RegExp(r'^version:\s*([^\s+]+)', multiLine: true).firstMatch(content);
          if (match?.group(1) != null) {
            return match!.group(1);
          }
        } on Object catch (_) {}
      }
    } on Object catch (_) {}

    final candidates = [
      'packages/flutter_notification_queue/pubspec.yaml',
      '../pubspec.yaml',
      'pubspec.yaml',
      'assets/pubspec.yaml',
    ];

    for (final candidate in candidates) {
      try {
        final content = await rootBundle.loadString(candidate);
        final match =
            RegExp(r'^version:\s*([^\s+]+)', multiLine: true).firstMatch(content);
        if (match?.group(1) != null) {
          return match!.group(1);
        }
      } on Object catch (_) {}
    }
    return null;
  }

  @override
  Widget build(final BuildContext context) => FutureBuilder<String?>(
        future: _versionFuture,
        builder: (final context, final snapshot) {
          final version = snapshot.data;
          if (version == null || version.isEmpty) {
            return const SizedBox.shrink();
          }
          return GestureDetector(
            onTap: () => ProjectInfoDialog.show(context, version: version),
            child: Text(
              'v$version',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.45),
                letterSpacing: 0.5,
              ),
            ),
          );
        },
      );
}
