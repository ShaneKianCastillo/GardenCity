import 'package:cloud_firestore/cloud_firestore.dart';

enum PlantHealthStatus { healthy, atRisk, infected }

class DiseaseScan {
  final String id;
  final String imageUrl;
  final bool isHealthy;
  final double healthyProbability;
  final List<DiseaseInfo> diseases;
  final PlantHealthStatus status;
  final DateTime scannedAt;

  DiseaseScan({
    required this.id,
    required this.imageUrl,
    required this.isHealthy,
    required this.healthyProbability,
    required this.diseases,
    required this.status,
    required this.scannedAt,
  });

  /// Determine health status based on diseases and probabilities
  static PlantHealthStatus determineStatus(bool isHealthy, List<DiseaseInfo> diseases) {
    if (isHealthy || diseases.isEmpty) return PlantHealthStatus.healthy;

    // Check highest probability disease
    final highestProb = diseases.isNotEmpty ? diseases.first.probability : 0.0;

    if (highestProb >= 0.7) return PlantHealthStatus.infected;
    if (highestProb >= 0.4) return PlantHealthStatus.atRisk;

    return PlantHealthStatus.healthy;
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      'isHealthy': isHealthy,
      'healthyProbability': healthyProbability,
      'diseases': diseases.map((d) => d.toMap()).toList(),
      'status': status.name, // 'healthy', 'atRisk', 'infected'
      'scannedAt': Timestamp.fromDate(scannedAt),
    };
  }

  /// Create from Firestore document
  factory DiseaseScan.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final diseasesData = (data['diseases'] as List<dynamic>?) ?? [];

    return DiseaseScan(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      isHealthy: data['isHealthy'] ?? false,
      healthyProbability: (data['healthyProbability'] as num?)?.toDouble() ?? 0.0,
      diseases: diseasesData.map((d) => DiseaseInfo.fromMap(d)).toList(),
      status: _parseStatus(data['status']),
      scannedAt: (data['scannedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static PlantHealthStatus _parseStatus(String? status) {
    switch (status) {
      case 'healthy':
        return PlantHealthStatus.healthy;
      case 'atRisk':
        return PlantHealthStatus.atRisk;
      case 'infected':
        return PlantHealthStatus.infected;
      default:
        return PlantHealthStatus.healthy;
    }
  }
}

class DiseaseInfo {
  final String name;
  final double probability;
  final String description;
  final List<String> commonNames;

  DiseaseInfo({
    required this.name,
    required this.probability,
    required this.description,
    required this.commonNames,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'probability': probability,
      'description': description,
      'commonNames': commonNames,
    };
  }

  factory DiseaseInfo.fromMap(Map<String, dynamic> map) {
    return DiseaseInfo(
      name: map['name'] ?? 'Unknown',
      probability: (map['probability'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      commonNames: (map['commonNames'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

/// Helper to save scan to Firestore
class DiseaseScanService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> saveScan({
    required String imageUrl,
    required bool isHealthy,
    required double healthyProbability,
    required List<Map<String, dynamic>> diseases,
  }) async {
    final diseaseInfoList = diseases.take(3).map((d) {
      final details = d['disease_details'];
      return DiseaseInfo(
        name: d['name'] ?? 'Unknown Disease',
        probability: (d['probability'] as num?)?.toDouble() ?? 0.0,
        description: details?['description'] ?? 'No description available',
        commonNames: (details?['common_names'] as List<dynamic>?)?.cast<String>() ?? [],
      );
    }).toList();

    final status = DiseaseScan.determineStatus(isHealthy, diseaseInfoList);

    await _firestore.collection('diseaseScans').add({
      'imageUrl': imageUrl,
      'isHealthy': isHealthy,
      'healthyProbability': healthyProbability,
      'diseases': diseaseInfoList.map((d) => d.toMap()).toList(),
      'status': status.name,
      'scannedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get all scans ordered by date (newest first)
  static Stream<List<DiseaseScan>> getScansStream() {
    return _firestore
        .collection('diseaseScans')
        .orderBy('scannedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => DiseaseScan.fromFirestore(doc))
        .toList());
  }

  /// Get health statistics
  static Stream<Map<String, int>> getHealthStats() {
    return _firestore.collection('diseaseScans').snapshots().map((snapshot) {
      int healthy = 0;
      int atRisk = 0;
      int infected = 0;

      for (final doc in snapshot.docs) {
        final status = doc.data()['status'] as String?;
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

      return {'healthy': healthy, 'atRisk': atRisk, 'infected': infected};
    });
  }
}