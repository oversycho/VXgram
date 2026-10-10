import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../bloc/user_list_cubit.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';
import 'profile_page.dart';

/// Followers / following / follow requests.
class UserListPage extends StatelessWidget {
  const UserListPage({super.key, required this.kind, required this.userId, required this.title, required this.isMe});
  final UserListKind kind; final String userId, title; final bool isMe;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (c) => UserListCubit(c.read<ProfileRepository>(), kind, userId)..load(),
        child: _View(kind: kind, title: title, isMe: isMe),
      );
}

class _View extends StatelessWidget {
  const _View({required this.kind, required this.title, required this.isMe});
  final UserListKind kind; final String title; final bool isMe;

  String get _emptyKey => kind == UserListKind.followers ? 'no_followers' : (kind == UserListKind.following ? 'no_following' : 'no_requests');

  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    final me = context.read<ProfileRepository>().currentUserId;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: BlocConsumer<UserListCubit, UserListState>(
        listenWhen: (p, s) => s.error != null && s.error != p.error,
        listener: (context, st) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(st.error!))),
        builder: (context, st) {
          if (st.status == UserListStatus.loading) return const Center(child: CircularProgressIndicator());
          if (st.status == UserListStatus.failure) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(st.error ?? ''), const SizedBox(height: 12),
              OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: () => context.read<UserListCubit>().load(), child: Text(context.t('retry'))),
            ]));
          }
          if (st.users.isEmpty) return Center(child: Text(context.t(_emptyKey), style: TextStyle(color: c.muted)));
          return NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels > n.metrics.maxScrollExtent - 400) context.read<UserListCubit>().loadMore();
              return false;
            },
            child: ListView.builder(
              itemCount: st.users.length,
              itemBuilder: (context, i) {
                final u = st.users[i];
                return ListTile(
                  leading: Avatar(url: u.avatarUrl, size: 48),
                  title: Text(u.username, style: const TextStyle(fontWeight: FontWeight.w700), textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                  subtitle: (u.fullName ?? '').isEmpty ? null : Text(u.fullName!, style: TextStyle(color: c.muted)),
                  trailing: _Trailing(user: u, kind: kind, isMe: isMe, meId: me),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: u.id))),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _Trailing extends StatelessWidget {
  const _Trailing({required this.user, required this.kind, required this.isMe, required this.meId});
  final UserSummary user; final UserListKind kind; final bool isMe; final String? meId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UserListCubit>();
    const pad = EdgeInsets.symmetric(horizontal: 14);
    const size = Size(0, 36); // the theme's default is full-width: override inside rows
    if (kind == UserListKind.requests) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        FilledButton(style: FilledButton.styleFrom(minimumSize: size, padding: pad), onPressed: () => cubit.respond(user, accept: true), child: Text(context.t('confirm'))),
        const SizedBox(width: 8),
        OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: size, padding: pad), onPressed: () => cubit.respond(user, accept: false), child: Text(context.t('delete'))),
      ]);
    }
    if (kind == UserListKind.followers && isMe) {
      return OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: size, padding: pad), onPressed: () => cubit.removeFollower(user), child: Text(context.t('remove')));
    }
    if (user.id == meId) return const SizedBox.shrink();
    final label = user.iFollow == FollowStatus.accepted ? 'following' : (user.iFollow == FollowStatus.pending ? 'requested' : 'follow');
    return user.iFollow == FollowStatus.none
        ? FilledButton(style: FilledButton.styleFrom(minimumSize: size, padding: pad), onPressed: () => cubit.toggleFollow(user), child: Text(context.t(label)))
        : OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: size, padding: pad), onPressed: () => cubit.toggleFollow(user), child: Text(context.t(label)));
  }
}
