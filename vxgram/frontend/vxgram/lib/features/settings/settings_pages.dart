import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../auth/bloc/auth_bloc.dart';
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 24), const Logo(), const SizedBox(height: 40),
              Text('Choose your language', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('زبان خود را انتخاب کنید', style: TextStyle(color: VxColors.of(context).muted)),
              const SizedBox(height: 28),
              const _LangThemeControls(),
              const Spacer(),
              FilledButton(onPressed: () => context.read<SettingsCubit>().finishPicker(), child: Text(context.t('continue'))),
            ]),
          ),
        ),
      );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.t('settings'))),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const _LangThemeControls(),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: VxColors.of(context).error),
            icon: const Icon(Icons.logout), label: Text(context.t('logout')),
            onPressed: () => context.read<AuthBloc>().add(const LogoutPressed()),
          ),
        ]),
      );
}
