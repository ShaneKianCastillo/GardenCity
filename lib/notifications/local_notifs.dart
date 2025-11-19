// lib/notifications/local_notifs.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotifs {
  LocalNotifs._();
  static final LocalNotifs instance = LocalNotifs._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'garden_default_channel',
    'GardenCity Notifications',
    description: 'General notifications for scheduled tasks',
    importance: Importance.high,
  );

  // ───────────────────────── helpers ─────────────────────────

  /// Extract a usable timezone name from whatever the platform returns.
  String _extractTzName(Object res) {
    if (res is String && res.isNotEmpty) return res;            // simple case

    if (res is Map) {                                           // some platforms
      final v = res['timezone'] ?? res['name'];
      if (v is String && v.isNotEmpty) return v;
    }

    try {                                                       // dynamic fields
      final dyn = res as dynamic;
      final v = (dyn.timezone ?? dyn.name);
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}

    // parse from toString(): e.g. "TimezoneInfo{timezone=Asia/Manila,...}"
    final s = res.toString();
    final m = RegExp(r'(?:timezone|name)\s*[:=]\s*([A-Za-z_/\-]+)').firstMatch(s);
    if (m != null) return m.group(1)!;

    return '';
  }

  // ───────────────────────── init ─────────────────────────

  Future<void> init() async {
    // 1) Load TZ DB
    tz.initializeTimeZones();

    // 2) Resolve device timezone robustly
    try {
      final res = await FlutterTimezone.getLocalTimezone(); // String | TimezoneInfo | Map | etc.
      var tzName = _extractTzName(res);

      if (tzName.isEmpty) {
        // Fallback by offset (helps on emulators)
        final hours = DateTime.now().timeZoneOffset.inHours;
        tzName = switch (hours) {
          8 => 'Asia/Manila',
          7 => 'Asia/Bangkok',
          9 => 'Asia/Tokyo',
          _ => 'UTC',
        };
        debugPrint('⚠️ Couldn’t read tz; fallback by offset → $tzName (type: ${res.runtimeType})');
      } else {
        debugPrint('🌍 Resolved device timezone: $tzName (type: ${res.runtimeType})');
      }

      tz.setLocalLocation(tz.getLocation(tzName));
      debugPrint('✅ tz.local = ${tz.local.name}');
    } catch (e) {
      debugPrint('‼️ Timezone resolve failed: $e; hard fallback to Asia/Manila');
      tz.setLocalLocation(tz.getLocation('Asia/Manila'));
    }

    // 3) Init plugin
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTap,
    );

    // 4) Android channel + permissions
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(_channel);
      await android.requestNotificationsPermission();    // Android 13+
      await android.requestExactAlarmsPermission();      // Android 12+
    }

    // 5) iOS permissions
    final ios =
    _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  void _onTap(NotificationResponse r) {
    debugPrint('🔔 tapped: ${r.payload}');
    // (Optional) navigate to a screen (e.g., /schedule)
  }

  Future<void> ensureExactAlarmAllowed() async {
    final android =
    _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final can = await android?.canScheduleExactNotifications();
    if (can == false) {
      await android?.requestExactAlarmsPermission();
    }
  }

  // ───────────────────── quick tests ─────────────────────

  Future<void> showImmediateTest() async {
    final id = Random().nextInt(0x7fffffff);
    await _plugin.show(
      id,
      '🔔 Immediate Test',
      'This is an instant notification!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<int> debugScheduleInSeconds(int seconds) => scheduleOne(
    title: '🔔 Test',
    body: 'Fired after $seconds seconds',
    when: DateTime.now().add(Duration(seconds: seconds)),
  );

  // ───────────────────── one-off & batches ─────────────────────

  /// Schedule a single one-off local notification.
  Future<int> scheduleOne({
    required String title,
    required String body,
    required DateTime when,
  }) async {
    final now = DateTime.now();
    final safe = when.isAfter(now.add(const Duration(seconds: 3)))
        ? when
        : now.add(const Duration(seconds: 5));

    final id = Random().nextInt(0x7fffffff);
    final tzWhen = tz.TZDateTime.from(safe, tz.local);

    debugPrint('📅 Scheduling #$id at $tzWhen (tz.local=${tz.local.name})');

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzWhen,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'task_reminder',
    );

    return id;
  }

  /// Schedule many one-off notifications (future times only).
  Future<List<int>> scheduleMany({
    required String title,
    required String body,
    required Iterable<DateTime> dates,
  }) async {
    final ids = <int>[];
    final now = DateTime.now();
    for (final d in dates) {
      if (d.isAfter(now)) {
        ids.add(await scheduleOne(title: title, body: body, when: d));
      }
    }
    return ids;
  }

  // ───────────────────── indefinite repeats (endDate == null) ─────────────────────

  /// Repeat **daily** at a fixed local time forever (until you cancel).
  Future<int> scheduleDaily({
    required String title,
    required String body,
    required TimeOfDay time,       // local time of day
    required DateTime anchorDate,  // first day to consider (today or later)
  }) async {
    // First candidate at chosen time on/after anchor.
    var first = DateTime(
      anchorDate.year, anchorDate.month, anchorDate.day,
      time.hour, time.minute,
    );
    // If that moment already passed, use tomorrow.
    if (!first.isAfter(DateTime.now())) {
      first = first.add(const Duration(days: 1));
    }

    final id = Random().nextInt(0x7fffffff);
    final tzStart = tz.TZDateTime.from(first, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzStart,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // 🔁 repeat daily at time
      payload: 'task_reminder',
    );

    return id;
  }

  /// Repeat **weekly** on the selected weekday at a fixed local time forever.
  /// `weekday0to6`: 0=Sun..6=Sat (same convention you use in the UI).
  Future<int> scheduleWeekly({
    required String title,
    required String body,
    required int weekday0to6,
    required TimeOfDay time,
    required DateTime anchorDate,
  }) async {
    // Build from anchor at chosen time and move forward until weekday matches.
    var d = DateTime(
      anchorDate.year, anchorDate.month, anchorDate.day,
      time.hour, time.minute,
    );
    while ((d.weekday % 7) != (weekday0to6 % 7)) {
      d = d.add(const Duration(days: 1));
    }
    // If same-day time has already passed, jump one full week.
    if (!d.isAfter(DateTime.now())) {
      d = d.add(const Duration(days: 7));
    }

    final id = Random().nextInt(0x7fffffff);
    final tzStart = tz.TZDateTime.from(d, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzStart,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // 🔁 weekly
      payload: 'task_reminder',
    );

    return id;
  }

  // ───────────────────── maintenance / debug ─────────────────────

  Future<void> cancelIds(List<dynamic> ids) async {
    for (final id in ids) {
      if (id is int) {
        await _plugin.cancel(id);
      }
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<List<PendingNotificationRequest>> getPendingNotifications() =>
      _plugin.pendingNotificationRequests();

  Future<void> debugPrintTz() async {
    final now = DateTime.now();
    final tzNow = tz.TZDateTime.now(tz.local);
    debugPrint('📍 tz.local: ${tz.local.name}');
    debugPrint('🕐 DateTime.now(): $now');
    debugPrint('🌍 TZDateTime.now(): $tzNow');
    debugPrint('⏰ Offset: ${now.timeZoneOffset}');
  }
}
