import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const kDarkGreen = Color(0xFF004643);

enum ActivityType { taskCreated, plantAdded, diseaseScanned }

class RecentActivity {
  final String id;
  final ActivityType type;
  final String description;
  final DateTime timestamp;

  RecentActivity({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
  });
}

class DashboardRecentActivity extends StatefulWidget {
  const DashboardRecentActivity({super.key});

  @override
  State<DashboardRecentActivity> createState() =>
      _DashboardRecentActivityState();
}

class _DashboardRecentActivityState extends State<DashboardRecentActivity> {
  bool _expanded = false;

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  Future<List<RecentActivity>> _getRecentActivities() async {
    final activities = <RecentActivity>[];

    // Get recent tasks
    final tasksSnapshot = await FirebaseFirestore.instance
        .collection('scheduledTasks')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    for (final doc in tasksSnapshot.docs) {
      final data = doc.data();
      final plantNames = (data['plantNames'] as List?)?.join(', ') ?? '';
      final taskType = (data['taskType'] as String?) ?? 'watering';
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

      if (createdAt != null) {
        activities.add(RecentActivity(
          id: doc.id,
          type: ActivityType.taskCreated,
          description:
          '${taskType[0].toUpperCase()}${taskType.substring(1)} schedule set for $plantNames',
          timestamp: createdAt,
        ));
      }
    }

    // Get recent plants
    final plantsSnapshot = await FirebaseFirestore.instance
        .collection('gardenPlants')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    for (final doc in plantsSnapshot.docs) {
      final data = doc.data();
      final plantName = data['plantName'] ?? 'Unknown';
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

      if (createdAt != null) {
        activities.add(RecentActivity(
          id: doc.id,
          type: ActivityType.plantAdded,
          description: 'Added $plantName to garden',
          timestamp: createdAt,
        ));
      }
    }

    // Get recent disease scans
    final scansSnapshot = await FirebaseFirestore.instance
        .collection('diseaseScans')
        .orderBy('scannedAt', descending: true)
        .limit(10)
        .get();

    for (final doc in scansSnapshot.docs) {
      final data = doc.data();
      final diseases = (data['diseases'] as List<dynamic>?) ?? [];
      final scannedAt = (data['scannedAt'] as Timestamp?)?.toDate();

      String diseaseText = 'Healthy';
      if (diseases.isNotEmpty) {
        final firstDisease = diseases.first as Map<String, dynamic>;
        diseaseText = firstDisease['name'] ?? 'Unknown';
      }

      if (scannedAt != null) {
        activities.add(RecentActivity(
          id: doc.id,
          type: ActivityType.diseaseScanned,
          description: 'Scanned a photo for disease - $diseaseText',
          timestamp: scannedAt,
        ));
      }
    }

    // Sort all activities by timestamp (newest first)
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return activities.take(20).toList();
  }

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
              Icon(Icons.history, color: kDarkGreen),
              SizedBox(width: 8),
              Text(
                'Recent Activity',
                style: TextStyle(
                  color: kDarkGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<RecentActivity>>(
          future: _getRecentActivities(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: kDarkGreen),
                ),
              );
            }

            final activities = snapshot.data!;

            if (activities.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'No recent activity',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              );
            }

            final previewActivities = activities.take(5).toList();

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Preview items
                      ...previewActivities
                          .map((activity) => _ActivityItem(activity: activity)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _toggleExpanded,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kDarkGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: Text(_expanded ? 'View Less' : 'View More'),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _expanded
                      ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: activities
                            .skip(5)
                            .map((activity) =>
                            _ActivityItem(activity: activity))
                            .toList(),
                      ),
                    ),
                  )
                      : const SizedBox.shrink(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final RecentActivity activity;

  const _ActivityItem({required this.activity});

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.taskCreated:
        return const Color(0xFF31A8FF); // blue
      case ActivityType.plantAdded:
        return const Color(0xFF22C55E); // green
      case ActivityType.diseaseScanned:
        return const Color(0xFFF59E0B); // orange
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getActivityColor(activity.type);
    final timeStr = _formatTime(activity.timestamp);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.description,
                  style: const TextStyle(
                    color: kDarkGreen,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}