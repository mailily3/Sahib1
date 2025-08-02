import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/image_db.dart';
// import 'activity_details_screen.dart'; // Navigation to ActivityDetailsScreen disabled

class AllActivitiesScreen extends StatelessWidget {
  const AllActivitiesScreen({super.key});

  // Helper method to get activity icon based on type
  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'رياضة':
      case 'sport':
        return Icons.sports_soccer;
      case 'ثقافة':
      case 'culture':
        return Icons.library_books;
      case 'تعليم':
      case 'education':
        return Icons.school;
      case 'تقنية':
      case 'technology':
        return Icons.computer;
      case 'طعام':
      case 'food':
        return Icons.restaurant;
      case 'فن':
      case 'art':
        return Icons.palette;
      case 'موسيقى':
      case 'music':
        return Icons.music_note;
      case 'سفر':
      case 'travel':
        return Icons.travel_explore;
      case 'صحة':
      case 'health':
        return Icons.fitness_center;
      case 'طبيعة':
      case 'nature':
        return Icons.park;
      case 'اجتماعي':
      case 'social':
        return Icons.people;
      case 'تطوع':
      case 'volunteer':
        return Icons.volunteer_activism;
      default:
        return Icons.event;
    }
  }

  // Helper method to get activity color based on type
  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'رياضة':
      case 'sport':
        return const Color(0xFF10B981);
      case 'ثقافة':
      case 'culture':
        return const Color(0xFF8B5CF6);
      case 'تعليم':
      case 'education':
        return const Color(0xFF3B82F6);
      case 'تقنية':
      case 'technology':
        return const Color(0xFF4F46E5);
      case 'طعام':
      case 'food':
        return const Color(0xFFF59E0B);
      case 'فن':
      case 'art':
        return const Color(0xFFEC4899);
      case 'موسيقى':
      case 'music':
        return const Color(0xFFEF4444);
      case 'سفر':
      case 'travel':
        return const Color(0xFF14B8A6);
      case 'صحة':
      case 'health':
        return const Color(0xFF84CC16);
      case 'طبيعة':
      case 'nature':
        return const Color(0xFF059669);
      case 'اجتماعي':
      case 'social':
        return const Color(0xFFF59E0B);
      case 'تطوع':
      case 'volunteer':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;
    final isMobile = screenWidth <= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F0),
      appBar: AppBar(
        title: Text(
          'جميع الأنشطة',
          style: TextStyle(
            fontSize: isLargeScreen ? 22 : (isTablet ? 20 : 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Fixed: Removed the date filter to show ALL activities
        stream:
            FirebaseFirestore.instance
                .collection('activities')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              padding: const EdgeInsets.all(40),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4F46E5),
                  strokeWidth: 3,
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(isMobile);
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            separatorBuilder: (_, __) => SizedBox(height: isMobile ? 12 : 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'نشاط';
              final location = data['location'] ?? 'غير معروف';
              final time = (data['time'] as Timestamp).toDate();
              final imageId = data['imageId'] as int?;
              final rawImageBytes = data['imageBytes'];
              final type = data['type'] ?? '';
              final maxParticipants = data['maxParticipants'] ?? 0;
              final currentParticipants = data['currentParticipants'] ?? 0;
              Uint8List? imageBytes;

              // Handle different data types that might come from Firestore
              if (rawImageBytes != null) {
                if (rawImageBytes is Uint8List) {
                  imageBytes = rawImageBytes;
                } else if (rawImageBytes is List) {
                  imageBytes = Uint8List.fromList(rawImageBytes.cast<int>());
                }
              }

              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final tomorrow = today.add(const Duration(days: 1));
              final activityDay = DateTime(time.year, time.month, time.day);

              String dayLabel;
              if (activityDay == today) {
                dayLabel = 'اليوم';
              } else if (activityDay == tomorrow) {
                dayLabel = 'غداً';
              } else {
                dayLabel = DateFormat.EEEE('ar').format(activityDay);
              }

              final formattedTime =
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
              final formattedDate = DateFormat.yMMMd('ar').format(time);
              final displayTime = '$formattedDate - $formattedTime';

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Navigation to ActivityDetailsScreen disabled
                      // Navigator.of(context).push(
                      //   MaterialPageRoute(
                      //     builder:
                      //         (_) => ActivityDetailsScreen(
                      //           activityData: data,
                      //           activityId: docs[index].id,
                      //         ),
                      //   ),
                      // );
                    },
                    borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enhanced Activity Image/Icon
                          FutureBuilder<Uint8List?>(
                            future: ImageDB.getImageFromData(
                              imageId,
                              imageBytes,
                            ),
                            builder: (ctx, imageSnapshot) {
                              return Container(
                                width: isTablet ? 90 : 75,
                                height: isTablet ? 90 : 75,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    isMobile ? 10 : 12,
                                  ),
                                  gradient: LinearGradient(
                                    colors: [
                                      _getActivityColor(type).withOpacity(0.1),
                                      _getActivityColor(type).withOpacity(0.05),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: _getActivityColor(
                                      type,
                                    ).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child:
                                    imageSnapshot.connectionState ==
                                                ConnectionState.done &&
                                            imageSnapshot.hasData
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            isMobile ? 10 : 12,
                                          ),
                                          child: Image.memory(
                                            imageSnapshot.data!,
                                            width: isTablet ? 90 : 75,
                                            height: isTablet ? 90 : 75,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                        : Icon(
                                          _getActivityIcon(type),
                                          size: isTablet ? 35 : 30,
                                          color: _getActivityColor(type),
                                        ),
                              );
                            },
                          ),
                          SizedBox(width: isMobile ? 12 : 16),
                          // Enhanced Activity Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Name and Type
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: isTablet ? 16 : 15,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1F2937),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (type.isNotEmpty) ...[
                                      SizedBox(width: isMobile ? 6 : 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isMobile ? 4 : 6,
                                          vertical: isMobile ? 2 : 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getActivityColor(
                                            type,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            isMobile ? 6 : 8,
                                          ),
                                          border: Border.all(
                                            color: _getActivityColor(
                                              type,
                                            ).withOpacity(0.3),
                                          ),
                                        ),
                                        child: Text(
                                          type,
                                          style: TextStyle(
                                            fontSize: isMobile ? 9 : 10,
                                            color: _getActivityColor(type),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                SizedBox(height: isMobile ? 6 : 8),
                                // Location
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: isMobile ? 12 : 14,
                                      color: const Color(0xFF6B7280),
                                    ),
                                    SizedBox(width: isMobile ? 3 : 4),
                                    Expanded(
                                      child: Text(
                                        location,
                                        style: TextStyle(
                                          fontSize: isMobile ? 11 : 12,
                                          color: const Color(0xFF6B7280),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: isMobile ? 4 : 6),
                                // Time
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: isMobile ? 12 : 14,
                                      color: const Color(0xFF6B7280),
                                    ),
                                    SizedBox(width: isMobile ? 3 : 4),
                                    Expanded(
                                      child: Text(
                                        displayTime,
                                        style: TextStyle(
                                          fontSize: isMobile ? 11 : 12,
                                          color: const Color(0xFF6B7280),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: isMobile ? 6 : 8),
                                // Participants with progress
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people,
                                      size: isMobile ? 12 : 14,
                                      color: const Color(0xFF6B7280),
                                    ),
                                    SizedBox(width: isMobile ? 3 : 4),
                                    Text(
                                      '$currentParticipants/$maxParticipants',
                                      style: TextStyle(
                                        fontSize: isMobile ? 10 : 11,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                    SizedBox(width: isMobile ? 6 : 8),
                                    Expanded(
                                      child: Container(
                                        height: isMobile ? 3 : 4,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor:
                                              maxParticipants > 0
                                                  ? (currentParticipants /
                                                          maxParticipants)
                                                      .clamp(0.0, 1.0)
                                                  : 0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  currentParticipants >=
                                                          maxParticipants
                                                      ? const Color(0xFFEF4444)
                                                      : const Color(0xFF10B981),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: isMobile ? 8 : 12),
                          // Enhanced Action Button
                          Container(
                            decoration: BoxDecoration(
                              gradient:
                                  currentParticipants >= maxParticipants
                                      ? null
                                      : const LinearGradient(
                                        colors: [
                                          Color(0xFF4F46E5),
                                          Color(0xFF7C3AED),
                                        ],
                                      ),
                              color:
                                  currentParticipants >= maxParticipants
                                      ? const Color(0xFFF3F4F6)
                                      : null,
                              borderRadius: BorderRadius.circular(
                                isMobile ? 10 : 12,
                              ),
                              boxShadow:
                                  currentParticipants >= maxParticipants
                                      ? null
                                      : [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF4F46E5,
                                          ).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                            ),
                            child: IconButton(
                              onPressed:
                                  currentParticipants >= maxParticipants
                                      ? null
                                      : () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('انضم إلى $name'),
                                            backgroundColor: const Color(
                                              0xFF10B981,
                                            ),
                                          ),
                                        );
                                      },
                              icon: Icon(
                                currentParticipants >= maxParticipants
                                    ? Icons.block
                                    : Icons.add,
                                color:
                                    currentParticipants >= maxParticipants
                                        ? const Color(0xFF9CA3AF)
                                        : Colors.white,
                                size: isMobile ? 18 : 20,
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
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: isMobile ? 24 : 32),
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy,
              size: isMobile ? 40 : 48,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            'لا توجد أنشطة متاحة',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Text(
            'قم بإضافة نشاط جديد أو انتظر إضافة أنشطة من قبل المستخدمين الآخرين',
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
