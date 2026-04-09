import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maeum_diary/application/use_case/get_diary_by_date_use_case.dart';
import 'package:maeum_diary/application/use_case/get_monthly_diary_use_case.dart';
import 'package:maeum_diary/application/use_case/save_diary_use_case.dart';
import 'package:maeum_diary/domain/port/diary_repository.dart';
import 'package:maeum_diary/infrastructure/adapter/diary_repository_adapter.dart';
import 'package:maeum_diary/infrastructure/datasource/diary_local_data_source.dart';
import 'package:maeum_diary/infrastructure/port/diary_data_source_port.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────

final diaryLocalDataSourceProvider = Provider<DiaryDataSourcePort>(
  (_) => DiaryLocalDataSource.instance,
);

final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepositoryAdapter(
    dataSource: ref.read(diaryLocalDataSourceProvider),
  );
});

// ─── Application ─────────────────────────────────────────────────────────────

final saveDiaryUseCaseProvider = Provider<SaveDiaryUseCase>((ref) {
  return SaveDiaryUseCase(repository: ref.read(diaryRepositoryProvider));
});

final getDiaryByDateUseCaseProvider = Provider<GetDiaryByDateUseCase>((ref) {
  return GetDiaryByDateUseCase(repository: ref.read(diaryRepositoryProvider));
});

final getMonthlyDiaryUseCaseProvider = Provider<GetMonthlyDiaryUseCase>((ref) {
  return GetMonthlyDiaryUseCase(repository: ref.read(diaryRepositoryProvider));
});
