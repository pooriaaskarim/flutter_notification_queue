import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/studio_bloc.dart';
import 'bloc/studio_event.dart';
import 'bloc/studio_state.dart';
import 'panels/code_editor_panel.dart';
import 'panels/configurator_panel.dart';

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
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),
          actions: [
            BlocBuilder<StudioBloc, StudioState>(
              builder: (final context, final state) => IconButton(
                onPressed: () {
                  final newMode = state.themeMode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
                  context.read<StudioBloc>().add(UpdateThemeMode(newMode));
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
                  if (constraints.maxWidth > 800) {
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
            if (constraints.maxWidth > 800) {
              return const SizedBox.shrink();
            }
            return BottomNavigationBar(
              currentIndex: _tabIndex,
              onTap: (final i) => setState(() => _tabIndex = i),
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Theme.of(context)
                  .colorScheme
                  .onSurface
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
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
          ),
          const Expanded(child: CodeEditorPanel()),
        ],
      );

  Widget _narrowLayout() => IndexedStack(
        index: _tabIndex,
        children: const [
          ConfiguratorPanel(),
          CodeEditorPanel(),
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
              Theme.of(context).colorScheme.surface,
              Theme.of(context).scaffoldBackgroundColor,
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
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.08),
                ),
              ),
            ),
          ],
        ),
      );
}
