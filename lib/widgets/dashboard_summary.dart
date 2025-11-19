import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const kDarkGreen = Color(0xFF004643);

class DashboardSummary extends StatelessWidget {
  const DashboardSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.insert_drive_file_outlined, color: kDarkGreen),
              SizedBox(width: 8),
              Text(
                'Summary',
                style: TextStyle(
                  color: kDarkGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          runSpacing: 12,
          spacing: 12,
          children: const [
            _TotalPlantsCard(),
            _TaskCompletedCard(),
            _InfectedPlantsCard(),
            _NextTaskCard(),
          ],
        ),
      ],
    );
  }
}

/// Panel 1: Total Plants
class _TotalPlantsCard extends StatelessWidget {
  const _TotalPlantsCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('gardenPlants').snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return _StatCard(
          icon: Icons.yard_outlined,
          title: 'Total Plants',
          value: '$count',
        );
      },
    );
  }
}

/// Panel 2: Task Completed (today, resets daily)
class _TaskCompletedCard extends StatelessWidget {
  const _TaskCompletedCard();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('scheduledTasks')
          .where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .snapshots(),
      builder: (context, snapshot) {
        int completedCount = 0;

        if (snapshot.hasData) {
          final currentTime = TimeOfDay.now();
          final currentMinutes = currentTime.hour * 60 + currentTime.minute;

          for (final doc in snapshot.data!.docs) {
            final timeStr = doc.data()['time']?.toString();
            if (timeStr != null) {
              final taskTime = _parseTime(timeStr);
              if (taskTime != null) {
                final taskMinutes = taskTime.hour * 60 + taskTime.minute;
                if (currentMinutes >= taskMinutes) {
                  completedCount++;
                }
              }
            }
          }
        }

        return _StatCard(
          icon: Icons.task_alt_outlined,
          title: 'Task Completed',
          value: '$completedCount',
        );
      },
    );
  }

  TimeOfDay? _parseTime(String s) {
    final r = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false);
    final m = r.firstMatch(s.trim());
    if (m == null) return null;

    int h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    final ap = m.group(3)!.toUpperCase();

    if (ap == 'PM' && h != 12) h += 12;
    if (ap == 'AM' && h == 12) h = 0;

    return TimeOfDay(hour: h, minute: min);
  }
}

/// Panel 3: Infected Plants
class _InfectedPlantsCard extends StatelessWidget {
  const _InfectedPlantsCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('diseaseScans')
          .where('status', isEqualTo: 'infected')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return _StatCard(
          icon: Icons.sick_outlined,
          title: 'Infected Plants',
          value: '$count',
        );
      },
    );
  }
}

/// Panel 4: Next Task
class _NextTaskCard extends StatelessWidget {
  const _NextTaskCard();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('scheduledTasks')
          .where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('date')
          .snapshots(),
      builder: (context, snapshot) {
        String nextTaskText = 'No tasks';

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final currentTime = TimeOfDay.now();
          final currentMinutes = currentTime.hour * 60 + currentTime.minute;

          // Find the next upcoming task
          for (final doc in snapshot.data!.docs) {
            final data = doc.data();
            final timeStr = data['time']?.toString();
            final taskType =
                (data['taskType'] as String?) ?? 'watering';
            final plantNames = (data['plantNames'] as List?)?.join(', ') ?? '';

            if (timeStr != null) {
              final taskTime = _parseTime(timeStr);
              if (taskTime != null) {
                final taskMinutes = taskTime.hour * 60 + taskTime.minute;

                // Find next task (time hasn't passed yet)
                if (currentMinutes < taskMinutes) {
                  nextTaskText =
                  '$timeStr ${taskType[0].toUpperCase()}${taskType.substring(1)} $plantNames';
                  break;
                }
              }
            }
          }
        }

        return SizedBox(
          width: (MediaQuery.of(context).size.width - 20 * 2 - 12) / 2,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.event_note_outlined, color: kDarkGreen),
                const SizedBox(height: 6),
                const Text(
                  'Next Task',
                  style: TextStyle(
                      color: kDarkGreen, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  nextTaskText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kDarkGreen, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  TimeOfDay? _parseTime(String s) {
    final r = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false);
    final m = r.firstMatch(s.trim());
    if (m == null) return null;

    int h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    final ap = m.group(3)!.toUpperCase();

    if (ap == 'PM' && h != 12) h += 12;
    if (ap == 'AM' && h == 12) h = 0;

    return TimeOfDay(hour: h, minute: min);
  }
}

/// Reusable Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 20 * 2 - 12) / 2,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: kDarkGreen),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                  color: kDarkGreen, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kDarkGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}