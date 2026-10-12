import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/failure.dart';
import '../domain/notification_repository.dart';

/// App-wide unread counter for the bell badge. Polls while signed in (simple and robust; no realtime socket needed).
class UnreadCubit extends Cubit<int> {
  UnreadCubit(this._repo, {this.interval = const Duration(seconds: 30)}) : super(0);
  final NotificationRepository _repo; final Duration interval;
  Timer? _timer;

  void start() {
    _timer?.cancel();
    refresh();
    _timer = Timer.periodic(interval, (_) => refresh());
  }

  void stop() { _timer?.cancel(); _timer = null; emit(0); } // on logout

  Future<void> refresh() async {
    try {
      final n = await _repo.unreadCount();
      if (!isClosed) emit(n);
    } on AppFailure catch (_) {/* keep the old number */}
  }

  void clear() => emit(0);

  @override
  Future<void> close() { _timer?.cancel(); return super.close(); }
}
