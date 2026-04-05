import 'package:maeum_diary/core/utils/date_utils.dart';
import 'package:maeum_diary/domain/entity/diary_entry.dart';
import 'package:maeum_diary/domain/repository/diary_repository.dart';
import 'package:maeum_diary/infrastructure/datasource/diary_local_data_source.dart';
import 'package:maeum_diary/infrastructure/dto/diary_entry_dto.dart';

/// [DiaryRepository] 포트의 SQLite 어댑터 구현체
final class DiaryRepositoryImpl implements DiaryRepository {
    final DiaryLocalDataSource _dataSource;

    const DiaryRepositoryImpl({required DiaryLocalDataSource dataSource})
        : _dataSource = dataSource;

    @override
    Future<DiaryEntry?> findByDate(DateTime date) async {
        final dateStr = _formatDate(date);
        final map = await _dataSource.queryByDate(dateStr);
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

    /// [DateTime]을 'yyyy-MM-dd' 형식으로 변환한다.
    String _formatDate(DateTime dt) {
        final local = toLocalDate(dt);
        final y = local.year.toString().padLeft(4, '0');
        final m = local.month.toString().padLeft(2, '0');
        final d = local.day.toString().padLeft(2, '0');
        return '$y-$m-$d';
    }
}
