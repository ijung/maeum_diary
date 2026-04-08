import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_diary/presentation/provider/notification_settings_provider.dart';

void main() {
    const baseTime = TimeOfDay(hour: 21, minute: 0);

    NotificationSettings makeSettings({
        bool enabled = false,
        TimeOfDay time = baseTime,
        bool alwaysNotify = false,
    }) {
        return NotificationSettings(
            enabled: enabled,
            time: time,
            alwaysNotify: alwaysNotify,
        );
    }

    group('NotificationSettings.copyWith', () {
        test('enabled를 변경한 새 객체를 반환한다', () {
            final settings = makeSettings(enabled: false);

            final updated = settings.copyWith(enabled: true);

            expect(updated.enabled, isTrue);
            expect(updated.time, settings.time);
            expect(updated.alwaysNotify, settings.alwaysNotify);
        });

        test('time을 변경한 새 객체를 반환한다', () {
            final settings = makeSettings();
            const newTime = TimeOfDay(hour: 8, minute: 30);

            final updated = settings.copyWith(time: newTime);

            expect(updated.time, newTime);
            expect(updated.enabled, settings.enabled);
            expect(updated.alwaysNotify, settings.alwaysNotify);
        });

        test('alwaysNotify를 변경한 새 객체를 반환한다', () {
            final settings = makeSettings(alwaysNotify: false);

            final updated = settings.copyWith(alwaysNotify: true);

            expect(updated.alwaysNotify, isTrue);
            expect(updated.enabled, settings.enabled);
            expect(updated.time, settings.time);
        });

        test('인자를 전달하지 않으면 기존 값을 유지한다', () {
            final settings = makeSettings(
                enabled: true,
                time: const TimeOfDay(hour: 9, minute: 0),
                alwaysNotify: true,
            );

            final updated = settings.copyWith();

            expect(updated.enabled, settings.enabled);
            expect(updated.time, settings.time);
            expect(updated.alwaysNotify, settings.alwaysNotify);
        });

        test('copyWith은 항상 새 객체를 반환한다', () {
            final settings = makeSettings();

            final updated = settings.copyWith();

            expect(identical(updated, settings), isFalse);
        });

        test('여러 필드를 동시에 변경할 수 있다', () {
            final settings = makeSettings();
            const newTime = TimeOfDay(hour: 7, minute: 0);

            final updated = settings.copyWith(enabled: true, time: newTime, alwaysNotify: true);

            expect(updated.enabled, isTrue);
            expect(updated.time, newTime);
            expect(updated.alwaysNotify, isTrue);
        });
    });
}
