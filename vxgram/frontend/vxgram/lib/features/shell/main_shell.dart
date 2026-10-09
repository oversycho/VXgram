import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../feed/ui/feed_page.dart';
import '../settings/settings_pages.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _i = 0;
  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    final items = [
      (Icons.home_outlined, Icons.home, 'home'), (Icons.search, Icons.search, 'explore'), (Icons.add, Icons.add, 'post'),
      (Icons.mail_outline, Icons.mail, 'inbox'), (Icons.person_outline, Icons.person, 'profile'),
    ];
    return Scaffold(
      body: IndexedStack(index: _i, children: const [FeedPage(), _Soon('explore'), _Soon('post'), _Soon('inbox'), _ProfileStub()]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: c.bg, border: Border(top: BorderSide(color: c.border))),
        child: SafeArea(
          child: SizedBox(
            height: 62,
            child: Row(children: [
              for (var k = 0; k < items.length; k++)
                Expanded(
                  child: InkResponse(
                    onTap: () => setState(() => _i = k),
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

class _Soon extends StatelessWidget {
  const _Soon(this.k);
  final String k;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.t(k))),
        body: Center(child: Text(context.t('coming_soon'), style: TextStyle(color: VxColors.of(context).muted))),
      );
}

/// Temporary until the profile feature is built: gives access to Settings (language / theme / logout).
class _ProfileStub extends StatelessWidget {
  const _ProfileStub();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.t('profile')), actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()))),
        ]),
        body: Center(child: Text(context.t('coming_soon'), style: TextStyle(color: VxColors.of(context).muted))),
      );
}
