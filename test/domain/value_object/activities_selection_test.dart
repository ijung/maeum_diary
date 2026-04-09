import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_diary/domain/value_object/activities_selection.dart';
import 'package:maeum_diary/domain/value_object/activity.dart';

void main() {
  group('ActivitiesSelection 생성', () {
    test('빈 목록으로 생성할 수 있다', () {
      final sel = ActivitiesSelection([]);
      expect(sel.values, isEmpty);
    });

    test('ActivitiesSelection.empty()로 생성할 수 있다', () {
      const sel = ActivitiesSelection.empty();
      expect(sel.values, isEmpty);
      expect(sel.isEmpty, isTrue);
    });

    test('활동 1개로 생성할 수 있다', () {
      final sel = ActivitiesSelection([Activity.study]);
      expect(sel.values, [Activity.study]);
    });

    test('활동 5개로 생성할 수 있다', () {
      final sel = ActivitiesSelection([
        Activity.study,
        Activity.exercise,
        Activity.date,
        Activity.movie,
        Activity.gaming,
      ]);
      expect(sel.values.length, 5);
    });

    test('6개 이상으로 생성하면 ArgumentError를 던진다', () {
      expect(
        () => ActivitiesSelection([
          Activity.study,
          Activity.exercise,
          Activity.date,
          Activity.movie,
          Activity.gaming,
          Activity.cooking,
        ]),
        throwsArgumentError,
      );
    });

    test('중복된 활동으로 생성하면 ArgumentError를 던진다', () {
      expect(
        () => ActivitiesSelection([Activity.study, Activity.study]),
        throwsArgumentError,
      );
    });
  });

  group('isEmpty', () {
    test('빈 선택은 isEmpty가 true이다', () {
      expect(ActivitiesSelection([]).isEmpty, isTrue);
    });

    test('항목이 있으면 isEmpty가 false이다', () {
      expect(ActivitiesSelection([Activity.study]).isEmpty, isFalse);
    });
  });

  group('maxCount', () {
    test('maxCount는 5이다', () {
      expect(ActivitiesSelection.maxCount, 5);
    });
  });

  group('동등성', () {
    test('같은 내용의 선택은 동등하다', () {
      final a = ActivitiesSelection([Activity.study, Activity.exercise]);
      final b = ActivitiesSelection([Activity.study, Activity.exercise]);
      expect(a, equals(b));
    });

    test('내용이 다르면 동등하지 않다', () {
      final a = ActivitiesSelection([Activity.study]);
      final b = ActivitiesSelection([Activity.exercise]);
      expect(a, isNot(equals(b)));
    });
  });
}
