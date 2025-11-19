import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

const kDarkGreen = Color(0xFF004643);

class DashboardMyPlantsChart extends StatelessWidget {
  const DashboardMyPlantsChart({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('diseaseScans').snapshots(),
      builder: (context, snapshot) {
        int healthy = 0;
        int atRisk = 0;
        int infected = 0;

        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final status = (doc.data() as Map<String, dynamic>)['status'] as String?;
            switch (status) {
              case 'healthy':
                healthy++;
                break;
              case 'atRisk':
                atRisk++;
                break;
              case 'infected':
                infected++;
                break;
            }
          }
        }

        final total = healthy + atRisk + infected;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.grass, color: kDarkGreen),
                  SizedBox(width: 8),
                  Text(
                    'My Plants',
                    style: TextStyle(
                      color: kDarkGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Total: $total',
                style: const TextStyle(
                  color: kDarkGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              if (total > 0)
                SizedBox(
                  height: 200,
                  child: CustomPaint(
                    size: const Size(200, 200),
                    painter: _PieChartPainter(
                      healthy: healthy,
                      atRisk: atRisk,
                      infected: infected,
                    ),
                  ),
                )
              else
                Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: const Text(
                    'No data available',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _Legend(color: Colors.green, label: 'Healthy'),
                  _Legend(color: Colors.orange, label: 'At risk'),
                  _Legend(color: Colors.red, label: 'Infected'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/my-garden');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDarkGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: const Text('View Plants'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: kDarkGreen,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final int healthy;
  final int atRisk;
  final int infected;

  _PieChartPainter({
    required this.healthy,
    required this.atRisk,
    required this.infected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = healthy + atRisk + infected;
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final healthyAngle = (healthy / total) * 2 * math.pi;
    final atRiskAngle = (atRisk / total) * 2 * math.pi;
    final infectedAngle = (infected / total) * 2 * math.pi;

    // Healthy (green)
    final healthyPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      healthyAngle,
      true,
      healthyPaint,
    );

    // At Risk (orange)
    final atRiskPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + healthyAngle,
      atRiskAngle,
      true,
      atRiskPaint,
    );

    // Infected (red)
    final infectedPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + healthyAngle + atRiskAngle,
      infectedAngle,
      true,
      infectedPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}