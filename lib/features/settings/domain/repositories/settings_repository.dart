import 'package:flutter/material.dart';

abstract interface class SettingsRepository {
  ThemeMode get themeMode;

  Future<void> setThemeMode(ThemeMode mode);
}
