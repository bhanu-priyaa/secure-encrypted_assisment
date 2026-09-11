import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/cubit/login_cubit.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../onboarding/presentation/pages/intro_page.dart';
import '../../../onboarding/presentation/pages/splash_page.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../security/domain/repositories/pin_repository.dart';
import '../../../security/presentation/pages/pin_lock_page.dart';
import '../cubit/session_cubit.dart';
import 'home_shell.dart';
import 'lifecycle_gate.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({required this.injector, super.key});

  final Injector injector;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: injector.authRepository),
        RepositoryProvider<ProfileRepository>.value(value: injector.profileRepository),
        RepositoryProvider<PinRepository>.value(value: injector.pinRepository),
      ],
      child: BlocProvider(
        create: (context) => SessionCubit(
          authRepository: injector.authRepository,
          pinRepository: injector.pinRepository,
          settingsRepository: injector.settingsRepository,
          onboardingRepository: injector.onboardingRepository,
        )..bootstrap(),
        child: BlocBuilder<SessionCubit, SessionState>(
          buildWhen: (previous, current) => previous.themeMode != current.themeMode,
          builder: (context, state) {
            return MaterialApp(
              title: 'Vault',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: state.themeMode,
              home: const LifecycleGate(child: _DestinationView()),
            );
          },
        ),
      ),
    );
  }
}

class _DestinationView extends StatelessWidget {
  const _DestinationView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionCubit, SessionState>(
      buildWhen: (previous, current) =>
          previous.destination != current.destination ||
          previous.locked != current.locked,
      builder: (context, state) {
        return switch (state.destination) {
          AppDestination.splash => const SplashPage(),
          AppDestination.intro => const IntroPage(),
          AppDestination.login => BlocProvider(
            create: (context) => LoginCubit(context.read<AuthRepository>()),
            child: const LoginPage(),
          ),
          AppDestination.home => BlocProvider(
            create: (context) => ProfileCubit(context.read<ProfileRepository>()),
            child: Stack(
              children: [
                Offstage(offstage: state.locked, child: const HomeShell()),
                if (state.locked) const Positioned.fill(child: PinLockPage()),
              ],
            ),
          ),
        };
      },
    );
  }
}
