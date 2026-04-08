import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 테마 모드 상태 관리
///
/// SharedPreferences에 'theme_mode' 키로 ThemeMode.index를 저장한다.
final class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
    static const String _key = 'theme_mode';

    @override
    Future<ThemeMode> build() async {
        final prefs = await SharedPreferences.getInstance();
        final index = prefs.getInt(_key) ?? 0;
        // ThemeMode.values 순서: system=0, light=1, dark=2
        return ThemeMode.values[index.clamp(0, ThemeMode.values.length - 1)];
    }

    Future<void> setThemeMode(ThemeMode mode) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_key, mode.index);
        state = AsyncData(mode);
    }
}

final themeModeProvider =
    AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
