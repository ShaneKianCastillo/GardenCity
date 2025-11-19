import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const kDarkGreen = Color(0xFF004643);

class DashboardTodaysTasks extends StatelessWidget {
  const DashboardTodaysTasks({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

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
              Icon(Icons.event_note_outlined, color: kDarkGreen),
              SizedBox(width: 8),
              Text(
                'Today\'s Task',
                style: TextStyle(
                  color: kDarkGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('scheduledTasks')
              .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
              .where('date', isLessThan: Timestamp.fromDate(endOfDay))
              .orderBy('date')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'No tasks scheduled for today',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              );
            }

            final docs = snapshot.data!.docs;

            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Time',
                            style: TextStyle(
                              color: kDarkGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Plant',
                            style: TextStyle(
                              color: kDarkGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Tasks',
                            style: TextStyle(
                              color: kDarkGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Task Rows
                  ...docs.map((doc) => _TaskRow(doc: doc)),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/schedule');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kDarkGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size.fromHeight(46),
            ),
            child: const Text('View More'),
          ),
        ),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> doc;

  const _TaskRow({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data()!;
    final timeStr = data['time']?.toString() ?? '';
    final plantNames = (data['plantNames'] as List?)?.join(', ') ?? 'N/A';
    final taskType = (data['taskType'] as String?) ?? 'watering';
    final taskDisplay =
        '${taskType[0].toUpperCase()}${taskType.substring(1)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              timeStr,
              style: const TextStyle(
                color: kDarkGreen,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              plantNames,
              style: const TextStyle(
                color: kDarkGreen,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              taskDisplay,
              style: const TextStyle(
                color: kDarkGreen,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}