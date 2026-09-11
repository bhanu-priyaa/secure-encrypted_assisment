import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failure.dart';
import '../../domain/repositories/auth_repository.dart';

enum LoginStatus { idle, submitting, success, failure }

class LoginState extends Equatable {
  const LoginState({
    this.status = LoginStatus.idle,
    this.usernameError,
    this.passwordError,
    this.formError,
  });

  final LoginStatus status;
  final String? usernameError;
  final String? passwordError;
  final String? formError;

  bool get isSubmitting => status == LoginStatus.submitting;

  @override
  List<Object?> get props => [status, usernameError, passwordError, formError];
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._auth) : super(const LoginState());

  final AuthRepository _auth;

  Future<void> submit({required String username, required String password}) async {
    if (state.isSubmitting) return;

    final usernameError = username.trim().isEmpty ? 'Username is required.' : null;
    final passwordError = switch (password) {
      '' => 'Password is required.',
      _ when password.length < AppConfig.minPasswordLength =>
        'Password must be at least ${AppConfig.minPasswordLength} characters.',
      _ => null,
    };

    if (usernameError != null || passwordError != null) {
      emit(LoginState(usernameError: usernameError, passwordError: passwordError));
      return;
    }

    emit(const LoginState(status: LoginStatus.submitting));

    try {
      await _auth.login(username: username.trim(), password: password);
      emit(const LoginState(status: LoginStatus.success));
    } on Failure catch (failure) {
      emit(LoginState(status: LoginStatus.failure, formError: failure.message));
    }
  }

  void clearErrors() {
    if (state.formError != null ||
        state.usernameError != null ||
        state.passwordError != null) {
      emit(const LoginState());
    }
  }
}
