import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_diary/domain/value_object/activity.dart';

void main() {
    group('Activity enum', () {
        test('총 14개의 활동이 정의되어 있다', () {
            expect(Activity.values.length, 14);
        });
    });

    group('ActivityExtension.emoji', () {
        test('date는 💑을 반환한다', () {
            expect(Activity.date.emoji, '💑');
        });

        test('overslept는 🛌을 반환한다', () {
            expect(Activity.overslept.emoji, '🛌');
        });

        test('drinking은 🍺을 반환한다', () {
            expect(Activity.drinking.emoji, '🍺');
        });

        test('workDinner는 🍻을 반환한다', () {
            expect(Activity.workDinner.emoji, '🍻');
        });

        test('study는 📚을 반환한다', () {
            expect(Activity.study.emoji, '📚');
        });

        test('exercise는 💪을 반환한다', () {
            expect(Activity.exercise.emoji, '💪');
        });

        test('walking은 🚶을 반환한다', () {
            expect(Activity.walking.emoji, '🚶');
        });

        test('hiking은 🧗을 반환한다', () {
            expect(Activity.hiking.emoji, '🧗');
        });

        test('shopping은 🛍️을 반환한다', () {
            expect(Activity.shopping.emoji, '🛍️');
        });

        test('travel은 ✈️을 반환한다', () {
            expect(Activity.travel.emoji, '✈️');
        });

        test('movie는 🎬을 반환한다', () {
            expect(Activity.movie.emoji, '🎬');
        });

        test('gaming은 🎮을 반환한다', () {
            expect(Activity.gaming.emoji, '🎮');
        });

        test('cooking은 🍳을 반환한다', () {
            expect(Activity.cooking.emoji, '🍳');
        });

        test('reading은 📖을 반환한다', () {
            expect(Activity.reading.emoji, '📖');
        });

        test('모든 활동이 비어있지 않은 이모지를 반환한다', () {
            for (final activity in Activity.values) {
                expect(activity.emoji, isNotEmpty);
            }
        });
    });

    group('ActivityExtension.label', () {
        test('date는 데이트를 반환한다', () {
            expect(Activity.date.label, '데이트');
        });

        test('overslept는 늦잠을 반환한다', () {
            expect(Activity.overslept.label, '늦잠');
        });

        test('drinking은 음주를 반환한다', () {
            expect(Activity.drinking.label, '음주');
        });

        test('workDinner는 모임을 반환한다', () {
            expect(Activity.workDinner.label, '모임');
        });

        test('study는 공부를 반환한다', () {
            expect(Activity.study.label, '공부');
        });

        test('exercise는 운동을 반환한다', () {
            expect(Activity.exercise.label, '운동');
        });

        test('walking은 산책을 반환한다', () {
            expect(Activity.walking.label, '산책');
        });

        test('hiking은 등산을 반환한다', () {
            expect(Activity.hiking.label, '등산');
        });

        test('shopping은 쇼핑을 반환한다', () {
            expect(Activity.shopping.label, '쇼핑');
        });

        test('travel은 여행을 반환한다', () {
            expect(Activity.travel.label, '여행');
        });

        test('movie는 영화를 반환한다', () {
            expect(Activity.movie.label, '영화');
        });

        test('gaming은 게임을 반환한다', () {
            expect(Activity.gaming.label, '게임');
        });

        test('cooking은 요리를 반환한다', () {
            expect(Activity.cooking.label, '요리');
        });

        test('reading은 독서를 반환한다', () {
            expect(Activity.reading.label, '독서');
        });

        test('모든 활동이 비어있지 않은 레이블을 반환한다', () {
            for (final activity in Activity.values) {
                expect(activity.label, isNotEmpty);
            }
        });
    });
}
