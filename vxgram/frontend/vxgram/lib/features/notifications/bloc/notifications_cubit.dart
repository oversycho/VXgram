import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/failure.dart';
import '../../profile/domain/profile_repository.dart';
import '../domain/app_notification.dart';
import '../domain/notification_repository.dart';

enum NotificationsStatus { loading, success, failure }

class NotificationsState extends Equatable {
  const NotificationsState({this.items = const [], this.status = NotificationsStatus.loading, this.hasMore = false, this.loadingMore = false, this.error});
  final List<AppNotification> items; final NotificationsStatus status; final bool hasMore, loadingMore; final String? error;
  NotificationsState copyWith({List<AppNotification>? items, NotificationsStatus? status, bool? hasMore, bool? loadingMore, String? error, bool clearError = false}) =>
      NotificationsState(items: items ?? this.items, status: status ?? this.status, hasMore: hasMore ?? this.hasMore,
          loadingMore: loadingMore ?? this.loadingMore, error: clearError ? null : (error ?? this.error));
  @override
  List<Object?> get props => [items, status, hasMore, loadingMore, error];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repo, this._profiles, {this.onMarkedRead}) : super(const NotificationsState());
  final NotificationRepository _repo; final ProfileRepository _profiles;
  /// Called after everything was marked read on the server (clears the bell badge).
  final void Function()? onMarkedRead;
  static const _page = 30;

  /// Loads the list, then marks everything read. Items keep their original read flag so new ones stay highlighted.
  Future<void> load() async {
    emit(const NotificationsState());
    try {
      final items = await _repo.list();
      emit(NotificationsState(items: items, status: NotificationsStatus.success, hasMore: items.length == _page));
      try { await _repo.markAllRead(); onMarkedRead?.call(); } on AppFailure catch (_) {}
    } on AppFailure catch (f) {
      emit(NotificationsState(status: NotificationsStatus.failure, error: f.message));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore || state.items.isEmpty) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final more = await _repo.list(before: state.items.last.createdAt);
      emit(state.copyWith(items: [...state.items, ...more], hasMore: more.length == _page, loadingMore: false));
    } on AppFailure catch (f) {
      emit(state.copyWith(loadingMore: false, error: f.message));
    }
  }

  /// Confirm / delete a follow request straight from the list.
  Future<void> respond(AppNotification n, {required bool accept}) async {
    emit(state.copyWith(clearError: true));
    try {
      await _profiles.respondToRequest(n.actorId, accept: accept);
      emit(state.copyWith(items: state.items.where((x) => x.id != n.id).toList()));
    } on AppFailure catch (f) {
      emit(state.copyWith(error: f.message));
    }
  }
}
