import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_diary/core/utils/date_utils.dart';

void main() {
    group('toLocalDate', () {
        test('시각 정보를 제거하고 날짜만 반환한다', () {
            final dt = DateTime(2024, 6, 15, 23, 59, 59);
            final result = toLocalDate(dt);
            expect(result, DateTime(2024, 6, 15));
        });

        test('이미 00:00:00인 경우 동일한 값을 반환한다', () {
            final dt = DateTime(2024, 1, 1);
            final result = toLocalDate(dt);
            expect(result, DateTime(2024, 1, 1));
        });
    });

    group('isEditableDate', () {
        final now = DateTime(2024, 6, 15, 12, 0, 0);

        test('오늘 날짜는 수정 가능하다', () {
            expect(isEditableDate(DateTime(2024, 6, 15), now: now), isTrue);
        });

        test('오늘 날짜 (시각 포함)도 수정 가능하다', () {
            expect(
                isEditableDate(DateTime(2024, 6, 15, 23, 59), now: now),
                isTrue,
            );
        });

        test('어제 날짜는 수정 가능하다', () {
            expect(isEditableDate(DateTime(2024, 6, 14), now: now), isTrue);
        });

        test('이틀 전 날짜는 수정 불가능하다', () {
            expect(isEditableDate(DateTime(2024, 6, 13), now: now), isFalse);
        });

        test('일주일 전 날짜는 수정 불가능하다', () {
            expect(isEditableDate(DateTime(2024, 6, 8), now: now), isFalse);
        });

        test('내일 날짜는 수정 불가능하다 (미래)', () {
            expect(isEditableDate(DateTime(2024, 6, 16), now: now), isFalse);
        });

        test('월이 바뀌는 경계에서 어제를 올바르게 판별한다', () {
            final firstOfMonth = DateTime(2024, 7, 1, 9, 0);
            // 어제 = 6월 30일
            expect(isEditableDate(DateTime(2024, 6, 30), now: firstOfMonth), isTrue);
            // 2일 전 = 6월 29일
            expect(isEditableDate(DateTime(2024, 6, 29), now: firstOfMonth), isFalse);
        });
    });
}
