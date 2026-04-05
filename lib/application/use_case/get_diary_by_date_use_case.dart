import 'package:maeum_diary/domain/entity/diary_entry.dart';
import 'package:maeum_diary/domain/repository/diary_repository.dart';

/// 특정 날짜의 일기를 조회하는 UseCase
final class GetDiaryByDateUseCase {
    final DiaryRepository _repository;

    const GetDiaryByDateUseCase({required DiaryRepository repository})
        : _repository = repository;

    /// [date]에 해당하는 일기를 반환한다. 없으면 null을 반환한다.
    Future<DiaryEntry?> execute(DateTime date) {
        return _repository.findByDate(date);
    }
}
