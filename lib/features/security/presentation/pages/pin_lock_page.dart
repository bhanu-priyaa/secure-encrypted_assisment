import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../app/presentation/cubit/session_cubit.dart';
import '../../domain/repositories/pin_repository.dart';
import '../cubit/pin_lock_cubit.dart';
import '../widgets/pin_widgets.dart';

class PinLockPage extends StatelessWidget {
  const PinLockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PinLockCubit(context.read<PinRepository>()),
      child: const _PinLockView(),
    );
  }
}

class _PinLockView extends StatelessWidget {
  const _PinLockView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<PinLockCubit, PinLockState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        final session = context.read<SessionCubit>();
        if (state.status == PinLockStatus.unlocked) {
          session.unlock();
        } else if (state.status == PinLockStatus.lockedOut) {
          session.logout(
            notice: 'Too many incorrect PIN attempts. Please sign in again.',
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.navy,
        body: SafeArea(
          child: BlocBuilder<PinLockCubit, PinLockState>(
            builder: (context, state) {
              final cubit = context.read<PinLockCubit>();
              final busy = state.status != PinLockStatus.idle;

              return Column(
                children: [
                  const Spacer(flex: 2),
                  Container(
                    height: 62,
                    width: 62,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.lock_outline, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Enter your PIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Unlock to return to your profile.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 34),
                  PinDots(filled: state.entry.length, onDark: true),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 30,
                    child: state.error != null
                        ? Text(
                            state.error!,
                            style: const TextStyle(
                              color: Color(0xFFFF9AA8),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : null,
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: PinKeypad(
                      enabled: !busy,
                      onDark: true,
                      onDigit: cubit.append,
                      onBackspace: cubit.backspace,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => context.read<SessionCubit>().logout(),
                    child: const Text(
                      'Log out instead',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
