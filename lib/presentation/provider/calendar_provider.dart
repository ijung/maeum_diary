import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maeum_diary/core/di/providers.dart';
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

/// 현재 표시 중인 월의 일기 목록 (Map<날짜키, DiaryEntry>)
///
/// 날짜키 형식: 'yyyy-MM-dd'
final monthlyDiaryProvider =
    FutureProvider.autoDispose<Map<String, DiaryEntry>>((ref) async {
    final month = ref.watch(selectedMonthProvider);
    final useCase = ref.read(getMonthlyDiaryUseCaseProvider);

    final entries = await useCase.execute(month.year, month.month);

    return {
        for (final e in entries) _toKey(e.date): e,
    };
});

String _toKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
}
