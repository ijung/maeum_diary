import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maeum_diary/core/service/notification_service.dart';
import 'package:maeum_diary/presentation/provider/settings_provider.dart';
import 'package:maeum_diary/presentation/screen/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 알림 서비스 초기화
    await NotificationService.instance.initialize();

    // 저장된 알림 설정으로 재스케줄링 (앱 재시작 시 알림 유지)
    await _rescheduleNotificationFromPrefs();

    runApp(
        const ProviderScope(
            child: MaeumDiaryApp(),
        ),
    );
}

/// 앱 시작 시 저장된 알림 설정을 읽어 재스케줄링
Future<void> _rescheduleNotificationFromPrefs() async {
    try {
        final prefs = await SharedPreferences.getInstance();
        final enabled = prefs.getBool('notif_enabled') ?? false;
        final hour = prefs.getInt('notif_hour') ?? 21;
        final minute = prefs.getInt('notif_minute') ?? 0;

        await NotificationService.instance.reschedule(
            enabled: enabled,
            time: TimeOfDay(hour: hour, minute: minute),
        );
    } catch (e, st) {
        // 알림 재스케줄링 실패 시 앱 실행은 계속하되 에러를 기록
        debugPrint('[NotificationService] 재스케줄링 실패: $e\n$st');
    }
}

class MaeumDiaryApp extends ConsumerWidget {
    const MaeumDiaryApp({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        // 로딩 중이거나 에러 시 시스템 테마로 폴백
        final themeMode =
            ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system;

        return MaterialApp(
            title: '마음 일기',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            // 한국어 로케일 지원 (intl 날짜 포맷용)
            localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
                Locale('ko', 'KR'),
                Locale('en', 'US'),
            ],
            locale: const Locale('ko', 'KR'),
            theme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF7B68EE),
                    brightness: Brightness.light,
                ),
                appBarTheme: const AppBarTheme(
                    centerTitle: true,
                    elevation: 0,
                ),
            ),
            darkTheme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF7B68EE),
                    brightness: Brightness.dark,
                ),
                appBarTheme: const AppBarTheme(
                    centerTitle: true,
                    elevation: 0,
                ),
            ),
            home: const MainScreen(),
        );
    }
}
