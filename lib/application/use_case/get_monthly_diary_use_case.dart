import 'package:maeum_diary/domain/entity/diary_entry.dart';
import 'package:maeum_diary/domain/repository/diary_repository.dart';

/// 월별 일기 목록을 조회하는 UseCase (캘린더용)
final class GetMonthlyDiaryUseCase {
    final DiaryRepository _repository;

    const GetMonthlyDiaryUseCase({required DiaryRepository repository})
        : _repository = repository;

    /// [year]년 [month]월에 작성된 모든 일기를 반환한다.
    Future<List<DiaryEntry>> execute(int year, int month) {
        return _repository.findByMonth(year, month);
    }
}
