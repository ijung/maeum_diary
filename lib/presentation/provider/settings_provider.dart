import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maeum_diary/core/service/notification_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── 테마 모드 ────────────────────────────────────────────────────────────────

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

// ─── 알림 설정 ────────────────────────────────────────────────────────────────

/// 알림 설정 모델
class NotificationSettings {
    final bool enabled;
    final TimeOfDay time;
    final bool alwaysNotify;

    const NotificationSettings({
        required this.enabled,
        required this.time,
        required this.alwaysNotify,
    });

    NotificationSettings copyWith({
        bool? enabled,
        TimeOfDay? time,
        bool? alwaysNotify,
    }) {
        return NotificationSettings(
            enabled: enabled ?? this.enabled,
            time: time ?? this.time,
            alwaysNotify: alwaysNotify ?? this.alwaysNotify,
        );
    }
}

/// 알림 설정 상태 관리
///
/// SharedPreferences에 'notif_enabled', 'notif_hour', 'notif_minute' 키로 저장한다.
/// 설정 변경 시 NotificationService를 통해 즉시 재스케줄링한다.
final class NotificationSettingsNotifier
    extends AsyncNotifier<NotificationSettings> {
    static const String _enabledKey = 'notif_enabled';
    static const String _hourKey = 'notif_hour';
    static const String _minuteKey = 'notif_minute';
    static const String _alwaysNotifyKey = 'notif_always_notify';

    // 기본 알림 시각: 21:00
    static const int _defaultHour = 21;
    static const int _defaultMinute = 0;

    @override
    Future<NotificationSettings> build() async {
        final prefs = await SharedPreferences.getInstance();
        return NotificationSettings(
            enabled: prefs.getBool(_enabledKey) ?? false,
            time: TimeOfDay(
                hour: prefs.getInt(_hourKey) ?? _defaultHour,
                minute: prefs.getInt(_minuteKey) ?? _defaultMinute,
            ),
            alwaysNotify: prefs.getBool(_alwaysNotifyKey) ?? false,
        );
    }

    Future<void> setEnabled(bool enabled) async {
        final current = state.valueOrNull;
        if (current == null) return;

        // 알림 활성화 시 권한 요청 — 거부되면 상태 변경 없이 종료
        if (enabled) {
            final granted = await NotificationService.instance.requestPermission();
            if (!granted) return;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_enabledKey, enabled);

        final next = current.copyWith(enabled: enabled);
        state = AsyncData(next);

        try {
            await NotificationService.instance.reschedule(
                enabled: enabled,
                time: next.time,
            );
        } catch (_) {
            // 스케줄링 실패 시 저장된 설정을 원래대로 롤백
            await prefs.setBool(_enabledKey, current.enabled);
            state = AsyncData(current);
            rethrow;
        }
    }

    Future<void> setAlwaysNotify(bool value) async {
        final current = state.valueOrNull;
        if (current == null) return;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_alwaysNotifyKey, value);
        state = AsyncData(current.copyWith(alwaysNotify: value));
    }

    Future<void> setTime(TimeOfDay time) async {
        final current = state.valueOrNull;
        if (current == null) return;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_hourKey, time.hour);
        await prefs.setInt(_minuteKey, time.minute);

        final next = current.copyWith(time: time);
        state = AsyncData(next);

        try {
            await NotificationService.instance.reschedule(
                enabled: next.enabled,
                time: time,
            );
        } catch (_) {
            // 스케줄링 실패 시 저장된 시간을 원래대로 롤백
            await prefs.setInt(_hourKey, current.time.hour);
            await prefs.setInt(_minuteKey, current.time.minute);
            state = AsyncData(current);
            rethrow;
        }
    }
}

final notificationSettingsProvider =
    AsyncNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
        NotificationSettingsNotifier.new);

// ─── 앱 정보 ──────────────────────────────────────────────────────────────────

/// 앱 버전 정보 조회 (package_info_plus)
final packageInfoProvider =
    FutureProvider<PackageInfo>((_) => PackageInfo.fromPlatform());
