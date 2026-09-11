import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../onboarding/domain/repositories/onboarding_repository.dart';
import '../../../security/domain/repositories/pin_repository.dart';
import '../../../settings/domain/repositories/settings_repository.dart';

enum AppDestination { splash, intro, login, home }

class SessionState extends Equatable {
  const SessionState({
    this.destination = AppDestination.splash,
    this.themeMode = ThemeMode.system,
    this.pinSet = false,
    this.locked = false,
    this.notice,
  });

  final AppDestination destination;
  final ThemeMode themeMode;
  final bool pinSet;
  final bool locked;
  final String? notice;

  SessionState copyWith({
    AppDestination? destination,
    ThemeMode? themeMode,
    bool? pinSet,
    bool? locked,
    String? notice,
    bool clearNotice = false,
  }) {
    return SessionState(
      destination: destination ?? this.destination,
      themeMode: themeMode ?? this.themeMode,
      pinSet: pinSet ?? this.pinSet,
      locked: locked ?? this.locked,
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }

  @override
  List<Object?> get props => [destination, themeMode, pinSet, locked, notice];
}

class SessionCubit extends Cubit<SessionState> {
  SessionCubit({
    required AuthRepositoryImpl authRepository,
    required PinRepository pinRepository,
    required SettingsRepository settingsRepository,
    required OnboardingRepository onboardingRepository,
  }) : _auth = authRepository,
       _pin = pinRepository,
       _settings = settingsRepository,
       _onboarding = onboardingRepository,
       super(const SessionState()) {
    _expirySub = _auth.sessionExpired.listen((_) => _onSessionExpired());
  }

  final AuthRepositoryImpl _auth;
  final PinRepository _pin;
  final SettingsRepository _settings;
  final OnboardingRepository _onboarding;

  late final StreamSubscription<void> _expirySub;

  Future<void> bootstrap() async {
    final started = DateTime.now();

    emit(state.copyWith(themeMode: _settings.themeMode));

    final hasSession = await _auth.hasSession();
    final pinSet = await _pin.isPinSet();

    final elapsed = DateTime.now().difference(started);
    if (elapsed < AppConfig.splashMinDuration) {
      await Future<void>.delayed(AppConfig.splashMinDuration - elapsed);
    }

    if (!hasSession) {
      emit(
        state.copyWith(
          destination: _onboarding.introSeen
              ? AppDestination.login
              : AppDestination.intro,
          pinSet: pinSet,
          locked: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(destination: AppDestination.home, pinSet: pinSet, locked: pinSet),
    );
  }

  Future<void> completeIntro() async {
    await _onboarding.markIntroSeen();
    emit(state.copyWith(destination: AppDestination.login));
  }

  void onLoggedIn() {
    emit(
      state.copyWith(destination: AppDestination.home, locked: false, clearNotice: true),
    );
  }

  Future<void> refreshPinStatus() async {
    emit(state.copyWith(pinSet: await _pin.isPinSet()));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _settings.setThemeMode(mode);
    emit(state.copyWith(themeMode: mode));
  }

  void lockIfNeeded() {
    if (state.pinSet && state.destination == AppDestination.home && !state.locked) {
      emit(state.copyWith(locked: true));
    }
  }

  void unlock() => emit(state.copyWith(locked: false));

  Future<void> logout({String? notice}) async {
    await _auth.logout();
    emit(
      SessionState(
        destination: AppDestination.login,
        themeMode: state.themeMode,
        notice: notice,
      ),
    );
  }

  void consumeNotice() => emit(state.copyWith(clearNotice: true));

  Future<void> _onSessionExpired() async {
    emit(
      SessionState(
        destination: AppDestination.login,
        themeMode: state.themeMode,
        notice: 'Your session has expired. Please sign in again.',
      ),
    );
  }

  @override
  Future<void> close() {
    _expirySub.cancel();
    return super.close();
  }
}
