import 'package:flutter/material.dart';
import '../auth/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import all dashboard widgets
import '../widgets/app_drawer.dart';
import '../widgets/dashboard_calendar.dart';
import '../widgets/dashboard_summary.dart';
import '../widgets/dashboard_my_plants_chart.dart';
import '../widgets/dashboard_finished_tasks.dart';
import '../widgets/dashboard_disease_history.dart';
import '../widgets/dashboard_todays_tasks.dart';
import '../widgets/dashboard_recent_activity.dart';

// Import disease scan service
import '../models/disease_scan.dart';

const kDarkGreen = Color(0xFF004643);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ImagePicker _picker = ImagePicker();

  final List<String> _apiKeys = [
    '1VGef4a4LHGWWhWyadfVeG7NasUP8KMxFaQVEPpz8qErDPJ6Fz',
    'fncHFHWV9S3NngGeM3WQiRtfAiv6YgKQecMaSb9jSlwVPxmEsN',
    'josigJMWLgsNpyNIGapuZZp8W48sjt9ZbuHEteBY81SV3xoTuR',
  ];

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
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  Future<String> _uploadToCloudinary(File file) async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];

    if (cloudName == null || uploadPreset == null) {
      throw Exception('Cloudinary env vars missing.');
    }

    final cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);

    final response = await cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        file.path,
        resourceType: CloudinaryResourceType.Image,
        folder: 'garden/disease_scans',
      ),
    );

    return response.secureUrl;
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

      // Upload to Cloudinary first
      final imageUrl = await _uploadToCloudinary(imageFile);

      // Analyze with Plant.id API
      final result = await _callPlantIdApi(imageFile);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (result != null) {
        // Save to Firestore
        await _saveScanToFirestore(result, imageUrl);

        // Show results
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

  Future<void> _saveScanToFirestore(
      Map<String, dynamic> result, String imageUrl) async {
    final healthAssessment = result['health_assessment'];
    if (healthAssessment == null) return;

    final isHealthy = (healthAssessment['is_healthy'] as bool?) ?? false;
    final healthyProbability =
        (healthAssessment['is_healthy_probability'] as num?)?.toDouble() ?? 0.0;
    final diseases = (healthAssessment['diseases'] as List<dynamic>?) ?? [];

    await DiseaseScanService.saveScan(
      imageUrl: imageUrl,
      isHealthy: isHealthy,
      healthyProbability: healthyProbability,
      diseases: diseases.cast<Map<String, dynamic>>(),
    );
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
    final isHealthyProbability =
        (healthAssessment['is_healthy_probability'] as num?)?.toDouble() ?? 0.0;
    final isPlant = (result['is_plant'] as bool?) ?? true;
    final isPlantProbability =
        (result['is_plant_probability'] as num?)?.toDouble() ?? 0.0;

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
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_hospital_outlined,
                        color: Colors.white),
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
                          color: isHealthy
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isHealthy
                                ? Colors.green
                                : Colors.red.shade400,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isHealthy
                                  ? Icons.check_circle
                                  : Icons.local_hospital,
                              color: isHealthy
                                  ? Colors.green
                                  : Colors.red.shade700,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isHealthy
                                        ? 'Plant is Healthy'
                                        : 'Health Issues Detected',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isHealthy
                                          ? Colors.green.shade800
                                          : Colors.red.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isHealthy
                                        ? 'Confidence: ${(isHealthyProbability * 100).toStringAsFixed(1)}%'
                                        : 'Needs attention - ${top3Diseases.length} issue(s) found',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isHealthy
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
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
                            Icon(Icons.medical_services_outlined,
                                color: kDarkGreen, size: 20),
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
                              Icon(Icons.grass,
                                  size: 48, color: Colors.green.shade300),
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
        title: Image.asset(
          'assets/DashboardText.png',
          height: 35,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'Gardening Guides',
            style: TextStyle(color: kDarkGreen, fontWeight: FontWeight.w800),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: kDarkGreen,
        elevation: 0,
      ),
      drawer: const AppDrawer(currentPage: 'dashboard'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // AI Disease Detector Button
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "Snap a photo of your plant and let our AI\ninstantly identify possible diseases or pest \nissues.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: greyText),
                ),
              ),
              const SizedBox(height: 50),

              // Calendar
              const DashboardCalendar(),
              const SizedBox(height: 24),

              // Summary
              const DashboardSummary(),
              const SizedBox(height: 24),

              // My Plants Chart
              const DashboardMyPlantsChart(),
              const SizedBox(height: 24),

              // Finished Tasks
              const DashboardFinishedTasks(),
              const SizedBox(height: 24),

              // Disease Detection History
              const DashboardDiseaseHistory(),
              const SizedBox(height: 24),

              // Today's Tasks
              const DashboardTodaysTasks(),
              const SizedBox(height: 24),

              // Recent Activity
              const DashboardRecentActivity(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
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

  const _DiseaseCard({required this.rank, required this.disease});

  @override
  State<_DiseaseCard> createState() => _DiseaseCardState();
}

class _DiseaseCardState extends State<_DiseaseCard> {
  @override
  Widget build(BuildContext context) {
    final name = widget.disease['name'] ?? 'Unknown Disease';
    final probability =
        (widget.disease['probability'] as num?)?.toDouble() ?? 0.0;
    final diseaseDetails = widget.disease['disease_details'];
    String description =
        diseaseDetails?['description'] ?? 'No description available';
    final commonNames =
        (diseaseDetails?['common_names'] as List<dynamic>?)?.join(', ') ?? '';

    final rankColors = [Colors.red, Colors.orange, Colors.amber];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: rankColors[widget.rank - 1].withOpacity(0.3), width: 1.5),
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
          tilePadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          initiallyExpanded: widget.rank == 1,
          leading: CircleAvatar(
            backgroundColor: rankColors[widget.rank - 1],
            child: Text('${widget.rank}',
                style: const TextStyle(color: Colors.white)),
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
              if (commonNames.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(commonNames,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      )),
                ),
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
                            rankColors[widget.rank - 1]),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                description,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade800, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}