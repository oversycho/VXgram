import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/l10n/app_strings.dart';
import '../bloc/unread_cubit.dart';
import 'notifications_page.dart';

/// Heart icon with an unread badge (home app bar). Opens the notifications list.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<UnreadCubit, int>(
        builder: (context, n) => IconButton(
          tooltip: context.t('notifications'),
          icon: Badge(isLabelVisible: n > 0, label: Text(n > 99 ? '99+' : context.s.n(n)), child: const Icon(Icons.favorite_border)),
          onPressed: () async {
            final unread = context.read<UnreadCubit>();
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
            unread.refresh();
          },
        ),
      );
}
