import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/l10n/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/common.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/ui/auth_pages.dart';
import 'features/settings/settings_cubit.dart';
import 'features/settings/settings_pages.dart';
import 'features/shell/main_shell.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class VxApp extends StatelessWidget {
  const VxApp({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, st) => MaterialApp(
        title: 'VXGram',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        locale: st.locale,
        supportedLocales: AppStrings.supported,
        localizationsDelegates: const [AppStrings.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        themeMode: st.mode,
        theme: AppTheme.build(Brightness.light, st.locale),
        darkTheme: AppTheme.build(Brightness.dark, st.locale),
        home: BlocListener<AuthBloc, AuthState>(
          listenWhen: (p, c) => p.status != c.status,
          // drop pushed pages (sign-up, settings) when auth state flips
          listener: (_, __) => navigatorKey.currentState?.popUntil((r) => r.isFirst),
          child: BlocBuilder<AuthBloc, AuthState>(
            buildWhen: (p, c) => p.status != c.status,
            builder: (context, auth) {
              if (!st.chosen) return const LanguagePickerPage();
              switch (auth.status) {
                case AuthStatus.unknown: return const Scaffold(body: Center(child: Logo(size: 40)));
                case AuthStatus.authenticated: return const MainShell();
                case AuthStatus.unauthenticated: return const LoginPage();
              }
            },
          ),
        ),
      ),
    );
  }
}
