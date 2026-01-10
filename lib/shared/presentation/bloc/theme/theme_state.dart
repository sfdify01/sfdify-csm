part of 'theme_bloc.dart';

class ThemeState extends Equatable {
  const ThemeState({
    this.themeMode = ThemeMode.system,
  });

  final ThemeMode themeMode;

  ThemeState copyWith({
    ThemeMode? themeMode,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.index,
    };
  }

  factory ThemeState.fromJson(Map<String, dynamic> json) {
    return ThemeState(
      themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
    );
  }

  @override
  List<Object?> get props => [themeMode];
}
