import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:maeum_diary/application/use_case/save_diary_use_case.dart';
import 'package:maeum_diary/core/error/failures.dart';
import 'package:maeum_diary/domain/entity/diary_entry.dart';
import 'package:maeum_diary/domain/port/diary_repository.dart';
import 'package:maeum_diary/domain/value_object/emotion.dart';
import 'package:maeum_diary/domain/value_object/emotions_selection.dart';

class MockDiaryRepository extends Mock implements DiaryRepository {}

void main() {
    setUpAll(() {
        // mocktail이 DiaryEntry 타입 인자를 any()로 매칭할 수 있도록 폴백 값 등록
        registerFallbackValue(DiaryEntry(
            id: 'fallback',
            date: DateTime(2024),
            emotions: EmotionsSelection([Emotion.happy]),
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
        ));
    });

    late MockDiaryRepository mockRepository;
    late SaveDiaryUseCase useCase;

    // 현재 시각 고정: 2024-06-15 12:00:00 (15시 이전)
    final fixedNow = DateTime(2024, 6, 15, 12, 0);
    final today = DateTime(2024, 6, 15);
    final yesterday = DateTime(2024, 6, 14);
    final twoDaysAgo = DateTime(2024, 6, 13);

    final sampleEmotions = EmotionsSelection([Emotion.happy]);

    setUp(() {
        mockRepository = MockDiaryRepository();
        useCase = SaveDiaryUseCase(
            repository: mockRepository,
            nowFactory: () => fixedNow,
        );

        // 기본적으로 save/update는 성공한다
        when(() => mockRepository.save(any())).thenAnswer((_) async {});
        when(() => mockRepository.update(any())).thenAnswer((_) async {});
    });

    group('날짜 검증', () {
        test('오늘 날짜면 저장에 성공한다', () async {
            when(() => mockRepository.findByDate(any())).thenAnswer((_) async => null);

            final failure = await useCase.execute(
                SaveDiaryInput(date: today, emotions: sampleEmotions),
            );

            expect(failure, isNull);
            verify(() => mockRepository.save(any())).called(1);
        });

        test('어제 날짜면 저장에 성공한다', () async {
            when(() => mockRepository.findByDate(any())).thenAnswer((_) async => null);

            final failure = await useCase.execute(
                SaveDiaryInput(date: yesterday, emotions: sampleEmotions),
            );

            expect(failure, isNull);
            verify(() => mockRepository.save(any())).called(1);
        });

        test('이틀 전 날짜면 EditNotAllowedFailure를 반환한다', () async {
            final failure = await useCase.execute(
                SaveDiaryInput(date: twoDaysAgo, emotions: sampleEmotions),
            );

            expect(failure, isA<EditNotAllowedFailure>());
            verifyNever(() => mockRepository.findByDate(any()));
            verifyNever(() => mockRepository.save(any()));
        });

        test('미래 날짜면 EditNotAllowedFailure를 반환한다', () async {
            final future = DateTime(2024, 6, 16);

            final failure = await useCase.execute(
                SaveDiaryInput(date: future, emotions: sampleEmotions),
            );

            expect(failure, isA<EditNotAllowedFailure>());
        });

        test('어제 날짜이지만 오늘 15시 이후면 EditNotAllowedFailure를 반환한다', () async {
            final useCaseAfter15 = SaveDiaryUseCase(
                repository: mockRepository,
                nowFactory: () => DateTime(2024, 6, 15, 15, 0),
            );

            final failure = await useCaseAfter15.execute(
                SaveDiaryInput(date: yesterday, emotions: sampleEmotions),
            );

            expect(failure, isA<EditNotAllowedFailure>());
            verifyNever(() => mockRepository.save(any()));
        });

        test('어제 날짜이고 오늘 14시 59분이면 저장에 성공한다', () async {
            final useCaseBefore15 = SaveDiaryUseCase(
                repository: mockRepository,
                nowFactory: () => DateTime(2024, 6, 15, 14, 59),
            );
            when(() => mockRepository.findByDate(any())).thenAnswer((_) async => null);

            final failure = await useCaseBefore15.execute(
                SaveDiaryInput(date: yesterday, emotions: sampleEmotions),
            );

            expect(failure, isNull);
            verify(() => mockRepository.save(any())).called(1);
        });
    });

    group('메모 검증', () {
        test('500자 메모는 저장에 성공한다', () async {
            when(() => mockRepository.findByDate(any())).thenAnswer((_) async => null);
            final memo500 = 'a' * 500;

            final failure = await useCase.execute(
                SaveDiaryInput(date: today, emotions: sampleEmotions, memo: memo500),
            );

            expect(failure, isNull);
        });

        test('501자 메모는 MemoTooLongFailure를 반환한다', () async {
            final memo501 = 'a' * 501;

            final failure = await useCase.execute(
                SaveDiaryInput(date: today, emotions: sampleEmotions, memo: memo501),
            );

            expect(failure, isA<MemoTooLongFailure>());
            verifyNever(() => mockRepository.save(any()));
        });

        test('공백만 있는 메모는 null로 저장된다', () async {
            when(() => mockRepository.findByDate(any())).thenAnswer((_) async => null);

            await useCase.execute(
                SaveDiaryInput(date: today, emotions: sampleEmotions, memo: '   '),
            );

            final captured = verify(() => mockRepository.save(captureAny())).captured;
            final savedEntry = captured.first as DiaryEntry;
            expect(savedEntry.memo, isNull);
        });

        test('null 메모는 그대로 null로 저장된다', () async {
            when(() => mockRepository.findByDate(any())).thenAnswer((_) async => null);

            await useCase.execute(
                SaveDiaryInput(date: today, emotions: sampleEmotions),
            );

            final captured = verify(() => mockRepository.save(captureAny())).captured;
            final savedEntry = captured.first as DiaryEntry;
            expect(savedEntry.memo, isNull);
        });
    });

    group('신규 저장 vs 수정', () {
        test('해당 날짜 일기가 없으면 save를 호출한다', () async {
            when(() => mockRepository.findByDate(any())).thenAnswer((_) async => null);

            await useCase.execute(
                SaveDiaryInput(date: today, emotions: sampleEmotions),
            );

            verify(() => mockRepository.save(any())).called(1);
            verifyNever(() => mockRepository.update(any()));
        });

        test('해당 날짜 일기가 있으면 update를 호출한다', () async {
            final existing = DiaryEntry(
                id: 'existing-id',
                date: today,
                emotions: EmotionsSelection([Emotion.sad]),
                createdAt: fixedNow,
                updatedAt: fixedNow,
            );
            when(() => mockRepository.findByDate(any()))
                .thenAnswer((_) async => existing);

            await useCase.execute(
                SaveDiaryInput(date: today, emotions: sampleEmotions),
            );

            verifyNever(() => mockRepository.save(any()));
            verify(() => mockRepository.update(any())).called(1);
        });

        test('update 시 id는 기존 값을 유지한다', () async {
            final existing = DiaryEntry(
                id: 'original-id',
                date: today,
                emotions: EmotionsSelection([Emotion.sad]),
                createdAt: fixedNow,
                updatedAt: fixedNow,
            );
            when(() => mockRepository.findByDate(any()))
                .thenAnswer((_) async => existing);

            await useCase.execute(
                SaveDiaryInput(date: today, emotions: sampleEmotions),
            );

            final captured = verify(() => mockRepository.update(captureAny())).captured;
            final updatedEntry = captured.first as DiaryEntry;
            expect(updatedEntry.id, 'original-id');
        });
    });
}
