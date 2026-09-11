import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/repositories/pin_repository.dart';
import '../cubit/set_pin_cubit.dart';
import '../widgets/pin_widgets.dart';

class SetPinPage extends StatelessWidget {
  const SetPinPage({required this.requireCurrentPin, super.key});

  final bool requireCurrentPin;

  static Route<bool> route({required bool requireCurrentPin}) {
    return MaterialPageRoute<bool>(
      builder: (_) => SetPinPage(requireCurrentPin: requireCurrentPin),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SetPinCubit(
        context.read<PinRepository>(),
        requireCurrentPin: requireCurrentPin,
      ),
      child: const _SetPinView(),
    );
  }
}

class _SetPinView extends StatelessWidget {
  const _SetPinView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocListener<SetPinCubit, SetPinState>(
      listenWhen: (previous, current) => previous.step != current.step,
      listener: (context, state) {
        if (state.step == SetPinStep.done) Navigator.of(context).pop(true);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Create app lock PIN')),
        body: SafeArea(
          child: BlocBuilder<SetPinCubit, SetPinState>(
            builder: (context, state) {
              final cubit = context.read<SetPinCubit>();
              final busy = state.step == SetPinStep.saving;

              return Column(
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 34),
                    child: Text(
                      _instruction(state.step),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  PinDots(filled: state.entry.length),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 34,
                    child: state.error != null
                        ? Text(
                            state.error!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.danger,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : Text(
                            _stepHint(state.step),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: PinKeypad(
                      enabled: !busy,
                      onDigit: cubit.append,
                      onBackspace: cubit.backspace,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static String _instruction(SetPinStep step) => switch (step) {
    SetPinStep.verifyCurrent => 'Enter your current PIN to continue.',
    SetPinStep.confirm => 'Enter the same six digits again to confirm.',
    _ => 'Choose a 6-digit PIN. You will need it each time you reopen the app.',
  };

  static String _stepHint(SetPinStep step) => switch (step) {
    SetPinStep.verifyCurrent => 'Current PIN',
    SetPinStep.confirm => 'Step 2 of 2 - confirm your PIN',
    SetPinStep.saving => 'Securing your PIN...',
    _ => 'Step 1 of 2 - you will confirm it next',
  };
}
