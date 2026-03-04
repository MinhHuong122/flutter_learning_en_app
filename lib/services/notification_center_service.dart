import 'dart:convert';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'lesson_service.dart';

class NotificationSettings {
  final bool studyReminderEnabled;
  final bool newLessonEnabled;
  final bool discountEnabled;
  final int reminderHour;
  final int reminderMinute;

  const NotificationSettings({
    required this.studyReminderEnabled,
    required this.newLessonEnabled,
    required this.discountEnabled,
    required this.reminderHour,
    required this.reminderMinute,
  });

  NotificationSettings copyWith({
    bool? studyReminderEnabled,
    bool? newLessonEnabled,
    bool? discountEnabled,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return NotificationSettings(
      studyReminderEnabled: studyReminderEnabled ?? this.studyReminderEnabled,
      newLessonEnabled: newLessonEnabled ?? this.newLessonEnabled,
      discountEnabled: discountEnabled ?? this.discountEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }
}

class AppNotificationItem {
  final String id;
  final String type; // system | new_lesson | discount
  final String title;
  final String description;
  final DateTime createdAt;
  final bool isRead;

  AppNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.isRead,
  });

  AppNotificationItem copyWith({bool? isRead}) {
    return AppNotificationItem(
      id: id,
      type: type,
      title: title,
      description: description,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'description': description,
        'created_at': createdAt.toIso8601String(),
        'is_read': isRead,
      };

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    return AppNotificationItem(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }
}

class NotificationCenterService {
  static final NotificationCenterService _instance =
      NotificationCenterService._internal();
  factory NotificationCenterService() => _instance;
  NotificationCenterService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const int _studyReminderId = 1001;

  static const String _kStudyReminderEnabled = 'notif_study_reminder_enabled';
  static const String _kNewLessonEnabled = 'notif_new_lesson_enabled';
  static const String _kDiscountEnabled = 'notif_discount_enabled';
  static const String _kReminderHour = 'notif_reminder_hour';
  static const String _kReminderMinute = 'notif_reminder_minute';
  static const String _kInAppNotifications = 'in_app_notifications';
  static const String _kLastKnownLessonCount = 'last_known_lesson_count';
  static const String _kLastKnownLessonCreatedAt =
      'last_known_lesson_created_at_millis';
  static const String _kLastDiscountDate = 'last_discount_notification_date';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    tz.initializeTimeZones();
    _initialized = true;
  }

  Future<NotificationSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return NotificationSettings(
      studyReminderEnabled: prefs.getBool(_kStudyReminderEnabled) ?? true,
      newLessonEnabled: prefs.getBool(_kNewLessonEnabled) ?? true,
      discountEnabled: prefs.getBool(_kDiscountEnabled) ?? true,
      reminderHour: prefs.getInt(_kReminderHour) ?? 20,
      reminderMinute: prefs.getInt(_kReminderMinute) ?? 0,
    );
  }

  Future<void> restoreSchedulesFromSavedSettings() async {
    final settings = await loadSettings();
    await _applyReminderSchedule(settings);
  }

  Future<void> saveSettings(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_kStudyReminderEnabled, settings.studyReminderEnabled);
    await prefs.setBool(_kNewLessonEnabled, settings.newLessonEnabled);
    await prefs.setBool(_kDiscountEnabled, settings.discountEnabled);
    await prefs.setInt(_kReminderHour, settings.reminderHour);
    await prefs.setInt(_kReminderMinute, settings.reminderMinute);

    await _applyReminderSchedule(settings);

    if (settings.studyReminderEnabled) {
      await _addInAppNotification(
        type: 'system',
        title: 'Đã bật nhắc học hằng ngày',
        description:
            'Hệ thống sẽ nhắc bạn học lúc ${settings.reminderHour.toString().padLeft(2, '0')}:${settings.reminderMinute.toString().padLeft(2, '0')}.',
      );
    }
  }

  Future<void> _applyReminderSchedule(NotificationSettings settings) async {
    await initialize();

    if (!settings.studyReminderEnabled) {
      await _localNotifications.cancel(_studyReminderId);
      return;
    }

    final scheduleTime = _nextInstanceOfTime(
      settings.reminderHour,
      settings.reminderMinute,
    );

    const androidDetails = AndroidNotificationDetails(
      'study_reminder_channel',
      'Study Reminders',
      channelDescription: 'Daily reminders to practice English',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.zonedSchedule(
      _studyReminderId,
      'Đến giờ học rồi! 📚',
      'Mở app PUPU và luyện tiếng Anh ngay nhé.',
      scheduleTime,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> syncNotifications() async {
    await initialize();
    final settings = await loadSettings();

    await _checkForNewLessons(settings);
    await _checkForDiscountNotification(settings);
  }

  Future<void> _checkForNewLessons(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final lessons = await LessonService().getParentLessons();

    if (lessons.isEmpty) return;

    final latestCreatedAtMillis = lessons
        .map((l) => l.createdAt?.millisecondsSinceEpoch ?? 0)
        .fold<int>(0, max);
    final currentCount = lessons.length;

    final hasBaseline = prefs.containsKey(_kLastKnownLessonCount);
    final lastCount = prefs.getInt(_kLastKnownLessonCount) ?? currentCount;
    final lastLatestMillis =
        prefs.getInt(_kLastKnownLessonCreatedAt) ?? latestCreatedAtMillis;

    if (hasBaseline &&
        (currentCount > lastCount || latestCreatedAtMillis > lastLatestMillis) &&
        settings.newLessonEnabled) {
      await _addInAppNotification(
        type: 'new_lesson',
        title: 'Bài học mới vừa cập nhật',
        description: 'Đã có nội dung học mới. Mở app để khám phá ngay.',
      );

      await _showInstantLocalNotification(
        id: 2001,
        title: 'Bài học mới cập nhật',
        body: 'Đã có bài học mới trong PUPU. Vào học ngay nhé!',
      );
    }

    await prefs.setInt(_kLastKnownLessonCount, currentCount);
    await prefs.setInt(_kLastKnownLessonCreatedAt, latestCreatedAtMillis);
  }

  Future<void> _checkForDiscountNotification(NotificationSettings settings) async {
    if (!settings.discountEnabled) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';
    final lastDate = prefs.getString(_kLastDiscountDate);

    if (lastDate == todayKey) return;

    await _addInAppNotification(
      type: 'discount',
      title: 'Ưu đãi học tập hôm nay',
      description: 'Giảm giá các khóa học nâng cao trong thời gian ngắn.',
    );

    await _showInstantLocalNotification(
      id: 3001,
      title: 'Ưu đãi mới 🎁',
      body: 'Bạn có ưu đãi giảm giá khóa học. Kiểm tra ngay!',
    );

    await prefs.setString(_kLastDiscountDate, todayKey);
  }

  Future<void> _showInstantLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'pupu_updates_channel',
      'PUPU Updates',
      channelDescription: 'New lesson and discount updates',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(id, title, body, details);
  }

  Future<List<AppNotificationItem>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kInAppNotifications);
    if (raw == null || raw.isEmpty) return [];

    final decoded = (jsonDecode(raw) as List)
        .map((e) => AppNotificationItem.fromJson(e as Map<String, dynamic>))
        .toList();

    decoded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return decoded;
  }

  Future<void> markAsRead(String id) async {
    final current = await getNotifications();
    final updated = current
        .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList();
    await _saveInAppNotifications(updated);
  }

  Future<void> _addInAppNotification({
    required String type,
    required String title,
    required String description,
  }) async {
    final current = await getNotifications();

    final now = DateTime.now();
    final id = '${type}_${now.millisecondsSinceEpoch}';

    current.insert(
      0,
      AppNotificationItem(
        id: id,
        type: type,
        title: title,
        description: description,
        createdAt: now,
        isRead: false,
      ),
    );

    if (current.length > 100) {
      current.removeRange(100, current.length);
    }

    await _saveInAppNotifications(current);
  }

  Future<void> _saveInAppNotifications(List<AppNotificationItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_kInAppNotifications, encoded);
  }
}
