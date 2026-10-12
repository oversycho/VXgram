import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../feed/ui/post_detail_page.dart';
import '../../profile/domain/profile_repository.dart';
import '../../profile/ui/profile_page.dart';
import '../bloc/notifications_cubit.dart';
import '../bloc/unread_cubit.dart';
import '../domain/app_notification.dart';
import '../domain/notification_repository.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (c) => NotificationsCubit(c.read<NotificationRepository>(), c.read<ProfileRepository>(),
            onMarkedRead: () => c.read<UnreadCubit>().clear())..load(),
        child: const _View(),
      );
}

class _View extends StatelessWidget {
  const _View();

  String _text(BuildContext context, AppNotification n) {
    final s = context.s;
    switch (n.type) {
      case NotificationType.like: return s.fmt('notif_like', {'u': n.actorUsername});
      case NotificationType.comment: return s.fmt('notif_comment', {'u': n.actorUsername, 'c': n.body ?? ''});
      case NotificationType.follow: return s.fmt('notif_follow', {'u': n.actorUsername});
      case NotificationType.followRequest: return s.fmt('notif_follow_request', {'u': n.actorUsername});
      case NotificationType.followAccepted: return s.fmt('notif_follow_accepted', {'u': n.actorUsername});
      case NotificationType.other: return n.actorUsername;
    }
  }

  void _open(BuildContext context, AppNotification n) {
    final hasPost = (n.type == NotificationType.like || n.type == NotificationType.comment) && n.postId != null;
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => hasPost ? PostDetailPage(postId: n.postId!) : ProfilePage(userId: n.actorId)));
  }

  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.t('notifications'))),
      body: BlocConsumer<NotificationsCubit, NotificationsState>(
        listenWhen: (p, s) => s.error != null && s.error != p.error && s.status == NotificationsStatus.success,
        listener: (context, st) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(st.error!))),
        builder: (context, st) {
          if (st.status == NotificationsStatus.loading) return const Center(child: CircularProgressIndicator());
          if (st.status == NotificationsStatus.failure) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(st.error ?? ''), const SizedBox(height: 12),
              OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: () => context.read<NotificationsCubit>().load(), child: Text(context.t('retry'))),
            ]));
          }
          if (st.items.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.notifications_none, size: 56, color: c.muted), const SizedBox(height: 12),
              Text(context.t('no_notifications'), style: TextStyle(color: c.muted)),
            ]));
          }
          return NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels > n.metrics.maxScrollExtent - 400) context.read<NotificationsCubit>().loadMore();
              return false;
            },
            child: ListView.builder(
              itemCount: st.items.length,
              itemBuilder: (context, i) {
                final n = st.items[i];
                final cubit = context.read<NotificationsCubit>();
                Widget? trailing;
                if (n.type == NotificationType.followRequest) {
                  const size = Size(0, 36); // the theme's default is full-width: override inside rows
                  const pad = EdgeInsets.symmetric(horizontal: 12);
                  trailing = Row(mainAxisSize: MainAxisSize.min, children: [
                    FilledButton(style: FilledButton.styleFrom(minimumSize: size, padding: pad), onPressed: () => cubit.respond(n, accept: true), child: Text(context.t('confirm'))),
                    const SizedBox(width: 6),
                    OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: size, padding: pad), onPressed: () => cubit.respond(n, accept: false), child: Text(context.t('delete'))),
                  ]);
                } else if (n.thumbUrl != null) {
                  trailing = ClipRRect(borderRadius: BorderRadius.circular(8),
                      child: SizedBox(width: 44, height: 44, child: MediaTile(url: n.thumbUrl!, isVideo: false, play: false)));
                }
                return Container(
                  color: n.read ? null : Color.alphaBlend(c.primary.withAlpha(22), c.bg),
                  child: ListTile(
                    leading: Avatar(url: n.actorAvatar, size: 44),
                    title: Text(_text(context, n), maxLines: 3, overflow: TextOverflow.ellipsis),
                    subtitle: Text(context.s.ago(n.createdAt), style: TextStyle(color: c.muted, fontSize: 12)),
                    trailing: trailing,
                    onTap: () => _open(context, n),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
