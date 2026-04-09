import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// 로컬 알림 서비스 — 싱글턴
///
/// 매일 설정된 시각에 일기 작성 알림을 스케줄링한다.
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  AndroidFlutterLocalNotificationsPlugin? _androidImpl;

  /// 알림 탭 시 실행할 콜백 (main.dart에서 등록)
  ///
  /// Presentation 레이어와 분리하기 위해 콜백으로 주입받는다.
  void Function()? _onNotificationTap;

  static const int _dailyNotificationId = 0;
  static const String _channelId = 'daily_reminder';
  static const String _channelName = '매일 일기 알림';

  // SharedPreferences 키
  static const String _enabledKey = 'notif_enabled';
  static const String _hourKey = 'notif_hour';
  static const String _minuteKey = 'notif_minute';
  static const String _alwaysNotifyKey = 'notif_always_notify';

  /// 알림 탭 핸들러 등록
  void setOnNotificationTap(void Function() handler) {
    _onNotificationTap = handler;
  }

  /// 앱이 알림 탭으로 실행됐는지 확인 (cold start 처리용)
  Future<bool> didLaunchFromNotification() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp == true;
  }

  /// 알림 플러그인 초기화 (main()에서 호출)
  Future<void> initialize() async {
    tz.initializeTimeZones();
    // 기기의 실제 로컬 타임존 사용 (5.x API: TimezoneInfo.identifier)
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      // 앱이 포그라운드/백그라운드 상태에서 알림 탭 시 호출
      onDidReceiveNotificationResponse: (_) {
        _onNotificationTap?.call();
      },
    );

    // 플랫폼별 구현체는 초기화 후 한 번만 resolve
    _androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
  }

  /// 알림 권한 요청 (Android 13+ / iOS)
  ///
  /// 반환값: 사용자가 권한을 허용했으면 true
  Future<bool> requestPermission() async {
    if (_androidImpl != null) {
      final granted = await _androidImpl!.requestNotificationsPermission();
      // null → Android 12 이하(API < 33): 권한 불필요, 자동 허용으로 처리
      return granted ?? true;
    }

    // iOS 권한 요청
    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final result = await iosImpl?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    // null → 이미 권한이 결정된 상태, 자동 허용으로 처리
    return result ?? true;
  }

  /// 저장된 설정으로 알림 재스케줄 (앱 재시작 시 호출)
  ///
  /// [hasDiaryToday]가 true이고 alwaysNotify=false인 경우 오늘 알림을 건너뛴다.
  /// 호출부에서 오늘 일기 존재 여부를 조회해 전달해야 한다.
  Future<void> rescheduleFromPrefs({bool hasDiaryToday = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? false;
    final hour = prefs.getInt(_hourKey) ?? 21;
    final minute = prefs.getInt(_minuteKey) ?? 0;
    final alwaysNotify = prefs.getBool(_alwaysNotifyKey) ?? false;

    final skipToday = !alwaysNotify && hasDiaryToday;

    await reschedule(
      enabled: enabled,
      time: TimeOfDay(hour: hour, minute: minute),
      skipToday: skipToday,
    );
  }

  /// 알림 스케줄 재설정
  ///
  /// [enabled]가 false면 기존 알림을 모두 취소한다.
  /// [enabled]가 true면 [time]에 매일 반복 알림을 등록한다.
  /// 실패 시 예외를 던진다.
  Future<void> reschedule({
    required bool enabled,
    required TimeOfDay time,
    bool skipToday = false,
  }) async {
    await _plugin.cancelAll();
    if (!enabled) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // 오늘을 건너뛰거나 이미 지난 시각이면 다음날로 설정
    if (skipToday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // USE_EXACT_ALARM(API 33+) 또는 SCHEDULE_EXACT_ALARM(API 31-32) 허용 여부 확인
    final canExact =
        await _androidImpl?.canScheduleExactNotifications() ?? false;

    await _plugin.zonedSchedule(
      id: _dailyNotificationId,
      title: '오늘 하루는 어떠셨나요?',
      body: '마음 일기를 기록해보세요.',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // exact alarm 가능하면 정확하게, 아니면 inexact로 폴백
      androidScheduleMode: canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      // skipToday=true일 때 matchDateTimeComponents를 사용하면
      // Android가 날짜를 무시하고 "오늘 시각"으로 재계산하므로
      // 한 번짜리 알림으로 내일에 발송하고, 앱 재시작 시 일일 반복으로 재설정됨
      matchDateTimeComponents: skipToday ? null : DateTimeComponents.time,
    );
  }
}
