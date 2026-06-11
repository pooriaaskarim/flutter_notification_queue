import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/studio_bloc.dart';
import 'panels/code_editor_panel.dart';
import 'panels/configurator_panel.dart';
import 'panels/event_log_panel.dart';
import 'studio_theme.dart';

/// The root layout for NFQ Studio.
///
/// Provides [StudioBloc] and renders a responsive split-pane layout:
/// - **Wide screens**: Configurator (left) + Code Editor (right)
/// - **Narrow screens**: Tabbed view with bottom navigation
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
  Widget build(final BuildContext context) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'NFQ STUDIO',
            style: TextStyle(
              letterSpacing: 4,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context)
              .colorScheme
              .surface
              .withValues(alpha: 0.85),
          elevation: 0,
          actions: [
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
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            const _StudioBackground(),
            SafeArea(
              child: LayoutBuilder(
                builder: (final context, final constraints) {
                  if (constraints.maxWidth > 1000) {
                    return _wideLayout();
                  }
                  return _narrowLayout();
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: LayoutBuilder(
          builder: (final context, final constraints) {
            if (constraints.maxWidth > 1000) {
              return const SizedBox.shrink();
            }
            return BottomNavigationBar(
              currentIndex: _tabIndex,
              onTap: (final i) => setState(() => _tabIndex = i),
              backgroundColor: StudioTheme.colorScheme.surface,
              selectedItemColor: StudioTheme.colorScheme.primary,
              unselectedItemColor:
                  StudioTheme.colorScheme.onSurface.withValues(alpha: 0.38),
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
            );
          },
        ),
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
              top: -100,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      StudioTheme.colorScheme.primary.withValues(alpha: 0.08),
                ),
              ),
            ),
          ],
        ),
      );
}
