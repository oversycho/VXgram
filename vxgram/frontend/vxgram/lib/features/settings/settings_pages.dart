import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/ui/auth_pages.dart';
import '../profile/bloc/profile_bloc.dart';
import '../profile/bloc/user_list_cubit.dart';
import '../profile/domain/profile.dart';
import '../profile/domain/profile_repository.dart';
import '../profile/ui/user_list_page.dart';
import 'settings_cubit.dart';

class _LangThemeControls extends StatelessWidget {
  const _LangThemeControls();
  @override
  Widget build(BuildContext context) {
    final st = context.watch<SettingsCubit>().state;
    final cubit = context.read<SettingsCubit>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(context.t('language'), style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      SegmentedButton<String>(
        segments: const [ButtonSegment(value: 'en', label: Text('English')), ButtonSegment(value: 'fa', label: Text('فارسی'))],
        selected: {st.locale.languageCode},
        onSelectionChanged: (v) => cubit.setLocale(Locale(v.first)),
      ),
      const SizedBox(height: 20),
      Text(context.t('appearance'), style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      SegmentedButton<ThemeMode>(
        segments: [
          ButtonSegment(value: ThemeMode.system, label: Text(context.t('system')), icon: const Icon(Icons.brightness_auto, size: 18)),
          ButtonSegment(value: ThemeMode.light, label: Text(context.t('light')), icon: const Icon(Icons.light_mode_outlined, size: 18)),
          ButtonSegment(value: ThemeMode.dark, label: Text(context.t('dark')), icon: const Icon(Icons.dark_mode_outlined, size: 18)),
        ],
        selected: {st.mode},
        onSelectionChanged: (v) => cubit.setMode(v.first),
      ),
    ]);
  }
}

/// First launch: choose language + theme (Figma "Mode picker" screen).
class LanguagePickerPage extends StatelessWidget {
  const LanguagePickerPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: KeyboardSafeBody(
            center: false,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 24), const Logo(), const SizedBox(height: 40),
              Text('Choose your language', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('زبان خود را انتخاب کنید', style: TextStyle(color: VxColors.of(context).muted)),
              const SizedBox(height: 28),
              const _LangThemeControls(),
              const SizedBox(height: 40),
              FilledButton(onPressed: () => context.read<SettingsCubit>().finishPicker(), child: Text(context.t('continue'))),
            ]),
          ),
        ),
      );
}

/// Needs a ProfileBloc above it (it is pushed from the own-profile page).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Widget _section(BuildContext context, String key) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Text(context.t(key), style: TextStyle(color: VxColors.of(context).muted, fontWeight: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.t('settings'))),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, st) {
          final p = st.profile;
          return ListView(padding: const EdgeInsets.all(16), children: [
            _section(context, 'account'),
            ListTile(
              leading: const Icon(Icons.lock_outline), title: Text(context.t('change_password')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage())),
            ),
            _section(context, 'privacy'),
            SwitchListTile(
              title: Text(context.t('private_account')), subtitle: Text(context.t('private_help')),
              value: p?.isPrivate ?? false,
              onChanged: p == null || st.busy ? null : (v) => context.read<ProfileBloc>().add(PrivacyToggled(v)),
            ),
            if (p?.isPrivate ?? false) _RequestsTile(userId: p!.id),
            _section(context, 'preferences'),
            const _LangThemeControls(),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: c.error),
              icon: const Icon(Icons.logout), label: Text(context.t('logout')),
              onPressed: () => context.read<AuthBloc>().add(const LogoutPressed()),
            ),
          ]);
        },
      ),
    );
  }
}

class _RequestsTile extends StatelessWidget {
  const _RequestsTile({required this.userId});
  final String userId;
  @override
  Widget build(BuildContext context) => FutureBuilder<List<UserSummary>>(
        future: context.read<ProfileRepository>().followRequests().catchError((_) => <UserSummary>[]),
        builder: (context, snap) {
          final n = snap.data?.length ?? 0;
          return ListTile(
            leading: const Icon(Icons.person_add_alt_1_outlined), title: Text(context.t('follow_requests')),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              if (n > 0) Badge(label: Text(context.s.n(n))),
              const SizedBox(width: 8), const Icon(Icons.chevron_right),
            ]),
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => UserListPage(kind: UserListKind.requests, userId: userId, title: context.t('follow_requests'), isMe: true))),
          );
        },
      );
}
