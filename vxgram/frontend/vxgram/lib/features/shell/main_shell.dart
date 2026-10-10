import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../create/ui/create_post_page.dart';
import '../explore/ui/explore_page.dart';
import '../feed/ui/feed_page.dart';
import '../profile/ui/profile_page.dart';
import '../share/ui/inbox_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _i = 0;
  // bumping these tells a tab to reload itself
  final _feedRefresh = ValueNotifier<int>(0), _inboxRefresh = ValueNotifier<int>(0);

  @override
  void dispose() { _feedRefresh.dispose(); _inboxRefresh.dispose(); super.dispose(); }

  void _posted() {
    _feedRefresh.value++;
    setState(() => _i = 0);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('post_created'))));
  }

  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    final items = [
      (Icons.home_outlined, Icons.home, 'home'), (Icons.search, Icons.search, 'explore'), (Icons.add, Icons.add, 'post'),
      (Icons.mail_outline, Icons.mail, 'inbox'), (Icons.person_outline, Icons.person, 'profile'),
    ];
    return Scaffold(
      body: IndexedStack(index: _i, children: [
        FeedPage(refresh: _feedRefresh),
        const ExplorePage(),
        CreatePostPage(onPosted: _posted),
        InboxPage(refresh: _inboxRefresh),
        ProfilePage(refresh: _feedRefresh),
      ]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: c.bg, border: Border(top: BorderSide(color: c.border))),
        child: SafeArea(
          child: SizedBox(
            height: 62,
            child: Row(children: [
              for (var k = 0; k < items.length; k++)
                Expanded(
                  child: InkResponse(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      setState(() => _i = k);
                      if (k == 3) _inboxRefresh.value++;
                    },
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      k == 2
                          ? Container(width: 40, height: 30, decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.add, color: c.text))
                          : Icon(_i == k ? items[k].$2 : items[k].$1, color: _i == k ? c.primary : c.muted),
                      const SizedBox(height: 2),
                      Text(context.t(items[k].$3), style: TextStyle(fontSize: 10.5, color: _i == k ? c.primary : c.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
