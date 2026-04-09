import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_diary/domain/entity/diary_entry.dart';
import 'package:maeum_diary/domain/value_object/activities_selection.dart';
import 'package:maeum_diary/domain/value_object/activity.dart';
import 'package:maeum_diary/domain/value_object/emotion.dart';
import 'package:maeum_diary/domain/value_object/emotions_selection.dart';
import 'package:maeum_diary/infrastructure/dto/diary_entry_dto.dart';

void main() {
  // 테스트 픽스처
  final baseMap = <String, dynamic>{
    'id': 'test-uuid',
    'date': '2024-06-15',
    'emotions': '["happy","sad"]',
    'activities': '[]',
    'memo': '오늘 메모',
    'created_at': '2024-06-15T10:00:00.000',
    'updated_at': '2024-06-15T11:00:00.000',
  };

  final baseEntity = DiaryEntry(
    id: 'test-uuid',
    date: DateTime(2024, 6, 15),
    emotions: EmotionsSelection([Emotion.happy, Emotion.sad]),
    memo: '오늘 메모',
    createdAt: DateTime(2024, 6, 15, 10, 0),
    updatedAt: DateTime(2024, 6, 15, 11, 0),
  );

  group('fromMap', () {
    test('정상 Map에서 DTO를 생성한다', () {
      final dto = DiaryEntryDto.fromMap(baseMap);

      expect(dto.id, 'test-uuid');
      expect(dto.date, '2024-06-15');
      expect(dto.emotions, '["happy","sad"]');
      expect(dto.activities, '[]');
      expect(dto.memo, '오늘 메모');
      expect(dto.createdAt, '2024-06-15T10:00:00.000');
      expect(dto.updatedAt, '2024-06-15T11:00:00.000');
    });

    test('activities 컬럼이 없으면 빈 JSON 배열([])을 기본값으로 사용한다', () {
      final mapWithoutActivities = Map<String, dynamic>.from(baseMap)
        ..remove('activities');

      final dto = DiaryEntryDto.fromMap(mapWithoutActivities);

      expect(dto.activities, '[]');
    });

    test('memo가 null이면 DTO의 memo도 null이다', () {
      final map = Map<String, dynamic>.from(baseMap)..['memo'] = null;

      final dto = DiaryEntryDto.fromMap(map);

      expect(dto.memo, isNull);
    });

    test('Android SQLite 버그: TEXT 컬럼이 int로 반환돼도 String으로 변환한다', () {
      // sqflite가 Android에서 숫자처럼 보이는 TEXT 값을 int로 반환하는 경우
      final mapWithIntId = Map<String, dynamic>.from(baseMap)
        ..['id'] = 12345; // int로 잘못 반환된 id

      final dto = DiaryEntryDto.fromMap(mapWithIntId);

      expect(dto.id, '12345');
      expect(dto.id, isA<String>());
    });

    test('emotions가 빈 문자열이면 빈 JSON 배열([])을 기본값으로 사용한다', () {
      final map = Map<String, dynamic>.from(baseMap)..['emotions'] = '';

      final dto = DiaryEntryDto.fromMap(map);

      expect(dto.emotions, '[]');
    });
  });

  group('toMap', () {
    test('DTO를 DB Map으로 직렬화한다', () {
      final dto = DiaryEntryDto.fromMap(baseMap);

      final map = dto.toMap();

      expect(map['id'], 'test-uuid');
      expect(map['date'], '2024-06-15');
      expect(map['emotions'], '["happy","sad"]');
      expect(map['activities'], '[]');
      expect(map['memo'], '오늘 메모');
      expect(map['created_at'], '2024-06-15T10:00:00.000');
      expect(map['updated_at'], '2024-06-15T11:00:00.000');
    });

    test('memo가 null이면 Map의 memo도 null이다', () {
      final map = Map<String, dynamic>.from(baseMap)..['memo'] = null;
      final dto = DiaryEntryDto.fromMap(map);

      final result = dto.toMap();

      expect(result['memo'], isNull);
    });

    test('fromMap → toMap 왕복 변환 시 원본 Map과 동일하다', () {
      final dto = DiaryEntryDto.fromMap(baseMap);

      final result = dto.toMap();

      expect(result, baseMap);
    });
  });

  group('fromDomain', () {
    test('DiaryEntry 엔티티를 DTO로 변환한다', () {
      final dto = DiaryEntryDto.fromDomain(baseEntity);

      expect(dto.id, baseEntity.id);
      expect(dto.date, '2024-06-15');
      expect(dto.memo, baseEntity.memo);
    });

    test('감정 목록을 JSON 배열로 직렬화한다', () {
      final dto = DiaryEntryDto.fromDomain(baseEntity);

      final decoded = jsonDecode(dto.emotions) as List;
      expect(decoded, ['happy', 'sad']);
    });

    test('활동 목록을 JSON 배열로 직렬화한다', () {
      final entryWithActivities = DiaryEntry(
        id: 'activity-uuid',
        date: DateTime(2024, 6, 15),
        emotions: EmotionsSelection([Emotion.happy]),
        activities: ActivitiesSelection([Activity.study, Activity.exercise]),
        createdAt: DateTime(2024, 6, 15, 10, 0),
        updatedAt: DateTime(2024, 6, 15, 10, 0),
      );

      final dto = DiaryEntryDto.fromDomain(entryWithActivities);
      final decoded = jsonDecode(dto.activities) as List;

      expect(decoded, ['study', 'exercise']);
    });

    test('활동이 없으면 빈 JSON 배열로 직렬화한다', () {
      final dto = DiaryEntryDto.fromDomain(baseEntity);
      final decoded = jsonDecode(dto.activities) as List;

      expect(decoded, isEmpty);
    });

    test('memo가 null인 엔티티를 변환하면 DTO의 memo도 null이다', () {
      final entityNoMemo = DiaryEntry(
        id: 'no-memo-id',
        date: DateTime(2024, 6, 15),
        emotions: EmotionsSelection([Emotion.happy]),
        createdAt: DateTime(2024, 6, 15, 10, 0),
        updatedAt: DateTime(2024, 6, 15, 10, 0),
      );

      final dto = DiaryEntryDto.fromDomain(entityNoMemo);

      expect(dto.memo, isNull);
    });

    test('감정 1개인 엔티티도 올바르게 변환한다', () {
      final singleEmotionEntry = DiaryEntry(
        id: 'single-id',
        date: DateTime(2024, 6, 15),
        emotions: EmotionsSelection([Emotion.happy]),
        createdAt: DateTime(2024, 6, 15, 10, 0),
        updatedAt: DateTime(2024, 6, 15, 10, 0),
      );

      final dto = DiaryEntryDto.fromDomain(singleEmotionEntry);
      final decoded = jsonDecode(dto.emotions) as List;

      expect(decoded, ['happy']);
    });
  });

  group('toDomain', () {
    test('DTO를 DiaryEntry 엔티티로 변환한다', () {
      final dto = DiaryEntryDto.fromMap(baseMap);

      final entry = dto.toDomain();

      expect(entry.id, 'test-uuid');
      expect(entry.date, DateTime(2024, 6, 15));
      expect(entry.memo, '오늘 메모');
    });

    test('JSON 배열의 감정 목록을 EmotionsSelection으로 역직렬화한다', () {
      final dto = DiaryEntryDto.fromMap(baseMap);

      final entry = dto.toDomain();

      expect(entry.emotions.values, [Emotion.happy, Emotion.sad]);
    });

    test('JSON 배열의 활동 목록을 ActivitiesSelection으로 역직렬화한다', () {
      final mapWithActivities = Map<String, dynamic>.from(baseMap)
        ..['activities'] = '["study","exercise"]';
      final dto = DiaryEntryDto.fromMap(mapWithActivities);

      final entry = dto.toDomain();

      expect(entry.activities.values, [Activity.study, Activity.exercise]);
    });

    test('활동 목록이 빈 배열이면 ActivitiesSelection이 비어있다', () {
      final dto = DiaryEntryDto.fromMap(baseMap);

      final entry = dto.toDomain();

      expect(entry.activities.isEmpty, isTrue);
    });

    test('memo가 null인 DTO를 변환하면 엔티티의 memo도 null이다', () {
      final map = Map<String, dynamic>.from(baseMap)..['memo'] = null;
      final dto = DiaryEntryDto.fromMap(map);

      final entry = dto.toDomain();

      expect(entry.memo, isNull);
    });
  });

  group('엔티티 → DTO → 엔티티 왕복 변환', () {
    test('변환 후 핵심 필드가 원본과 동일하다', () {
      final dto = DiaryEntryDto.fromDomain(baseEntity);
      final restored = dto.toDomain();

      expect(restored.id, baseEntity.id);
      expect(restored.date, baseEntity.date);
      expect(restored.emotions, baseEntity.emotions);
      expect(restored.activities, baseEntity.activities);
      expect(restored.memo, baseEntity.memo);
    });

    test('활동 목록이 있어도 왕복 변환이 정확하다', () {
      final entryWithActivities = DiaryEntry(
        id: 'activity-id',
        date: DateTime(2024, 6, 15),
        emotions: EmotionsSelection([Emotion.happy]),
        activities: ActivitiesSelection([Activity.study, Activity.date]),
        createdAt: DateTime(2024, 6, 15, 10, 0),
        updatedAt: DateTime(2024, 6, 15, 10, 0),
      );

      final restored = DiaryEntryDto.fromDomain(entryWithActivities).toDomain();

      expect(restored.activities.values, [Activity.study, Activity.date]);
    });

    test('memo가 null인 경우에도 왕복 변환이 정확하다', () {
      final entityNoMemo = DiaryEntry(
        id: 'no-memo-id',
        date: DateTime(2024, 6, 15),
        emotions: EmotionsSelection([Emotion.happy]),
        createdAt: DateTime(2024, 6, 15, 10, 0),
        updatedAt: DateTime(2024, 6, 15, 10, 0),
      );

      final restored = DiaryEntryDto.fromDomain(entityNoMemo).toDomain();

      expect(restored.id, entityNoMemo.id);
      expect(restored.memo, isNull);
    });

    test('감정 3개도 왕복 변환이 정확하다', () {
      final entry3 = DiaryEntry(
        id: '3-emotions-id',
        date: DateTime(2024, 6, 15),
        emotions: EmotionsSelection([
          Emotion.happy,
          Emotion.sad,
          Emotion.angry,
        ]),
        createdAt: DateTime(2024, 6, 15, 10, 0),
        updatedAt: DateTime(2024, 6, 15, 10, 0),
      );

      final restored = DiaryEntryDto.fromDomain(entry3).toDomain();

      expect(restored.emotions.values, [
        Emotion.happy,
        Emotion.sad,
        Emotion.angry,
      ]);
    });
  });
}
