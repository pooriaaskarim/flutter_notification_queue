import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Events ──

sealed class StudioEvent {
  const StudioEvent();
}

final class ToggleTheme extends StudioEvent {
  const ToggleTheme();
}

// ── State ──

class StudioState {
  const StudioState({this.themeMode = ThemeMode.dark});

  final ThemeMode themeMode;

  StudioState copyWith({final ThemeMode? themeMode}) =>
      StudioState(themeMode: themeMode ?? this.themeMode);
}

// ── Bloc ──

/// Manages Studio appearance — theme and future layout concerns.
class StudioBloc extends Bloc<StudioEvent, StudioState> {
  StudioBloc() : super(const StudioState()) {
    on<ToggleTheme>((final event, final emit) {
      emit(
        state.copyWith(
          themeMode: state.themeMode == ThemeMode.dark
              ? ThemeMode.light
              : ThemeMode.dark,
        ),
      );
    });
  }
}
