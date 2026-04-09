import 'package:maeum_diary/core/error/failures.dart';
import 'package:maeum_diary/core/utils/date_utils.dart';
import 'package:maeum_diary/domain/entity/diary_entry.dart';
import 'package:maeum_diary/domain/port/diary_repository.dart';
import 'package:maeum_diary/domain/value_object/activities_selection.dart';
import 'package:maeum_diary/domain/value_object/emotions_selection.dart';
import 'package:uuid/uuid.dart';

/// 일기 저장/수정 입력값
final class SaveDiaryInput {
  final DateTime date;
  final EmotionsSelection emotions;
  final ActivitiesSelection activities;
  final String? memo;

  const SaveDiaryInput({
    required this.date,
    required this.emotions,
    ActivitiesSelection? activities,
    this.memo,
  }) : activities = activities ?? const ActivitiesSelection.empty();
}

/// 일기 저장 또는 수정을 처리하는 UseCase
///
/// 비즈니스 규칙:
/// - 오늘 또는 어제 날짜만 작성·수정 가능
/// - 메모는 옵셔널이지만 있을 경우 500자를 초과할 수 없음
/// - 해당 날짜에 이미 일기가 존재하면 update, 없으면 save
final class SaveDiaryUseCase {
  static const int _maxMemoLength = 500;

  final DiaryRepository _repository;
  final Uuid _uuid;

  /// [now]: 테스트에서 현재 시각을 주입할 때 사용한다. null이면 [DateTime.now()].
  final DateTime? Function()? _nowFactory;

  SaveDiaryUseCase({
    required DiaryRepository repository,
    Uuid uuid = const Uuid(),
    DateTime? Function()? nowFactory,
  }) : _repository = repository,
       _uuid = uuid,
       _nowFactory = nowFactory;

  /// [input]에 따라 일기를 저장 또는 수정한다.
  ///
  /// 성공하면 null을 반환하고, 실패하면 [Failure]를 반환한다.
  Future<Failure?> execute(SaveDiaryInput input) async {
    final now = _nowFactory?.call() ?? DateTime.now();

    // 오늘/어제 여부 검증
    if (!isEditableDate(input.date, now: now)) {
      return const EditNotAllowedFailure();
    }

    // 메모 길이 검증
    final trimmedMemo = input.memo?.trim();
    if (trimmedMemo != null && trimmedMemo.isNotEmpty) {
      if (trimmedMemo.length > _maxMemoLength) {
        return const MemoTooLongFailure();
      }
    }

    final existing = await _repository.findByDate(input.date);

    if (existing == null) {
      // 신규 저장
      final entry = DiaryEntry(
        id: _uuid.v4(),
        date: toLocalDate(input.date),
        emotions: input.emotions,
        activities: input.activities,
        memo: (trimmedMemo?.isEmpty ?? true) ? null : trimmedMemo,
        createdAt: now,
        updatedAt: now,
      );
      await _repository.save(entry);
    } else {
      // 기존 수정
      final updated = existing.copyWith(
        emotions: input.emotions,
        activities: input.activities,
        memo: (trimmedMemo?.isEmpty ?? true) ? null : trimmedMemo,
        clearMemo: trimmedMemo == null || trimmedMemo.isEmpty,
        updatedAt: now,
      );
      await _repository.update(updated);
    }

    return null;
  }
}
