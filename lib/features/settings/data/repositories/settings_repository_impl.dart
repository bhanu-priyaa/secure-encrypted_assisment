import 'package:flutter/material.dart';

import '../../../../core/storage/prefs_store.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._prefs);

  final PrefsStore _prefs;

  @override
  ThemeMode get themeMode => switch (_prefs.themeMode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  @override
  Future<void> setThemeMode(ThemeMode mode) => _prefs.setThemeMode(mode.name);
}
