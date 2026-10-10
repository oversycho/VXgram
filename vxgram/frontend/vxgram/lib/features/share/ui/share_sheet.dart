import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../profile/domain/profile_repository.dart';
import '../bloc/share_cubit.dart';
import '../domain/share_repository.dart';

/// Send a post to other users, copy its link, or hand it to the system share sheet.
class ShareSheet extends StatelessWidget {
  const ShareSheet({super.key, required this.postId, required this.link});
  final String postId, link;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (c) => ShareCubit(c.read<ProfileRepository>(), c.read<ShareRepository>(), postId)..load(),
        child: _Body(link: link),
      );
}

class _Body extends StatefulWidget {
  const _Body({required this.link});
  final String link;
  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _msg = TextEditingController();
  @override
  void dispose() { _msg.dispose(); super.dispose(); }

  Widget _action(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final c = VxColors.of(context);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12), onTap: onTap,
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(children: [
          CircleAvatar(radius: 22, backgroundColor: c.surface, child: Icon(icon, color: c.text)),
          const SizedBox(height: 6), Text(label, style: const TextStyle(fontSize: 12)),
        ])),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    final mq = MediaQuery.of(context);
    final h = math.max(320.0, math.min(mq.size.height * .75, mq.size.height - mq.viewInsets.bottom - 100));
    return BlocListener<ShareCubit, ShareState>(
      listenWhen: (p, s) => (s.sent && !p.sent) || (s.error != null && s.error != p.error),
      listener: (context, st) {
        final messenger = ScaffoldMessenger.of(context);
        if (st.sent) {
          final text = context.t('sent');
          Navigator.pop(context);
          messenger.showSnackBar(SnackBar(content: Text(text)));
        } else {
          messenger.showSnackBar(SnackBar(content: Text(st.error!)));
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
        child: SizedBox(
          height: h,
          child: Column(children: [
            Text(context.t('share'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                _action(context, Icons.link, context.t('copy_link'), () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final text = context.t('link_copied');
                  await Clipboard.setData(ClipboardData(text: widget.link));
                  messenger.showSnackBar(SnackBar(content: Text(text)));
                }),
                _action(context, Icons.ios_share, context.t('share_to'), () => Share.share(widget.link)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                onChanged: (v) => context.read<ShareCubit>().search(v),
                decoration: InputDecoration(hintText: context.t('search_people'), prefixIcon: Icon(Icons.search, color: c.muted), isDense: true),
              ),
            ),
            Expanded(
              child: BlocBuilder<ShareCubit, ShareState>(
                buildWhen: (p, s) => p.users != s.users || p.selected != s.selected || p.loading != s.loading,
                builder: (context, st) {
                  if (st.loading && st.users.isEmpty) return const Center(child: CircularProgressIndicator());
                  if (st.users.isEmpty) return Center(child: Text(context.t('no_users'), style: TextStyle(color: c.muted)));
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: .85),
                    itemCount: st.users.length,
                    itemBuilder: (context, i) {
                      final u = st.users[i];
                      final on = st.selected.contains(u.id);
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.read<ShareCubit>().toggle(u.id),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Stack(children: [
                            Avatar(url: u.avatarUrl, size: 64),
                            if (on) PositionedDirectional(bottom: 0, end: 0, child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle, border: Border.all(color: c.bg, width: 2)),
                              child: Icon(Icons.check, size: 14, color: c.onPrimary),
                            )),
                          ]),
                          const SizedBox(height: 6),
                          Text(u.username, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 12)),
                        ]),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(children: [
                TextField(controller: _msg, maxLength: 300, decoration: InputDecoration(hintText: context.t('message_hint'), counterText: '', isDense: true)),
                const SizedBox(height: 10),
                BlocBuilder<ShareCubit, ShareState>(
                  buildWhen: (p, s) => p.selected != s.selected || p.sending != s.sending,
                  builder: (context, st) => FilledButton(
                    onPressed: st.selected.isEmpty || st.sending ? null : () => context.read<ShareCubit>().send(_msg.text),
                    child: st.sending
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(st.selected.isEmpty ? context.t('send') : context.s.fmt('send_n', {'n': st.selected.length})),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
