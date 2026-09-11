import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/repositories/pin_repository.dart';

enum PinLockStatus { idle, checking, unlocked, lockedOut }

class PinLockState extends Equatable {
  const PinLockState({
    this.status = PinLockStatus.idle,
    this.entry = '',
    this.attemptsUsed = 0,
    this.error,
  });

  final PinLockStatus status;
  final String entry;
  final int attemptsUsed;
  final String? error;

  int get attemptsRemaining => AppConfig.maxPinAttempts - attemptsUsed;

  @override
  List<Object?> get props => [status, entry, attemptsUsed, error];
}

class PinLockCubit extends Cubit<PinLockState> {
  PinLockCubit(this._pin) : super(const PinLockState());

  final PinRepository _pin;

  void append(int digit) {
    if (state.status != PinLockStatus.idle) return;
    if (state.entry.length >= AppConfig.pinLength) return;

    final next = '${state.entry}$digit';
    emit(PinLockState(entry: next, attemptsUsed: state.attemptsUsed, error: state.error));

    if (next.length == AppConfig.pinLength) _verify(next);
  }

  void backspace() {
    if (state.entry.isEmpty || state.status != PinLockStatus.idle) return;
    emit(
      PinLockState(
        entry: state.entry.substring(0, state.entry.length - 1),
        attemptsUsed: state.attemptsUsed,
        error: state.error,
      ),
    );
  }

  Future<void> _verify(String value) async {
    emit(
      PinLockState(
        status: PinLockStatus.checking,
        entry: value,
        attemptsUsed: state.attemptsUsed,
      ),
    );

    if (await _pin.verifyPin(value)) {
      emit(const PinLockState(status: PinLockStatus.unlocked));
      return;
    }

    final used = state.attemptsUsed + 1;
    if (used >= AppConfig.maxPinAttempts) {
      emit(PinLockState(status: PinLockStatus.lockedOut, attemptsUsed: used));
      return;
    }

    final left = AppConfig.maxPinAttempts - used;
    final noun = left == 1 ? 'attempt' : 'attempts';
    emit(
      PinLockState(attemptsUsed: used, error: 'Incorrect PIN. $left $noun remaining.'),
    );
  }
}
