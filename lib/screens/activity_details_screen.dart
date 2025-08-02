import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:untitled/core/image_db.dart';

class ActivityDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> activityData;
  final String activityId;

  const ActivityDetailsScreen({
    super.key,
    required this.activityData,
    required this.activityId,
  });

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isJoined = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
    _checkJoinStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _joinActivity() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يجب تسجيل الدخول أولاً'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      final activityRef = FirebaseFirestore.instance
          .collection('activities')
          .doc(widget.activityId);

      // Check if user is already joined
      final userActivityRef = FirebaseFirestore.instance
          .collection('user_activities')
          .doc('${user.uid}_${widget.activityId}');

      final userActivityDoc = await userActivityRef.get();

      if (userActivityDoc.exists) {
        // User is already joined, so leave the activity
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final activityDoc = await transaction.get(activityRef);
          if (activityDoc.exists) {
            final currentParticipants =
                activityDoc.data()!['currentParticipants'] ?? 0;
            if (currentParticipants > 0) {
              transaction.update(activityRef, {
                'currentParticipants': currentParticipants - 1,
              });
            }
          }
          transaction.delete(userActivityRef);
        });

        setState(() {
          _isJoined = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('تم إلغاء الانضمام إلى ${widget.activityData['name']}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      } else {
        // User is not joined, so join the activity
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final activityDoc = await transaction.get(activityRef);
          if (activityDoc.exists) {
            final currentParticipants =
                activityDoc.data()!['currentParticipants'] ?? 0;
            final maxParticipants = activityDoc.data()!['maxParticipants'] ?? 0;

            if (currentParticipants >= maxParticipants) {
              throw Exception('النشاط ممتلئ');
            }

            transaction.update(activityRef, {
              'currentParticipants': currentParticipants + 1,
            });

            transaction.set(userActivityRef, {
              'userId': user.uid,
              'activityId': widget.activityId,
              'joinedAt': FieldValue.serverTimestamp(),
              'userEmail': user.email,
              'userName': user.displayName ?? 'مستخدم',
            });
          }
        });

        setState(() {
          _isJoined = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم الانضمام إلى ${widget.activityData['name']}'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().contains('النشاط ممتلئ')
              ? 'النشاط ممتلئ - لا يمكن الانضمام'
              : 'حدث خطأ، حاول مرة أخرى'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkJoinStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userActivityRef = FirebaseFirestore.instance
          .collection('user_activities')
          .doc('${user.uid}_${widget.activityId}');

      final userActivityDoc = await userActivityRef.get();

      setState(() {
        _isJoined = userActivityDoc.exists;
      });
    } catch (e) {
      // Handle error silently
    }
  }

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

    // Safely extract data with fallbacks
    final name = widget.activityData['name']?.toString() ?? 'نشاط غير محدد';
    final location = widget.activityData['location']?.toString() ?? 'غير معروف';
    final description =
        widget.activityData['description']?.toString() ?? 'لا يوجد وصف متاح';
    final type = widget.activityData['type']?.toString() ?? '';
    final maxParticipants =
        (widget.activityData['maxParticipants'] as num?)?.toInt() ?? 0;
    final currentParticipants =
        (widget.activityData['currentParticipants'] as num?)?.toInt() ?? 0;
    final imageId = widget.activityData['imageId'] as int?;
    final rawImageBytes = widget.activityData['imageBytes'];
    Uint8List? imageBytes;

    // Handle different data types that might come from Firestore
    if (rawImageBytes != null) {
      if (rawImageBytes is Uint8List) {
        imageBytes = rawImageBytes;
      } else if (rawImageBytes is List) {
        imageBytes = Uint8List.fromList(rawImageBytes.cast<int>());
      }
    }
    final organizer =
        widget.activityData['organizer']?.toString() ?? 'منظم غير معروف';
    final contactInfo = widget.activityData['contactInfo']?.toString();

    final requirements = widget.activityData['requirements']?.toString();

    // Handle time data safely
    DateTime activityTime;
    try {
      if (widget.activityData['time'] is Timestamp) {
        activityTime = (widget.activityData['time'] as Timestamp).toDate();
      } else if (widget.activityData['time'] is DateTime) {
        activityTime = widget.activityData['time'] as DateTime;
      } else {
        activityTime = DateTime.now();
      }
    } catch (e) {
      activityTime = DateTime.now();
    }

    final formattedTime = DateFormat.Hm().format(activityTime);
    final formattedDate = DateFormat.yMMMd('ar').format(activityTime);
    final formattedDay = DateFormat.EEEE('ar').format(activityTime);
    final isActivityFull = currentParticipants >= maxParticipants;
    final remainingSpots = maxParticipants - currentParticipants;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F0),
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar with Hero Image
          SliverAppBar(
            expandedHeight: isTablet ? 350 : 300,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFFFBF8F0),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    size: 18, color: Color(0xFF1F2937)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.favorite_border,
                      size: 18, color: Color(0xFF1F2937)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم إضافة النشاط للمفضلة'),
                        backgroundColor: Color(0xFFEF4444),
                      ),
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                margin: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + kToolbarHeight,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FutureBuilder<Uint8List?>(
                        future: ImageDB.getImageFromData(imageId, imageBytes),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.done &&
                              snapshot.hasData) {
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            );
                          }
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _getActivityColor(type).withOpacity(0.8),
                                  _getActivityColor(type).withOpacity(0.6),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                _getActivityIcon(type),
                                size: isTablet ? 100 : 80,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 24 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Type Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: isTablet ? 32 : 28,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1F2937),
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'منظم بواسطة $organizer',
                                  style: TextStyle(
                                    fontSize: isTablet ? 16 : 14,
                                    color: const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (type.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _getActivityColor(type),
                                    _getActivityColor(type).withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getActivityColor(type)
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                type,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Quick Info Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickInfoCard(
                              icon: Icons.location_on,
                              title: 'الموقع',
                              subtitle: location,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickInfoCard(
                              icon: Icons.access_time,
                              title: 'الوقت',
                              subtitle: formattedTime,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickInfoCard(
                              icon: Icons.calendar_today,
                              title: 'التاريخ',
                              subtitle: '$formattedDay، $formattedDate',
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Participants Section
                      _buildSectionCard(
                        title: 'المشاركون',
                        icon: Icons.people,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'المشاركون الحاليون',
                                  style: TextStyle(
                                    fontSize: isTablet ? 16 : 14,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF4F46E5),
                                        Color(0xFF7C3AED)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$currentParticipants/$maxParticipants',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: maxParticipants > 0
                                    ? (currentParticipants / maxParticipants)
                                        .clamp(0.0, 1.0)
                                    : 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isActivityFull
                                          ? [
                                              const Color(0xFFEF4444),
                                              const Color(0xFFDC2626)
                                            ]
                                          : [
                                              const Color(0xFF4F46E5),
                                              const Color(0xFF7C3AED)
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isActivityFull
                                  ? 'النشاط ممتلئ - لا توجد أماكن متاحة'
                                  : '$remainingSpots ${remainingSpots == 1 ? 'مكان متبقي' : 'أماكن متبقية'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isActivityFull
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF10B981),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Participants List Section
                      _buildSectionCard(
                        title: 'قائمة المشاركين',
                        icon: Icons.people_outline,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('user_activities')
                              .where('activityId', isEqualTo: widget.activityId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 48,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'لا يوجد مشاركون بعد',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: const Color(0xFF6B7280),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'كن أول من ينضم إلى هذا النشاط!',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Column(
                              children: snapshot.data!.docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final userName = data['userName'] ?? 'مستخدم';
                                final userEmail = data['userEmail'] ?? '';
                                final joinedAt = data['joinedAt'] as Timestamp?;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4F46E5)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          color: const Color(0xFF4F46E5),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              userName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1F2937),
                                              ),
                                            ),
                                            if (userEmail.isNotEmpty)
                                              Text(
                                                userEmail,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                            if (joinedAt != null)
                                              Text(
                                                'انضم في ${DateFormat.yMMMd('ar').format(joinedAt.toDate())}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF9CA3AF),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Description Section
                      _buildSectionCard(
                        title: 'وصف النشاط',
                        icon: Icons.description,
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 15,
                            color: const Color(0xFF374151),
                            height: 1.6,
                          ),
                        ),
                      ),

                      // Requirements Section (if available)
                      if (requirements != null && requirements.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildSectionCard(
                          title: 'المتطلبات',
                          icon: Icons.checklist,
                          child: Text(
                            requirements,
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 15,
                              color: const Color(0xFF374151),
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],

                      // Contact Information (if available)
                      if (contactInfo != null && contactInfo.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildSectionCard(
                          title: 'معلومات الاتصال',
                          icon: Icons.contact_phone,
                          child: Text(
                            contactInfo,
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 15,
                              color: const Color(0xFF374151),
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: isTablet ? 64 : 56,
                              decoration: BoxDecoration(
                                gradient: isActivityFull
                                    ? null
                                    : LinearGradient(
                                        colors: _isJoined
                                            ? [
                                                const Color(0xFF10B981),
                                                const Color(0xFF059669)
                                              ]
                                            : [
                                                const Color(0xFF4F46E5),
                                                const Color(0xFF7C3AED)
                                              ],
                                      ),
                                color: isActivityFull
                                    ? const Color(0xFFF3F4F6)
                                    : null,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: isActivityFull
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: (_isJoined
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFF4F46E5))
                                              .withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: isActivityFull || _isLoading
                                      ? null
                                      : _joinActivity,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _isLoading
                                            ? SizedBox(
                                                width: isTablet ? 28 : 24,
                                                height: isTablet ? 28 : 24,
                                                child:
                                                    const CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Icon(
                                                isActivityFull
                                                    ? Icons.block
                                                    : _isJoined
                                                        ? Icons.check_circle
                                                        : Icons.add_circle,
                                                color: isActivityFull
                                                    ? const Color(0xFF9CA3AF)
                                                    : Colors.white,
                                                size: isTablet ? 28 : 24,
                                              ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _isLoading
                                              ? 'جاري التحميل...'
                                              : isActivityFull
                                                  ? 'النشاط ممتلئ'
                                                  : _isJoined
                                                      ? 'منضم'
                                                      : 'انضم الآن',
                                          style: TextStyle(
                                            fontSize: isTablet ? 18 : 16,
                                            fontWeight: FontWeight.bold,
                                            color: isActivityFull
                                                ? const Color(0xFF9CA3AF)
                                                : Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            height: isTablet ? 64 : 56,
                            width: isTablet ? 64 : 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: const Color(0xFFE5E7EB)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم الاتصال بالمنظم'),
                                      backgroundColor: Color(0xFF4F46E5),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Icon(
                                  Icons.phone,
                                  color: const Color(0xFF4F46E5),
                                  size: isTablet ? 28 : 24,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: isTablet ? 64 : 56,
                            width: isTablet ? 64 : 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: const Color(0xFFE5E7EB)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم إرسال رسالة للمنظم'),
                                      backgroundColor: Color(0xFF10B981),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Icon(
                                  Icons.message,
                                  color: const Color(0xFF10B981),
                                  size: isTablet ? 28 : 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isTablet ? 40 : 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
