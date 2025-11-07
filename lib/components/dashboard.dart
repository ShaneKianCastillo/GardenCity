import 'package:flutter/material.dart';
import 'login.dart';
import 'package:firebase_auth/firebase_auth.dart';

const kDarkGreen = Color(0xFF004643);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  bool _showCalendar = false;
  late final AnimationController _controller;
  late final Animation<Offset> _slideDown;

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

  void _openAIDetectorOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Upload Photo'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Upload Photo chosen')),
                );
                // TODO: implement gallery pick
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Take Photo chosen')),
                );
                // TODO: implement camera capture
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final greyText = const Color(0xFF6B7280);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: kDarkGreen,
        elevation: 0,
      ),
      drawer: Drawer(
        width: 280,
        child: SafeArea(
          child: Stack(
            children: [
              // Drawer content
              ListView(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Header with logo + wordmark
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset('assets/GardenCityLogo.png',
                            width: 44, height: 44),
                        const SizedBox(width: 10),
                        Image.asset('assets/GardenCityText.png', height: 22),
                      ],
                    ),
                  ),
                  // Menu items
                  _NavTile(
                    label: 'My Garden',
                    icon: Icons.local_florist_outlined,
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: push My Garden page
                    },
                  ),
                  _NavTile(
                    label: 'Guides',
                    icon: Icons.menu_book_outlined,
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: push Guides page
                    },
                  ),
                  _NavTile(
                    label: 'Schedules',
                    icon: Icons.event_outlined,
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: push Schedules page
                    },
                  ),
                  _NavTile(
                    label: 'Dashboard',
                    icon: Icons.dashboard_outlined,
                    selected: true, // current page highlighted
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  // Logout
                  _NavTile(
                    label: 'Logout',
                    icon: Icons.logout,
                    selected: false,
                    onTap: () async {
                      // sign out then go to LoginPage, clearing history
                      try {
                        await FirebaseAuth.instance.signOut();
                      } catch (_) {}
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                            (route) => false,
                      );
                    },
                  ),
                ],
              ),
              // Close (X) button at the right side of drawer
              Positioned(
                top: 8,
                right: -6, // peeks into the scrim a bit
                child: IconButton(
                  icon: const Icon(Icons.close, color: kDarkGreen, size: 28),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // AI Disease Detector image as a button
              GestureDetector(
                onTap: _openAIDetectorOptions,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: kDarkGreen.withOpacity(0.15),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/AIDiseaseDetectorButton.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Tagline
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "Snap a photo of your plant and let our AI\ninstantly identify possible diseases or pest \nissues.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: greyText),
                ),
              ),
              const SizedBox(height: 50),
              // Date card + View Calendar button
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
                      // Top: date + time on white
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 14, left: 16, right: 16, bottom: 10),
                        child: Column(
                          children: const [
                            Text(
                              'August 20, 2025',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: kDarkGreen,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '08:00 AM',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: kDarkGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Thin dark divider
                      Container(height: 10, color: kDarkGreen),
                      // Bottom: button
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
              // Slide-down calendar panel
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                clipBehavior: Clip.hardEdge,
                child: _showCalendar
                    ? SlideTransition(
                  position: _slideDown,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _CalendarPanel(),
                  ),
                )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 14),
              // Summary section
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
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
              // Four stat cards
              Wrap(
                runSpacing: 12,
                spacing: 12,
                children: [
                  _StatCard(
                      icon: Icons.yard_outlined,
                      title: 'Total Plants',
                      value: '6'),
                  _StatCard(
                      icon: Icons.task_alt_outlined,
                      title: 'Task Completed',
                      value: '2'),
                  _StatCard(
                      icon: Icons.sick_outlined,
                      title: 'Infected Plants',
                      value: '2'),
                  const _NextTaskCard(),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

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

class _NextTaskCard extends StatelessWidget {
  const _NextTaskCard();

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
          children: const [
            Icon(Icons.event_note_outlined, color: kDarkGreen),
            SizedBox(height: 6),
            Text(
              'Next Task',
              style:
              TextStyle(color: kDarkGreen, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 2),
            Text(
              '9:00 AM Fertilize Lettuce',
              textAlign: TextAlign.center,
              style: TextStyle(color: kDarkGreen),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarPanel extends StatelessWidget {
  _CalendarPanel({Key? key}) : super(key: key);

  final DateTime _now = DateTime.now();

  List<Widget> _buildWeekdayHeaders(TextStyle? style) {
    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return names.map((n) => Center(child: Text(n, style: style))).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstDayOfMonth = DateTime(_now.year, _now.month, 1);
    final daysInMonth = DateTime(_now.year, _now.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7;
    final totalCells = startWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

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
          Text(
            '${_monthName(_now.month)} ${_now.year}',
            style: const TextStyle(
              color: kDarkGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            children: [
              ..._buildWeekdayHeaders(
                theme.textTheme.labelMedium
                    ?.copyWith(color: const Color(0xFF6B7280)),
              ),
              ...List.generate(startWeekday, (i) => const SizedBox()),
              ...List.generate(daysInMonth, (i) {
                final day = i + 1;
                final isToday = day == _now.day;
                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isToday ? kDarkGreen.withOpacity(0.1) : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: kDarkGreen,
                        fontWeight:
                        isToday ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
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
    return months[m - 1];
  }
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
    final tile = Container(
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        onTap: onTap,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: tile,
    );
  }
}
