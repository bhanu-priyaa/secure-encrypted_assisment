import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/profile_snapshot.dart';
import '../../domain/repositories/profile_repository.dart';

enum ProfileStatus { loading, success, failure }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.loading,
    this.snapshot,
    this.errorMessage,
  });

  final ProfileStatus status;
  final ProfileSnapshot? snapshot;
  final String? errorMessage;

  @override
  List<Object?> get props => [
    status,
    snapshot?.user,
    snapshot?.source,
    snapshot?.cachedAt,
    errorMessage,
  ];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileState());

  final ProfileRepository _repository;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(const ProfileState());

    try {
      emit(
        ProfileState(
          status: ProfileStatus.success,
          snapshot: await _repository.getProfile(),
        ),
      );
    } on Failure catch (failure) {
      emit(
        ProfileState(
          status: ProfileStatus.failure,
          snapshot: state.snapshot,
          errorMessage: failure.message,
        ),
      );
    }
  }
}
