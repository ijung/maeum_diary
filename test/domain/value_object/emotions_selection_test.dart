import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_diary/domain/value_object/emotion.dart';
import 'package:maeum_diary/domain/value_object/emotions_selection.dart';

void main() {
    group('EmotionsSelection 생성', () {
        test('감정 1개로 생성할 수 있다', () {
            final sel = EmotionsSelection([Emotion.happy]);
            expect(sel.values, [Emotion.happy]);
        });

        test('감정 3개로 생성할 수 있다', () {
            final sel = EmotionsSelection([Emotion.happy, Emotion.sad, Emotion.angry]);
            expect(sel.values.length, 3);
        });

        test('빈 목록으로 생성하면 ArgumentError를 던진다', () {
            expect(() => EmotionsSelection([]), throwsArgumentError);
        });

        test('4개 이상으로 생성하면 ArgumentError를 던진다', () {
            expect(
                () => EmotionsSelection([
                    Emotion.happy,
                    Emotion.sad,
                    Emotion.angry,
                    Emotion.anxious,
                ]),
                throwsArgumentError,
            );
        });

        test('중복된 감정으로 생성하면 ArgumentError를 던진다', () {
            expect(
                () => EmotionsSelection([Emotion.happy, Emotion.happy]),
                throwsArgumentError,
            );
        });
    });

    group('canAddMore', () {
        test('1개 선택 시 추가 가능하다', () {
            expect(EmotionsSelection([Emotion.happy]).canAddMore, isTrue);
        });

        test('2개 선택 시 추가 가능하다', () {
            expect(
                EmotionsSelection([Emotion.happy, Emotion.sad]).canAddMore,
                isTrue,
            );
        });

        test('3개 선택 시 추가 불가능하다', () {
            expect(
                EmotionsSelection([Emotion.happy, Emotion.sad, Emotion.angry]).canAddMore,
                isFalse,
            );
        });
    });

    group('add', () {
        test('감정을 추가하면 새 객체를 반환한다', () {
            final sel = EmotionsSelection([Emotion.happy]);
            final added = sel.add(Emotion.sad);
            expect(added.values, [Emotion.happy, Emotion.sad]);
        });

        test('이미 선택된 감정을 추가하면 동일 객체를 반환한다', () {
            final sel = EmotionsSelection([Emotion.happy]);
            final result = sel.add(Emotion.happy);
            expect(identical(result, sel), isTrue);
        });

        test('3개 이상 추가하면 ArgumentError를 던진다', () {
            final sel = EmotionsSelection([Emotion.happy, Emotion.sad, Emotion.angry]);
            expect(() => sel.add(Emotion.anxious), throwsArgumentError);
        });
    });

    group('remove', () {
        test('감정을 제거하면 새 객체를 반환한다', () {
            final sel = EmotionsSelection([Emotion.happy, Emotion.sad]);
            final removed = sel.remove(Emotion.sad);
            expect(removed.values, [Emotion.happy]);
        });

        test('선택되지 않은 감정을 제거하면 동일 객체를 반환한다', () {
            final sel = EmotionsSelection([Emotion.happy]);
            final result = sel.remove(Emotion.sad);
            expect(identical(result, sel), isTrue);
        });

        test('마지막 감정을 제거하면 ArgumentError를 던진다', () {
            final sel = EmotionsSelection([Emotion.happy]);
            expect(() => sel.remove(Emotion.happy), throwsArgumentError);
        });
    });

    group('contains', () {
        test('선택된 감정은 true를 반환한다', () {
            final sel = EmotionsSelection([Emotion.happy, Emotion.sad]);
            expect(sel.contains(Emotion.happy), isTrue);
            expect(sel.contains(Emotion.sad), isTrue);
        });

        test('선택되지 않은 감정은 false를 반환한다', () {
            final sel = EmotionsSelection([Emotion.happy]);
            expect(sel.contains(Emotion.sad), isFalse);
        });
    });

    group('동등성', () {
        test('같은 순서의 같은 감정은 동등하다', () {
            final a = EmotionsSelection([Emotion.happy, Emotion.sad]);
            final b = EmotionsSelection([Emotion.happy, Emotion.sad]);
            expect(a, equals(b));
        });

        test('순서가 다르면 동등하지 않다', () {
            final a = EmotionsSelection([Emotion.happy, Emotion.sad]);
            final b = EmotionsSelection([Emotion.sad, Emotion.happy]);
            expect(a, isNot(equals(b)));
        });
    });
}
