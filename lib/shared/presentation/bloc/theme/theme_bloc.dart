import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

part 'theme_event.dart';
part 'theme_state.dart';

@singleton
class ThemeBloc extends HydratedBloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState()) {
    on<ThemeChanged>(_onThemeChanged);
    on<ThemeToggled>(_onThemeToggled);
  }

  void _onThemeChanged(ThemeChanged event, Emitter<ThemeState> emit) {
    emit(state.copyWith(themeMode: event.themeMode));
  }

  void _onThemeToggled(ThemeToggled event, Emitter<ThemeState> emit) {
    final newThemeMode = switch (state.themeMode) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      ThemeMode.system => ThemeMode.light,
    };
    emit(state.copyWith(themeMode: newThemeMode));
  }

  @override
  ThemeState? fromJson(Map<String, dynamic> json) {
    return ThemeState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(ThemeState state) {
    return state.toJson();
  }
}
