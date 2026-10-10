import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/failure.dart';
import '../../profile/domain/profile.dart';
import '../../profile/domain/profile_repository.dart';

enum SearchStatus { idle, loading, success, failure }

class SearchState extends Equatable {
  const SearchState({this.query = '', this.users = const [], this.status = SearchStatus.idle, this.error});
  final String query; final List<UserSummary> users; final SearchStatus status; final String? error;
  @override
  List<Object?> get props => [query, users, status, error];
}

/// Debounced username search.
class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._repo, {this.debounce = const Duration(milliseconds: 350)}) : super(const SearchState());
  final ProfileRepository _repo; final Duration debounce;
  Timer? _timer;

  void onChanged(String raw) {
    final q = raw.trim();
    _timer?.cancel();
    if (q.isEmpty) { emit(const SearchState()); return; }
    emit(SearchState(query: q, users: state.users, status: SearchStatus.loading));
    _timer = Timer(debounce, () async {
      try {
        final r = await _repo.searchUsers(q);
        if (!isClosed && state.query == q) emit(SearchState(query: q, users: r, status: SearchStatus.success));
      } on AppFailure catch (f) {
        if (!isClosed && state.query == q) emit(SearchState(query: q, status: SearchStatus.failure, error: f.message));
      }
    });
  }

  @override
  Future<void> close() { _timer?.cancel(); return super.close(); }
}
