import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState extends Equatable {
  const SettingsState({required this.locale, required this.mode, required this.chosen});
  final Locale locale; final ThemeMode mode;
  final bool chosen; // false until the first-launch language picker is completed
  SettingsState copyWith({Locale? locale, ThemeMode? mode, bool? chosen}) =>
      SettingsState(locale: locale ?? this.locale, mode: mode ?? this.mode, chosen: chosen ?? this.chosen);
  @override
  List<Object?> get props => [locale, mode, chosen];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._p)
      : super(SettingsState(
          locale: Locale(_p.getString('lang') ?? 'en'),
          mode: ThemeMode.values.firstWhere((m) => m.name == _p.getString('theme'), orElse: () => ThemeMode.system),
          chosen: _p.getString('lang') != null,
        ));
  final SharedPreferences _p;

  void setLocale(Locale l) { _p.setString('lang', l.languageCode); emit(state.copyWith(locale: l, chosen: true)); }
  void setMode(ThemeMode m) { _p.setString('theme', m.name); emit(state.copyWith(mode: m)); }
  void finishPicker() { _p.setString('lang', state.locale.languageCode); emit(state.copyWith(chosen: true)); }
}
