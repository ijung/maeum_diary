import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maeum_diary/application/use_case/get_diary_by_date_use_case.dart';
import 'package:maeum_diary/application/use_case/get_monthly_diary_use_case.dart';
import 'package:maeum_diary/application/use_case/save_diary_use_case.dart';
import 'package:maeum_diary/domain/repository/diary_repository.dart';
import 'package:maeum_diary/infrastructure/datasource/diary_local_data_source.dart';
import 'package:maeum_diary/infrastructure/repository/diary_repository_impl.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────

final diaryLocalDataSourceProvider = Provider<DiaryLocalDataSource>(
    (_) => DiaryLocalDataSource.instance,
);

final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
    return DiaryRepositoryImpl(
        dataSource: ref.read(diaryLocalDataSourceProvider),
    );
});

// ─── Application ─────────────────────────────────────────────────────────────

final saveDiaryUseCaseProvider = Provider<SaveDiaryUseCase>((ref) {
    return SaveDiaryUseCase(
        repository: ref.read(diaryRepositoryProvider),
    );
});

final getDiaryByDateUseCaseProvider = Provider<GetDiaryByDateUseCase>((ref) {
    return GetDiaryByDateUseCase(
        repository: ref.read(diaryRepositoryProvider),
    );
});

final getMonthlyDiaryUseCaseProvider = Provider<GetMonthlyDiaryUseCase>((ref) {
    return GetMonthlyDiaryUseCase(
        repository: ref.read(diaryRepositoryProvider),
    );
});
