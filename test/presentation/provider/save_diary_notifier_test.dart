import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:maeum_diary/application/use_case/save_diary_use_case.dart';
import 'package:maeum_diary/core/di/providers.dart';
import 'package:maeum_diary/core/error/failures.dart';
import 'package:maeum_diary/domain/entity/diary_entry.dart';
import 'package:maeum_diary/domain/port/diary_repository.dart';
import 'package:maeum_diary/domain/value_object/activities_selection.dart';
import 'package:maeum_diary/domain/value_object/emotion.dart';
import 'package:maeum_diary/domain/value_object/emotions_selection.dart';
import 'package:maeum_diary/presentation/provider/calendar_provider.dart';
import 'package:maeum_diary/presentation/provider/diary_provider.dart';

class _MockDiaryRepository extends Mock implements DiaryRepository {}

void main() {
    late _MockDiaryRepository mockRepository;

    final input = SaveDiaryInput(
        date: DateTime(2024, 6, 15),
        emotions: EmotionsSelection([Emotion.happy]),
    );

    setUpAll(() {
        registerFallbackValue(
            SaveDiaryInput(
                date: DateTime(2024),
                emotions: EmotionsSelection([Emotion.calm]),
            ),
        );
        registerFallbackValue(
            DiaryEntry(
                id: 'fallback',
                date: DateTime(2024),
                emotions: EmotionsSelection([Emotion.calm]),
                activities: const ActivitiesSelection.empty(),
                createdAt: DateTime(2024),
                updatedAt: DateTime(2024),
            ),
        );
        registerFallbackValue(DateTime(2024));
    });

    setUp(() {
        mockRepository = _MockDiaryRepository();
    });

    ProviderContainer makeContainer({
        required SaveDiaryUseCase useCase,
    }) {
        return ProviderContainer(
            overrides: [
                saveDiaryUseCaseProvider.overrideWithValue(useCase),
            ],
        );
    }

    group('build()', () {
        test('초기 상태는 SaveDiaryIdle이다', () {
            final useCase = SaveDiaryUseCase(repository: mockRepository);
            final container = makeContainer(useCase: useCase);
            addTearDown(container.dispose);

            expect(
                container.read(saveDiaryProvider),
                isA<SaveDiaryIdle>(),
            );
        });
    });

    group('save() - 성공', () {
        test('저장 성공 시 상태가 SaveDiarySuccess로 전환된다', () async {
            when(() => mockRepository.findByDate(any())).thenAnswer((_) async => null);
            when(() => mockRepository.save(any())).thenAnswer((_) async {});
            final useCase = SaveDiaryUseCase(
                repository: mockRepository,
                nowFactory: () => DateTime(2024, 6, 15, 10),
            );
            final container = makeContainer(useCase: useCase);
            addTearDown(container.dispose);

            final result = await container.read(saveDiaryProvider.notifier).save(input);

            expect(result, isTrue);
            expect(
                container.read(saveDiaryProvider),
                isA<SaveDiarySuccess>(),
            );
        });

        test('저장 성공 시 monthlyDiaryProvider 캐시가 무효화된다', () async {
            when(() => mockRepository.findByDate(any())).thenAnswer((_) async => null);
            when(() => mockRepository.save(any())).thenAnswer((_) async {});
            final useCase = SaveDiaryUseCase(
                repository: mockRepository,
                nowFactory: () => DateTime(2024, 6, 15, 10),
            );
            final container = makeContainer(useCase: useCase);
            addTearDown(container.dispose);

            // monthlyDiaryProvider를 구독하여 캐시 무효화 감지
            var refreshCount = 0;
            container.listen(
                monthlyDiaryProvider,
                (_, __) => refreshCount++,
            );

            await container.read(saveDiaryProvider.notifier).save(input);

            // invalidate 호출 시 리스너가 실행된다
            expect(refreshCount, greaterThan(0));
        });
    });

    group('save() - 실패', () {
        test('날짜 검증 실패 시 상태가 SaveDiaryError로 전환된다', () async {
            // 먼 과거 날짜는 EditNotAllowedFailure 반환
            final pastInput = SaveDiaryInput(
                date: DateTime(2020, 1, 1),
                emotions: EmotionsSelection([Emotion.happy]),
            );
            final useCase = SaveDiaryUseCase(
                repository: mockRepository,
                nowFactory: () => DateTime(2024, 6, 15, 10),
            );
            final container = makeContainer(useCase: useCase);
            addTearDown(container.dispose);

            final result = await container.read(saveDiaryProvider.notifier).save(pastInput);

            expect(result, isFalse);
            final state = container.read(saveDiaryProvider);
            expect(state, isA<SaveDiaryError>());
            expect((state as SaveDiaryError).failure, isA<EditNotAllowedFailure>());
        });

        test('저장 실패 시 false를 반환한다', () async {
            when(() => mockRepository.findByDate(any())).thenAnswer((_) async => null);
            when(() => mockRepository.save(any())).thenThrow(Exception('DB 오류'));
            final useCase = SaveDiaryUseCase(
                repository: mockRepository,
                nowFactory: () => DateTime(2024, 6, 15, 10),
            );
            final container = makeContainer(useCase: useCase);
            addTearDown(container.dispose);

            expect(
                () => container.read(saveDiaryProvider.notifier).save(input),
                throwsException,
            );
        });
    });

    group('reset()', () {
        test('reset() 호출 시 상태가 SaveDiaryIdle로 복귀한다', () async {
            when(() => mockRepository.findByDate(any())).thenAnswer((_) async => null);
            when(() => mockRepository.save(any())).thenAnswer((_) async {});
            final useCase = SaveDiaryUseCase(
                repository: mockRepository,
                nowFactory: () => DateTime(2024, 6, 15, 10),
            );
            final container = makeContainer(useCase: useCase);
            addTearDown(container.dispose);

            await container.read(saveDiaryProvider.notifier).save(input);
            expect(container.read(saveDiaryProvider), isA<SaveDiarySuccess>());

            container.read(saveDiaryProvider.notifier).reset();

            expect(container.read(saveDiaryProvider), isA<SaveDiaryIdle>());
        });
    });
}
