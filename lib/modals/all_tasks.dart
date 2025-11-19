import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/schedule_page.dart'; // TaskType + colors + kDarkGreen
import 'task_setting.dart';               // <— to open editor
import '../notifications/local_notifs.dart';

const kDarkGreen = Color(0xFF004643);
class AllTasks extends StatefulWidget {
  const AllTasks({super.key});
  @override
  State<AllTasks> createState() => _AllTasksState();
}

class _AllTasksState extends State<AllTasks> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Text('Please log in to view tasks', style: TextStyle(color: Colors.red)),
        ),
      );
    }

    final q = FirebaseFirestore.instance
        .collection('scheduledTasks')
        .where('userId', isEqualTo: currentUser.uid);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(
            children: [
              Row(
                children: [
                  const Spacer(),
                  Image.asset(
                    'assets/titles/AllTasksLabel.png',
                    height: 35,
                    errorBuilder: (_, __, ___) => const Text(
                      'Tasks',
                      style: TextStyle(color: kDarkGreen, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: kDarkGreen),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: q.snapshots(),
                  builder: (ctx, snap) {
                    if (snap.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Failed to load tasks:\n${snap.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    }
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator(color: kDarkGreen));
                    }

                    final docs = snap.data!.docs;

                    List<QueryDocumentSnapshot<Map<String, dynamic>>> group(String type) =>
                        docs.where((d) => (d.data()['taskType'] as String?) == type).toList();

                    return Scrollbar(
                      thumbVisibility: true,
                      child: ListView(
                        children: [
                          _TaskSection(
                            title: 'Watering',
                            color: taskColor(TaskType.watering),
                            items: group('watering'),
                          ),
                          _TaskSection(
                            title: 'Fertilizing',
                            color: taskColor(TaskType.fertilizing),
                            items: group('fertilizing'),
                          ),
                          _TaskSection(
                            title: 'Pruning',
                            color: taskColor(TaskType.pruning),
                            items: group('pruning'),
                          ),
                          if (docs.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text('No tasks yet.', style: TextStyle(color: kDarkGreen)),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> items;

  const _TaskSection({
    required this.title,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
      children: [
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 10),
            child: Text('No $title tasks', style: const TextStyle(color: Color(0xFF6B7280))),
          )
        else
          ...items.map((d) {
            final data = d.data();

            final namesList = (data['plantNames'] is List)
                ? List<String>.from(data['plantNames'] as List)
                : const <String>[];
            final names = namesList.join(', ');

            final ts = data['date'] as Timestamp?;
            final when = ts != null ? _fmt(ts.toDate()) : '';
            final time = data['time']?.toString() ?? '';

            final endRaw = data['endDate'];
            String? endStr;
            if (endRaw is Timestamp) {
              endStr = _fmt(endRaw.toDate());
            } else if (endRaw is String && endRaw.trim().isNotEmpty) {
              endStr = endRaw;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_florist, color: color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          names.isEmpty ? 'Unnamed plant' : names,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                      // EDIT
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined, size: 20, color: kDarkGreen),
                        onPressed: () async {
                          await showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (_) => TaskSetting(
                              editDocId: d.id,
                              existing: data, // pass whole map for prefill
                            ),
                          );
                        },
                      ),
                      // DELETE
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFAA2E25)),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete task?'),
                              content: const Text('This will remove the task and cancel all scheduled notifications.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFAA2E25)),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ) ?? false;
                          if (!ok) return;

                          // Show loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(child: CircularProgressIndicator(color: kDarkGreen)),
                          );

                          try {
                            // 1) Cancel any scheduled local notifications for this task
                            final ids = (data['notificationIds'] as List?)?.cast<int>() ?? const <int>[];
                            if (ids.isNotEmpty) {
                              await LocalNotifs.instance.cancelIds(ids);
                            }

                            // 2) Delete the task document
                            await FirebaseFirestore.instance
                                .collection('scheduledTasks')
                                .doc(d.id)
                                .delete();

                            if (context.mounted) {
                              Navigator.pop(context); // loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Task deleted and notifications cancelled')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context); // loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Delete failed: $e')),
                              );
                            }
                          }
                        },
                      ),

                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Time: $time — $when', style: const TextStyle(color: Color(0xFF6B7280))),
                  if (endStr != null)
                    Text('End Date: $endStr', style: const TextStyle(color: Color(0xFFEF4444))),
                  const Divider(height: 18),
                ],
              ),
            );
          }),
      ],
    );
  }

  String _fmt(DateTime d) {
    const m = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }
}