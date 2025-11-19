import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login.dart';
import '../reportModal/report_problem.dart';
import '../widgets/app_drawer.dart';

const kDarkGreen = Color(0xFF004643);

class SoilTypes extends StatefulWidget {
  const SoilTypes({super.key});

  @override
  State<SoilTypes> createState() => _SoilTypesState();
}

class _SoilTypesState extends State<SoilTypes> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _showSoilDetails(_SoilType soil) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Padding(
                // squeezed like the design
                padding: const EdgeInsets.fromLTRB(30, 14, 30, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // X button on its own row, top-right
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Title brought down closer to image
                    Image.asset(
                      soil.titleAsset,
                      height: 26,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Text(
                        soil.name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: kDarkGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        soil.imageAsset,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      soil.intro,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...soil.facts.map(
                          (fact) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${fact.label} – ',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  height: 1.4,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              TextSpan(
                                text: fact.text,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  height: 1.4,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          showReportProblemDialog(
                            context,
                            topicLabel: 'Soil type: ${soil.name}',
                          );
                        },
                        child: const Text(
                          'Report Problem',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final soils = <_SoilType>[
      _SoilType(
        name: 'Loam Soil',
        buttonLabel: 'View Loam Soil',
        imageAsset: 'assets/soils/LoamSoil.png',
        titleAsset: 'assets/soilTypeText/LoamSoilText.png',
        intro:
        'Loam is a balanced mix of sand, silt, and clay. It gives roots the best structure—holding nutrients and moisture while still draining well.',
        facts: const [
          _SoilFact(
            label: 'Texture',
            text: 'Soft, crumbly, slightly moist.',
          ),
          _SoilFact(
            label: 'Drainage',
            text: 'Good.',
          ),
          _SoilFact(
            label: 'Nutrient Retention',
            text: 'High.',
          ),
          _SoilFact(
            label: 'Ideal For',
            text: 'Most vegetables, herbs, and flowering plants.',
          ),
          _SoilFact(
            label: 'Urban Use',
            text:
            'Great for containers and raised beds; maintain with compost/vermicast to keep moisture.',
          ),
        ],
      ),
      _SoilType(
        name: 'Sandy Soil',
        buttonLabel: 'View Sandy Soil',
        imageAsset: 'assets/soils/SandySoil.png',
        titleAsset: 'assets/soilTypeText/SandySoilText.png',
        intro:
        'Sandy soil has large particles that drain very fast and warm quickly, but it doesn’t hold nutrients well.',
        facts: const [
          _SoilFact(
            label: 'Texture',
            text: 'Gritty and loose.',
          ),
          _SoilFact(
            label: 'Drainage',
            text: 'Excellent (fast).',
          ),
          _SoilFact(
            label: 'Nutrient Retention',
            text: 'Low, nutrients wash out easily.',
          ),
          _SoilFact(
            label: 'Ideal For',
            text:
            'Root crops (carrot, radish) and Mediterranean herbs and succulents.',
          ),
          _SoilFact(
            label: 'Urban Use',
            text:
            'Good for plants that hate “wet feet”. Mix in compost, coco peat, or vermicast to boost water-holding and feed more often.',
          ),
        ],
      ),
      _SoilType(
        name: 'Silt Soil',
        buttonLabel: 'View Silt Soil',
        imageAsset: 'assets/soils/SiltSoil.png',
        titleAsset: 'assets/soilTypeText/SiltSoilText.png',
        intro:
        'Silt has medium-sized particles. It’s naturally fertile and holds moisture better than sand but can compact without structure.',
        facts: const [
          _SoilFact(
            label: 'Texture',
            text: 'Smooth, silky; slightly slick when wet.',
          ),
          _SoilFact(
            label: 'Drainage',
            text: 'Moderate; can get waterlogged if compacted.',
          ),
          _SoilFact(
            label: 'Nutrient Retention',
            text: 'Moderate to high.',
          ),
          _SoilFact(
            label: 'Ideal For',
            text:
            'Leafy greens, brassicas, most vegetables with regular soil conditioning.',
          ),
          _SoilFact(
            label: 'Urban Use',
            text:
            'Use in raised beds/containers with structure; mix in coarse material and compost to reduce erosion.',
          ),
        ],
      ),
      _SoilType(
        name: 'Clay Soil',
        buttonLabel: 'View Clay Soil',
        imageAsset: 'assets/soils/ClaySoil.png',
        titleAsset: 'assets/soilTypeText/ClaySoilText.png',
        intro:
        'Clay has very fine particles. It’s nutrient-rich but heavy, drains slowly, and can become hard when dry.',
        facts: const [
          _SoilFact(
            label: 'Texture',
            text: 'Sticky when wet; hard/cloddy when dry.',
          ),
          _SoilFact(
            label: 'Drainage',
            text: 'Poor to slow; prone to waterlogging.',
          ),
          _SoilFact(
            label: 'Nutrient Retention',
            text: 'Very high.',
          ),
          _SoilFact(
            label: 'Ideal For',
            text:
            'Moisture-loving plants and many fruiting shrubs once drainage is improved.',
          ),
          _SoilFact(
            label: 'Urban Use',
            text:
            'Prefer raised beds/containers; lighten with compost, carbonized rice hull (CRH), and perlite; avoid working soil when wet and keep mulched.',
          ),
        ],
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
          'assets/soilTypeText/SoilTypesText.png',
          height: 35,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'Soil Types',
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
      drawer: const AppDrawer(currentPage: 'guides'),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button like other pages
            TextButton.icon(
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
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                itemCount: soils.length,
                itemBuilder: (context, index) {
                  final soil = soils[index];
                  return _SoilCard(
                    soil: soil,
                    onTap: () => _showSoilDetails(soil),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoilFact {
  final String label;
  final String text;

  const _SoilFact({
    required this.label,
    required this.text,
  });
}

class _SoilType {
  final String name;
  final String buttonLabel;
  final String imageAsset;
  final String titleAsset;
  final String intro;
  final List<_SoilFact> facts;

  const _SoilType({
    required this.name,
    required this.buttonLabel,
    required this.imageAsset,
    required this.titleAsset,
    required this.intro,
    required this.facts,
  });
}

class _SoilCard extends StatelessWidget {
  final _SoilType soil;
  final VoidCallback onTap;

  const _SoilCard({
    required this.soil,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                soil.imageAsset,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
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
                child: Text(
                  soil.buttonLabel,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
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
