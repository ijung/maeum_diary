import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:maeum_diary/domain/entity/diary_entry.dart';
import 'package:maeum_diary/domain/value_object/emotion.dart';
import 'package:maeum_diary/domain/value_object/emotions_selection.dart';
import 'package:maeum_diary/infrastructure/adapter/diary_repository_adapter.dart';
import 'package:maeum_diary/infrastructure/port/diary_data_source_port.dart';

class MockDataSource extends Mock implements DiaryDataSourcePort {}

void main() {
  late MockDataSource mockDataSource;
  late DiaryRepositoryAdapter adapter;

  final baseEntry = DiaryEntry(
    id: 'test-uuid',
    date: DateTime(2024, 6, 15),
    emotions: EmotionsSelection([Emotion.happy, Emotion.sad]),
    memo: '오늘 메모',
    createdAt: DateTime(2024, 6, 15, 10, 0),
    updatedAt: DateTime(2024, 6, 15, 11, 0),
  );

  // DB에 저장된 행 형태의 픽스처
  final baseMap = <String, dynamic>{
    'id': 'test-uuid',
    'date': '2024-06-15',
    'emotions': '["happy","sad"]',
    'memo': '오늘 메모',
    'created_at': '2024-06-15T10:00:00.000',
    'updated_at': '2024-06-15T11:00:00.000',
  };

  setUp(() {
    mockDataSource = MockDataSource();
    adapter = DiaryRepositoryAdapter(dataSource: mockDataSource);
  });

  // ─── findByDate ────────────────────────────────────────────────────────

  group('findByDate', () {
    test('데이터가 있으면 DiaryEntry로 변환해 반환한다', () async {
      when(
        () => mockDataSource.queryByDate('2024-06-15'),
      ).thenAnswer((_) async => baseMap);

      final result = await adapter.findByDate(DateTime(2024, 6, 15));

      expect(result, isNotNull);
      expect(result!.id, 'test-uuid');
      expect(result.memo, '오늘 메모');
      expect(result.emotions.values, [Emotion.happy, Emotion.sad]);
    });

    test('데이터가 없으면 null을 반환한다', () async {
      when(
        () => mockDataSource.queryByDate(any()),
      ).thenAnswer((_) async => null);

      final result = await adapter.findByDate(DateTime(2024, 6, 15));

      expect(result, isNull);
    });

    test('날짜를 yyyy-MM-dd 형식으로 변환해 DataSource에 전달한다', () async {
      when(
        () => mockDataSource.queryByDate(any()),
      ).thenAnswer((_) async => null);

      await adapter.findByDate(DateTime(2024, 1, 5, 23, 59));

      verify(() => mockDataSource.queryByDate('2024-01-05')).called(1);
    });

    test('월·일이 한 자리일 때 0으로 채워 전달한다', () async {
      when(
        () => mockDataSource.queryByDate(any()),
      ).thenAnswer((_) async => null);

      await adapter.findByDate(DateTime(2024, 3, 7));

      verify(() => mockDataSource.queryByDate('2024-03-07')).called(1);
    });

    test('시각 정보가 포함된 DateTime도 날짜 부분만 사용한다', () async {
      when(
        () => mockDataSource.queryByDate(any()),
      ).thenAnswer((_) async => null);

      await adapter.findByDate(DateTime(2024, 6, 15, 23, 59, 59));

      verify(() => mockDataSource.queryByDate('2024-06-15')).called(1);
    });
  });

  // ─── findByMonth ───────────────────────────────────────────────────────

  group('findByMonth', () {
    test('여러 행을 DiaryEntry 목록으로 변환한다', () async {
      final secondMap = <String, dynamic>{
        'id': 'uuid-2',
        'date': '2024-06-20',
        'emotions': '["sad"]',
        'memo': null,
        'created_at': '2024-06-20T09:00:00.000',
        'updated_at': '2024-06-20T09:00:00.000',
      };
      when(
        () => mockDataSource.queryByMonth(2024, 6),
      ).thenAnswer((_) async => [baseMap, secondMap]);

      final result = await adapter.findByMonth(2024, 6);

      expect(result.length, 2);
      expect(result[0].id, 'test-uuid');
      expect(result[1].id, 'uuid-2');
    });

    test('해당 월에 데이터가 없으면 빈 목록을 반환한다', () async {
      when(
        () => mockDataSource.queryByMonth(any(), any()),
      ).thenAnswer((_) async => []);

      final result = await adapter.findByMonth(2024, 6);

      expect(result, isEmpty);
    });

    test('year·month를 그대로 DataSource에 전달한다', () async {
      when(
        () => mockDataSource.queryByMonth(any(), any()),
      ).thenAnswer((_) async => []);

      await adapter.findByMonth(2024, 11);

      verify(() => mockDataSource.queryByMonth(2024, 11)).called(1);
    });
  });

  // ─── save ──────────────────────────────────────────────────────────────

  group('save', () {
    test('DiaryEntry를 Map으로 변환해 DataSource에 insert한다', () async {
      when(() => mockDataSource.insert(any())).thenAnswer((_) async {});

      await adapter.save(baseEntry);

      final captured = verify(
        () => mockDataSource.insert(captureAny()),
      ).captured;
      final map = captured.first as Map<String, dynamic>;
      expect(map['id'], 'test-uuid');
      expect(map['date'], '2024-06-15');
      expect(map['memo'], '오늘 메모');
    });

    test('memo가 null인 엔티티를 저장하면 map의 memo도 null이다', () async {
      when(() => mockDataSource.insert(any())).thenAnswer((_) async {});
      final entryNoMemo = DiaryEntry(
        id: 'no-memo-id',
        date: DateTime(2024, 6, 15),
        emotions: EmotionsSelection([Emotion.happy]),
        createdAt: DateTime(2024, 6, 15, 10, 0),
        updatedAt: DateTime(2024, 6, 15, 10, 0),
      );

      await adapter.save(entryNoMemo);

      final captured = verify(
        () => mockDataSource.insert(captureAny()),
      ).captured;
      final map = captured.first as Map<String, dynamic>;
      expect(map['memo'], isNull);
    });
  });

  // ─── update ────────────────────────────────────────────────────────────

  group('update', () {
    test('DiaryEntry를 Map으로 변환해 DataSource에 update한다', () async {
      when(() => mockDataSource.update(any())).thenAnswer((_) async {});

      await adapter.update(baseEntry);

      final captured = verify(
        () => mockDataSource.update(captureAny()),
      ).captured;
      final map = captured.first as Map<String, dynamic>;
      expect(map['id'], 'test-uuid');
      expect(map['date'], '2024-06-15');
    });

    test('변경된 감정 목록이 올바르게 직렬화되어 전달된다', () async {
      when(() => mockDataSource.update(any())).thenAnswer((_) async {});
      final updatedEntry = baseEntry.copyWith(
        emotions: EmotionsSelection([Emotion.angry]),
      );

      await adapter.update(updatedEntry);

      final captured = verify(
        () => mockDataSource.update(captureAny()),
      ).captured;
      final map = captured.first as Map<String, dynamic>;
      expect(map['emotions'], '["angry"]');
    });
  });
}
