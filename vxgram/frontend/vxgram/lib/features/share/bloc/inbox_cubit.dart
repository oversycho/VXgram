import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/failure.dart';
import '../domain/inbox_item.dart';
import '../domain/share_repository.dart';

enum InboxStatus { loading, success, failure }

class InboxState extends Equatable {
  const InboxState({this.items = const [], this.status = InboxStatus.loading, this.error});
  final List<InboxItem> items; final InboxStatus status; final String? error;
  @override
  List<Object?> get props => [items, status, error];
}

class InboxCubit extends Cubit<InboxState> {
  InboxCubit(this._repo) : super(const InboxState());
  final ShareRepository _repo;

  /// [silent]: keep the current list on screen while reloading (tab re-entry / pull to refresh).
  Future<void> load({bool silent = false}) async {
    if (!silent) emit(const InboxState());
    try {
      emit(InboxState(items: await _repo.inbox(), status: InboxStatus.success));
    } on AppFailure catch (f) {
      emit(state.items.isEmpty ? InboxState(status: InboxStatus.failure, error: f.message) : state);
    }
  }

  Future<void> markSeen(InboxItem item) async {
    if (item.seen) return;
    emit(InboxState(items: [for (final i in state.items) i.id == item.id ? i.markSeen() : i], status: InboxStatus.success));
    try { await _repo.markSeen(item.id); } on AppFailure catch (_) {}
  }
}
