import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/login.dart';

const kDarkGreen = Color(0xFF004643);

class GardeningGuides extends StatefulWidget {
  const GardeningGuides({super.key});

  @override
  State<GardeningGuides> createState() => _GardeningGuidesState();
}

class _GardeningGuidesState extends State<GardeningGuides> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _comingSoon(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$what • content coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guides = <_GuideItem>[
      _GuideItem(
        title: 'View Soil Types',
        description:
        'Explore the basics of soil types and why they matter. Identify your garden’s soil and match plants to your conditions.',
        asset: 'assets/guides/SoilTypes.png',
        onTap: () {
          Navigator.pushNamed(context, '/soil-types'); // you’ll wire this route
        },
      ),
      _GuideItem(
        title: 'View Seasonal Plants',
        description:
        'See what to grow each season in your area, with planting windows and simple tips to keep beds productive \nyear-round.',
        asset: 'assets/guides/SeasonalPlants.png',
        onTap: () {
          Navigator.pushNamed(context, '/seasonal-plants'); // you’ll wire this route
        },
      ),
      _GuideItem(
        title: 'View Fertilizing Process',
        description:
        'Understand when and how to feed your plants. Learn the basics of nutrients, timing, and safe application for steady growth.',
        asset: 'assets/guides/FertilizingProcess.png',
        onTap: () {
          Navigator.pushNamed(context, '/fertilizing-process'); // you’ll wire this route
        },
      ),
      _GuideItem(
        title: 'View Planting Process',
        description:
        'Plant the right \n way—choose the best spot, prepare the bed, set proper depth and spacing, then water for strong starts.',
        asset: 'assets/guides/PlantingProcess.png',
        onTap: () {
          Navigator.pushNamed(context, '/planting-process'); // you’ll wire this route
        },
      ),
      _GuideItem(
        title: 'View Pruning Process',
        description:
        'Learn the essentials: clean cuts, tool care, and timing by plant type so you reshape growth without over-pruning.',
        asset: 'assets/guides/PruningProcess.png',
        onTap: () {
          Navigator.pushNamed(context, '/pruning-process'); // you’ll wire this route
        },
      ),
    ];

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
          'assets/titles/GuidesTitle.png',
          height: 35,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'Gardening Guides',
            style: TextStyle(color: kDarkGreen, fontWeight: FontWeight.w800),
          ),
        ),
        centerTitle: true,
        foregroundColor: kDarkGreen,
      ),
      drawer: Drawer(
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
                      children: [
                        Image.asset('assets/GardenCityLogo.png',
                            width: 44, height: 44),
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
                      Navigator.pushReplacementNamed(context, '/my-garden');
                    },
                  ),
                  _NavTile(
                    label: 'Guides',
                    icon: Icons.menu_book_outlined,
                    selected: true,
                    onTap: () => Navigator.pop(context),
                  ),
                  _NavTile(
                    label: 'Schedules',
                    icon: Icons.event_outlined,
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/schedule');
                    },
                  ),
                  _NavTile(
                    label: 'Dashboard',
                    icon: Icons.dashboard_outlined,
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    },
                  ),
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
                  icon: const Icon(Icons.close, color: kDarkGreen, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(30, 16, 30, 24), // more side padding
        itemCount: guides.length,
        itemBuilder: (context, index) {
          return _GuideCard(item: guides[index]);
        },
      ),

    );
  }
}

class _GuideItem {
  final String title;
  final String description;
  final String asset;
  final VoidCallback onTap;

  const _GuideItem({
    required this.title,
    required this.description,
    required this.asset,
    required this.onTap,
  });
}

class _GuideCard extends StatelessWidget {
  final _GuideItem item;

  const _GuideCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F1EC), // light mint background
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    item.asset,
                    width: 150,
                    height: 110,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: item.onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kDarkGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  item.title,
                  style: const TextStyle(
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
