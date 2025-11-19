import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login.dart';
import '../relatedVideos/related_videos.dart';
import '../widgets/app_drawer.dart';

const kDarkGreen = Color(0xFF004643);

class PruningProcess extends StatefulWidget {
  const PruningProcess({super.key});

  @override
  State<PruningProcess> createState() => _PruningProcessState();
}

class _PruningProcessState extends State<PruningProcess> {
  void _viewRelatedVideos() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RelatedVideosPage(
          category: VideoCategory.pruning,
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
          'assets/pruningProcess/title/PruningProcessText.png',
          height: 35,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'Pruning Process',
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

      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back + View Related Videos (same layout as fertilizing)
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
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                SizedBox(
                  width: 210, // same pill width as fertilizing page
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
                    // Image 1
                    _buildImage(
                      'assets/pruningProcess/img/FirstPruningImg.png',
                    ),
                    const SizedBox(height: 20),

                    // 1. Inspect & Plan
                    _buildHeading('1. Inspect & Plan'),
                    _buildBullet(
                        'Carefully examine each plant: look for dead/diseased leaves and stems, crossing branches, or signs of legginess.'),
                    _buildBullet(
                        'Visualize the desired shape — don’t prune without intent.'),

                    const SizedBox(height: 16),

                    // 2. Use Clean, Sharp Tools
                    _buildHeading('2. Use Clean, Sharp Tools'),
                    _buildBullet(
                        'Use pruning shears or scissors depending on stem thickness.'),
                    _buildBullet(
                        'Sterilize tools (e.g., 70% alcohol) to avoid disease spread.'),

                    const SizedBox(height: 16),

                    // 3. Remove Dead & Disease Growth
                    _buildHeading('3. Remove Dead & Disease Growth'),
                    _buildBullet(
                        'Cut away dead, yellow, or diseased leaves/stems first.'),
                    _buildBullet(
                        'Make cuts at a 45° angle near a bud, node, or branch union (“branch collar”).'),

                    const SizedBox(height: 24),

                    // Image 2
                    _buildImage(
                      'assets/pruningProcess/img/SecondPruningImg.png',
                    ),
                    const SizedBox(height: 20),

                    // 4. Trim Leggy Stems for Shape
                    _buildHeading('4. Trim Leggy Stems for Shape'),
                    _buildBullet(
                        'Shorten long, thin stems just above a bud to encourage fuller growth.'),
                    _buildBullet(
                        'For container plants, shaping helps maintain compact structure and airflow.'),

                    const SizedBox(height: 16),

                    // 5. Deadhead Spent Blooms
                    _buildHeading('5. Deadhead Spent Blooms'),
                    _buildBullet(
                        'For flowering plants, remove spent blooms to direct energy toward new growth.'),
                    _buildBullet(
                        'Cut above a leaf pair or node.'),

                    const SizedBox(height: 16),

                    // 6. Thin Out Crossed or Crowded Branches
                    _buildHeading(
                        '6. Thin Out Crossed or Crowded Branches'),
                    _buildBullet(
                        'Remove branches that are crossing or rubbing together to reduce disease risk and improve light/air exposure.'),

                    const SizedBox(height: 16),

                    // 7. Final Shaping & Cleanup
                    _buildHeading('7. Final Shaping & Cleanup'),
                    _buildBullet(
                        'Step back and check overall form; touch up any long or uneven growth.'),
                    _buildBullet('Disinfect tools after use.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helpers --------------------------------------------------------

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
            child: Icon(
              Icons.image_not_supported,
              size: 40,
              color: Color(0xFF9CA3AF),
            ),
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

  const _NavTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}
