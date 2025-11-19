import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../notifications/local_notifs.dart';

class NotificationTestPage extends StatelessWidget {
  const NotificationTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Test')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test Local Notifications',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // === IMMEDIATE TEST (NO SCHEDULING) ===
            ElevatedButton.icon(
              onPressed: () async {
                await LocalNotifs.instance.showImmediateTest();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Immediate notification sent!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('Show Immediate Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size.fromHeight(50),
              ),
            ),

            const Divider(height: 40),
            const Text(
              'Scheduled Notifications',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () async {
                final id = await LocalNotifs.instance.debugScheduleInSeconds(5);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Notification in 5s (ID: $id)')),
                );
              },
              child: const Text('Test in 5 seconds'),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () async {
                final id = await LocalNotifs.instance.debugScheduleInSeconds(10);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Notification in 10s (ID: $id)')),
                );
              },
              child: const Text('Test in 10 seconds'),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () async {
                final id = await LocalNotifs.instance.debugScheduleInSeconds(30);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Notification in 30s (ID: $id)')),
                );
              },
              child: const Text('Test in 30 seconds'),
            ),

            const Divider(height: 40),
            const Text(
              'Diagnostics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // === TIMEZONE INFO ===
            OutlinedButton.icon(
              onPressed: () {
                final localTz = tz.local;
                final now = DateTime.now();
                final tzNow = tz.TZDateTime.now(localTz);

                debugPrint('═══ TIMEZONE DIAGNOSTICS ═══');
                debugPrint('📍 tz.local.name: ${localTz.name}');
                debugPrint('🕐 DateTime.now(): $now');
                debugPrint('🌍 TZDateTime.now(tz.local): $tzNow');
                debugPrint('⏰ Offset: ${now.timeZoneOffset}');
                debugPrint('═══════════════════════════');

                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Timezone Info'),
                    content: Text(
                      'Timezone: ${localTz.name}\n'
                          'DateTime.now(): $now\n'
                          'TZDateTime.now(): $tzNow\n'
                          'Offset: ${now.timeZoneOffset}',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.info_outline),
              label: const Text('Show Timezone Info'),
            ),
            const SizedBox(height: 8),

            // === CHECK PERMISSIONS ===
            OutlinedButton.icon(
              onPressed: () async {
                debugPrint('═══ PERMISSION CHECK ═══');

                final plugin = FlutterLocalNotificationsPlugin();
                final android = plugin.resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>();

                if (android != null) {
                  final canSchedule = await android.canScheduleExactNotifications() ?? false;
                  debugPrint('✅ Can schedule exact notifications: $canSchedule');

                  if (!canSchedule) {
                    debugPrint('⚠️ Requesting exact alarm permission...');
                    await android.requestExactAlarmsPermission();
                  }

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        canSchedule
                            ? '✅ Exact alarms allowed'
                            : '⚠️ Requesting permission...',
                      ),
                      backgroundColor: canSchedule ? Colors.green : Colors.orange,
                    ),
                  );
                } else {
                  debugPrint('⚠️ Not running on Android');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Not running on Android')),
                  );
                }
                debugPrint('═══════════════════════');
              },
              icon: const Icon(Icons.alarm),
              label: const Text('Check Exact Alarm Permission'),
            ),
            const SizedBox(height: 8),

            // === PENDING NOTIFICATIONS ===
            OutlinedButton.icon(
              onPressed: () async {
                final pending = await LocalNotifs.instance.getPendingNotifications();

                debugPrint('═══ PENDING NOTIFICATIONS ═══');
                debugPrint('📋 Total pending: ${pending.length}');
                for (final p in pending) {
                  debugPrint('  - ID: ${p.id}, Title: ${p.title}, Body: ${p.body}');
                }
                debugPrint('═══════════════════════════');

                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Pending (${pending.length})'),
                    content: SingleChildScrollView(
                      child: Text(
                        pending.isEmpty
                            ? 'No pending notifications'
                            : pending.map((p) => 'ID: ${p.id}\n${p.title}\n${p.body}').join('\n\n'),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.list),
              label: const Text('View Pending'),
            ),
            const SizedBox(height: 8),

            // === CANCEL ALL ===
            OutlinedButton.icon(
              onPressed: () async {
                await LocalNotifs.instance.cancelAll();
                debugPrint('🗑️ All notifications cancelled');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications cancelled'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Cancel All'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),

            const SizedBox(height: 20),
            const Card(
              color: Color(0xFFFFF3CD),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Testing Tips:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('1. Try "Immediate" first to test basic notifications'),
                    Text('2. Check console logs for timezone info'),
                    Text('3. Ensure app notifications are enabled in Settings'),
                    Text('4. For Android 12+, allow "Alarms & reminders"'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}