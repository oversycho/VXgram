import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../bloc/feed_bloc.dart';
import '../domain/post_repository.dart';
import 'post_card.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key, this.refresh});
  final Listenable? refresh; // ticks when a post was created
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (c) => FeedBloc(c.read<PostRepository>())..add(const FeedStarted()),
        child: _FeedView(refresh: refresh),
      );
}

class _FeedView extends StatefulWidget {
  const _FeedView({this.refresh});
  final Listenable? refresh;
  @override
  State<_FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<_FeedView> {
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    widget.refresh?.addListener(_onRefresh);
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) context.read<FeedBloc>().add(const FeedLoadMore());
    });
  }
  @override
  void _onRefresh() => context.read<FeedBloc>().add(const FeedRefreshed());
  @override
  void dispose() { widget.refresh?.removeListener(_onRefresh); _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    return Scaffold(
      appBar: AppBar(title: const Logo(size: 24), centerTitle: false, bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(color: c.border))),
      body: BlocConsumer<FeedBloc, FeedState>(
        listenWhen: (p, s) => s.error != null && p.error != s.error,
        listener: (context, st) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(st.error!))),
        builder: (context, st) {
          if (st.status == FeedStatus.loading || st.status == FeedStatus.initial) return const Center(child: CircularProgressIndicator());
          if (st.status == FeedStatus.failure && st.posts.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(st.error ?? '', textAlign: TextAlign.center), const SizedBox(height: 12),
              OutlinedButton(onPressed: () => context.read<FeedBloc>().add(const FeedStarted()), child: Text(context.t('retry'))),
            ]));
          }
          return RefreshIndicator(
            onRefresh: () async {
              final done = Completer<void>();
              context.read<FeedBloc>().add(FeedRefreshed(done));
              await done.future;
            },
            child: st.posts.isEmpty
                ? ListView(children: [
                    SizedBox(height: MediaQuery.of(context).size.height * .3),
                    Icon(Icons.photo_camera_outlined, size: 56, color: c.muted), const SizedBox(height: 12),
                    Center(child: Text(context.t('empty_feed'), style: TextStyle(color: c.muted))),
                  ])
                : ListView.builder(
                    controller: _scroll, itemCount: st.posts.length + (st.loadingMore ? 1 : 0),
                    itemBuilder: (_, i) => i == st.posts.length
                        ? const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                        : PostCard(key: ValueKey(st.posts[i].id), post: st.posts[i]),
                  ),
          );
        },
      ),
    );
  }
}
