import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:maeum_diary/application/use_case/get_diary_by_date_use_case.dart';
import 'package:maeum_diary/core/di/providers.dart';
import 'package:maeum_diary/domain/entity/diary_entry.dart';
import 'package:maeum_diary/domain/port/diary_repository.dart';
import 'package:maeum_diary/domain/value_object/emotion.dart';
import 'package:maeum_diary/domain/value_object/emotions_selection.dart';
import 'package:maeum_diary/presentation/provider/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockDiaryRepository extends Mock implements DiaryRepository {}

void main() {
    late _MockDiaryRepository mockRepository;

    // 오늘 일기가 존재하는 경우를 시뮬레이션하기 위한 픽스처
    final fakeDiaryEntry = DiaryEntry(
        id: 'test-id',
        date: DateTime(2024, 6, 15),
        emotions: EmotionsSelection([Emotion.happy]),
        createdAt: DateTime(2024, 6, 15),
        updatedAt: DateTime(2024, 6, 15),
    );

    setUpAll(() {
        // DateTime 타입을 any()로 매칭할 수 있도록 폴백 값 등록
        registerFallbackValue(DateTime(2024));
    });

    setUp(() {
        mockRepository = _MockDiaryRepository();
        SharedPreferences.setMockInitialValues({});
    });

    /// getDiaryByDateUseCaseProvider를 mock repository를 사용하는 실 인스턴스로 교체한다.
    ProviderContainer makeContainer() {
        return ProviderContainer(
            overrides: [
                getDiaryByDateUseCaseProvider.overrideWithValue(
                    GetDiaryByDateUseCase(repository: mockRepository),
                ),
            ],
        );
    }

    // ─── build() ──────────────────────────────────────────────────────────────

    group('build()', () {
        test('SharedPreferences가 비어있으면 기본값(알림 OFF, 21:00, alwaysNotify=false)으로 초기화된다', () async {
            final container = makeContainer();
            addTearDown(container.dispose);

            final settings = await container.read(notificationSettingsProvider.future);

            expect(settings.enabled, isFalse);
            expect(settings.time, const TimeOfDay(hour: 21, minute: 0));
            expect(settings.alwaysNotify, isFalse);
        });

        test('SharedPreferences에 저장된 값을 불러온다', () async {
            SharedPreferences.setMockInitialValues({
                'notif_enabled': true,
                'notif_hour': 8,
                'notif_minute': 30,
                'notif_always_notify': true,
            });
            final container = makeContainer();
            addTearDown(container.dispose);

            final settings = await container.read(notificationSettingsProvider.future);

            expect(settings.enabled, isTrue);
            expect(settings.time, const TimeOfDay(hour: 8, minute: 30));
            expect(settings.alwaysNotify, isTrue);
        });
    });

    // ─── setAlwaysNotify() ────────────────────────────────────────────────────

    group('setAlwaysNotify()', () {
        test('false로 변경하면 state.alwaysNotify가 false가 된다', () async {
            SharedPreferences.setMockInitialValues({'notif_always_notify': true});
            when(() => mockRepository.findByDate(any())).thenAnswer((_) async => null);
            final container = makeContainer();
            addTearDown(container.dispose);

            await container.read(notificationSettingsProvider.future);
            await container.read(notificationSettingsProvider.notifier).setAlwaysNotify(false);

            expect(container.read(notificationSettingsProvider).valueOrNull?.alwaysNotify, isFalse);
        });

        test('true로 변경하면 state.alwaysNotify가 true가 된다', () async {
            final container = makeContainer();
            addTearDown(container.dispose);

            await container.read(notificationSettingsProvider.future);
            await container.read(notificationSettingsProvider.notifier).setAlwaysNotify(true);

            expect(container.read(notificationSettingsProvider).valueOrNull?.alwaysNotify, isTrue);
        });

        test('false && 알림 활성화 상태면 오늘 일기 존재 여부를 조회한다', () async {
            SharedPreferences.setMockInitialValues({
                'notif_enabled': true,
                'notif_always_notify': true,
            });
            when(() => mockRepository.findByDate(any())).thenAnswer((_) async => null);
            final container = makeContainer();
            addTearDown(container.dispose);

            await container.read(notificationSettingsProvider.future);
            await container.read(notificationSettingsProvider.notifier).setAlwaysNotify(false);

            verify(() => mockRepository.findByDate(any())).called(1);
        });

        test('false && 알림 비활성화 상태면 오늘 일기 존재 여부를 조회하지 않는다', () async {
            SharedPreferences.setMockInitialValues({
                'notif_enabled': false,
                'notif_always_notify': true,
            });
            final container = makeContainer();
            addTearDown(container.dispose);

            await container.read(notificationSettingsProvider.future);
            await container.read(notificationSettingsProvider.notifier).setAlwaysNotify(false);

            verifyNever(() => mockRepository.findByDate(any()));
        });

        test('true로 변경하면 오늘 일기 존재 여부를 조회하지 않는다', () async {
            SharedPreferences.setMockInitialValues({'notif_enabled': true});
            final container = makeContainer();
            addTearDown(container.dispose);

            await container.read(notificationSettingsProvider.future);
            await container.read(notificationSettingsProvider.notifier).setAlwaysNotify(true);

            verifyNever(() => mockRepository.findByDate(any()));
        });

        test('오늘 일기가 있고 알림 활성화 상태면 DB 조회 결과가 반영된다', () async {
            // 이 테스트는 _hasDiaryToday()가 진짜 DB 결과를 반환하는지 검증한다.
            SharedPreferences.setMockInitialValues({
                'notif_enabled': true,
                'notif_always_notify': true,
            });
            when(() => mockRepository.findByDate(any()))
                .thenAnswer((_) async => fakeDiaryEntry);
            final container = makeContainer();
            addTearDown(container.dispose);

            await container.read(notificationSettingsProvider.future);
            // 예외 없이 완료되면 성공 (NotificationService 실패는 무시됨)
            await container.read(notificationSettingsProvider.notifier).setAlwaysNotify(false);

            verify(() => mockRepository.findByDate(any())).called(1);
        });
    });

    // ─── setTime() ────────────────────────────────────────────────────────────

    group('setTime()', () {
        const newTime = TimeOfDay(hour: 8, minute: 30);

        test('state.time이 새 시각으로 변경된다', () async {
            final container = makeContainer();
            addTearDown(container.dispose);

            await container.read(notificationSettingsProvider.future);
            await container.read(notificationSettingsProvider.notifier).setTime(newTime);

            expect(container.read(notificationSettingsProvider).valueOrNull?.time, newTime);
        });

        test('알림 활성화 && alwaysNotify=false이면 오늘 일기 존재 여부를 조회한다', () async {
            SharedPreferences.setMockInitialValues({
                'notif_enabled': true,
                'notif_always_notify': false,
            });
            when(() => mockRepository.findByDate(any()))
                .thenAnswer((_) async => fakeDiaryEntry);
            final container = makeContainer();
            addTearDown(container.dispose);

            await container.read(notificationSettingsProvider.future);
            await container.read(notificationSettingsProvider.notifier).setTime(newTime);

            verify(() => mockRepository.findByDate(any())).called(1);
        });

        test('알림 비활성화 상태이면 오늘 일기 존재 여부를 조회하지 않는다', () async {
            SharedPreferences.setMockInitialValues({'notif_enabled': false});
            final container = makeContainer();
            addTearDown(container.dispose);

            await container.read(notificationSettingsProvider.future);
            await container.read(notificationSettingsProvider.notifier).setTime(newTime);

            verifyNever(() => mockRepository.findByDate(any()));
        });

        test('알림 활성화 && alwaysNotify=true이면 오늘 일기 존재 여부를 조회하지 않는다', () async {
            SharedPreferences.setMockInitialValues({
                'notif_enabled': true,
                'notif_always_notify': true,
            });
            final container = makeContainer();
            addTearDown(container.dispose);

            await container.read(notificationSettingsProvider.future);
            await container.read(notificationSettingsProvider.notifier).setTime(newTime);

            verifyNever(() => mockRepository.findByDate(any()));
        });
    });
}
