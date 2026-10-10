import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/failure.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';

enum UserListKind { followers, following, requests }
enum UserListStatus { loading, success, failure }

class UserListState extends Equatable {
  const UserListState({this.users = const [], this.status = UserListStatus.loading, this.hasMore = false, this.loadingMore = false, this.error});
  final List<UserSummary> users; final UserListStatus status; final bool hasMore, loadingMore; final String? error;
  UserListState copyWith({List<UserSummary>? users, UserListStatus? status, bool? hasMore, bool? loadingMore, String? error, bool clearError = false}) =>
      UserListState(users: users ?? this.users, status: status ?? this.status, hasMore: hasMore ?? this.hasMore,
          loadingMore: loadingMore ?? this.loadingMore, error: clearError ? null : (error ?? this.error));
  @override
  List<Object?> get props => [users, status, hasMore, loadingMore, error];
}

class UserListCubit extends Cubit<UserListState> {
  UserListCubit(this._repo, this.kind, this.userId) : super(const UserListState());
  final ProfileRepository _repo; final UserListKind kind; final String userId;
  static const _page = 50;

  Future<List<UserSummary>> _fetch(int offset) {
    switch (kind) {
      case UserListKind.followers: return _repo.followers(userId, offset: offset);
      case UserListKind.following: return _repo.following(userId, offset: offset);
      case UserListKind.requests: return _repo.followRequests();
    }
  }

  Future<void> load() async {
    emit(const UserListState());
    try {
      final u = await _fetch(0);
      emit(UserListState(users: u, status: UserListStatus.success, hasMore: kind != UserListKind.requests && u.length == _page));
    } on AppFailure catch (f) {
      emit(UserListState(status: UserListStatus.failure, error: f.message));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final u = await _fetch(state.users.length);
      emit(state.copyWith(users: [...state.users, ...u], hasMore: u.length == _page, loadingMore: false));
    } on AppFailure catch (f) {
      emit(state.copyWith(loadingMore: false, error: f.message));
    }
  }

  Future<void> toggleFollow(UserSummary u) async {
    emit(state.copyWith(clearError: true));
    try {
      FollowStatus next;
      if (u.iFollow == FollowStatus.none) { next = await _repo.follow(u.id); } else { await _repo.unfollow(u.id); next = FollowStatus.none; }
      emit(state.copyWith(users: [for (final x in state.users) x.id == u.id ? x.copyWith(iFollow: next) : x]));
    } on AppFailure catch (f) {
      emit(state.copyWith(error: f.message));
    }
  }

  Future<void> respond(UserSummary u, {required bool accept}) => _removeAfter(u, () => _repo.respondToRequest(u.id, accept: accept));
  Future<void> removeFollower(UserSummary u) => _removeAfter(u, () => _repo.removeFollower(u.id));

  Future<void> _removeAfter(UserSummary u, Future<void> Function() action) async {
    emit(state.copyWith(clearError: true));
    try {
      await action();
      emit(state.copyWith(users: state.users.where((x) => x.id != u.id).toList()));
    } on AppFailure catch (f) {
      emit(state.copyWith(error: f.message));
    }
  }
}
