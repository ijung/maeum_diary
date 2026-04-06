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
        // 기본 픽스처: 오늘 12시 (15시 이전)
        final nowBefore15 = DateTime(2024, 6, 15, 12, 0, 0);

        test('오늘 날짜는 수정 가능하다', () {
            expect(isEditableDate(DateTime(2024, 6, 15), now: nowBefore15), isTrue);
        });

        test('오늘 날짜 (시각 포함)도 수정 가능하다', () {
            expect(
                isEditableDate(DateTime(2024, 6, 15, 23, 59), now: nowBefore15),
                isTrue,
            );
        });

        test('오늘 날짜는 15시 이후에도 수정 가능하다', () {
            final nowAfter15 = DateTime(2024, 6, 15, 15, 0);
            expect(isEditableDate(DateTime(2024, 6, 15), now: nowAfter15), isTrue);
        });

        test('어제 날짜는 오늘 15시 이전이면 수정 가능하다', () {
            expect(isEditableDate(DateTime(2024, 6, 14), now: nowBefore15), isTrue);
        });

        test('어제 날짜는 오늘 14시 59분이면 수정 가능하다', () {
            final nowAt1459 = DateTime(2024, 6, 15, 14, 59);
            expect(isEditableDate(DateTime(2024, 6, 14), now: nowAt1459), isTrue);
        });

        test('어제 날짜는 오늘 15시 정각이면 수정 불가능하다', () {
            final nowAt15 = DateTime(2024, 6, 15, 15, 0);
            expect(isEditableDate(DateTime(2024, 6, 14), now: nowAt15), isFalse);
        });

        test('어제 날짜는 오늘 15시 이후면 수정 불가능하다', () {
            final nowAfter15 = DateTime(2024, 6, 15, 20, 0);
            expect(isEditableDate(DateTime(2024, 6, 14), now: nowAfter15), isFalse);
        });

        test('이틀 전 날짜는 수정 불가능하다', () {
            expect(isEditableDate(DateTime(2024, 6, 13), now: nowBefore15), isFalse);
        });

        test('일주일 전 날짜는 수정 불가능하다', () {
            expect(isEditableDate(DateTime(2024, 6, 8), now: nowBefore15), isFalse);
        });

        test('내일 날짜는 수정 불가능하다 (미래)', () {
            expect(isEditableDate(DateTime(2024, 6, 16), now: nowBefore15), isFalse);
        });

        test('월이 바뀌는 경계에서 어제를 올바르게 판별한다 (15시 이전)', () {
            final firstOfMonth = DateTime(2024, 7, 1, 9, 0);
            // 어제 = 6월 30일, 9시이므로 수정 가능
            expect(isEditableDate(DateTime(2024, 6, 30), now: firstOfMonth), isTrue);
            // 2일 전 = 6월 29일
            expect(isEditableDate(DateTime(2024, 6, 29), now: firstOfMonth), isFalse);
        });

        test('월이 바뀌는 경계에서 어제를 올바르게 판별한다 (15시 이후)', () {
            final firstOfMonthAfter15 = DateTime(2024, 7, 1, 16, 0);
            // 어제 = 6월 30일, 16시이므로 수정 불가능
            expect(isEditableDate(DateTime(2024, 6, 30), now: firstOfMonthAfter15), isFalse);
        });
    });
}
