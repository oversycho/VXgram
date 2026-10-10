import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vxgram/features/settings/settings_cubit.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('first launch: nothing chosen, onboarding not seen', () async {
    final c = SettingsCubit(await SharedPreferences.getInstance());
    expect(c.state.chosen, isFalse);
    expect(c.state.onboarded, isFalse);
    expect(c.state.mode, ThemeMode.system);
    await c.close();
  });

  test('language, theme and onboarding are remembered', () async {
    final prefs = await SharedPreferences.getInstance();
    final c = SettingsCubit(prefs)..setLocale(const Locale('fa'))..setMode(ThemeMode.dark)..finishOnboarding();
    final again = SettingsCubit(prefs); // simulates the next app start
    expect(again.state.locale.languageCode, 'fa');
    expect(again.state.mode, ThemeMode.dark);
    expect(again.state.chosen, isTrue);
    expect(again.state.onboarded, isTrue);
    await c.close();
    await again.close();
  });
}
