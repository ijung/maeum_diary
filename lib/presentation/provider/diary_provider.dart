import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maeum_diary/application/use_case/save_diary_use_case.dart';
import 'package:maeum_diary/core/di/providers.dart';
import 'package:maeum_diary/core/error/failures.dart';
import 'package:maeum_diary/domain/entity/diary_entry.dart';
import 'package:maeum_diary/presentation/provider/calendar_provider.dart';

/// 특정 날짜의 일기를 조회하는 Provider
final diaryByDateProvider = FutureProvider.autoDispose
    .family<DiaryEntry?, DateTime>((ref, date) {
      final useCase = ref.read(getDiaryByDateUseCaseProvider);
      return useCase.execute(date);
    });

// ─── 일기 저장 상태 ───────────────────────────────────────────────────────────

sealed class SaveDiaryState {
  const SaveDiaryState();
}

final class SaveDiaryIdle extends SaveDiaryState {
  const SaveDiaryIdle();
}

final class SaveDiaryLoading extends SaveDiaryState {
  const SaveDiaryLoading();
}

final class SaveDiarySuccess extends SaveDiaryState {
  const SaveDiarySuccess();
}

final class SaveDiaryError extends SaveDiaryState {
  final Failure failure;
  const SaveDiaryError(this.failure);
}

/// 일기 저장/수정 Notifier
final class SaveDiaryNotifier extends Notifier<SaveDiaryState> {
  @override
  SaveDiaryState build() => const SaveDiaryIdle();

  /// [input]에 따라 일기를 저장 또는 수정한다.
  Future<bool> save(SaveDiaryInput input) async {
    state = const SaveDiaryLoading();

    final useCase = ref.read(saveDiaryUseCaseProvider);
    final failure = await useCase.execute(input);

    if (failure != null) {
      state = SaveDiaryError(failure);
      return false;
    }

    // 월별 캐시 무효화 → 캘린더 자동 갱신
    ref.invalidate(monthlyDiaryProvider);

    state = const SaveDiarySuccess();
    return true;
  }

  void reset() => state = const SaveDiaryIdle();
}

final saveDiaryProvider = NotifierProvider<SaveDiaryNotifier, SaveDiaryState>(
  SaveDiaryNotifier.new,
);
