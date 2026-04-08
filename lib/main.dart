import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maeum_diary/core/service/notification_service.dart';
import 'package:maeum_diary/core/utils/date_utils.dart' as date_utils;
import 'package:maeum_diary/infrastructure/datasource/diary_local_data_source.dart';
import 'package:maeum_diary/presentation/provider/theme_provider.dart';
import 'package:maeum_diary/presentation/screen/diary_edit_screen.dart';
import 'package:maeum_diary/presentation/screen/main_screen.dart';

/// 앱 전역 네비게이터 키 — 알림 탭 시 화면 전환에 사용
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Android 15 edge-to-edge: deprecated setStatusBarColor / setNavigationBarColor 호출 방지
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // .env 파일 로드 (없거나 파싱 실패해도 앱 실행 유지)
    await dotenv.load(fileName: '.env').catchError((_) {});

    // 알림 서비스 초기화
    await NotificationService.instance.initialize();

    // 저장된 알림 설정으로 재스케줄링 (앱 재시작 시 알림 유지)
    await _rescheduleNotificationFromPrefs();

    runApp(
        const ProviderScope(
            child: MaeumDiaryApp(),
        ),
    );

    // runApp 이후에 탭 핸들러 등록 (navigatorKey가 활성화된 뒤)
    NotificationService.instance.setOnNotificationTap(_navigateToTodayDiary);

    // 앱 종료 상태에서 알림 탭으로 실행된 경우 (cold start) 처리
    WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (await NotificationService.instance.didLaunchFromNotification()) {
            _navigateToTodayDiary();
        }
    });
}

/// 알림 탭 시 오늘 날짜 일기 작성 화면으로 이동
void _navigateToTodayDiary() {
    final today = date_utils.toLocalDate(DateTime.now());
    navigatorKey.currentState?.push(
        MaterialPageRoute(
            builder: (_) => DiaryEditScreen(date: today),
        ),
    );
}

/// 앱 시작 시 저장된 알림 설정을 읽어 재스케줄링
///
/// Riverpod ProviderScope 바깥이므로 DiaryLocalDataSource.instance를 직접 사용해
/// 오늘 일기 존재 여부를 조회한다.
Future<void> _rescheduleNotificationFromPrefs() async {
    try {
        final today = date_utils.toDateKey(DateTime.now());
        final row = await DiaryLocalDataSource.instance.queryByDate(today);
        await NotificationService.instance.rescheduleFromPrefs(
            hasDiaryToday: row != null,
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
            navigatorKey: navigatorKey,
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
