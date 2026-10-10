import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/failure.dart';
import '../domain/comment.dart';
import '../domain/comment_repository.dart';

enum CommentsStatus { loading, success, failure }

class CommentsState extends Equatable {
  const CommentsState({this.comments = const [], this.status = CommentsStatus.loading, this.hasMore = false, this.loadingMore = false, this.sending = false, this.error});
  final List<Comment> comments; final CommentsStatus status; final bool hasMore, loadingMore, sending; final String? error;
  CommentsState copyWith({List<Comment>? comments, CommentsStatus? status, bool? hasMore, bool? loadingMore, bool? sending, String? error, bool clearError = false}) =>
      CommentsState(comments: comments ?? this.comments, status: status ?? this.status, hasMore: hasMore ?? this.hasMore,
          loadingMore: loadingMore ?? this.loadingMore, sending: sending ?? this.sending, error: clearError ? null : (error ?? this.error));
  @override
  List<Object?> get props => [comments, status, hasMore, loadingMore, sending, error];
}

class CommentsCubit extends Cubit<CommentsState> {
  CommentsCubit(this._repo, this.postId, {this.onCountChanged}) : super(const CommentsState());
  final CommentRepository _repo; final String postId;
  /// +1 / -1: lets the post card keep its comment counter in sync.
  final void Function(int delta)? onCountChanged;
  static const _page = 30;

  Future<void> load() async {
    emit(const CommentsState());
    try {
      final c = await _repo.comments(postId);
      emit(CommentsState(comments: c, status: CommentsStatus.success, hasMore: c.length == _page));
    } on AppFailure catch (f) {
      emit(CommentsState(status: CommentsStatus.failure, error: f.message));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore || state.comments.isEmpty) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final c = await _repo.comments(postId, before: state.comments.last.createdAt);
      emit(state.copyWith(comments: [...state.comments, ...c], hasMore: c.length == _page, loadingMore: false));
    } on AppFailure catch (f) {
      emit(state.copyWith(loadingMore: false, error: f.message));
    }
  }

  /// Returns true when the comment was saved (so the UI can clear its text field).
  Future<bool> send(String text) async {
    final t = text.trim();
    if (t.isEmpty || state.sending) return false;
    emit(state.copyWith(sending: true, clearError: true));
    try {
      final c = await _repo.add(postId, t);
      emit(state.copyWith(comments: [c, ...state.comments], sending: false));
      onCountChanged?.call(1);
      return true;
    } on AppFailure catch (f) {
      emit(state.copyWith(sending: false, error: f.message));
      return false;
    }
  }

  Future<void> delete(Comment c) async {
    emit(state.copyWith(clearError: true));
    try {
      await _repo.delete(c.id);
      emit(state.copyWith(comments: state.comments.where((x) => x.id != c.id).toList()));
      onCountChanged?.call(-1);
    } on AppFailure catch (f) {
      emit(state.copyWith(error: f.message));
    }
  }
}
