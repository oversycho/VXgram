import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/failure.dart';
import '../../profile/domain/profile.dart';
import '../../profile/domain/profile_repository.dart';
import '../domain/share_repository.dart';

class ShareState extends Equatable {
  const ShareState({this.users = const [], this.selected = const {}, this.query = '', this.loading = true, this.sending = false, this.sent = false, this.error});
  final List<UserSummary> users; final Set<String> selected; final String query; final bool loading, sending, sent; final String? error;
  ShareState copyWith({List<UserSummary>? users, Set<String>? selected, String? query, bool? loading, bool? sending, bool? sent, String? error, bool clearError = false}) =>
      ShareState(users: users ?? this.users, selected: selected ?? this.selected, query: query ?? this.query, loading: loading ?? this.loading,
          sending: sending ?? this.sending, sent: sent ?? this.sent, error: clearError ? null : (error ?? this.error));
  @override
  List<Object?> get props => [users, selected, query, loading, sending, sent, error];
}

/// Pick people (people you follow by default, or search by username) and send them a post.
class ShareCubit extends Cubit<ShareState> {
  ShareCubit(this._profiles, this._share, this.postId, {this.debounce = const Duration(milliseconds: 350)}) : super(const ShareState());
  final ProfileRepository _profiles; final ShareRepository _share; final String postId; final Duration debounce;
  Timer? _timer;

  String? get _me => _profiles.currentUserId;

  Future<void> load() async {
    emit(state.copyWith(query: '', loading: true, clearError: true));
    try {
      final u = await _profiles.following(_me!);
      emit(state.copyWith(users: u, loading: false));
    } on AppFailure catch (f) {
      emit(state.copyWith(loading: false, error: f.message));
    }
  }

  void search(String raw) {
    final q = raw.trim();
    _timer?.cancel();
    if (q.isEmpty) { load(); return; }
    emit(state.copyWith(query: q, loading: true, clearError: true));
    _timer = Timer(debounce, () async {
      try {
        final r = await _profiles.searchUsers(q);
        if (!isClosed && state.query == q) emit(state.copyWith(users: r.where((u) => u.id != _me).toList(), loading: false));
      } on AppFailure catch (f) {
        if (!isClosed && state.query == q) emit(state.copyWith(loading: false, error: f.message));
      }
    });
  }

  void toggle(String userId) {
    final s = {...state.selected};
    if (!s.remove(userId)) s.add(userId);
    emit(state.copyWith(selected: s));
  }

  Future<void> send(String message) async {
    if (state.selected.isEmpty || state.sending) return;
    emit(state.copyWith(sending: true, clearError: true));
    try {
      final m = message.trim();
      await _share.sharePost(postId, state.selected.toList(), message: m.isEmpty ? null : m);
      emit(state.copyWith(sending: false, sent: true));
    } on AppFailure catch (f) {
      emit(state.copyWith(sending: false, error: f.message));
    }
  }

  @override
  Future<void> close() { _timer?.cancel(); return super.close(); }
}
