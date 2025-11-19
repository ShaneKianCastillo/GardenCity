import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login.dart';

const kDarkGreen = Color(0xFF004643);

/// Reusable drawer widget for consistent navigation across all pages
class AppDrawer extends StatelessWidget {
  final String currentPage; // 'my-garden', 'guides', 'schedule', 'dashboard'

  const AppDrawer({
    super.key,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 280,
      child: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
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
                _NavTile(
                  label: 'My Garden',
                  icon: Icons.local_florist_outlined,
                  selected: currentPage == 'my-garden',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentPage != 'my-garden') {
                      Navigator.pushReplacementNamed(context, '/my-garden');
                    }
                  },
                ),
                _NavTile(
                  label: 'Guides',
                  icon: Icons.menu_book_outlined,
                  selected: currentPage == 'guides',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentPage != 'guides') {
                      Navigator.pushReplacementNamed(context, '/guides');
                    }
                  },
                ),
                _NavTile(
                  label: 'Schedules',
                  icon: Icons.event_outlined,
                  selected: currentPage == 'schedule',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentPage != 'schedule') {
                      Navigator.pushReplacementNamed(context, '/schedule');
                    }
                  },
                ),
                _NavTile(
                  label: 'Dashboard',
                  icon: Icons.dashboard_outlined,
                  selected: currentPage == 'dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentPage != 'dashboard') {
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    }
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
                    if (!context.mounted) return;
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
                tooltip: 'Close',
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