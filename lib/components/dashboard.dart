import 'package:flutter/material.dart';
import 'login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

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
  final ImagePicker _picker = ImagePicker();

  final List<String> _apiKeys = [
    '1VGef4a4LHGWWhWyadfVeG7NasUP8KMxFaQVEPpz8qErDPJ6Fz',
    'YOUR_SECOND_API_KEY',
    'YOUR_THIRD_API_KEY',
  ];

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

  Future<Map<String, dynamic>?> _callPlantIdApi(File imageFile) async {
    for (int i = 0; i < _apiKeys.length; i++) {
      try {
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        final response = await http.post(
          Uri.parse('https://api.plant.id/v2/health_assessment'),
          headers: {
            'Content-Type': 'application/json',
            'Api-Key': _apiKeys[i],
          },
          body: jsonEncode({
            'images': [base64Image],
            'modifiers': ['crops_fast', 'similar_images'],
            'disease_details': [
              'cause',
              'common_names',
              'classification',
              'description',
              'treatment',
            ],
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return jsonDecode(response.body);
        }
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  Future<void> _processPlantImage(XFile? pickedFile) async {
    if (pickedFile == null) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(pickedFile.path),
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(color: kDarkGreen),
              const SizedBox(height: 12),
              const Text('Analyzing plant...'),
            ],
          ),
        ),
      ),
    );

    try {
      final imageFile = File(pickedFile.path);
      final result = await _callPlantIdApi(imageFile);

      if (!mounted) return;
      Navigator.pop(context);

      if (result != null) {
        _showPlantIdResults(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All API keys failed. Please check your keys.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showPlantIdResults(Map<String, dynamic> result) {
    final healthAssessment = result['health_assessment'];
    if (healthAssessment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No health assessment data found')),
      );
      return;
    }

    final diseases = healthAssessment['diseases'] as List<dynamic>? ?? [];
    final isHealthy = (healthAssessment['is_healthy'] as bool?) ?? false;
    final isHealthyProbability = (healthAssessment['is_healthy_probability'] as num?)?.toDouble() ?? 0.0;
    final isPlant = (result['is_plant'] as bool?) ?? true;
    final isPlantProbability = (result['is_plant_probability'] as num?)?.toDouble() ?? 0.0;

    if (!isPlant || isPlantProbability < 0.5) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Not a Plant'),
            ],
          ),
          content: Text(
            'The image does not appear to be a plant (${(isPlantProbability * 100).toStringAsFixed(1)}% confidence). Please try again with a clear photo of a plant.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final top3Diseases = diseases.take(3).toList();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: kDarkGreen,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_hospital_outlined, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Plant Health Report',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isHealthy ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isHealthy ? Colors.green : Colors.red.shade400,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isHealthy ? Icons.check_circle : Icons.local_hospital,
                              color: isHealthy ? Colors.green : Colors.red.shade700,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isHealthy ? 'Plant is Healthy' : 'Health Issues Detected',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isHealthy ? Colors.green.shade800 : Colors.red.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isHealthy 
                                        ? 'Confidence: ${(isHealthyProbability * 100).toStringAsFixed(1)}%'
                                        : 'Needs attention - ${top3Diseases.length} issue(s) found',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isHealthy ? Colors.green.shade700 : Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (top3Diseases.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Row(
                          children: [
                            Icon(Icons.medical_services_outlined, color: kDarkGreen, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Detected Issues & Remedies',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kDarkGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...top3Diseases.asMap().entries.map((entry) {
                          final index = entry.key;
                          final disease = entry.value;
                          return _DiseaseCard(
                            rank: index + 1,
                            disease: disease,
                          );
                        }).toList(),
                      ] else ...[
                        const SizedBox(height: 24),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.grass, size: 48, color: Colors.green.shade300),
                              const SizedBox(height: 12),
                              Text(
                                'No diseases detected',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                _processPlantImage(image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                _processPlantImage(image);
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

class _DiseaseCard extends StatefulWidget {
  final int rank;
  final Map<String, dynamic> disease;

  const _DiseaseCard({
    required this.rank,
    required this.disease,
  });

  @override
  State<_DiseaseCard> createState() => _DiseaseCardState();
}

class _DiseaseCardState extends State<_DiseaseCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.disease['name'] ?? 'Unknown Disease';
    final probability = (widget.disease['probability'] as num?)?.toDouble() ?? 0.0;
    final diseaseDetails = widget.disease['disease_details'];
    
    String description = 'No description available';
    List<String> treatments = [];
    String cause = '';
    
    if (diseaseDetails != null) {
      description = diseaseDetails['description'] ?? description;
      cause = diseaseDetails['cause'] ?? '';
      
      final treatmentData = diseaseDetails['treatment'];
      if (treatmentData != null) {
        if (treatmentData is Map) {
          if (treatmentData.containsKey('chemical')) {
            final chemical = treatmentData['chemical'];
            if (chemical is List) {
              treatments.addAll(chemical.map((e) => 'Chemical: $e').toList().cast<String>());
            } else if (chemical is String && chemical.isNotEmpty) {
              treatments.add('Chemical: $chemical');
            }
          }
          if (treatmentData.containsKey('biological')) {
            final biological = treatmentData['biological'];
            if (biological is List) {
              treatments.addAll(biological.map((e) => 'Biological: $e').toList().cast<String>());
            } else if (biological is String && biological.isNotEmpty) {
              treatments.add('Biological: $biological');
            }
          }
          if (treatmentData.containsKey('prevention')) {
            final prevention = treatmentData['prevention'];
            if (prevention is List) {
              treatments.addAll(prevention.map((e) => 'Prevention: $e').toList().cast<String>());
            } else if (prevention is String && prevention.isNotEmpty) {
              treatments.add('Prevention: $prevention');
            }
          }
        } else if (treatmentData is List) {
          treatments.addAll(treatmentData.map((e) => e.toString()).toList().cast<String>());
        } else if (treatmentData is String && treatmentData.isNotEmpty) {
          treatments.add(treatmentData);
        }
      }
    }
    
    final commonNames = (diseaseDetails?['common_names'] as List<dynamic>?)?.join(', ') ?? '';

    final rankColors = [
      Colors.red,
      Colors.orange,
      Colors.amber,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rankColors[widget.rank - 1].withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: rankColors[widget.rank - 1].withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          initiallyExpanded: widget.rank == 1,
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
          },
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  rankColors[widget.rank - 1],
                  rankColors[widget.rank - 1].withOpacity(0.7),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: rankColors[widget.rank - 1].withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${widget.rank}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          title: Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: rankColors[widget.rank - 1].shade800,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (commonNames.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  commonNames,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: probability,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          rankColors[widget.rank - 1],
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: rankColors[widget.rank - 1].withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(probability * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: rankColors[widget.rank - 1].shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: rankColors[widget.rank - 1].withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cause.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.science_outlined, size: 18, color: rankColors[widget.rank - 1]),
                        const SizedBox(width: 8),
                        const Text(
                          'Cause',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: kDarkGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cause,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.description_outlined, size: 18, color: rankColors[widget.rank - 1]),
                      const SizedBox(width: 8),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: kDarkGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                      height: 1.5,
                    ),
                  ),
                  if (treatments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.healing, size: 18, color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Remedies & Treatment',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...treatments.map((treatment) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade600,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      treatment,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade800,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No specific treatment information available. Consult a plant specialist.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
