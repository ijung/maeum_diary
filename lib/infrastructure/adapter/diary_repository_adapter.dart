import 'package:maeum_diary/core/utils/date_utils.dart';
import 'package:maeum_diary/domain/entity/diary_entry.dart';
import 'package:maeum_diary/domain/port/diary_repository.dart';
import 'package:maeum_diary/infrastructure/dto/diary_entry_dto.dart';
import 'package:maeum_diary/infrastructure/port/diary_data_source_port.dart';

/// [DiaryRepository] 포트의 로컬 DB 어댑터 구현체 (Secondary/Driven Adapter)
///
/// [DiaryDataSourcePort]를 통해 실제 데이터 소스에 접근하므로
/// SQLite 구현 세부 사항에 독립적이다.
final class DiaryRepositoryAdapter implements DiaryRepository {
  final DiaryDataSourcePort _dataSource;

  const DiaryRepositoryAdapter({required DiaryDataSourcePort dataSource})
    : _dataSource = dataSource;

  @override
  Future<DiaryEntry?> findByDate(DateTime date) async {
    final map = await _dataSource.queryByDate(toDateKey(date));
    if (map == null) return null;
    return DiaryEntryDto.fromMap(map).toDomain();
  }

  @override
  Future<List<DiaryEntry>> findByMonth(int year, int month) async {
    final rows = await _dataSource.queryByMonth(year, month);
    return rows.map((map) => DiaryEntryDto.fromMap(map).toDomain()).toList();
  }

  @override
  Future<void> save(DiaryEntry entry) async {
    final dto = DiaryEntryDto.fromDomain(entry);
    await _dataSource.insert(dto.toMap());
  }

  @override
  Future<void> update(DiaryEntry entry) async {
    final dto = DiaryEntryDto.fromDomain(entry);
    await _dataSource.update(dto.toMap());
  }
}
