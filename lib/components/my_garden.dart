import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login.dart';
import '../modals/add_plant.dart';
import '../widgets/app_drawer.dart';

const kDarkGreen = Color(0xFF004643);

class MyGarden extends StatefulWidget {
  const MyGarden({super.key});

  @override
  State<MyGarden> createState() => _MyGardenState();
}

class _MyGardenState extends State<MyGarden> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _deletePlant(_Plant plant, {VoidCallback? closeDialog}) async {
    if (plant.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete plant?'),
        content: Text(
          'This will remove "${plant.name ?? 'plant'}" from your garden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
      const Center(child: CircularProgressIndicator(color: kDarkGreen)),
    );

    try {
      await FirebaseFirestore.instance
          .collection('gardenPlants')
          .doc(plant.id)
          .delete();

      if (mounted) {
        Navigator.pop(context); // progress
        closeDialog?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plant removed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _plantsStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Return empty stream if not logged in
      return const Stream.empty();
    }

    // Use a simpler query that doesn't require composite index
    // We'll sort in memory instead
    return FirebaseFirestore.instance
        .collection('gardenPlants')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawerEnableOpenDragGesture: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: kDarkGreen),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        title: Image.asset(
          'assets/titles/MyGardenTitle.png',
          height: 35,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'My Garden',
            style: TextStyle(
              color: kDarkGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilledButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (_) => const AddPlant(),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: kDarkGreen,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Add Plant',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(currentPage: 'my-garden'),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _plantsStream(),
            builder: (context, snap) {
              if (snap.hasError) {
                return const Center(
                  child: Text(
                    'Failed to load plants.',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: kDarkGreen),
                );
              }

              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.yard_outlined,
                          size: 48, color: kDarkGreen),
                      SizedBox(height: 10),
                      Text(
                        'No plants yet. Tap "Add Plant" to get started.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kDarkGreen),
                      ),
                    ],
                  ),
                );
              }

              // Parse plants and sort by createdAt in memory
              final plants = docs.map((d) => _Plant.fromDoc(d)).toList();
              plants.sort((a, b) {
                if (a.dateAdded == null && b.dateAdded == null) return 0;
                if (a.dateAdded == null) return 1;
                if (b.dateAdded == null) return -1;
                return b.dateAdded!.compareTo(a.dateAdded!);
              });

              return GridView.builder(
                itemCount: plants.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  // slightly taller cards to avoid overflow on real devices
                  childAspectRatio: 0.70,
                ),
                itemBuilder: (_, i) => _PlantCard(
                  plant: plants[i],
                  onView: () => _showPlantView(plants[i]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showPlantView(_Plant plant) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      plant.imageUrl ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: const Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    plant.name ?? 'Unnamed plant',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: kDarkGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _kv('Type', plant.type ?? '—'),
                _kv('Soil Type', plant.soil ?? '—'),
                _kv('Date Added', _fmtDate(plant.dateAdded)),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _deletePlant(
                      plant,
                      closeDialog: () => Navigator.pop(ctx),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFAA2E25),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: const Text('Remove Plant'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _fmtDate(DateTime? d) {
    if (d == null) return '—';
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
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Widget _kv(String k, String v) {
    return Align(
      alignment: Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 13.5,
          ),
          children: [
            TextSpan(
              text: '$k: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: v),
          ],
        ),
      ),
    );
  }
}

class _PlantCard extends StatelessWidget {
  final _Plant plant;
  final VoidCallback onView;

  const _PlantCard({
    required this.plant,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: kDarkGreen.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image takes flexible height so we never overflow
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                plant.imageUrl ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFE5E7EB),
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.name ?? 'Unnamed plant',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  plant.type ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onView,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kDarkGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                child: const Text('View'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Plant {
  final String? id;
  final String? name;
  final String? type;
  final String? soil;
  final String? imageUrl;
  final DateTime? dateAdded;

  _Plant({
    this.id,
    this.name,
    this.type,
    this.soil,
    this.imageUrl,
    this.dateAdded,
  });

  factory _Plant.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['createdAt'];
    DateTime? added;
    if (ts is Timestamp) added = ts.toDate();

    return _Plant(
      id: doc.id,
      name: data['plantName'] as String?,
      type: data['plantType'] as String?,
      soil: data['soilType'] as String?,
      imageUrl: data['imageUrl'] as String?,
      dateAdded: added,
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