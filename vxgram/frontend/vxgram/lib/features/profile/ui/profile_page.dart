import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../feed/bloc/feed_bloc.dart';
import '../../feed/domain/post.dart';
import '../../feed/domain/post_repository.dart';
import '../../feed/ui/post_card.dart';
import '../../settings/settings_pages.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/user_list_cubit.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';
import 'avatar_picker.dart';
import 'edit_profile_page.dart';
import 'user_list_page.dart';

/// [userId] == null -> the signed-in user's own profile.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.userId});
  final String? userId;

  @override
  Widget build(BuildContext context) {
    final id = userId ?? context.read<ProfileRepository>().currentUserId!;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (c) => ProfileBloc(c.read<ProfileRepository>(), id)..add(const ProfileStarted())),
        // posts load when the profile says canView == true (see listener below)
        BlocProvider(create: (c) => FeedBloc(c.read<PostRepository>(), scope: 'profile', author: id)),
      ],
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();
  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) context.read<FeedBloc>().add(const FeedLoadMore());
    });
  }
  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  Future<void> _refresh() async {
    final a = Completer<void>(), b = Completer<void>();
    context.read<ProfileBloc>().add(ProfileRefreshed(a));
    context.read<FeedBloc>().add(FeedRefreshed(b));
    await Future.wait([a.future, b.future]);
  }

  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    return MultiBlocListener(
      listeners: [
        BlocListener<ProfileBloc, ProfileState>(
          listenWhen: (p, s) => (s.error != null && s.error != p.error) || (s.notice != null && s.notice != p.notice),
          listener: (context, st) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(st.error ?? context.t(st.notice!)))),
        ),
        BlocListener<ProfileBloc, ProfileState>(
          listenWhen: (p, s) => p.profile?.canView != true && s.profile?.canView == true,
          listener: (context, st) => context.read<FeedBloc>().add(const FeedStarted()),
        ),
      ],
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, st) {
          final p = st.profile;
          if (p == null) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(child: st.status == ProfileStatus.failure
                  ? Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(st.error ?? '', textAlign: TextAlign.center), const SizedBox(height: 12),
                      OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                          onPressed: () => context.read<ProfileBloc>().add(const ProfileStarted()), child: Text(context.t('retry'))),
                    ])
                  : const CircularProgressIndicator()),
            );
          }
          return Scaffold(
            appBar: AppBar(
              title: Directionality(textDirection: TextDirection.ltr, child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(p.username, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                if (p.isPrivate) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.lock, size: 16)),
              ])),
              actions: [
                if (p.isMe)
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => BlocProvider.value(value: context.read<ProfileBloc>(), child: const SettingsPage()))),
                  ),
              ],
              bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(color: c.border)),
            ),
            body: RefreshIndicator(
              onRefresh: _refresh,
              child: BlocBuilder<FeedBloc, FeedState>(
                builder: (context, fs) => CustomScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _Header(p: p, busy: st.busy)),
                    const SliverToBoxAdapter(child: Divider()),
                    if (!p.canView)
                      const SliverToBoxAdapter(child: _Locked())
                    else if (fs.status == FeedStatus.success && fs.posts.isEmpty)
                      SliverToBoxAdapter(child: _EmptyPosts(isMe: p.isMe))
                    else if (fs.status == FeedStatus.initial || fs.status == FeedStatus.loading)
                      const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())))
                    else
                      SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 2, crossAxisSpacing: 2),
                        delegate: SliverChildBuilderDelegate((ctx, i) => _Thumb(post: fs.posts[i]), childCount: fs.posts.length),
                      ),
                    if (fs.loadingMore)
                      const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.p, required this.busy});
  final Profile p; final bool busy;

  void _openList(BuildContext context, UserListKind kind, String title) {
    if (!p.canView) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => UserListPage(kind: kind, userId: p.id, title: title, isMe: p.isMe)));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = VxColors.of(context);
    final bloc = context.read<ProfileBloc>();
    Widget stat(int n, String label, [VoidCallback? onTap]) => InkWell(
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Column(children: [
            Text(s.n(n), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(label, style: TextStyle(color: c.muted, fontSize: 13)),
          ])),
        );

    Widget button;
    if (p.isMe) {
      button = OutlinedButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider.value(value: bloc, child: const EditProfilePage()))),
        child: Text(context.t('edit_profile')),
      );
    } else if (p.followStatus == FollowStatus.accepted) {
      button = OutlinedButton(
        onPressed: busy ? null : () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(ctx.s.fmt('unfollow_q', {'u': '@${p.username}'})),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.t('cancel'))),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.t('unfollow'), style: TextStyle(color: c.error))),
              ],
            ),
          );
          if (ok == true) bloc.add(const UnfollowPressed());
        },
        child: Text(context.t('following')),
      );
    } else if (p.followStatus == FollowStatus.pending) {
      button = OutlinedButton(onPressed: busy ? null : () => bloc.add(const UnfollowPressed()), child: Text(context.t('requested')));
    } else {
      button = FilledButton(
        onPressed: busy ? null : () => bloc.add(const FollowPressed()),
        child: Text(context.t(p.followsMe ? 'follow_back' : 'follow')),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          EditableAvatar(url: p.avatarUrl, onTap: p.isMe && !busy ? () => pickAvatar(context) : null),
          const SizedBox(width: 12),
          Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            stat(p.postsCount, context.t('posts')),
            stat(p.followersCount, context.t('followers'), () => _openList(context, UserListKind.followers, context.t('followers'))),
            stat(p.followingCount, context.t('following_label'), () => _openList(context, UserListKind.following, context.t('following_label'))),
          ])),
        ]),
        const SizedBox(height: 12),
        if ((p.fullName ?? '').isNotEmpty) Text(p.fullName!, style: const TextStyle(fontWeight: FontWeight.w700)),
        if (p.bio.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text(p.bio)),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: button),
      ]),
    );
  }
}

class _Locked extends StatelessWidget {
  const _Locked();
  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(children: [
        Icon(Icons.lock_outline, size: 56, color: c.muted), const SizedBox(height: 12),
        Text(context.t('private_title'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 4),
        Text(context.t('private_body'), textAlign: TextAlign.center, style: TextStyle(color: c.muted)),
      ]),
    );
  }
}

class _EmptyPosts extends StatelessWidget {
  const _EmptyPosts({required this.isMe});
  final bool isMe;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(48),
        child: Column(children: [
          Icon(Icons.photo_camera_outlined, size: 56, color: VxColors.of(context).muted), const SizedBox(height: 12),
          Text(context.t('no_posts'), style: TextStyle(color: VxColors.of(context).muted)),
        ]),
      );
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.post});
  final Post post;
  @override
  Widget build(BuildContext context) {
    final first = post.media.isEmpty ? null : post.media.first;
    return GestureDetector(
      onTap: () async {
        final feed = context.read<FeedBloc>();
        final prof = context.read<ProfileBloc>();
        await Navigator.push(context, MaterialPageRoute(
            builder: (_) => BlocProvider.value(value: feed, child: PostsViewerPage(startId: post.id))));
        prof.add(const ProfileRefreshed()); // post count may have changed
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

/// Scrollable list of the profile's posts, opened at the tapped one. Reuses the profile's FeedBloc.
class PostsViewerPage extends StatefulWidget {
  const PostsViewerPage({super.key, required this.startId});
  final String startId;
  @override
  State<PostsViewerPage> createState() => _PostsViewerPageState();
}

class _PostsViewerPageState extends State<PostsViewerPage> {
  final _keys = <String, GlobalKey>{};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[widget.startId]?.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx);
    });
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<FeedBloc, FeedState>(
        listenWhen: (p, s) => s.posts.isEmpty && p.posts.isNotEmpty,
        listener: (context, st) => Navigator.pop(context), // last post deleted
        builder: (context, st) => Scaffold(
          appBar: AppBar(title: Text(context.t('posts'))),
          body: SingleChildScrollView(
            child: Column(children: [for (final p in st.posts) PostCard(key: _keys.putIfAbsent(p.id, () => GlobalKey()), post: p)]),
          ),
        ),
      );
}
