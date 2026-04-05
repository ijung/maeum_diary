import 'package:maeum_diary/domain/entity/diary_entry.dart';

/// 일기 저장소 포트 (Hexagonal Architecture의 Port)
///
/// Infrastructure 레이어에서 이 인터페이스를 구현한다.
/// Application 레이어는 이 인터페이스에만 의존하므로
/// 실제 저장소 구현에 독립적이다.
abstract interface class DiaryRepository {
    /// [date]의 일기를 조회한다. 없으면 null을 반환한다.
    Future<DiaryEntry?> findByDate(DateTime date);

    /// [year]년 [month]월의 모든 일기를 조회한다.
    Future<List<DiaryEntry>> findByMonth(int year, int month);

    /// 새 일기를 저장한다.
    Future<void> save(DiaryEntry entry);

    /// 기존 일기를 수정한다.
    Future<void> update(DiaryEntry entry);
}
