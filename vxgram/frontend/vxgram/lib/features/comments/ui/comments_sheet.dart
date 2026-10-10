import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../bloc/comments_cubit.dart';
import '../domain/comment_repository.dart';

/// Show with showModalBottomSheet(isScrollControlled: true).
class CommentsSheet extends StatelessWidget {
  const CommentsSheet({super.key, required this.postId, required this.postOwnerId, this.onCountChanged});
  final String postId, postOwnerId; final void Function(int delta)? onCountChanged;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (c) => CommentsCubit(c.read<CommentRepository>(), postId, onCountChanged: onCountChanged)..load(),
        child: _Body(postOwnerId: postOwnerId),
      );
}

class _Body extends StatefulWidget {
  const _Body({required this.postOwnerId});
  final String postOwnerId;
  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _ctl = TextEditingController();
  @override
  void dispose() { _ctl.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (await context.read<CommentsCubit>().send(_ctl.text)) _ctl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    final me = context.read<CommentRepository>().currentUserId;
    final mq = MediaQuery.of(context);
    final h = math.max(260.0, math.min(mq.size.height * .7, mq.size.height - mq.viewInsets.bottom - 120));
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: SizedBox(
        height: h,
        child: Column(children: [
          Text(context.t('comments'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8), const Divider(),
          Expanded(
            child: BlocConsumer<CommentsCubit, CommentsState>(
              listenWhen: (p, s) => s.error != null && s.error != p.error,
              listener: (context, st) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(st.error!))),
              builder: (context, st) {
                if (st.status == CommentsStatus.loading) return const Center(child: CircularProgressIndicator());
                if (st.status == CommentsStatus.failure) {
                  return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(st.error ?? ''), const SizedBox(height: 12),
                    OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                        onPressed: () => context.read<CommentsCubit>().load(), child: Text(context.t('retry'))),
                  ]));
                }
                if (st.comments.isEmpty) {
                  return Center(child: Padding(padding: const EdgeInsets.all(24),
                      child: Text(context.t('no_comments'), textAlign: TextAlign.center, style: TextStyle(color: c.muted))));
                }
                return NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) context.read<CommentsCubit>().loadMore();
                    return false;
                  },
                  child: ListView.builder(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: st.comments.length,
                    itemBuilder: (context, i) {
                      final m = st.comments[i];
                      final canDelete = m.userId == me || widget.postOwnerId == me;
                      return ListTile(
                        leading: Avatar(url: m.avatarUrl, size: 36),
                        title: Text(m.username, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m.body), Text(context.s.ago(m.createdAt), style: TextStyle(color: c.muted, fontSize: 12)),
                        ]),
                        trailing: canDelete ? IconButton(icon: Icon(Icons.close, size: 18, color: c.muted), onPressed: () => context.read<CommentsCubit>().delete(m)) : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
            child: Row(children: [
              Expanded(child: TextField(controller: _ctl, minLines: 1, maxLines: 3, maxLength: 500,
                  decoration: InputDecoration(hintText: context.t('add_comment'), counterText: '', isDense: true))),
              BlocBuilder<CommentsCubit, CommentsState>(
                buildWhen: (p, s) => p.sending != s.sending,
                builder: (context, st) => st.sending
                    ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                    : TextButton(onPressed: _send, child: Text(context.t('post_btn'))),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
