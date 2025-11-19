import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login.dart';
import '../reportModal/report_problem.dart';
import '../widgets/app_drawer.dart';

const kDarkGreen = Color(0xFF004643);

class DrySeason extends StatefulWidget {
  const DrySeason({super.key});

  @override
  State<DrySeason> createState() => _DrySeasonState();
}

class _DrySeasonState extends State<DrySeason> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _showPlantDetails(_SeasonPlant plant) {
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
                // same squeeze as soil types
                padding: const EdgeInsets.fromLTRB(30, 14, 30, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // X button on very top-right
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
                    Text(
                      plant.title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: kDarkGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        plant.asset,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      plant.intro,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...plant.facts.map(
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
                            topicLabel: 'Dry season: ${plant.cardName}',
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
    final plants = <_SeasonPlant>[
      _SeasonPlant(
        cardName: 'Peppers',
        title: 'Peppers – Chili & Bell (Capsicum annuum / C. frutescens)',
        asset: 'assets/seasonalPlants/dryPlants/Peppers.png',
        intro:
        'Peppers are heat-loving crops that perform best in the dry season, producing well with steady sun and warmth. They fit nicely in containers and raised beds for balcony or patio growing.',
        facts: const [
          _PlantFact(
            label: 'Sunlight',
            text: '6–8+ hrs full sun.',
          ),
          _PlantFact(
            label: 'Watering',
            text: 'Keep evenly moist; avoid soggy soil.',
          ),
          _PlantFact(
            label: 'Soil',
            text: 'Well-draining loam, rich in compost.',
          ),
          _PlantFact(
            label: 'Container depth',
            text: 'Minimum 12 in.',
          ),
          _PlantFact(
            label: 'Harvest',
            text: '60–90 days (green earlier; colored later).',
          ),
        ],
      ),
      _SeasonPlant(
        cardName: 'Tomato',
        title: 'Tomato (Solanum lycopersicum)',
        asset: 'assets/seasonalPlants/dryPlants/Tomato.png',
        intro:
        'Tomato is a warm-season fruit vegetable that thrives during the dry season. It’s ideal for urban gardening setups such as raised beds, grow bags, and deep containers.',
        facts: const [
          _PlantFact(
            label: 'Sunlight',
            text: 'Requires 6–8 hours of full sun daily.',
          ),
          _PlantFact(
            label: 'Watering',
            text:
            'Regular; avoid waterlogging. Water the base, not the leaves.',
          ),
          _PlantFact(
            label: 'Soil',
            text: 'Prefers well-draining loam soil.',
          ),
          _PlantFact(
            label: 'Container depth',
            text: 'Minimum 12 inches.',
          ),
          _PlantFact(
            label: 'Harvest',
            text: '60–85 days.',
          ),
        ],
      ),
      _SeasonPlant(
        cardName: 'Eggplant',
        title: 'Eggplant (Solanum melongena)',
        asset: 'assets/seasonalPlants/dryPlants/EggPlant.png',
        intro:
        'Eggplant thrives in hot, dry-season conditions and rewards regular feeding and sunlight. It grows reliably in roomy pots or raised beds with good drainage.',
        facts: const [
          _PlantFact(
            label: 'Sunlight',
            text: '6–8+ hrs full sun.',
          ),
          _PlantFact(
            label: 'Watering',
            text: 'Regular; do not let soil dry out completely.',
          ),
          _PlantFact(
            label: 'Soil',
            text: 'Fertile, well-draining loam.',
          ),
          _PlantFact(
            label: 'Container depth',
            text: 'Minimum 12–14 in.',
          ),
          _PlantFact(
            label: 'Harvest',
            text: '65–85 days.',
          ),
        ],
      ),
      _SeasonPlant(
        cardName: 'Squash',
        title: 'Squash (Cucurbita moschata)',
        asset: 'assets/seasonalPlants/dryPlants/Squash.png',
        intro:
        'Squash is a vigorous, warm-season vine that yields heavily in the dry months. It suits large containers or raised beds with a sturdy trellis or ample ground space.',
        facts: const [
          _PlantFact(
            label: 'Sunlight',
            text: '6–8+ hrs full sun.',
          ),
          _PlantFact(
            label: 'Watering',
            text: 'Deep, regular; mulch to retain moisture.',
          ),
          _PlantFact(
            label: 'Soil',
            text: 'Rich loam with compost; good drainage.',
          ),
          _PlantFact(
            label: 'Container depth',
            text: 'Minimum 18 in (large grow bag ideal).',
          ),
          _PlantFact(
            label: 'Harvest',
            text: '90–110 days.',
          ),
        ],
      ),
      _SeasonPlant(
        cardName: 'Okra',
        title: 'Okra (Abelmoschus esculentus)',
        asset: 'assets/seasonalPlants/dryPlants/Okra.png',
        intro:
        'Okra loves heat and sun, making it perfect for the dry season. It’s well-suited to deep containers or raised beds and produces continuously when harvested young.',
        facts: const [
          _PlantFact(
            label: 'Sunlight',
            text: '6–8+ hrs full sun.',
          ),
          _PlantFact(
            label: 'Watering',
            text: 'Moderate, steady moisture.',
          ),
          _PlantFact(
            label: 'Soil',
            text: 'Well-draining loam; tolerates heat.',
          ),
          _PlantFact(
            label: 'Container depth',
            text: 'Minimum 12–18 in.',
          ),
          _PlantFact(
            label: 'Harvest',
            text: '50–60 days.',
          ),
        ],
      ),
      _SeasonPlant(
        cardName: 'Watermelon',
        title: 'Watermelon (Citrullus lanatus)',
        asset: 'assets/seasonalPlants/dryPlants/Watermelon.png',
        intro:
        'Watermelon needs the hottest, sunniest part of the dry season and plenty of root space. Compact varieties can be grown in very large containers or raised beds with strong support.',
        facts: const [
          _PlantFact(
            label: 'Sunlight',
            text: '8 hrs full sun.',
          ),
          _PlantFact(
            label: 'Watering',
            text: 'Deep, consistent; reduce a bit at final ripening.',
          ),
          _PlantFact(
            label: 'Soil',
            text: 'Rich, well-drained loam.',
          ),
          _PlantFact(
            label: 'Container depth',
            text: 'Minimum 18 in (very large volume).',
          ),
          _PlantFact(
            label: 'Harvest',
            text: '75–95 days.',
          ),
        ],
      ),
      _SeasonPlant(
        cardName: 'Melon',
        title: 'Melon / Cantaloupe (Cucumis melo)',
        asset: 'assets/seasonalPlants/dryPlants/Melon.png',
        intro:
        'Melons flourish in warm, dry weather with good airflow. They adapt to large pots or raised beds and benefit from trellising for clean, evenly ripened fruit.',
        facts: const [
          _PlantFact(
            label: 'Sunlight',
            text: '6–8+ hrs full sun.',
          ),
          _PlantFact(
            label: 'Watering',
            text: 'Regular, deep; avoid wetting foliage.',
          ),
          _PlantFact(
            label: 'Soil',
            text: 'Fertile, well-draining loam.',
          ),
          _PlantFact(
            label: 'Container depth',
            text: 'Minimum 16–18 in.',
          ),
          _PlantFact(
            label: 'Harvest',
            text: '70–90 days.',
          ),
        ],
      ),
      _SeasonPlant(
        cardName: 'Cucumber',
        title: 'Cucumber (Cucumis sativus)',
        asset: 'assets/seasonalPlants/dryPlants/Cucumber.png',
        intro:
        'Cucumber is a fast, warm-season climber that fruits abundantly in the dry months. It’s ideal for trellised containers or grow bags in sunny urban spaces.',
        facts: const [
          _PlantFact(
            label: 'Sunlight',
            text: '6–8 hrs full sun.',
          ),
          _PlantFact(
            label: 'Watering',
            text: 'Consistent moisture; never waterlog.',
          ),
          _PlantFact(
            label: 'Soil',
            text: 'Moist, well-draining loam with compost.',
          ),
          _PlantFact(
            label: 'Container depth',
            text: 'Minimum 12–14 in.',
          ),
          _PlantFact(
            label: 'Harvest',
            text: '45–65 days.',
          ),
        ],
      ),
      _SeasonPlant(
        cardName: 'String Beans',
        title: 'String Beans (Yardlong/Green Bean)',
        asset: 'assets/seasonalPlants/dryPlants/StringBeans.png',
        intro:
        'String beans prefer warm, dry conditions and reward frequent picking. Bush types fit medium containers, while climbers excel on trellises in raised beds or pots.',
        facts: const [
          _PlantFact(
            label: 'Sunlight',
            text: '6–8 hrs full sun.',
          ),
          _PlantFact(
            label: 'Watering',
            text: 'Moderate; keep soil evenly moist.',
          ),
          _PlantFact(
            label: 'Soil',
            text:
            'Well-drained loam; avoid heavy nitrogen at flowering.',
          ),
          _PlantFact(
            label: 'Container depth',
            text: 'Minimum 12 in (trellis for climbers).',
          ),
          _PlantFact(
            label: 'Harvest',
            text: '50–70 days.',
          ),
        ],
      ),
      _SeasonPlant(
        cardName: 'Corn',
        title: 'Corn (Zea mays)',
        asset: 'assets/seasonalPlants/dryPlants/Corn.png',
        intro:
        'Corn performs best in the dry season with full sun and warmth. It’s most successful in large planters or raised beds planted in clusters for good pollination.',
        facts: const [
          _PlantFact(
            label: 'Sunlight',
            text: '6–8+ hrs full sun.',
          ),
          _PlantFact(
            label: 'Watering',
            text: 'Deep, regular; extra at tasseling/silking.',
          ),
          _PlantFact(
            label: 'Soil',
            text: 'Rich, well-drained loam; heavy feeder.',
          ),
          _PlantFact(
            label: 'Container depth',
            text: 'Minimum 18 in (large tub/bed; plant several).',
          ),
          _PlantFact(
            label: 'Harvest',
            text: '75–95 days (sweet corn).',
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
          'assets/seasonalPlants/titles/DrySeasonText.png',
          height: 35,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'Dry Season',
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
              child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                itemCount: plants.length,
                itemBuilder: (context, index) {
                  final plant = plants[index];
                  return _PlantCard(
                    plant: plant,
                    onView: () => _showPlantDetails(plant),
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

class _PlantFact {
  final String label;
  final String text;

  const _PlantFact({
    required this.label,
    required this.text,
  });
}

class _SeasonPlant {
  final String cardName;
  final String title;
  final String asset;
  final String intro;
  final List<_PlantFact> facts;

  const _SeasonPlant({
    required this.cardName,
    required this.title,
    required this.asset,
    required this.intro,
    required this.facts,
  });
}

class _PlantCard extends StatelessWidget {
  final _SeasonPlant plant;
  final VoidCallback onView;

  const _PlantCard({
    required this.plant,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onView,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    plant.asset,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                plant.cardName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onView,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDarkGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
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
