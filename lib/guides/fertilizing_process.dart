import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login.dart';
import '../relatedVideos/related_videos.dart';
import '../widgets/app_drawer.dart';

const kDarkGreen = Color(0xFF004643);

class FertilizingProcess extends StatefulWidget {
  const FertilizingProcess({super.key});

  @override
  State<FertilizingProcess> createState() => _FertilizingProcessState();
}

class _FertilizingProcessState extends State<FertilizingProcess> {
  void _viewRelatedVideos() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RelatedVideosPage(
          category: VideoCategory.fertilizing,
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
    return Scaffold(
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
          'assets/fertilizingProcess/title/FertilizingProcessText.png',
          height: 35,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'Fertilizing Process',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: kDarkGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        centerTitle: true,
      ),
      drawer: const AppDrawer(currentPage: 'guides'),
      backgroundColor: Colors.white,

      // Same pattern as dry_season.dart - Padding + Column with SingleChildScrollView inside
      // Replace the entire body section in your fertilizing_process.dart

      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back (left) + View Related Videos (right) - SAME AS SEASONAL PLANTS
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
                      color: kDarkGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                SizedBox(
                  width: 210, // narrower pill - SAME AS SEASONAL PLANTS
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image 1
                    _buildImage('assets/fertilizingProcess/img/FirstImg.png'),
                    const SizedBox(height: 20),

                    // Step 1
                    _buildHeading('1.  Test Your Soil'),
                    _buildBullet('Start with a basic soil test to check pH and nutrient levels.'),
                    _buildBullet('This prevents nutrient imbalances and protects plants from over-fertilizing.'),
                    _buildBullet('In urban setups, this applies even to potted plants or raised beds.'),

                    const SizedBox(height: 16),

                    // Step 2
                    _buildHeading('2.  Prepare a Balanced Soil Mix'),
                    _buildBullet('Combine 3 parts loam, 1 part compost or manure, and 1 part rice hulls or coco peat.'),
                    _buildBullet('This ensures drainage, aeration, and nutrient retention for potted plants.'),
                    _buildBullet('For poor soils, add carbonized rice hulls (CRH) or vermicast.'),

                    const SizedBox(height: 24),

                    // Image 2
                    _buildImage('assets/fertilizingProcess/img/SecondImg.png'),
                    const SizedBox(height: 20),

                    // Step 3
                    _buildHeading('3.  Apply Base Fertilizer (Before Planting)'),
                    _buildBullet('Mix in organic fertilizers like:'),
                    _buildBullet('Decomposed manure', indent: 16),
                    _buildBullet('Fermented plant juice (FPJ)', indent: 16),
                    _buildBullet('Fish amino acid (FAA)', indent: 16),
                    _buildBullet('Eggshell vinegar (calcium phosphate)', indent: 16),
                    _buildBullet('Incorporate gently into the top 2–3 inches of soil 1–2 weeks before planting.'),

                    const SizedBox(height: 16),

                    // Step 4
                    _buildHeading('4.  Fertilize During Growth'),
                    _buildBullet('Once plants are established:'),
                    _buildBullet('Apply Compost Soil Extract (CSE): mix 4 tbsp per liter of water; apply ~900 mL near plant base weekly.', indent: 16),
                    _buildBullet('Use side-dressing: place a spoonful of organic fertilizer 2–3 inches from the stem; cover lightly.', indent: 16),

                    const SizedBox(height: 24),

                    // Image 3
                    _buildImage('assets/fertilizingProcess/img/ThirdImg.png'),
                    const SizedBox(height: 20),

                    // Step 5
                    _buildHeading('5.  Maintain & Boost with Natural Remedies'),
                    _buildBullet('Rotate fertilizing every 7–10 days, adjusting based on growth stage.'),
                    _buildBullet('Water early in the day to avoid leaf burn.'),
                    _buildBullet('Rotate container positions to ensure even sunlight and growth.'),
                    _buildBullet('Clean containers and tools regularly to avoid disease buildup.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widgets that return proper Widget types
  Widget _buildImage(String assetPath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Image.asset(
        assetPath,
        width: double.infinity,
        height: 210,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: double.infinity,
          height: 210,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Center(
            child: Icon(Icons.image_not_supported, size: 40, color: Color(0xFF9CA3AF)),
          ),
        ),
      ),
    );
  }

  Widget _buildHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildBullet(String text, {double indent = 0}) {
    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 4),
      child: Text(
        '• $text',
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          height: 1.4,
          color: Colors.black87,
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

  const _NavTile({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(color: selected ? kDarkGreen : Colors.transparent, borderRadius: BorderRadius.circular(6)),
        child: ListTile(
          leading: Icon(icon, color: selected ? Colors.white : kDarkGreen),
          title: Text(label, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: selected ? Colors.white : Colors.black87)),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}