import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_diary/domain/entity/diary_entry.dart';
import 'package:maeum_diary/domain/value_object/emotion.dart';
import 'package:maeum_diary/domain/value_object/emotions_selection.dart';

void main() {
  final baseDate = DateTime(2024, 6, 15);
  final baseCreatedAt = DateTime(2024, 6, 15, 10, 0);
  final baseUpdatedAt = DateTime(2024, 6, 15, 10, 0);
  final baseEmotions = EmotionsSelection([Emotion.happy]);

  DiaryEntry makeEntry({
    String id = 'test-id',
    String? memo,
    EmotionsSelection? emotions,
  }) {
    return DiaryEntry(
      id: id,
      date: baseDate,
      emotions: emotions ?? baseEmotions,
      memo: memo,
      createdAt: baseCreatedAt,
      updatedAt: baseUpdatedAt,
    );
  }

  group('copyWith', () {
    test('emotions를 교체한 새 엔티티를 반환한다', () {
      final entry = makeEntry();
      final newEmotions = EmotionsSelection([Emotion.sad]);

      final updated = entry.copyWith(emotions: newEmotions);

      expect(updated.emotions, newEmotions);
      expect(updated.id, entry.id);
      expect(updated.date, entry.date);
      expect(updated.memo, entry.memo);
      expect(updated.createdAt, entry.createdAt);
    });

    test('memo를 교체한 새 엔티티를 반환한다', () {
      final entry = makeEntry(memo: '기존 메모');

      final updated = entry.copyWith(memo: '새 메모');

      expect(updated.memo, '새 메모');
      expect(updated.emotions, entry.emotions);
    });

    test('updatedAt을 교체한 새 엔티티를 반환한다', () {
      final entry = makeEntry();
      final newUpdatedAt = DateTime(2024, 6, 15, 12, 0);

      final updated = entry.copyWith(updatedAt: newUpdatedAt);

      expect(updated.updatedAt, newUpdatedAt);
      expect(updated.createdAt, entry.createdAt);
    });

    test('clearMemo: true이면 memo가 null이 된다', () {
      final entry = makeEntry(memo: '지울 메모');

      final updated = entry.copyWith(clearMemo: true);

      expect(updated.memo, isNull);
    });

    test('clearMemo: true이면 memo 인자가 있어도 null이 된다', () {
      // clearMemo가 memo 인자보다 우선한다
      final entry = makeEntry(memo: '기존 메모');

      final updated = entry.copyWith(memo: '새 메모', clearMemo: true);

      expect(updated.memo, isNull);
    });

    test('인자를 전달하지 않으면 기존 값을 유지한다', () {
      final entry = makeEntry(memo: '메모');

      final updated = entry.copyWith();

      expect(updated.id, entry.id);
      expect(updated.date, entry.date);
      expect(updated.emotions, entry.emotions);
      expect(updated.memo, entry.memo);
      expect(updated.createdAt, entry.createdAt);
      expect(updated.updatedAt, entry.updatedAt);
    });

    test('copyWith은 항상 새 객체를 반환한다', () {
      final entry = makeEntry();

      final updated = entry.copyWith();

      expect(identical(updated, entry), isFalse);
    });

    test('copyWith 후에도 id는 변경되지 않는다', () {
      final entry = makeEntry(id: 'original-id');

      final updated = entry.copyWith(
        emotions: EmotionsSelection([Emotion.sad]),
        memo: '변경',
      );

      expect(updated.id, 'original-id');
    });
  });

  group('동등성 (==)', () {
    test('같은 id면 동등하다', () {
      final a = makeEntry(id: 'same-id');
      final b = makeEntry(id: 'same-id');

      expect(a, equals(b));
    });

    test('다른 id면 동등하지 않다', () {
      final a = makeEntry(id: 'id-a');
      final b = makeEntry(id: 'id-b');

      expect(a, isNot(equals(b)));
    });

    test('id가 같으면 감정·메모가 달라도 동등하다', () {
      final a = DiaryEntry(
        id: 'same-id',
        date: baseDate,
        emotions: EmotionsSelection([Emotion.happy]),
        memo: '메모 A',
        createdAt: baseCreatedAt,
        updatedAt: baseUpdatedAt,
      );
      final b = DiaryEntry(
        id: 'same-id',
        date: baseDate,
        emotions: EmotionsSelection([Emotion.sad]),
        memo: '메모 B',
        createdAt: baseCreatedAt,
        updatedAt: baseUpdatedAt,
      );

      expect(a, equals(b));
    });

    test('자기 자신과 동등하다', () {
      final entry = makeEntry();

      expect(entry, equals(entry));
    });
  });

  group('hashCode', () {
    test('같은 id면 hashCode가 같다', () {
      final a = makeEntry(id: 'same-id');
      final b = makeEntry(id: 'same-id');

      expect(a.hashCode, b.hashCode);
    });

    test('다른 id면 hashCode가 다르다', () {
      final a = makeEntry(id: 'id-a');
      final b = makeEntry(id: 'id-b');

      // 충돌 가능성은 이론적으로 존재하지만 단순 문자열의 경우 실제론 다르다
      expect(a.hashCode, isNot(b.hashCode));
    });
  });
}
