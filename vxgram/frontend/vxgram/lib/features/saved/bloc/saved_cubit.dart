import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/failure.dart';
import '../domain/saved_repository.dart';

class SavedState extends Equatable {
  const SavedState({this.ids = const {}, this.error});
  final Set<String> ids; final String? error;
  @override
  List<Object?> get props => [ids, error];
}

/// App-wide: knows which posts the user saved, so any PostCard can show a filled bookmark.
class SavedCubit extends Cubit<SavedState> {
  SavedCubit(this._repo) : super(const SavedState());
  final SavedRepository _repo;

  Future<void> load() async {
    try {
      emit(SavedState(ids: await _repo.savedIds()));
    } on AppFailure catch (f) {
      emit(SavedState(ids: state.ids, error: f.message));
    }
  }

  void clear() => emit(const SavedState()); // on logout

  /// Optimistic. Returns false (and reverts) when the server call fails; the message is in state.error.
  Future<bool> toggle(String postId) async {
    final was = state.ids.contains(postId);
    final next = {...state.ids};
    was ? next.remove(postId) : next.add(postId);
    emit(SavedState(ids: next));
    try {
      await _repo.toggle(postId);
      return true;
    } on AppFailure catch (f) {
      final back = {...state.ids};
      was ? back.add(postId) : back.remove(postId);
      emit(SavedState(ids: back, error: f.message));
      return false;
    }
  }
}
