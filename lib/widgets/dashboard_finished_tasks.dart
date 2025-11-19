import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const kDarkGreen = Color(0xFF004643);

class DashboardFinishedTasks extends StatelessWidget {
  const DashboardFinishedTasks({super.key});

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
        int wateringTotal = 0;
        int wateringCompleted = 0;
        int fertilizingTotal = 0;
        int fertilizingCompleted = 0;
        int pruningTotal = 0;
        int pruningCompleted = 0;

        if (snapshot.hasData) {
          final currentTime = TimeOfDay.now();
          final currentMinutes = currentTime.hour * 60 + currentTime.minute;

          for (final doc in snapshot.data!.docs) {
            final data = doc.data();
            final taskType = (data['taskType'] as String?) ?? 'watering';
            final timeStr = data['time']?.toString();

            bool isCompleted = false;
            if (timeStr != null) {
              final taskTime = _parseTime(timeStr);
              if (taskTime != null) {
                final taskMinutes = taskTime.hour * 60 + taskTime.minute;
                isCompleted = currentMinutes >= taskMinutes;
              }
            }

            switch (taskType) {
              case 'watering':
                wateringTotal++;
                if (isCompleted) wateringCompleted++;
                break;
              case 'fertilizing':
                fertilizingTotal++;
                if (isCompleted) fertilizingCompleted++;
                break;
              case 'pruning':
                pruningTotal++;
                if (isCompleted) pruningCompleted++;
                break;
            }
          }
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.bar_chart, color: kDarkGreen),
                  SizedBox(width: 8),
                  Text(
                    'Finished Tasks',
                    style: TextStyle(
                      color: kDarkGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 220, // Increased height to prevent overflow
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BarColumn(
                      label: 'Watering',
                      completed: wateringCompleted,
                      total: wateringTotal,
                      color: const Color(0xFF31A8FF),
                    ),
                    _BarColumn(
                      label: 'Fertilizing',
                      completed: fertilizingCompleted,
                      total: fertilizingTotal,
                      color: const Color(0xFF22C55E),
                    ),
                    _BarColumn(
                      label: 'Pruning',
                      completed: pruningCompleted,
                      total: pruningTotal,
                      color: const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ),
            ],
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

class _BarColumn extends StatelessWidget {
  final String label;
  final int completed;
  final int total;
  final Color color;

  const _BarColumn({
    required this.label,
    required this.completed,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (completed / total * 100).round() : 0;
    final completedHeight = total > 0 ? (completed / total * 140) : 0.0; // Reduced from 150
    final remainingHeight = total > 0 ? ((total - completed) / total * 140) : 0.0; // Reduced from 150

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Percentage text
          Text(
            '$percentage%',
            style: const TextStyle(
              color: kDarkGreen,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          // Bar
          Container(
            width: 60,
            height: 140, // Reduced from 150 to fit better
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (remainingHeight > 0)
                  Container(
                    height: remainingHeight,
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                  ),
                if (completedHeight > 0)
                  Container(
                    height: completedHeight,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.vertical(
                        bottom: const Radius.circular(8),
                        top: remainingHeight > 0
                            ? Radius.zero
                            : const Radius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Label
          Text(
            label,
            style: const TextStyle(
              color: kDarkGreen,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}