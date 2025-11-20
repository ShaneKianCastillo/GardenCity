import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login.dart';
import '../widgets/app_drawer.dart';
import 'seasonal_admin_reco.dart';

const kDarkGreen = Color(0xFF004643);

class SeasonalPlants extends StatefulWidget {
  const SeasonalPlants({super.key});

  @override
  State<SeasonalPlants> createState() => _SeasonalPlantsState();
}

class _SeasonalPlantsState extends State<SeasonalPlants> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openAdminRecommendations() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SeasonalAdminRecoPage(),
      ),
    );
  }

  void _openDrySeason() {
    Navigator.pushNamed(context, '/dry-season');
  }

  void _openWetSeason() {
    Navigator.pushNamed(context, '/wet-season');
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
          'assets/seasonalPlants/titles/SeasonalPlantsText.png',
          height: 35,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'Seasonal Plants',
            style: TextStyle(
              color: kDarkGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        centerTitle: true,
        foregroundColor: kDarkGreen,
      ),
      drawer: const AppDrawer(currentPage: 'guides'),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Back button
          Align(
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
                  color: kDarkGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // NEW: Admin Recommendations Card
          _AdminRecoCard(onTap: _openAdminRecommendations),
          const SizedBox(height: 20),

          // Existing cards
          _SeasonCard(
            imageAsset: 'assets/seasonalPlants/dryPlants/DrySeason.png',
            title: 'Dry Season',
            subtitle: 'December to May',
            onTap: _openDrySeason,
          ),
          _SeasonCard(
            imageAsset: 'assets/seasonalPlants/wetPlants/WetSeason.png',
            title: 'Wet Season',
            subtitle: 'June to November',
            onTap: _openWetSeason,
          ),
        ],
      ),
    );
  }
}

// NEW: Admin Recommendations Card
class _AdminRecoCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AdminRecoCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                'https://images.unsplash.com/photo-1466692476868-aef1dfb1e735?w=800',
                width: double.infinity,
                height: 170,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: double.infinity,
                  height: 170,
                  decoration: BoxDecoration(
                    color: kDarkGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.eco, size: 64, color: kDarkGreen),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  const Text(
                    'Admin Recommendations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Expert curated content & guides',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kDarkGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'View Admin Recommendations',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeasonCard extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SeasonCard({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                imageAsset,
                width: double.infinity,
                height: 170,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kDarkGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'View Recommend Plants',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}