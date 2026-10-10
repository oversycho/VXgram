import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../feed/domain/new_media.dart';
import '../../feed/domain/post_repository.dart';
import '../bloc/create_post_bloc.dart';

class CreatePostPage extends StatelessWidget {
  const CreatePostPage({super.key, required this.onPosted});
  final VoidCallback onPosted;
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (c) => CreatePostBloc(c.read<PostRepository>()),
        child: _CreateView(onPosted: onPosted),
      );
}

class _CreateView extends StatefulWidget {
  const _CreateView({required this.onPosted});
  final VoidCallback onPosted;
  @override
  State<_CreateView> createState() => _CreateViewState();
}

class _CreateViewState extends State<_CreateView> {
  final _caption = TextEditingController();
  @override
  void dispose() { _caption.dispose(); super.dispose(); }

  Future<void> _pick() async {
    final bloc = context.read<CreatePostBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final remaining = NewMedia.maxItems - bloc.state.media.length;
    if (remaining <= 0) { messenger.showSnackBar(SnackBar(content: Text(context.t('max_media')))); return; }
    final unsupported = context.t('unsupported_file'), tooLarge = context.t('file_too_large');
    final picker = ImagePicker();
    List<XFile> files;
    if (remaining == 1) {
      final one = await picker.pickMedia();
      files = one == null ? [] : [one];
    } else {
      files = await picker.pickMultipleMedia(limit: remaining);
    }
    final items = <NewMedia>[];
    for (final f in files) {
      final ext = f.name.contains('.') ? f.name.split('.').last : '';
      final bytes = await f.readAsBytes();
      final m = NewMedia(bytes: bytes, ext: ext);
      if (!m.isSupported) { messenger.showSnackBar(SnackBar(content: Text(unsupported))); continue; }
      if (bytes.length > NewMedia.maxBytes) { messenger.showSnackBar(SnackBar(content: Text(tooLarge))); continue; }
      items.add(m);
    }
    if (items.isNotEmpty && !bloc.isClosed) bloc.add(MediaAdded(items));
  }

  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    return BlocConsumer<CreatePostBloc, CreatePostState>(
      listenWhen: (p, s) => (s.posted && !p.posted) || (s.error != null && s.error != p.error),
      listener: (context, st) {
        if (st.posted) {
          _caption.clear();
          context.read<CreatePostBloc>().add(const CreateReset());
          widget.onPosted();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(st.error!)));
        }
      },
      builder: (context, st) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(title: Text(context.t('post')), actions: [
            TextButton(
              onPressed: st.media.isEmpty || st.uploading ? null : () => context.read<CreatePostBloc>().add(const PostSubmitted()),
              child: Text(context.t('publish')),
            ),
          ]),
          body: KeyboardSafeBody(
            center: false,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (st.media.isEmpty)
                SizedBox(height: 160, child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 160)),
                  onPressed: _pick, icon: const Icon(Icons.add_photo_alternate_outlined), label: Text(context.t('select_media'))))
              else
                SizedBox(
                  height: 112,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    for (var i = 0; i < st.media.length; i++)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: Stack(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(width: 112, height: 112, child: st.media[i].isVideo
                                ? Container(color: c.surface, child: Icon(Icons.videocam, size: 36, color: c.muted))
                                : Image.memory(st.media[i].bytes, fit: BoxFit.cover, cacheWidth: 300)),
                          ),
                          PositionedDirectional(top: 4, end: 4, child: GestureDetector(
                            onTap: st.uploading ? null : () => context.read<CreatePostBloc>().add(MediaRemoved(i)),
                            child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 14, color: Colors.white)),
                          )),
                        ]),
                      ),
                    if (st.media.length < NewMedia.maxItems)
                      InkWell(
                        borderRadius: BorderRadius.circular(12), onTap: st.uploading ? null : _pick,
                        child: Container(width: 112, height: 112, decoration: BoxDecoration(border: Border.all(color: c.border), borderRadius: BorderRadius.circular(12)),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.add, color: c.muted), const SizedBox(height: 4), Text(context.t('add_more'), style: TextStyle(color: c.muted, fontSize: 12)),
                            ])),
                      ),
                  ]),
                ),
              const SizedBox(height: 20),
              TextField(
                controller: _caption, maxLength: 2200, maxLines: 5, enabled: !st.uploading,
                onChanged: (v) => context.read<CreatePostBloc>().add(CaptionChanged(v)),
                decoration: InputDecoration(hintText: context.t('caption_hint')),
              ),
              if (st.uploading) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: st.total == 0 ? null : st.done / st.total),
                const SizedBox(height: 8),
                Text(context.s.fmt('uploading_n', {'done': st.done + 1 > st.total ? st.total : st.done + 1, 'total': st.total}), style: TextStyle(color: c.muted)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
