import 'dart:async';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/failure.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';

abstract class ProfileEvent { const ProfileEvent(); }
class ProfileStarted extends ProfileEvent { const ProfileStarted(); }
class ProfileRefreshed extends ProfileEvent { const ProfileRefreshed([this.done]); final Completer<void>? done; }
class FollowPressed extends ProfileEvent { const FollowPressed(); }
class UnfollowPressed extends ProfileEvent { const UnfollowPressed(); }
class PrivacyToggled extends ProfileEvent { const PrivacyToggled(this.value); final bool value; }
class AvatarPicked extends ProfileEvent { const AvatarPicked(this.bytes, this.ext); final Uint8List bytes; final String ext; }
class ProfileEdited extends ProfileEvent {
  const ProfileEdited({this.fullName, this.bio, this.username});
  final String? fullName, bio, username;
}

enum ProfileStatus { loading, success, failure }

class ProfileState extends Equatable {
  const ProfileState({this.profile, this.status = ProfileStatus.loading, this.busy = false, this.error, this.notice});
  final Profile? profile; final ProfileStatus status; final bool busy;
  final String? error;   // raw backend message
  final String? notice;  // l10n key
  ProfileState copyWith({Profile? profile, ProfileStatus? status, bool? busy, String? error, String? notice, bool clear = false}) => ProfileState(
      profile: profile ?? this.profile, status: status ?? this.status, busy: busy ?? this.busy,
      error: clear ? null : (error ?? this.error), notice: clear ? null : (notice ?? this.notice));
  @override
  List<Object?> get props => [profile, status, busy, error, notice];
}

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._repo, this.userId) : super(const ProfileState()) {
    on<ProfileStarted>((e, emit) async { emit(state.copyWith(status: ProfileStatus.loading, clear: true)); await _load(emit); });
    on<ProfileRefreshed>((e, emit) async { try { await _load(emit); } finally { e.done?.complete(); } });
    on<FollowPressed>((e, emit) => _act(emit, () => _repo.follow(userId)));
    on<UnfollowPressed>((e, emit) => _act(emit, () => _repo.unfollow(userId)));
    on<PrivacyToggled>((e, emit) => _act(emit, () => _repo.setPrivate(e.value)));
    on<AvatarPicked>((e, emit) => _act(emit, () => _repo.updateAvatar(e.bytes, e.ext)));
    on<ProfileEdited>((e, emit) => _act(emit,
        () => _repo.updateProfile(fullName: e.fullName, bio: e.bio, username: e.username), notice: 'profile_updated'));
  }
  final ProfileRepository _repo; final String userId;

  Future<void> _load(Emitter<ProfileState> emit) async {
    try {
      final p = await _repo.getProfile(userId);
      emit(state.copyWith(profile: p, status: ProfileStatus.success, busy: false));
    } on AppFailure catch (f) {
      emit(state.copyWith(status: state.profile == null ? ProfileStatus.failure : state.status, busy: false, error: f.message));
    }
  }

  /// Runs a write action, then reloads the profile so counts / follow state / canView are fresh.
  Future<void> _act(Emitter<ProfileState> emit, Future<void> Function() action, {String? notice}) async {
    emit(state.copyWith(busy: true, clear: true));
    try {
      await action();
      final p = await _repo.getProfile(userId);
      emit(state.copyWith(profile: p, status: ProfileStatus.success, busy: false, notice: notice));
    } on AppFailure catch (f) {
      emit(state.copyWith(busy: false, error: f.message));
    }
  }
}
