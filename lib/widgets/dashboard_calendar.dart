import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const kDarkGreen = Color(0xFF004643);

enum TaskType { watering, fertilizing, pruning }

Color taskColor(TaskType t) {
  switch (t) {
    case TaskType.watering:
      return const Color(0xFF31A8FF); // blue
    case TaskType.fertilizing:
      return const Color(0xFF22C55E); // green
    case TaskType.pruning:
      return const Color(0xFFF59E0B); // orange
  }
}

class DashboardCalendar extends StatefulWidget {
  const DashboardCalendar({super.key});

  @override
  State<DashboardCalendar> createState() => _DashboardCalendarState();
}

class _DashboardCalendarState extends State<DashboardCalendar>
    with SingleTickerProviderStateMixin {
  bool _showCalendar = false;
  late final AnimationController _controller;
  late final Animation<Offset> _slideDown;

  DateTime _monthAnchor = DateTime(DateTime.now().year, DateTime.now().month);

  DateTime get _firstDay => DateTime(_monthAnchor.year, _monthAnchor.month, 1);
  DateTime get _lastDay =>
      DateTime(_monthAnchor.year, _monthAnchor.month + 1, 0, 23, 59, 59, 999);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _slideDown = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCalendar() {
    setState(() => _showCalendar = !_showCalendar);
    if (_showCalendar) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _prevMonth() => setState(
          () => _monthAnchor = DateTime(_monthAnchor.year, _monthAnchor.month - 1));

  void _nextMonth() => setState(
          () => _monthAnchor = DateTime(_monthAnchor.year, _monthAnchor.month + 1));

  Stream<QuerySnapshot<Map<String, dynamic>>> _monthTasksStream() {
    return FirebaseFirestore.instance
        .collection('scheduledTasks')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_firstDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_lastDay))
        .orderBy('date')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = _formatDate(now);
    final timeStr = _formatTime(now);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _monthTasksStream(),
      builder: (context, snap) {
        // Build day -> color map
        final markers = <int, Color>{};
        final latestCreated = <int, Timestamp>{};

        if (snap.hasData) {
          for (final doc in snap.data!.docs) {
            final data = doc.data();
            final ts = data['date'];
            if (ts is! Timestamp) continue;

            final day = ts.toDate().day;
            final typeStr = (data['taskType'] as String?) ?? 'watering';
            final ttype = _parseTaskType(typeStr);
            final color = taskColor(ttype);

            final created = data['createdAt'];
            final createdTs = created is Timestamp ? created : null;

            if (createdTs != null) {
              if (latestCreated[day] == null ||
                  createdTs.compareTo(latestCreated[day]!) > 0) {
                latestCreated[day] = createdTs;
                markers[day] = color;
              }
            } else {
              markers[day] = color;
            }
          }
        }

        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: kDarkGreen, width: 1.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 14, left: 16, right: 16, bottom: 10),
                      child: Column(
                        children: [
                          Text(
                            dateStr,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: kDarkGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeStr,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: kDarkGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 10, color: kDarkGreen),
                    InkWell(
                      onTap: _toggleCalendar,
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: kDarkGreen,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x3300C853),
                              offset: Offset(0, 3),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: Text(
                          _showCalendar ? 'Hide Calendar' : 'View Calendar',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              clipBehavior: Clip.hardEdge,
              child: _showCalendar
                  ? SlideTransition(
                position: _slideDown,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _CalendarPanel(
                    monthAnchor: _monthAnchor,
                    onPrev: _prevMonth,
                    onNext: _nextMonth,
                    markers: markers,
                  ),
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
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

  String _formatDate(DateTime d) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatTime(DateTime d) {
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    final ap = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }
}

class _CalendarPanel extends StatelessWidget {
  final DateTime monthAnchor;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final Map<int, Color> markers;

  const _CalendarPanel({
    required this.monthAnchor,
    required this.onPrev,
    required this.onNext,
    required this.markers,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(monthAnchor.year, monthAnchor.month, 1);
    final daysInMonth =
        DateTime(monthAnchor.year, monthAnchor.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;

    String monthName(int m) => const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ][m - 1];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                  onPressed: onPrev,
                  icon: const Icon(Icons.chevron_left, color: kDarkGreen)),
              Expanded(
                child: Text(
                  '${monthName(monthAnchor.month)} ${monthAnchor.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: kDarkGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right, color: kDarkGreen)),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            children: [
              ...['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'].map(
                    (d) => Center(
                  child: Text(d,
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 12)),
                ),
              ),
              ...List.generate(startWeekday, (i) => const SizedBox()),
              ...List.generate(daysInMonth, (i) {
                final day = i + 1;
                final dotColor = markers[day];
                final isToday = day == DateTime.now().day &&
                    monthAnchor.month == DateTime.now().month &&
                    monthAnchor.year == DateTime.now().year;

                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isToday ? kDarkGreen.withOpacity(0.1) : null,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          color: kDarkGreen,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (dotColor != null)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
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
    );
  }
}