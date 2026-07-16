import 'package:flutter/material.dart';

/// Uygulamanın gece/gündüz tema modunu yöneten singleton.
class ThemeManager {
  ThemeManager._();
  static final ThemeManager instance = ThemeManager._();

  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
    ThemeMode.light,
  );

  ThemeMode get themeMode => themeModeNotifier.value;
  bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  void toggleTheme() {
    themeModeNotifier.value = themeModeNotifier.value == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
  }
}
