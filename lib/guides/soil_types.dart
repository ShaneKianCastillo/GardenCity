import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_drawer.dart';
import '../relatedVideos/related_videos.dart';

const kDarkGreen = Color(0xFF004643);

class SoilTypes extends StatefulWidget {
  const SoilTypes({super.key});

  @override
  State<SoilTypes> createState() => _SoilTypesState();
}

class _SoilTypesState extends State<SoilTypes> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            'Types of Soils',
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),

          // Content list
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('contents')
                  .where('category', isEqualTo: 'Type of Soils')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: kDarkGreen),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          const Text(
                            'Error loading content',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No content available yet',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  );
                }

                // Sort by createdAt in Dart instead of Firestore
                final docs = snapshot.data!.docs;
                docs.sort((a, b) {
                  final aTime = a.data()['createdAt'] as Timestamp?;
                  final bTime = b.data()['createdAt'] as Timestamp?;

                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime); // Descending order
                });

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();

                    return _ContentCard(
                      contentId: doc.id,
                      title: data['title'] ?? 'Untitled',
                      description: data['description'] ?? '',
                      imageUrl: _getFirstImage(data),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getFirstImage(Map<String, dynamic> data) {
    final images = data['images'];
    if (images is List && images.isNotEmpty) {
      return images[0] as String;
    }
    return '';
  }
}

class _ContentCard extends StatelessWidget {
  final String contentId;
  final String title;
  final String description;
  final String imageUrl;

  const _ContentCard({
    required this.contentId,
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  void _viewRelatedVideos(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DynamicRelatedVideosPage(
          contentId: contentId,
          contentTitle: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('contents')
          .doc(contentId)
          .get(),
      builder: (context, snapshot) {
        String author = 'Loading...';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data();
          author = data?['author'] ?? 'Unknown';
        }

        return Container(
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
              // Image
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: double.infinity,
                      height: 180,
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

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: kDarkGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
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
                    // Author name
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'By $author',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _viewRelatedVideos(context),
                        icon: const Icon(Icons.ondemand_video, size: 18),
                        label: const Text(
                          'View Related Videos',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kDarkGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}