import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:maeum_diary/application/use_case/get_diary_by_date_use_case.dart';
import 'package:maeum_diary/domain/entity/diary_entry.dart';
import 'package:maeum_diary/domain/port/diary_repository.dart';
import 'package:maeum_diary/domain/value_object/emotion.dart';
import 'package:maeum_diary/domain/value_object/emotions_selection.dart';

class MockDiaryRepository extends Mock implements DiaryRepository {}

void main() {
  late MockDiaryRepository mockRepository;
  late GetDiaryByDateUseCase useCase;

  final targetDate = DateTime(2024, 6, 15);
  final now = DateTime(2024, 6, 15, 12, 0);

  setUp(() {
    mockRepository = MockDiaryRepository();
    useCase = GetDiaryByDateUseCase(repository: mockRepository);
  });

  test('해당 날짜 일기가 있으면 DiaryEntry를 반환한다', () async {
    final entry = DiaryEntry(
      id: 'test-id',
      date: targetDate,
      emotions: EmotionsSelection([Emotion.happy]),
      createdAt: now,
      updatedAt: now,
    );
    when(
      () => mockRepository.findByDate(targetDate),
    ).thenAnswer((_) async => entry);

    final result = await useCase.execute(targetDate);

    expect(result, isNotNull);
    expect(result!.id, 'test-id');
  });

  test('해당 날짜 일기가 없으면 null을 반환한다', () async {
    when(
      () => mockRepository.findByDate(targetDate),
    ).thenAnswer((_) async => null);

    final result = await useCase.execute(targetDate);

    expect(result, isNull);
  });
}
