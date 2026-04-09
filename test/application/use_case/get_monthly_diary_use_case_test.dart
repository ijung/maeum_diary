import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:maeum_diary/application/use_case/get_monthly_diary_use_case.dart';
import 'package:maeum_diary/domain/entity/diary_entry.dart';
import 'package:maeum_diary/domain/port/diary_repository.dart';
import 'package:maeum_diary/domain/value_object/emotion.dart';
import 'package:maeum_diary/domain/value_object/emotions_selection.dart';

class MockDiaryRepository extends Mock implements DiaryRepository {}

void main() {
  late MockDiaryRepository mockRepository;
  late GetMonthlyDiaryUseCase useCase;

  final now = DateTime(2024, 6, 15, 12, 0);

  setUp(() {
    mockRepository = MockDiaryRepository();
    useCase = GetMonthlyDiaryUseCase(repository: mockRepository);
  });

  test('해당 월의 일기 목록을 반환한다', () async {
    final entries = [
      DiaryEntry(
        id: 'id-1',
        date: DateTime(2024, 6, 1),
        emotions: EmotionsSelection([Emotion.happy]),
        createdAt: now,
        updatedAt: now,
      ),
      DiaryEntry(
        id: 'id-2',
        date: DateTime(2024, 6, 10),
        emotions: EmotionsSelection([Emotion.sad, Emotion.tired]),
        createdAt: now,
        updatedAt: now,
      ),
    ];
    when(
      () => mockRepository.findByMonth(2024, 6),
    ).thenAnswer((_) async => entries);

    final result = await useCase.execute(2024, 6);

    expect(result.length, 2);
    expect(result.first.id, 'id-1');
    expect(result.last.id, 'id-2');
  });

  test('해당 월에 일기가 없으면 빈 목록을 반환한다', () async {
    when(() => mockRepository.findByMonth(2024, 1)).thenAnswer((_) async => []);

    final result = await useCase.execute(2024, 1);

    expect(result, isEmpty);
  });
}
