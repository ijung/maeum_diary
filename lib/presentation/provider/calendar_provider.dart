import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maeum_diary/core/di/providers.dart';
import 'package:maeum_diary/core/service/holiday_service.dart';
import 'package:maeum_diary/core/utils/date_utils.dart' as date_utils;
import 'package:maeum_diary/domain/entity/diary_entry.dart';

/// 현재 표시 중인 월 (기본값: 이번 달)
final selectedMonthProvider = StateProvider<DateTime>((ref) {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
});

/// 선택된 날짜 (기본값: 오늘)
final selectedDateProvider = StateProvider<DateTime>((ref) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
});

/// [year]년 공휴일 날짜 Set (yyyy-MM-dd)
///
/// API 실패 또는 API 키 미설정 시 빈 Set을 반환해 앱 정상 동작을 보장한다.
final holidayProvider =
    FutureProvider.autoDispose.family<Set<String>, int>((ref, year) {
    return HolidayService.instance.getHolidaysForYear(year);
});

/// 현재 표시 중인 월의 일기 목록 (Map<날짜키, DiaryEntry>)
///
/// 날짜키 형식: 'yyyy-MM-dd'
final monthlyDiaryProvider =
    FutureProvider.autoDispose<Map<String, DiaryEntry>>((ref) async {
    final month = ref.watch(selectedMonthProvider);
    final useCase = ref.read(getMonthlyDiaryUseCaseProvider);

    final entries = await useCase.execute(month.year, month.month);

    return {
        for (final e in entries) date_utils.toDateKey(e.date): e,
    };
});
