import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../modals/task_setting.dart';
import '../modals/all_tasks.dart';
import '../auth/login.dart';
import '../widgets/app_drawer.dart';

const kDarkGreen = Color(0xFF004643);

enum TaskType { watering, fertilizing, pruning }

Color taskColor(TaskType t) {
  switch (t) {
    case TaskType.watering:
      return const Color(0xFF31A8FF); // blue-ish
    case TaskType.fertilizing:
      return const Color(0xFF22C55E); // green
    case TaskType.pruning:
      return const Color(0xFFF59E0B); // orange
  }
}

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime _monthAnchor = DateTime(DateTime.now().year, DateTime.now().month);

  DateTime get _firstDay => DateTime(_monthAnchor.year, _monthAnchor.month, 1);
  DateTime get _lastDay => DateTime(_monthAnchor.year, _monthAnchor.month + 1, 0, 23, 59, 59, 999);

  /// Query tasks in this month filtered by userId
  Stream<QuerySnapshot<Map<String, dynamic>>> _monthTasksStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    // Simplified query - filter only by userId, then filter dates in memory
    return FirebaseFirestore.instance
        .collection('scheduledTasks')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots();
  }

  void _prevMonth() =>
      setState(() => _monthAnchor = DateTime(_monthAnchor.year, _monthAnchor.month - 1));
  void _nextMonth() =>
      setState(() => _monthAnchor = DateTime(_monthAnchor.year, _monthAnchor.month + 1));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: kDarkGreen),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Image.asset(
          'assets/titles/ScheduleTitle.png',
          height: 35,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'Schedules',
            style: TextStyle(color: kDarkGreen, fontWeight: FontWeight.w800),
          ),
        ),
        centerTitle: true,
        foregroundColor: kDarkGreen,
      ),
      drawer: const AppDrawer(currentPage: 'schedule'),

      backgroundColor: Colors.white,

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _monthTasksStream(),
        builder: (context, snap) {
          // Build day -> color map (latest createdAt wins if present)
          final markers = <int, Color>{};
          final latestCreated = <int, Timestamp>{};

          if (snap.hasData) {
            // Filter docs by date range in memory
            final filteredDocs = snap.data!.docs.where((doc) {
              final data = doc.data();
              final ts = data['date'];
              if (ts is! Timestamp) return false;
              final taskDate = ts.toDate();
              return taskDate.isAfter(_firstDay.subtract(const Duration(seconds: 1))) &&
                  taskDate.isBefore(_lastDay.add(const Duration(seconds: 1)));
            }).toList();

            for (final doc in filteredDocs) {
              final data = doc.data();
              final ts = data['date'];
              if (ts is! Timestamp) continue;
              final day = ts.toDate().day;

              final typeStr = (data['taskType'] as String?) ?? 'watering';
              final ttype = _parseTaskType(typeStr);
              final color = taskColor(ttype);

              final created = data['createdAt'];
              final createdTs = created is Timestamp ? created : null;

              // choose the latest by createdAt for that day
              if (createdTs != null) {
                if (latestCreated[day] == null || createdTs.compareTo(latestCreated[day]!) > 0) {
                  latestCreated[day] = createdTs;
                  markers[day] = color;
                }
              } else {
                // if no createdAt, just overwrite (last iterated wins)
                markers[day] = color;
              }
            }
          }

          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load month: ${snap.error}',
                    textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            child: Column(
              children: [
                _CalendarCard(
                  monthAnchor: _monthAnchor,
                  onPrev: _prevMonth,
                  onNext: _nextMonth,
                  markers: markers,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit_calendar),
                    label: const Text('ADD TASK'),
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (_) => const TaskSetting(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    'assets/titles/TodayTaskLabel.png',
                    height: 30,
                    errorBuilder: (_, __, ___) => const Text(
                      'Scheduled Task for Today',
                      style: TextStyle(color: kDarkGreen, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const _TodayTasksList(), // shows ONLY today's tasks
              ],
            ),
          );
        },
      ),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.list_alt_outlined),
            label: const Text('VIEW ALL TASK'),
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (_) => const AllTasks(),
              );
            },
          ),
        ),
      ),
    );
  }

  TaskType _parseTaskType(String s) {
    switch (s) {
      case 'fertilizing':
        return TaskType.fertilizing;
      case 'pruning':
        return TaskType.pruning;
      default:
        return TaskType.watering;
    }
  }
}

class _CalendarCard extends StatelessWidget {
  final DateTime monthAnchor;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final Map<int, Color> markers; // day -> color

  const _CalendarCard({
    required this.monthAnchor,
    required this.onPrev,
    required this.onNext,
    required this.markers,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(monthAnchor.year, monthAnchor.month, 1);
    final daysInMonth = DateTime(monthAnchor.year, monthAnchor.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;

    String _monthName(int m) => const [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ][m - 1];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: Text(
                    '${_monthName(monthAnchor.month)} ${monthAnchor.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: kDarkGreen, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
              ],
            ),
            const SizedBox(height: 6),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              children: [
                ...['SUN','MON','TUE','WED','THU','FRI','SAT'].map(
                      (d) => Center(
                    child: Text(d, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                  ),
                ),
                ...List.generate(startWeekday, (i) => const SizedBox()),
                ...List.generate(daysInMonth, (i) {
                  final day = i + 1;
                  final dotColor = markers[day];
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text('$day', style: const TextStyle(color: kDarkGreen)),
                        if (dotColor != null)
                          Positioned(
                            bottom: 4,
                            child: Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayTasksList extends StatelessWidget {
  const _TodayTasksList();

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Text('Please log in', style: TextStyle(color: Colors.red));
    }

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

    // Simplified query - just filter by userId
    final q = FirebaseFirestore.instance
        .collection('scheduledTasks')
        .where('userId', isEqualTo: currentUser.uid);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: LinearProgressIndicator(color: kDarkGreen),
          );
        }

        // Filter docs by today's date in memory
        final todayDocs = snap.data!.docs.where((d) {
          final ts = d['date'];
          if (ts is! Timestamp) return false;
          final taskDate = ts.toDate();
          return taskDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
              taskDate.isBefore(end.add(const Duration(seconds: 1)));
        }).toList();

        if (todayDocs.isEmpty) {
          return const Text('None', style: TextStyle(color: kDarkGreen));
        }
        return Column(
          children: todayDocs.map((d) {
            final names = (d['plantNames'] is List) ? (d['plantNames'] as List).join(', ') : '';
            final type = (d['taskType'] as String?) ?? 'watering';
            final t = d['time']?.toString() ?? '';
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.circle, color: taskColor(_tt(type)), size: 12),
              title: Text('$names • ${type[0].toUpperCase()}${type.substring(1)}'),
              subtitle: Text(t),
            );
          }).toList(),
        );
      },
    );
  }

  TaskType _tt(String s) =>
      s == 'fertilizing' ? TaskType.fertilizing
          : s == 'pruning' ? TaskType.pruning
          : TaskType.watering;
}

class _NavTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? kDarkGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: ListTile(
          leading: Icon(icon, color: selected ? Colors.white : kDarkGreen),
          title: Text(
            label,
            style: base?.copyWith(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}