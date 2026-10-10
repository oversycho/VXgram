import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../feed/bloc/feed_bloc.dart';
import '../../feed/domain/post.dart';
import '../../feed/domain/post_repository.dart';
import '../../profile/domain/profile_repository.dart';
import '../../profile/ui/profile_page.dart';
import '../bloc/search_cubit.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});
  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (c) => FeedBloc(c.read<PostRepository>(), scope: 'explore')..add(const FeedStarted())),
          BlocProvider(create: (c) => SearchCubit(c.read<ProfileRepository>())),
        ],
        child: const _ExploreView(),
      );
}

class _ExploreView extends StatefulWidget {
  const _ExploreView();
  @override
  State<_ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<_ExploreView> {
  final _scroll = ScrollController();
  final _query = TextEditingController();
  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) context.read<FeedBloc>().add(const FeedLoadMore());
    });
  }
  @override
  void dispose() { _scroll.dispose(); _query.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 16,
          title: TextField(
            controller: _query, autocorrect: false, textInputAction: TextInputAction.search,
            onChanged: (v) { context.read<SearchCubit>().onChanged(v); setState(() {}); },
            decoration: InputDecoration(
              hintText: context.t('search_username'), prefixIcon: Icon(Icons.search, color: c.muted), isDense: true,
              suffixIcon: _query.text.isEmpty ? null : IconButton(icon: Icon(Icons.close, color: c.muted), onPressed: () {
                _query.clear(); context.read<SearchCubit>().onChanged(''); setState(() {});
              }),
            ),
          ),
        ),
        body: BlocBuilder<SearchCubit, SearchState>(
          builder: (context, ss) => ss.query.isEmpty ? _Grid(scroll: _scroll) : _Results(state: ss),
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.scroll});
  final ScrollController scroll;
  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    return BlocBuilder<FeedBloc, FeedState>(
      builder: (context, fs) {
        if (fs.status == FeedStatus.initial || fs.status == FeedStatus.loading) return const Center(child: CircularProgressIndicator());
        if (fs.status == FeedStatus.failure && fs.posts.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(fs.error ?? ''), const SizedBox(height: 12),
            OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: () => context.read<FeedBloc>().add(const FeedStarted()), child: Text(context.t('retry'))),
          ]));
        }
        return RefreshIndicator(
          onRefresh: () async {
            final done = Completer<void>();
            context.read<FeedBloc>().add(FeedRefreshed(done));
            await done.future;
          },
          child: fs.posts.isEmpty
              ? ListView(children: [
                  SizedBox(height: MediaQuery.of(context).size.height * .25),
                  Icon(Icons.explore_outlined, size: 56, color: c.muted), const SizedBox(height: 12),
                  Center(child: Text(context.t('no_posts'), style: TextStyle(color: c.muted))),
                ])
              : GridView.builder(
                  controller: scroll, physics: const AlwaysScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 2, crossAxisSpacing: 2),
                  itemCount: fs.posts.length,
                  itemBuilder: (context, i) => _Thumb(post: fs.posts[i]),
                ),
        );
      },
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.post});
  final Post post;
  @override
  Widget build(BuildContext context) {
    final first = post.media.isEmpty ? null : post.media.first;
    return GestureDetector(
      onTap: () {
        final feed = context.read<FeedBloc>();
        Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider.value(value: feed, child: PostsViewerPage(startId: post.id))));
      },
      child: Stack(fit: StackFit.expand, children: [
        if (first != null) MediaTile(url: first.url, isVideo: first.isVideo, play: false) else Container(color: VxColors.of(context).surface),
        if (post.media.length > 1)
          const PositionedDirectional(top: 6, end: 6, child: Icon(Icons.collections, size: 16, color: Colors.white, shadows: [Shadow(blurRadius: 4)])),
        if (post.media.length == 1 && first!.isVideo)
          const PositionedDirectional(top: 6, end: 6, child: Icon(Icons.videocam, size: 18, color: Colors.white, shadows: [Shadow(blurRadius: 4)])),
      ]),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.state});
  final SearchState state;
  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    if (state.status == SearchStatus.loading && state.users.isEmpty) return const Center(child: CircularProgressIndicator());
    if (state.status == SearchStatus.failure) return Center(child: Text(state.error ?? ''));
    if (state.status == SearchStatus.success && state.users.isEmpty) {
      return Center(child: Text('${context.t('no_users')}: "${state.query}"', style: TextStyle(color: c.muted)));
    }
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: state.users.length,
      itemBuilder: (context, i) {
        final u = state.users[i];
        return ListTile(
          leading: Avatar(url: u.avatarUrl, size: 48),
          title: Row(children: [
            Flexible(child: Text(u.username, style: const TextStyle(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr)),
            if (u.isPrivate) Padding(padding: const EdgeInsets.only(left: 6, right: 6), child: Icon(Icons.lock, size: 14, color: c.muted)),
          ]),
          subtitle: (u.fullName ?? '').isEmpty ? null : Text(u.fullName!, style: TextStyle(color: c.muted)),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: u.id))),
        );
      },
    );
  }
}
