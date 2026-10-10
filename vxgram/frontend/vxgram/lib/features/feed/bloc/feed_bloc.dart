import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/failure.dart';
import '../domain/post.dart';
import '../domain/post_repository.dart';

abstract class FeedEvent { const FeedEvent(); }
class FeedStarted extends FeedEvent { const FeedStarted(); }
class FeedRefreshed extends FeedEvent { const FeedRefreshed([this.done]); final Completer<void>? done; }
class FeedLoadMore extends FeedEvent { const FeedLoadMore(); }
class FeedLikeToggled extends FeedEvent { const FeedLikeToggled(this.postId); final String postId; }
class FeedPostDeleted extends FeedEvent { const FeedPostDeleted(this.postId); final String postId; }
class FeedCommentCountChanged extends FeedEvent { const FeedCommentCountChanged(this.postId, this.delta); final String postId; final int delta; }

enum FeedStatus { initial, loading, success, failure }

class FeedState extends Equatable {
  const FeedState({this.posts = const [], this.status = FeedStatus.initial, this.hasMore = true, this.loadingMore = false, this.error});
  final List<Post> posts; final FeedStatus status; final bool hasMore, loadingMore; final String? error;
  FeedState copyWith({List<Post>? posts, FeedStatus? status, bool? hasMore, bool? loadingMore, String? error, bool clearError = false}) => FeedState(
      posts: posts ?? this.posts, status: status ?? this.status, hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore, error: clearError ? null : (error ?? this.error));
  @override
  List<Object?> get props => [posts, status, hasMore, loadingMore, error];
}

/// Reusable for feed / profile grid / explore via [scope] ('feed' | 'profile' | 'explore').
class FeedBloc extends Bloc<FeedEvent, FeedState> {
  FeedBloc(this._repo, {this.scope = 'feed', this.author}) : super(const FeedState()) {
    on<FeedStarted>((e, emit) async { emit(state.copyWith(status: FeedStatus.loading, clearError: true)); await _load(emit); });
    on<FeedRefreshed>((e, emit) async { try { await _load(emit); } finally { e.done?.complete(); } });
    on<FeedLoadMore>(_more);
    on<FeedLikeToggled>(_like);
    on<FeedPostDeleted>(_delete);
    on<FeedCommentCountChanged>((e, emit) => emit(state.copyWith(posts: [
      for (final p in state.posts)
        if (p.id == e.postId) p.copyWith(commentsCount: p.commentsCount + e.delta < 0 ? 0 : p.commentsCount + e.delta) else p])));
  }
  final PostRepository _repo; final String scope; final String? author;
  static const _page = 15;

  Future<void> _load(Emitter<FeedState> emit) async {
    try {
      final p = await _repo.getPosts(scope: scope, author: author, limit: _page);
      emit(FeedState(posts: p, status: FeedStatus.success, hasMore: p.length == _page));
    } on AppFailure catch (f) {
      emit(state.copyWith(status: FeedStatus.failure, error: f.message));
    }
  }

  Future<void> _more(FeedLoadMore e, Emitter<FeedState> emit) async {
    if (!state.hasMore || state.loadingMore || state.posts.isEmpty) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final p = await _repo.getPosts(scope: scope, author: author, limit: _page, before: state.posts.last.createdAt);
      emit(state.copyWith(posts: [...state.posts, ...p], hasMore: p.length == _page, loadingMore: false));
    } on AppFailure catch (f) {
      emit(state.copyWith(loadingMore: false, error: f.message));
    }
  }

  Future<void> _like(FeedLikeToggled e, Emitter<FeedState> emit) async {
    List<Post> swap(bool liked) => [for (final p in state.posts)
      if (p.id == e.postId) p.copyWith(likedByMe: liked, likesCount: p.likesCount + (liked ? 1 : -1)) else p];
    final cur = state.posts.firstWhere((p) => p.id == e.postId);
    emit(state.copyWith(posts: swap(!cur.likedByMe))); // optimistic
    try {
      await _repo.toggleLike(e.postId);
    } on AppFailure catch (f) {
      emit(state.copyWith(posts: swap(cur.likedByMe), error: f.message)); // revert
    }
  }

  Future<void> _delete(FeedPostDeleted e, Emitter<FeedState> emit) async {
    try {
      await _repo.deletePost(e.postId);
      emit(state.copyWith(posts: state.posts.where((p) => p.id != e.postId).toList(), clearError: true));
    } on AppFailure catch (f) {
      emit(state.copyWith(error: f.message));
    }
  }
}
