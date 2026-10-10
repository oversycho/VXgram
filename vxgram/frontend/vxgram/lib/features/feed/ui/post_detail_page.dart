import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/feed_bloc.dart';
import '../domain/post_repository.dart';
import 'post_card.dart';

/// One post by id (opened from the inbox). Reuses FeedBloc with scope 'post'.
class PostDetailPage extends StatelessWidget {
  const PostDetailPage({super.key, required this.postId});
  final String postId;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (c) => FeedBloc(c.read<PostRepository>(), scope: 'post', author: postId)..add(const FeedStarted()),
        child: Scaffold(
          appBar: AppBar(title: Text(context.t('posts'))),
          body: BlocBuilder<FeedBloc, FeedState>(
            builder: (context, st) {
              if (st.status == FeedStatus.initial || st.status == FeedStatus.loading) return const Center(child: CircularProgressIndicator());
              if (st.posts.isEmpty) {
                return Center(child: Text(st.error ?? context.t('post_unavailable'), style: TextStyle(color: VxColors.of(context).muted), textAlign: TextAlign.center));
              }
              return SingleChildScrollView(child: Column(children: [for (final p in st.posts) PostCard(key: ValueKey(p.id), post: p)]));
            },
          ),
        ),
      );
}
