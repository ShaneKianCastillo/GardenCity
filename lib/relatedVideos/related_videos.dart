import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login.dart';

const kDarkGreen = Color(0xFF004643);

enum VideoCategory {
  fertilizing,
  planting,
  pruning,
  seasonal,
}

class RelatedVideo {
  final String title;
  final String description;
  final String youtubeUrl;
  final String thumbnailAsset;

  const RelatedVideo({
    required this.title,
    required this.description,
    required this.youtubeUrl,
    required this.thumbnailAsset,
  });
}

class RelatedVideosPage extends StatefulWidget {
  final VideoCategory category;

  const RelatedVideosPage({
    super.key,
    required this.category,
  });

  @override
  State<RelatedVideosPage> createState() => _RelatedVideosPageState();
}

class _RelatedVideosPageState extends State<RelatedVideosPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Video data for each category
  static const Map<VideoCategory, List<RelatedVideo>> _videoData = {
    VideoCategory.fertilizing: [
      RelatedVideo(
        title: 'Understanding Fertilizer Numbers',
        description:
        'In this video we are going to show you how to figure out the nutrient concentration in a bag of fertilizer. At the end of this video you will know what the numbers on the front of a bag mean and how they will influence plant growth.',
        youtubeUrl: 'https://youtu.be/n7nG-gHcv4I',
        thumbnailAsset:
        'assets/relatedVideos/FertilizingProcessImg/FirstLinkImg.png',
      ),
      RelatedVideo(
        title: 'How Fertilizer Helps Plants Grow',
        description:
        'You might often give your houseplant fertilizer in order to speed up their growth. But how exactly does this help your plants grow?',
        youtubeUrl: 'https://youtu.be/y9b2p69CxCk',
        thumbnailAsset:
        'assets/relatedVideos/FertilizingProcessImg/SecondLinkImg.png',
      ),
      RelatedVideo(
        title: 'Common Fertilizer Mistakes',
        description:
        'In today\'s 2 minute garden tip, I discuss a common fertilizer mistake that may be ruining your garden\'s productivity. When fertilizing your garden, it is important to choose the correct fertilizers with the right balance of nutrients.',
        youtubeUrl: 'https://youtu.be/R8ScnMiKzNw',
        thumbnailAsset:
        'assets/relatedVideos/FertilizingProcessImg/ThirdLinkImg.png',
      ),
      RelatedVideo(
        title: 'Feeding Tomatoes Correctly',
        description:
        'All Tomatoes Need Food. As a large, vigorous backyard staple, tomato plants are what\'s known as a "heavy feeder". We\'ll look at how often to feed your tomato plants, as well as what to feed them with.',
        youtubeUrl: 'https://youtu.be/aC1B2ePY3Ag',
        thumbnailAsset:
        'assets/relatedVideos/FertilizingProcessImg/FourthLinkImg.png',
      ),
    ],
    VideoCategory.planting: [
      RelatedVideo(
        title: 'Growing Tomatoes from Seed to Fruit',
        description:
        '160 days time lapse of growing tomatoes from seed to fruit. Watch me as I grow cherry tomatoes in a small pot indoors. Growing tomatoes at home is easy if you follow my video and avoid some of the common gardening mistakes.',
        youtubeUrl: 'https://youtu.be/KwQSjAAIqDo',
        thumbnailAsset:
        'assets/relatedVideos/PlantingProcessImg/FirstLinkImg.png',
      ),
      RelatedVideo(
        title: 'How to Plant Cabbage (Pechay)',
        description: 'From day 1 to harvest! How to plant cabbage (pechay).',
        youtubeUrl: 'https://youtu.be/Jf1npjko3AU',
        thumbnailAsset:
        'assets/relatedVideos/PlantingProcessImg/SecondLinkImg.png',
      ),
      RelatedVideo(
        title: 'Growing Watermelon Time Lapse',
        description:
        'Full watermelon growing stages were demonstrated in this time lapse of growing sugar baby watermelon from seed to harvested fruits over 110 days.',
        youtubeUrl: 'https://youtu.be/KNoPwKT8rVQ',
        thumbnailAsset:
        'assets/relatedVideos/PlantingProcessImg/ThirdLinkImg.png',
      ),
    ],
    VideoCategory.pruning: [
      RelatedVideo(
        title: 'Four Basic Pruning Cuts',
        description:
        'Learn the four basic pruning cuts from UC Marin Master Gardener. Four cuts — Heading, Thinning, Releadering (or Reduction), and Jump cuts are demonstrated and explained in detail.',
        youtubeUrl: 'https://youtu.be/YLYolsTjmKs',
        thumbnailAsset:
        'assets/relatedVideos/PruningProcessImg/FirstLinkImg.png',
      ),
      RelatedVideo(
        title: 'Prune Plants for Growth',
        description:
        'Shared how to prune plant for growth or how to prune plants to promote growth. Early spring is the best time to prune back any type of plant.',
        youtubeUrl: 'https://youtu.be/jj4ywJNeCqU',
        thumbnailAsset:
        'assets/relatedVideos/PruningProcessImg/SecondLinkImg.png',
      ),
      RelatedVideo(
        title: 'Pruning Roses in Winter',
        description:
        'Need help pruning your roses this winter? Learn how to cut and shape your rose bushes for healthier spring growth. These four simple steps will have you pruning your roses in no time.',
        youtubeUrl: 'https://youtu.be/J6la_YikkQc',
        thumbnailAsset:
        'assets/relatedVideos/PruningProcessImg/ThirdLinkImg.png',
      ),
    ],
    VideoCategory.seasonal: [
      RelatedVideo(
        title: 'Year-Round Growing Cycle',
        description:
        'This video walks you through the year-round cycle of growing plants, explaining which species are suited to spring, summer, autumn and even winter.',
        youtubeUrl: 'https://www.youtube.com/watch?v=0WiTWpSqs8Q',
        thumbnailAsset:
        'assets/relatedVideos/seasonalPlantsImg/FirstLinkImg.png',
      ),
      RelatedVideo(
        title: 'Spring Container Plants',
        description:
        'Focused on the spring season, this video presents a selection of container-friendly plants for balconies or small patios that flourish during spring.',
        youtubeUrl: 'https://www.youtube.com/watch?v=VOgrAShQT_8',
        thumbnailAsset:
        'assets/relatedVideos/seasonalPlantsImg/SecondLinkImg.png',
      ),
      RelatedVideo(
        title: 'Summer Urban Garden Guide',
        description:
        'This video is a practical guide aimed at urban gardeners wanting to maximise their space during the summer season. It introduces several vegetables that are easy to grow in summer heat.',
        youtubeUrl: 'https://www.youtube.com/watch?v=xPxsyk5AKxY',
        thumbnailAsset:
        'assets/relatedVideos/seasonalPlantsImg/ThirdLinkImg.png',
      ),
      RelatedVideo(
        title: 'June Garden Tour',
        description:
        'The creator gives a tour of their urban garden in June, showing what\'s currently blooming, fruiting, or being harvested. It offers real-world context for what plants are suited to that mid-year period.',
        youtubeUrl: 'https://www.youtube.com/watch?v=gI2BY7zyv6A',
        thumbnailAsset:
        'assets/relatedVideos/seasonalPlantsImg/FourthLinkImg.png',
      ),
      RelatedVideo(
        title: 'Top 10 Spring Plants',
        description:
        'This video presents a curated list of ten plants that shine in the spring garden — many of which are suitable for containers or compact spaces.',
        youtubeUrl: 'https://www.youtube.com/watch?v=PMn7KY6Bl5o',
        thumbnailAsset:
        'assets/relatedVideos/seasonalPlantsImg/FifthLinkImg.png',
      ),
    ],
  };

  List<RelatedVideo> get _videos => _videoData[widget.category] ?? [];

  String get _categoryTitle {
    switch (widget.category) {
      case VideoCategory.fertilizing:
        return 'Fertilizing Process';
      case VideoCategory.planting:
        return 'Planting Process';
      case VideoCategory.pruning:
        return 'Pruning Process';
      case VideoCategory.seasonal:
        return 'Seasonal Plants';
    }
  }

  Future<void> _launchYouTube(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open YouTube video'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
          'assets/relatedVideos/title/RelatedVideosText.png',
          height: 35,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'Related Videos',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: kDarkGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        centerTitle: true,
        foregroundColor: kDarkGreen,
      ),
      drawer: _buildDrawer(),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Back button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
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
            ),
          ),

          // Category label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kDarkGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kDarkGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.category_outlined,
                      color: kDarkGreen, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Category: $_categoryTitle',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: kDarkGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Video list
          Expanded(
            child: _videos.isEmpty
                ? const Center(
              child: Text(
                'No videos available',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF6B7280),
                ),
              ),
            )
                : ListView.builder(
              padding:
              const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                final video = _videos[index];
                return _VideoCard(
                  video: video,
                  onTap: () => _launchYouTube(video.youtubeUrl),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: 280,
      child: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/GardenCityLogo.png',
                        width: 44,
                        height: 44,
                      ),
                      const SizedBox(width: 10),
                      Image.asset('assets/GardenCityText.png', height: 22),
                    ],
                  ),
                ),
                _NavTile(
                  label: 'My Garden',
                  icon: Icons.local_florist_outlined,
                  selected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(
                        context, '/my-garden');
                  },
                ),
                _NavTile(
                  label: 'Guides',
                  icon: Icons.menu_book_outlined,
                  selected: true,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(
                        context, '/guides');
                  },
                ),
                _NavTile(
                  label: 'Schedules',
                  icon: Icons.event_outlined,
                  selected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(
                        context, '/schedule');
                  },
                ),
                _NavTile(
                  label: 'Dashboard',
                  icon: Icons.dashboard_outlined,
                  selected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(
                        context, '/dashboard');
                  },
                ),
                const SizedBox(height: 12),
                const Divider(),
                _NavTile(
                  label: 'Logout',
                  icon: Icons.logout,
                  selected: false,
                  onTap: () async {
                    try {
                      await FirebaseAuth.instance.signOut();
                    } catch (_) {}
                    if (!mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      LoginPage.routeName,
                          (_) => false,
                    );
                  },
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: -6,
              child: IconButton(
                icon: const Icon(Icons.close,
                    color: kDarkGreen, size: 28),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final RelatedVideo video;
  final VoidCallback onTap;

  const _VideoCard({
    required this.video,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: Image.asset(
                    video.thumbnailAsset,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: double.infinity,
                      height: 200,
                      color: const Color(0xFFE5E7EB),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ),
                ),
                // Play button overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kDarkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    video.description,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFF6B7280),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Icon(
                        Icons.ondemand_video,
                        size: 18,
                        color: kDarkGreen,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Watch on YouTube',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kDarkGreen,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: kDarkGreen,
                      ),
                    ],
                  ),
                ],
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
          leading:
          Icon(icon, color: selected ? Colors.white : kDarkGreen),
          title: Text(
            label,
            style: base?.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
          onTap: onTap,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}
