import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/repositories/pin_repository.dart';

enum SetPinStep { verifyCurrent, enter, confirm, saving, done }

class SetPinState extends Equatable {
  const SetPinState({this.step = SetPinStep.enter, this.entry = '', this.error});

  final SetPinStep step;
  final String entry;
  final String? error;

  SetPinState copyWith({SetPinStep? step, String? entry, String? error}) {
    return SetPinState(step: step ?? this.step, entry: entry ?? this.entry, error: error);
  }

  @override
  List<Object?> get props => [step, entry, error];
}

class SetPinCubit extends Cubit<SetPinState> {
  SetPinCubit(this._pin, {required bool requireCurrentPin})
    : super(
        SetPinState(
          step: requireCurrentPin ? SetPinStep.verifyCurrent : SetPinStep.enter,
        ),
      );

  final PinRepository _pin;

  String _firstEntry = '';

  void append(int digit) {
    if (state.step == SetPinStep.saving || state.step == SetPinStep.done) return;
    if (state.entry.length >= AppConfig.pinLength) return;

    final next = '${state.entry}$digit';
    emit(state.copyWith(entry: next));

    if (next.length == AppConfig.pinLength) _onComplete(next);
  }

  void backspace() {
    if (state.entry.isEmpty) return;
    if (state.step == SetPinStep.saving || state.step == SetPinStep.done) return;
    emit(state.copyWith(entry: state.entry.substring(0, state.entry.length - 1)));
  }

  Future<void> _onComplete(String value) async {
    switch (state.step) {
      case SetPinStep.verifyCurrent:
        final ok = await _pin.verifyPin(value);
        emit(
          ok
              ? const SetPinState()
              : const SetPinState(
                  step: SetPinStep.verifyCurrent,
                  error: 'That is not your current PIN.',
                ),
        );

      case SetPinStep.enter:
        _firstEntry = value;
        emit(const SetPinState(step: SetPinStep.confirm));

      case SetPinStep.confirm:
        if (value != _firstEntry) {
          _firstEntry = '';
          emit(const SetPinState(error: 'Those PINs did not match. Start again.'));
          return;
        }
        emit(SetPinState(step: SetPinStep.saving, entry: value));
        await _pin.setPin(value);
        _firstEntry = '';
        emit(const SetPinState(step: SetPinStep.done));

      case SetPinStep.saving:
      case SetPinStep.done:
        return;
    }
  }
}
