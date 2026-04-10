import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_diary/domain/value_object/emotion.dart';

void main() {
    group('Emotion enum', () {
        test('총 9개의 감정이 정의되어 있다', () {
            expect(Emotion.values.length, 9);
        });
    });

    group('EmotionExtension.emoji', () {
        test('happy는 😊을 반환한다', () {
            expect(Emotion.happy.emoji, '😊');
        });

        test('calm은 😌을 반환한다', () {
            expect(Emotion.calm.emoji, '😌');
        });

        test('sad는 😢을 반환한다', () {
            expect(Emotion.sad.emoji, '😢');
        });

        test('angry는 😠을 반환한다', () {
            expect(Emotion.angry.emoji, '😠');
        });

        test('anxious는 😰을 반환한다', () {
            expect(Emotion.anxious.emoji, '😰');
        });

        test('neutral은 😐을 반환한다', () {
            expect(Emotion.neutral.emoji, '😐');
        });

        test('excited는 🤩을 반환한다', () {
            expect(Emotion.excited.emoji, '🤩');
        });

        test('tired는 😴을 반환한다', () {
            expect(Emotion.tired.emoji, '😴');
        });

        test('loved는 🥰을 반환한다', () {
            expect(Emotion.loved.emoji, '🥰');
        });

        test('모든 감정이 비어있지 않은 이모지를 반환한다', () {
            for (final emotion in Emotion.values) {
                expect(emotion.emoji, isNotEmpty);
            }
        });
    });

    group('EmotionExtension.label', () {
        test('happy는 행복을 반환한다', () {
            expect(Emotion.happy.label, '행복');
        });

        test('calm은 평온을 반환한다', () {
            expect(Emotion.calm.label, '평온');
        });

        test('sad는 슬픔을 반환한다', () {
            expect(Emotion.sad.label, '슬픔');
        });

        test('angry는 화남을 반환한다', () {
            expect(Emotion.angry.label, '화남');
        });

        test('anxious는 불안을 반환한다', () {
            expect(Emotion.anxious.label, '불안');
        });

        test('neutral은 덤덤을 반환한다', () {
            expect(Emotion.neutral.label, '덤덤');
        });

        test('excited는 설렘을 반환한다', () {
            expect(Emotion.excited.label, '설렘');
        });

        test('tired는 피곤을 반환한다', () {
            expect(Emotion.tired.label, '피곤');
        });

        test('loved는 사랑을 반환한다', () {
            expect(Emotion.loved.label, '사랑');
        });

        test('모든 감정이 비어있지 않은 레이블을 반환한다', () {
            for (final emotion in Emotion.values) {
                expect(emotion.label, isNotEmpty);
            }
        });
    });
}
