import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login.dart';
import '../relatedVideos/related_videos.dart';
import '../widgets/app_drawer.dart';

const kDarkGreen = Color(0xFF004643);

class PlantingProcess extends StatefulWidget {
  const PlantingProcess({super.key});

  @override
  State<PlantingProcess> createState() => _PlantingProcessState();
}

class _PlantingProcessState extends State<PlantingProcess> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _viewRelatedVideos() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RelatedVideosPage(
          category: VideoCategory.planting,
        ),
      ),
    );
  }

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const headingStyle = TextStyle(
      fontFamily: 'Poppins',
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: Colors.black,
    );

    const bulletStyle = TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      height: 1.4,
      color: Colors.black87,
    );

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
          'assets/plantingProcess/title/PlantingProcessText.png',
          height: 35,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'Planting Process',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: kDarkGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        centerTitle: true,
        foregroundColor: kDarkGreen,
      ),
      drawer: const AppDrawer(currentPage: 'guides'),
      backgroundColor: Colors.white,

      // >>> same layout approach as FertilizingProcess <<<
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back (left) + View Related Videos (right, fixed width)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _goBack,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: kDarkGreen,
                  ),
                  label: const Text(
                    'Back',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: kDarkGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                SizedBox(
                  width: 210, // same pill width as FertilizingProcess
                  child: ElevatedButton.icon(
                    onPressed: _viewRelatedVideos,
                    icon: const Icon(Icons.ondemand_video, size: 18),
                    label: const Text(
                      'View Related Videos',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kDarkGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/plantingProcess/img/FirstPhoto.png',
                        width: double.infinity,
                        height: 210,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 210,
                          width: double.infinity,
                          color: Colors.grey.shade300,
                          alignment: Alignment.center,
                          child: const Text('First image missing'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Step 1
                    const Text('1. Soil Preparation', style: headingStyle),
                    const SizedBox(height: 4),
                    const Text(
                      '• Loosen the soil, remove weeds, and mix in compost or fertilizer '
                          'to enrich it and improve drainage.',
                      style: bulletStyle,
                    ),

                    const SizedBox(height: 16),

                    // Step 2
                    const Text('2. Seed or Seedling Selection',
                        style: headingStyle),
                    const SizedBox(height: 4),
                    const Text(
                      '• Choose healthy seeds or strong seedlings that suit the climate '
                          'and season.',
                      style: bulletStyle,
                    ),

                    const SizedBox(height: 24),

                    // Second image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/plantingProcess/img/SecondPhoto.png',
                        width: double.infinity,
                        height: 210,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 210,
                          width: double.infinity,
                          color: Colors.grey.shade300,
                          alignment: Alignment.center,
                          child: const Text('Second image missing'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Step 3
                    const Text('3. Planting', style: headingStyle),
                    const SizedBox(height: 4),
                    const Text(
                      '• Use a planting method that fits your crop (e.g., direct seeding, '
                          'transplanting, row planting).\n'
                          '• Follow recommended spacing and depth.',
                      style: bulletStyle,
                    ),

                    const SizedBox(height: 16),

                    // Step 4
                    const Text('4. Watering', style: headingStyle),
                    const SizedBox(height: 4),
                    const Text(
                      '• Water the soil immediately after planting to help seeds or roots settle.\n'
                          '• Maintain consistent moisture as needed.',
                      style: bulletStyle,
                    ),
                  ],
                ),
              ),
            ),
          ],
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
              fontFamily: 'Poppins',
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
