import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/env.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../comments/ui/comments_sheet.dart';
import '../../profile/ui/profile_page.dart';
import '../../saved/bloc/saved_cubit.dart';
import '../../share/ui/share_sheet.dart';
import '../bloc/feed_bloc.dart';
import '../domain/post.dart';
import '../domain/post_repository.dart';

class PostCard extends StatefulWidget {
  const PostCard({super.key, required this.post});
  final Post post;
  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int _page = 0;

  Future<void> _menu() async {
    final bloc = context.read<FeedBloc>();
    final c = VxColors.of(context);
    final act = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: Icon(Icons.delete_outline, color: c.error), title: Text(ctx.t('delete_post'), style: TextStyle(color: c.error)), onTap: () => Navigator.pop(ctx, 'delete')),
        ListTile(title: Text(ctx.t('cancel'), textAlign: TextAlign.center), onTap: () => Navigator.pop(ctx)),
      ])),
    );
    if (act != 'delete' || !mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.t('delete_post')), content: Text(ctx.t('delete_post_q')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.t('delete'), style: TextStyle(color: c.error))),
        ],
      ),
    );
    if (ok == true) bloc.add(FeedPostDeleted(widget.post.id));
  }

  void _openComments() {
    final bloc = context.read<FeedBloc>();
    final p = widget.post;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (_) => CommentsSheet(postId: p.id, postOwnerId: p.userId, onCountChanged: (d) => bloc.add(FeedCommentCountChanged(p.id, d))),
    );
  }

  void _openShare() => showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (_) => ShareSheet(postId: widget.post.id, link: Env.postLink(widget.post.id)));

  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    final s = context.s;
    final p = widget.post;
    final mine = p.userId == context.read<PostRepository>().currentUserId;
    final link = Env.postLink(p.id);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Expanded(child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: p.userId))),
            child: Row(children: [
              Avatar(url: p.avatarUrl, size: 40), const SizedBox(width: 12),
              Expanded(child: Text(p.username, style: const TextStyle(fontWeight: FontWeight.w700), textDirection: TextDirection.ltr, textAlign: TextAlign.start)),
            ]),
          )),
          Text(s.ago(p.createdAt), style: TextStyle(color: c.muted, fontSize: 12)),
          if (mine) IconButton(icon: const Icon(Icons.more_horiz), onPressed: _menu),
        ]),
      ),
      AspectRatio(
        aspectRatio: 1,
        child: Stack(children: [
          PageView.builder(
            itemCount: p.media.length, onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => MediaTile(url: p.media[i].url, isVideo: p.media[i].isVideo, thumbUrl: p.media[i].thumbUrl),
          ),
          if (p.media.length > 1)
            PositionedDirectional(top: 12, end: 12, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
              child: Text('${s.digits('${_page + 1}')}/${s.digits('${p.media.length}')}', style: const TextStyle(color: Colors.white, fontSize: 12)),
            )),
        ]),
      ),
      if (p.media.length > 1)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < p.media.length; i++)
              AnimatedContainer(duration: const Duration(milliseconds: 150), margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: i == _page ? 8 : 6, height: i == _page ? 8 : 6,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: i == _page ? c.primary : c.border)),
          ]),
        ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(children: [
          IconButton(
            icon: Icon(p.likedByMe ? Icons.favorite : Icons.favorite_border, color: p.likedByMe ? c.pink : null),
            onPressed: () => context.read<FeedBloc>().add(FeedLikeToggled(p.id)),
          ),
          IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: _openComments),
          // flip the plane icon in RTL
          IconButton(icon: Transform.flip(flipX: Directionality.of(context) == TextDirection.rtl, child: const Icon(Icons.send_outlined)),
              onPressed: _openShare),
          IconButton(icon: const Icon(Icons.link), onPressed: () async {
            await Clipboard.setData(ClipboardData(text: link));
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('link_copied'))));
          }),
          const Spacer(),
          BlocSelector<SavedCubit, SavedState, bool>(
            selector: (st) => st.ids.contains(p.id),
            builder: (context, saved) => IconButton(
              icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, color: saved ? c.primary : null),
              onPressed: () async {
                final cubit = context.read<SavedCubit>();
                final messenger = ScaffoldMessenger.of(context);
                if (!await cubit.toggle(p.id)) messenger.showSnackBar(SnackBar(content: Text(cubit.state.error ?? '')));
              },
            ),
          ),
        ]),
      ),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(s.fmt('likes_n', {'n': p.likesCount}), style: const TextStyle(fontWeight: FontWeight.w700))),
      if (p.caption.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text.rich(TextSpan(children: [TextSpan(text: '${p.username} ', style: const TextStyle(fontWeight: FontWeight.w700)), TextSpan(text: p.caption)])),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        child: GestureDetector(
          onTap: _openComments,
          child: Text(p.commentsCount > 0 ? s.fmt('view_comments_n', {'n': p.commentsCount}) : context.t('add_comment'), style: TextStyle(color: c.muted)),
        ),
      ),
      const SizedBox(height: 20),
    ]);
  }
}
