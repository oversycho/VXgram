import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../feed/ui/post_detail_page.dart';
import '../bloc/inbox_cubit.dart';
import '../domain/share_repository.dart';

/// [refresh] ticks when the tab is opened again, so new shares show up.
class InboxPage extends StatelessWidget {
  const InboxPage({super.key, this.refresh});
  final Listenable? refresh;
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (c) => InboxCubit(c.read<ShareRepository>())..load(),
        child: _InboxView(refresh: refresh),
      );
}

class _InboxView extends StatefulWidget {
  const _InboxView({this.refresh});
  final Listenable? refresh;
  @override
  State<_InboxView> createState() => _InboxViewState();
}

class _InboxViewState extends State<_InboxView> {
  void _onRefresh() => context.read<InboxCubit>().load(silent: true);
  @override
  void initState() { super.initState(); widget.refresh?.addListener(_onRefresh); }
  @override
  void dispose() { widget.refresh?.removeListener(_onRefresh); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.t('inbox'))),
      body: BlocBuilder<InboxCubit, InboxState>(
        builder: (context, st) {
          if (st.status == InboxStatus.loading) return const Center(child: CircularProgressIndicator());
          if (st.status == InboxStatus.failure) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(st.error ?? ''), const SizedBox(height: 12),
              OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: () => context.read<InboxCubit>().load(), child: Text(context.t('retry'))),
            ]));
          }
          return RefreshIndicator(
            onRefresh: () => context.read<InboxCubit>().load(silent: true),
            child: st.items.isEmpty
                ? ListView(children: [
                    SizedBox(height: MediaQuery.of(context).size.height * .25),
                    Icon(Icons.mail_outline, size: 56, color: c.muted), const SizedBox(height: 12),
                    Center(child: Text(context.t('inbox_empty'), style: TextStyle(color: c.muted))),
                  ])
                : ListView.builder(
                    itemCount: st.items.length,
                    itemBuilder: (context, i) {
                      final it = st.items[i];
                      return ListTile(
                        leading: Avatar(url: it.senderAvatar, size: 48),
                        title: Text(context.s.fmt('sent_you_post', {'u': it.senderUsername}),
                            style: TextStyle(fontWeight: it.seen ? FontWeight.w400 : FontWeight.w700)),
                        subtitle: Text([if ((it.message ?? '').isNotEmpty) it.message!, context.s.ago(it.createdAt)].join(' · '),
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted)),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (!it.seen) Container(width: 9, height: 9, margin: const EdgeInsets.only(right: 8, left: 8), decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle)),
                          if (it.thumbUrl != null)
                            ClipRRect(borderRadius: BorderRadius.circular(8),
                                child: SizedBox(width: 48, height: 48, child: MediaTile(url: it.thumbUrl!, isVideo: false, play: false))),
                        ]),
                        onTap: () {
                          context.read<InboxCubit>().markSeen(it);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailPage(postId: it.postId)));
                        },
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
