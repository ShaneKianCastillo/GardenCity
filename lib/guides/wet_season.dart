import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login.dart';
import '../reportModal/report_problem.dart';
import '../widgets/app_drawer.dart';

const kDarkGreen = Color(0xFF004643);

class WetSeason extends StatefulWidget {
  const WetSeason({super.key});

  @override
  State<WetSeason> createState() => _WetSeasonState();
}

class _WetSeasonState extends State<WetSeason> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _showPlantDetails(_SeasonPlant plant) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white, // pure white modal
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Padding(
                // same as soil types & dry season
                padding: const EdgeInsets.fromLTRB(30, 14, 30, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            topicLabel: 'Wet season: ${plant.cardName}',
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
        cardName: 'Yardlong Bean',
        title:
        'Sitaw / Yardlong Bean (Vigna unguiculata subsp. sesquipedalis)',
        asset: 'assets/seasonalPlants/wetPlants/YardlongBean.png',
        intro:
        'Sitaw is a rain-tolerant climber that thrives in the wet season. It’s perfect for vertical urban gardens using trellises over containers or raised beds.',
        facts: const [
          _PlantFact(
            label: 'Sunlight',
            text: '6–8 hrs full sun.',
          ),
          _PlantFact(
            label: 'Watering',
            text: 'Moderate; avoid waterlogging.',
          ),
          _PlantFact(
            label: 'Soil',
            text: 'Well-draining loam; add compost.',
          ),
          _PlantFact(
            label: 'Container depth',
            text: 'Minimum 12 in + trellis.',
          ),
          _PlantFact(
            label: 'Harvest',
            text: '45–60 days.',
          ),
        ],
      ),
      _SeasonPlant(
        cardName: 'Bok Choy',
        title:
        'Pechay / Bok Choy (Brassica rapa subsp. chinensis)',
        asset: 'assets/seasonalPlants/wetPlants/BokChoy.png',
        intro:
        'Pechay is a fast, reliable leafy green for cool, wet months. It grows well in shallow containers or raised beds with steady moisture.',
        facts: const [
          _PlantFact(
            label: 'Sunlight',
            text: '4–6 hrs sun or bright partial shade.',
          ),
          _PlantFact(
            label: 'Watering',
            text: 'Keep consistently moist.',
          ),
          _PlantFact(
            label: 'Soil',
            text: 'Fertile, well-drained; rich in organic matter.',
          ),
          _PlantFact(
            label: 'Container depth',
            text: 'Minimum 6–8 in.',
          ),
          _PlantFact(
            label: 'Harvest',
            text: '30–45 days.',
          ),
        ],
      ),
      _SeasonPlant(
        cardName: 'Mustard Greens',
        title: 'Mustard Greens (Brassica juncea)',
        asset: 'assets/seasonalPlants/wetPlants/MustardGreens.png',
        intro:
        'Mustard greens grow quickly during the wet season and bounce back after repeated harvests. They’re excellent for small containers and partial-shade patios.',
        facts: const [
          _PlantFact(
            label: 'Sunlight',
            text: '4–6 hrs sun; tolerates partial shade.',
          ),
          _PlantFact(
            label: 'Watering',
            text: 'Even moisture; do not let soil dry out.',
          ),
          _PlantFact(
            label: 'Soil',
            text: 'Rich, well-draining loam.',
          ),
          _PlantFact(
            label: 'Container depth',
            text: 'Minimum 8–10 in.',
          ),
          _PlantFact(
            label: 'Harvest',
            text: '30–45 days (baby leaves earlier).',
          ),
        ],
      ),
      _SeasonPlant(
        cardName: 'Lettuce',
        title: 'Lettuce – Rain-Tolerant Types (Lactuca sativa)',
        asset: 'assets/seasonalPlants/wetPlants/Lettuce.png',
        intro:
        'Rain-tolerant lettuces handle the wet season with good airflow and light shade. They’re ideal for shallow containers and quick, continuous harvests.',
        facts: const [
          _PlantFact(
            label: 'Sunlight',
            text: '4–6 hrs sun; afternoon shade helps.',
          ),
          _PlantFact(
            label: 'Watering',
            text: 'Consistent light moisture.',
          ),
          _PlantFact(
            label: 'Soil',
            text: 'Loose, well-drained, high in compost.',
          ),
          _PlantFact(
            label: 'Container depth',
            text: 'Minimum 6–8 in.',
          ),
          _PlantFact(
            label: 'Harvest',
            text: '35–55 days (leaf types sooner).',
          ),
        ],
      ),
      _SeasonPlant(
        cardName: 'Malunggay',
        title: 'Malunggay / Moringa (Moringa oleifera)',
        asset: 'assets/seasonalPlants/wetPlants/Malungay.png',
        intro:
        'Malunggay is a hardy tree that handles tropical rains and heat well. It suits very large containers or yard corners and provides frequent leafy harvests with pruning.',
        facts: const [
          _PlantFact(
            label: 'Sunlight',
            text: '6–8+ hrs full sun.',
          ),
          _PlantFact(
            label: 'Watering',
            text: 'Light to moderate; avoid standing water.',
          ),
          _PlantFact(
            label: 'Soil',
            text: 'Well-draining, sandy loam; not fussy.',
          ),
          _PlantFact(
            label: 'Container depth',
            text: 'Minimum 18 in (very large pot/drum).',
          ),
          _PlantFact(
            label: 'Harvest',
            text: 'Leaves from 3–4 months; ongoing prunings.',
          ),
        ],
      ),
      _SeasonPlant(
        cardName: 'Taro',
        title: 'Gabi / Taro (Colocasia esculenta)',
        asset: 'assets/seasonalPlants/wetPlants/Taro.png',
        intro:
        'Gabi loves constant moisture and performs well in the wet season. It can be grown in lined beds or large containers kept consistently wet.',
        facts: const [
          _PlantFact(
            label: 'Sunlight',
            text: '4–6 hrs sun; tolerates partial shade.',
          ),
          _PlantFact(
            label: 'Watering',
            text: 'Keep consistently moist to wet.',
          ),
          _PlantFact(
            label: 'Soil',
            text: 'Rich, heavy loam with organic matter.',
          ),
          _PlantFact(
            label: 'Container depth',
            text: 'Minimum 12–18 in.',
          ),
          _PlantFact(
            label: 'Harvest',
            text: 'Leaves 45–60 days; corms 8–9 months.',
          ),
        ],
      ),
      _SeasonPlant(
        cardName: 'Bottle Gourd',
        title: 'Upo / Bottle Gourd (Lagenaria siceraria)',
        asset: 'assets/seasonalPlants/wetPlants/BottleGourd.png',
        intro:
        'Upo is a strong, rain-season vine that bears best with sturdy trellising. It works in large containers or raised beds where fruits hang cleanly.',
        facts: const [
          _PlantFact(
            label: 'Sunlight',
            text: '6–8 hrs full sun.',
          ),
          _PlantFact(
            label: 'Watering',
            text: 'Regular, deep; mulch recommended.',
          ),
          _PlantFact(
            label: 'Soil',
            text: 'Fertile, well-drained loam.',
          ),
          _PlantFact(
            label: 'Container depth',
            text: 'Minimum 14–18 in (large volume).',
          ),
          _PlantFact(
            label: 'Harvest',
            text: '70–90 days.',
          ),
        ],
      ),
      _SeasonPlant(
        cardName: 'Sponge Gourd',
        title: 'Patola / Sponge Gourd (Luffa cylindrica)',
        asset: 'assets/seasonalPlants/wetPlants/SpongeGourd.png',
        intro:
        'Patola thrives in wet months and climbs readily, producing tender fruits when picked young. It’s ideal for trellised containers or pergolas in small spaces.',
        facts: const [
          _PlantFact(
            label: 'Sunlight',
            text: '6–8 hrs full sun.',
          ),
          _PlantFact(
            label: 'Watering',
            text: 'Steady moisture; avoid soggy roots.',
          ),
          _PlantFact(
            label: 'Soil',
            text: 'Rich, well-draining loam.',
          ),
          _PlantFact(
            label: 'Container depth',
            text: 'Minimum 12–18 in + trellis.',
          ),
          _PlantFact(
            label: 'Harvest',
            text: '60–80 days.',
          ),
        ],
      ),
      _SeasonPlant(
        cardName: 'Bitter Gourd',
        title: 'Ampalaya / Bitter Gourd (Momordica charantia)',
        asset: 'assets/seasonalPlants/wetPlants/BitterGourd.png',
        intro:
        'Ampalaya is a rain-tolerant vine that benefits from pruning and training for airflow. It’s well-suited to trellised containers or raised beds in urban gardens.',
        facts: const [
          _PlantFact(
            label: 'Sunlight',
            text: '6–8 hrs full sun.',
          ),
          _PlantFact(
            label: 'Watering',
            text: 'Regular; keep evenly moist.',
          ),
          _PlantFact(
            label: 'Soil',
            text: 'Fertile, well-draining loam with compost.',
          ),
          _PlantFact(
            label: 'Container depth',
            text: 'Minimum 12–18 in + trellis.',
          ),
          _PlantFact(
            label: 'Harvest',
            text: '60–80 days; pick fruits while green and firm.',
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
          'assets/seasonalPlants/titles/WetSeasonText.png',
          height: 35,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'Wet Season',
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
