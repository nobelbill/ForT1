import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/food_item.dart';

/// 유통기한 임박 로컬 알림을 관리한다. 외부 서버 없이 기기에서 예약된다.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// 유통기한 며칠 전에 알릴지.
  static const reminderLeadDays = 3;

  /// 알림을 보낼 시각(시).
  static const reminderHour = 9;

  static const _channelId = 'expiry_reminders';
  static const _channelName = '유통기한 알림';

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    // 한국 사용자 기준. 필요 시 기기 타임존 패키지로 대체 가능.
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    await _requestPermissions();
    _ready = true;
  }

  Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: '식품 유통기한이 임박하면 알려드려요.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  /// 식품의 유통기한 N일 전 오전에 알림을 예약한다.
  /// 예약 시각이 이미 지났다면 건너뛴다.
  Future<void> scheduleForItem(FoodItem item) async {
    final id = item.id;
    if (id == null) return;
    await init();

    final exp = item.expiryDate;
    final when = tz.TZDateTime(
      tz.local,
      exp.year,
      exp.month,
      exp.day,
      reminderHour,
    ).subtract(const Duration(days: reminderLeadDays));

    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id: id,
      title: '유통기한이 다가와요 ⏰',
      body: '${item.name}의 유통기한이 $reminderLeadDays일 남았어요.',
      scheduledDate: when,
      notificationDetails: _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelForItem(int id) async {
    await _plugin.cancel(id: id);
  }

  /// 디버그/테스트용 즉시 알림.
  @visibleForTesting
  Future<void> showNow(String title, String body) async {
    await init();
    await _plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: _details(),
    );
  }
}
