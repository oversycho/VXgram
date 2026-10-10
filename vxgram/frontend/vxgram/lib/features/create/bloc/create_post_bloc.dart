import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/failure.dart';
import '../../feed/domain/new_media.dart';
import '../../feed/domain/post_repository.dart';

abstract class CreatePostEvent { const CreatePostEvent(); }
class MediaAdded extends CreatePostEvent { const MediaAdded(this.items); final List<NewMedia> items; }
class MediaRemoved extends CreatePostEvent { const MediaRemoved(this.index); final int index; }
class CaptionChanged extends CreatePostEvent { const CaptionChanged(this.text); final String text; }
class PostSubmitted extends CreatePostEvent { const PostSubmitted(); }
class CreateReset extends CreatePostEvent { const CreateReset(); }

class CreatePostState extends Equatable {
  const CreatePostState({this.media = const [], this.caption = '', this.uploading = false, this.done = 0, this.total = 0, this.posted = false, this.error});
  final List<NewMedia> media; final String caption; final bool uploading, posted; final int done, total; final String? error;
  CreatePostState copyWith({List<NewMedia>? media, String? caption, bool? uploading, int? done, int? total, bool? posted, String? error, bool clearError = false}) =>
      CreatePostState(media: media ?? this.media, caption: caption ?? this.caption, uploading: uploading ?? this.uploading, done: done ?? this.done,
          total: total ?? this.total, posted: posted ?? this.posted, error: clearError ? null : (error ?? this.error));
  // NewMedia has no == : compare by identity of the list contents
  @override
  List<Object?> get props => [media.length, media.map((m) => m.bytes.length).toList(), caption, uploading, done, total, posted, error];
}

class CreatePostBloc extends Bloc<CreatePostEvent, CreatePostState> {
  CreatePostBloc(this._repo) : super(const CreatePostState()) {
    on<MediaAdded>((e, emit) => emit(state.copyWith(media: [...state.media, ...e.items].take(NewMedia.maxItems).toList(), clearError: true)));
    on<MediaRemoved>((e, emit) => emit(state.copyWith(media: [...state.media]..removeAt(e.index))));
    on<CaptionChanged>((e, emit) => emit(state.copyWith(caption: e.text)));
    on<CreateReset>((e, emit) => emit(const CreatePostState()));
    on<PostSubmitted>(_submit);
  }
  final PostRepository _repo;

  Future<void> _submit(PostSubmitted e, Emitter<CreatePostState> emit) async {
    if (state.uploading || state.media.isEmpty) return;
    emit(state.copyWith(uploading: true, done: 0, total: state.media.length, posted: false, clearError: true));
    try {
      await _repo.createPost(
        caption: state.caption, media: state.media,
        onProgress: (d, t) { if (!emit.isDone) emit(state.copyWith(done: d, total: t)); },
      );
      emit(state.copyWith(uploading: false, posted: true));
    } on AppFailure catch (f) {
      emit(state.copyWith(uploading: false, error: f.message));
    }
  }
}
