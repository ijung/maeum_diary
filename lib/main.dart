import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maeum_diary/presentation/screen/main_screen.dart';

void main() {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(
        const ProviderScope(
            child: MaeumDiaryApp(),
        ),
    );
}

class MaeumDiaryApp extends StatelessWidget {
    const MaeumDiaryApp({super.key});

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: '마음 일기',
            debugShowCheckedModeBanner: false,
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
