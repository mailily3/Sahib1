import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:untitled/core/image_db.dart';
import 'package:untitled/screens/all_activities_screen.dart';
import '../widgets/interest_card.dart';
import '../widgets/popular_group_card.dart';
import 'profile_screen.dart';
import 'add_activity_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;

  // Filter variables
  String? _selectedInterest;
  String? _selectedLocation;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showFilters = false;

  // Enhanced Filter options with all KSA cities
  final List<String> filterInterests = const [
    'جميع الاهتمامات',
    'رياضة',
    'ثقافة',
    'تعليم',
    'تقنية',
    'طعام',
    'فن',
    'موسيقى',
    'سفر',
    'صحة',
    'طبيعة',
    'اجتماعي',
    'تطوع',
    'أعمال',
    'ألعاب',
    'لغات',
    'طبخ',
    'تصوير',
    'قراءة',
    'يوغا',
    'مشي',
  ];

  // Cities matching your original data (exact match for filtering)
  final List<String> filterLocations = const [
    'جميع المواقع',
    'الرياض',
    'جدة',
    'الدمام',
    'مكة',
    'المدينة',
    'الطائف',
    'تبوك',
    'أبها',
    'حائل',
    'بريدة',
    'خميس مشيط',
    'الجبيل',
    'ينبع',
    'القصيم',
    'الباحة',
    'نجران',
    'الجوف',
    'الحدود الشمالية',
    'جازان',
    'عسير',
    'مكة المكرمة',
    'المدينة المنورة',
  ];

  final List<String> interests = const [
    'نادي الكتاب',
    'يوغا',
    'أصحاب المشي',
    'STEM',
  ];

  final List<Map<String, String>> groups = const [
    {
      'image': 'assets/images/explore.jpg',
      'title': 'مستكشفو نهاية الأسبوع',
      'subtitle': 'تبقى فقط 5 أماكن',
    },
    {
      'image': 'assets/images/sunset.jpg',
      'title': 'لقاء غروب الشمس',
      'subtitle': 'اقتراب من الامتلاء',
    },
    {'image': 'assets/images/bike.jpg', 'title': 'سباق دراجات', 'subtitle': ''},
    {'image': 'assets/images/flower.jpg', 'title': 'رسم', 'subtitle': ''},
  ];

  // Method to check if any filters are active
  bool get _hasActiveFilters {
    return (_selectedInterest != null &&
            _selectedInterest != 'جميع الاهتمامات') ||
        (_selectedLocation != null && _selectedLocation != 'جميع المواقع') ||
        _startDate != null ||
        _endDate != null;
  }

  // Method to clear all filters
  void _clearAllFilters() {
    setState(() {
      _selectedInterest = null;
      _selectedLocation = null;
      _startDate = null;
      _endDate = null;
    });
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

  // Method to apply filters to activities
  List<QueryDocumentSnapshot> _applyFilters(
    List<QueryDocumentSnapshot> activities,
  ) {
    return activities.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      // Filter by interest/type
      if (_selectedInterest != null && _selectedInterest != 'جميع الاهتمامات') {
        final activityType = (data['type'] ?? '').toString().toLowerCase();
        if (activityType != _selectedInterest!.toLowerCase()) {
          return false;
        }
      }

      // Filter by location
      if (_selectedLocation != null && _selectedLocation != 'جميع المواقع') {
        final activityLocation =
            (data['location'] ?? '').toString().toLowerCase();
        if (!activityLocation.contains(_selectedLocation!.toLowerCase())) {
          return false;
        }
      }

      // Filter by date range
      if (_startDate != null || _endDate != null) {
        try {
          final activityTime = (data['time'] as Timestamp).toDate();

          if (_startDate != null && activityTime.isBefore(_startDate!)) {
            return false;
          }

          if (_endDate != null && activityTime.isAfter(_endDate!)) {
            return false;
          }
        } catch (e) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;
    final isMobile = screenWidth <= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? 32 : (isTablet ? 24 : 16),
            vertical: isMobile ? 8 : 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Enhanced Header row with user info
              FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseAuth.instance.currentUser != null
                        ? FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .get()
                        : null,
                builder: (context, snapshot) {
                  String userName = 'مستخدم';
                  String userEmail = 'user@example.com';

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    userName = 'جاري التحميل...';
                    userEmail = 'جاري التحميل...';
                  } else if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    userName = data['name'] ?? 'مستخدم';
                    userEmail =
                        data['email'] ??
                        FirebaseAuth.instance.currentUser?.email ??
                        'user@example.com';
                  } else if (FirebaseAuth.instance.currentUser != null) {
                    userName =
                        FirebaseAuth.instance.currentUser!.displayName ??
                        'مستخدم';
                    userEmail =
                        FirebaseAuth.instance.currentUser!.email ??
                        'user@example.com';
                  }

                  return Container(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF4F46E5).withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius:
                                isLargeScreen
                                    ? 32
                                    : (isTablet ? 28 : (isMobile ? 20 : 24)),
                            backgroundImage: const AssetImage(
                              'assets/images/profile.png',
                            ),
                          ),
                        ),
                        SizedBox(width: isMobile ? 12 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: TextStyle(
                                  fontSize:
                                      isLargeScreen
                                          ? 22
                                          : (isTablet
                                              ? 20
                                              : (isMobile ? 16 : 18)),
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                              Text(
                                userEmail,
                                style: TextStyle(
                                  fontSize:
                                      isLargeScreen
                                          ? 18
                                          : (isTablet
                                              ? 16
                                              : (isMobile ? 12 : 14)),
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.notifications_none,
                                  color: Color(0xFF374151),
                                ),
                                onPressed: () {},
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
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
              ),

              SizedBox(height: isMobile ? 16 : 24),

              // Enhanced Search bar with modern filter icon
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Modern Filter icon button
                    Container(
                      decoration: BoxDecoration(
                        gradient:
                            _hasActiveFilters
                                ? const LinearGradient(
                                  colors: [
                                    Color(0xFF4F46E5),
                                    Color(0xFF7C3AED),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                                : null,
                        color: _hasActiveFilters ? null : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                _hasActiveFilters
                                    ? const Color(0xFF4F46E5).withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                        icon: Stack(
                          children: [
                            Icon(
                              Icons.tune,
                              size: isMobile ? 20 : 24,
                              color:
                                  _hasActiveFilters
                                      ? Colors.white
                                      : const Color(0xFF6B7280),
                            ),
                            if (_hasActiveFilters)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFEF3C7),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        tooltip: 'الفلترة المتقدمة',
                      ),
                    ),
                    SizedBox(width: isMobile ? 12 : 16),
                    // Enhanced Search text field
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          _debounceTimer?.cancel();
                          _debounceTimer = Timer(
                            const Duration(milliseconds: 500),
                            () {
                              setState(() {
                                _searchQuery = value.trim();
                              });
                            },
                          );
                        },
                        decoration: InputDecoration(
                          hintText: 'ابحث عن نشاط، اهتمامات، مواعيد…',
                          hintStyle: TextStyle(
                            color: const Color(0xFF9CA3AF),
                            fontSize: isMobile ? 14 : 16,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(
                            Icons.search,
                            color: const Color(0xFF6B7280),
                            size: isMobile ? 20 : 22,
                          ),
                          suffixIcon:
                              _searchQuery.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Color(0xFF6B7280),
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                  : null,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: isMobile ? 14 : 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isMobile ? 12 : 16,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isMobile ? 12 : 16,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isMobile ? 12 : 16,
                            ),
                            borderSide: const BorderSide(
                              color: Color(0xFF4F46E5),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Enhanced Advanced Filters Section
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _showFilters ? null : 0,
                child:
                    _showFilters
                        ? Container(
                          margin: EdgeInsets.only(top: isMobile ? 16 : 20),
                          padding: EdgeInsets.all(
                            isLargeScreen
                                ? 28
                                : (isTablet ? 24 : (isMobile ? 16 : 20)),
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.white, Color(0xFFF8FAFC)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(
                              isMobile ? 16 : 20,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF4F46E5,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.filter_list,
                                          color: Color(0xFF4F46E5),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'الفلترة المتقدمة',
                                        style: TextStyle(
                                          fontSize: isTablet ? 18 : 16,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1F2937),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_hasActiveFilters)
                                    TextButton.icon(
                                      onPressed: _clearAllFilters,
                                      icon: const Icon(
                                        Icons.clear_all,
                                        size: 16,
                                        color: Color(0xFFEF4444),
                                      ),
                                      label: const Text(
                                        'مسح الكل',
                                        style: TextStyle(
                                          color: Color(0xFFEF4444),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: isMobile ? 16 : 24),

                              // Responsive filter layout
                              isLargeScreen
                                  ? Row(
                                    children: [
                                      Expanded(child: _buildInterestFilter()),
                                      SizedBox(width: isMobile ? 12 : 20),
                                      Expanded(child: _buildLocationFilter()),
                                      SizedBox(width: isMobile ? 12 : 20),
                                      Expanded(child: _buildDateFilter()),
                                    ],
                                  )
                                  : Column(
                                    children: [
                                      _buildInterestFilter(),
                                      SizedBox(height: isMobile ? 16 : 20),
                                      _buildLocationFilter(),
                                      SizedBox(height: isMobile ? 16 : 20),
                                      _buildDateFilter(),
                                    ],
                                  ),
                            ],
                          ),
                        )
                        : const SizedBox(),
              ),

              // Active filters chips
              if (_hasActiveFilters) ...[
                SizedBox(height: isMobile ? 12 : 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_selectedInterest != null &&
                        _selectedInterest != 'جميع الاهتمامات')
                      _buildFilterChip('الاهتمام: $_selectedInterest', () {
                        setState(() => _selectedInterest = null);
                      }),
                    if (_selectedLocation != null &&
                        _selectedLocation != 'جميع المواقع')
                      _buildFilterChip('الموقع: $_selectedLocation', () {
                        setState(() => _selectedLocation = null);
                      }),
                    if (_startDate != null)
                      _buildFilterChip(
                        'من: ${DateFormat('dd/MM').format(_startDate!)}',
                        () {
                          setState(() => _startDate = null);
                        },
                      ),
                    if (_endDate != null)
                      _buildFilterChip(
                        'إلى: ${DateFormat('dd/MM').format(_endDate!)}',
                        () {
                          setState(() => _endDate = null);
                        },
                      ),
                  ],
                ),
              ],

              // Enhanced Search Results
              if (_searchQuery.isNotEmpty || _hasActiveFilters)
                Column(
                  children: [
                    if (_debounceTimer?.isActive == true)
                      Container(
                        padding: const EdgeInsets.all(32),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4F46E5),
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    if (_debounceTimer?.isActive != true)
                      StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('activities')
                                .orderBy('createdAt', descending: true)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container(
                              padding: const EdgeInsets.all(40),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            );
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return _buildEmptyState(
                              'لا توجد أنشطة متاحة.',
                              'جرب البحث عن شيء آخر',
                            );
                          }

                          // Apply search and filters
                          List<QueryDocumentSnapshot> results =
                              snapshot.data!.docs;

                          // Apply text search
                          if (_searchQuery.isNotEmpty) {
                            results =
                                results.where((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final name =
                                      (data['name'] ?? '')
                                          .toString()
                                          .toLowerCase();
                                  final location =
                                      (data['location'] ?? '')
                                          .toString()
                                          .toLowerCase();
                                  final type =
                                      (data['type'] ?? '')
                                          .toString()
                                          .toLowerCase();
                                  final description =
                                      (data['description'] ?? '')
                                          .toString()
                                          .toLowerCase();
                                  final query = _searchQuery.toLowerCase();

                                  return name.contains(query) ||
                                      location.contains(query) ||
                                      type.contains(query) ||
                                      description.contains(query);
                                }).toList();
                          }

                          // Apply filters
                          results = _applyFilters(results);

                          if (results.isEmpty) {
                            return _buildEmptyState(
                              'لا توجد نتائج مطابقة',
                              'جرب تغيير معايير البحث أو الفلترة',
                            );
                          }

                          return _buildSearchResults(results, isTablet);
                        },
                      ),
                  ],
                ),

              SizedBox(height: isMobile ? 24 : 32),

              // Rest of the original content with enhanced styling
              _buildTodayActivities(isTablet),
              SizedBox(height: isMobile ? 24 : 32),
              _buildMyInterests(isTablet),
              SizedBox(height: isMobile ? 24 : 32),
              _buildPopularGroups(isTablet, isLargeScreen),
            ],
          ),
        ),
      ),

      // Enhanced Bottom Navigation
      bottomNavigationBar: Container(
        height: isMobile ? 70 : 80,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.person_outline, false, () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              }, isMobile: isMobile),
              _buildNavItem(
                Icons.notifications_none,
                false,
                () {},
                isMobile: isMobile,
              ),
              _buildNavItem(Icons.add, true, () async {
                final added = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddActivityScreen()),
                );
                if (added == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تمت إضافة النشاط بنجاح!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              }, isMobile: isMobile),
              _buildNavItem(Icons.search, false, () {}, isMobile: isMobile),
              _buildNavItem(
                Icons.home,
                false,
                () {},
                isActive: true,
                isMobile: isMobile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    bool isSpecial,
    VoidCallback onTap, {
    bool isActive = false,
    bool isMobile = false,
  }) {
    if (isSpecial) {
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: isMobile ? 24 : 28),
          onPressed: onTap,
        ),
      );
    }

    return IconButton(
      icon: Icon(
        icon,
        size: isMobile ? 24 : 28,
        color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF6B7280),
      ),
      onPressed: onTap,
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 12,
        vertical: isMobile ? 6 : 8,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 10 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterLabel('الاهتمام', Icons.favorite_outline),
        const SizedBox(height: 12),
        _buildDropdown(
          value: _selectedInterest,
          hint: 'اختر الاهتمام',
          items: filterInterests,
          onChanged: (value) => setState(() => _selectedInterest = value),
        ),
      ],
    );
  }

  Widget _buildLocationFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterLabel('الموقع', Icons.location_on_outlined),
        const SizedBox(height: 12),
        _buildDropdown(
          value: _selectedLocation,
          hint: 'اختر المدينة',
          items: filterLocations,
          onChanged: (value) => setState(() => _selectedLocation = value),
        ),
      ],
    );
  }

  Widget _buildDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterLabel('التاريخ', Icons.calendar_today_outlined),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                'من تاريخ',
                _startDate,
                (date) => setState(() => _startDate = date),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateField(
                'إلى تاريخ',
                _endDate,
                (date) => setState(() => _endDate = date),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF4F46E5)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(hint, style: const TextStyle(color: Color(0xFF9CA3AF))),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 10 : 12,
          ),
        ),
        items:
            items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(fontSize: isMobile ? 12 : 14),
                ),
              );
            }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateField(
    String hint,
    DateTime? date,
    Function(DateTime?) onChanged,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;
    return GestureDetector(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF4F46E5),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );
        if (selectedDate != null) {
          onChanged(selectedDate);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: const Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null ? DateFormat('dd/MM/yyyy').format(date) : hint,
                style: TextStyle(
                  color:
                      date != null
                          ? const Color(0xFF374151)
                          : const Color(0xFF9CA3AF),
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;

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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off,
              size: isMobile ? 40 : 48,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
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

  Widget _buildSearchResults(
    List<QueryDocumentSnapshot> results,
    bool isTablet,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;
    final isLargeScreen = screenWidth > 900;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: isMobile ? 16 : 24),
        Row(
          children: [
            Text(
              'نتائج البحث',
              style: TextStyle(
                fontSize:
                    isLargeScreen ? 22 : (isTablet ? 20 : (isMobile ? 16 : 18)),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            SizedBox(width: isMobile ? 8 : 12),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 12,
                vertical: isMobile ? 4 : 6,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
              ),
              child: Text(
                '${results.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 10 : 12,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 12 : 16),
        // Enhanced search results list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: results.length,
          separatorBuilder: (_, __) => SizedBox(height: isMobile ? 12 : 16),
          itemBuilder: (ctx, index) {
            final data = results[index].data() as Map<String, dynamic>;
            final name = data['name'] ?? 'نشاط';
            final location = data['location'] ?? 'غير معروف';
            final time = (data['time'] as Timestamp).toDate();
            final imageId = data['imageId'] as int?;
            final rawImageBytes = data['imageBytes'];
            Uint8List? imageBytes;

            // Handle different data types that might come from Firestore
            if (rawImageBytes != null) {
              if (rawImageBytes is Uint8List) {
                imageBytes = rawImageBytes;
              } else if (rawImageBytes is List) {
                imageBytes = Uint8List.fromList(rawImageBytes.cast<int>());
              }
            }

            final type = data['type'] ?? '';
            final maxParticipants = data['maxParticipants'] ?? 0;
            final currentParticipants = data['currentParticipants'] ?? 0;

            return _buildActivityCard(
              name: name,
              location: location,
              time: time,
              imageId: imageId,
              imageBytes: imageBytes,
              type: type,
              maxParticipants: maxParticipants,
              currentParticipants: currentParticipants,
              isTablet: isTablet,
              activityData: data,
              activityId: results[index].id,
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityCard({
    required String name,
    required String location,
    required DateTime time,
    required int? imageId,
    required Uint8List? imageBytes,
    required String type,
    required int maxParticipants,
    required int currentParticipants,
    required bool isTablet,
    required Map<String, dynamic> activityData,
    required String activityId,
  }) {
    final formattedTime = DateFormat.Hm().format(time);
    final formattedDate = DateFormat.yMMMd('ar').format(time);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            //           activityData: activityData,
            //           activityId: activityId,
            //         ),
            //   ),
            // );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced Activity Image/Icon
                FutureBuilder<Uint8List?>(
                  future: ImageDB.getImageFromData(imageId, imageBytes),
                  builder: (ctx, snapshot) {
                    return Container(
                      width: isTablet ? 90 : 75,
                      height: isTablet ? 90 : 75,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            _getActivityColor(type).withOpacity(0.1),
                            _getActivityColor(type).withOpacity(0.05),
                          ],
                        ),
                        border: Border.all(
                          color: _getActivityColor(type).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child:
                          snapshot.connectionState == ConnectionState.done &&
                                  snapshot.hasData
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  snapshot.data!,
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
                const SizedBox(width: 16),
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
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _getActivityColor(type).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getActivityColor(
                                    type,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getActivityColor(type),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Time
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$formattedDate - $formattedTime',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Participants with progress
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 14,
                            color: const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$currentParticipants/$maxParticipants',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(2),
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
                                        currentParticipants >= maxParticipants
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(2),
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
                const SizedBox(width: 12),
                // Enhanced Action Button
                Container(
                  decoration: BoxDecoration(
                    gradient:
                        currentParticipants >= maxParticipants
                            ? null
                            : const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                            ),
                    color:
                        currentParticipants >= maxParticipants
                            ? const Color(0xFFF3F4F6)
                            : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow:
                        currentParticipants >= maxParticipants
                            ? null
                            : [
                              BoxShadow(
                                color: const Color(0xFF4F46E5).withOpacity(0.3),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('انضم إلى $name'),
                                  backgroundColor: const Color(0xFF10B981),
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
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayActivities(bool isTablet) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('activities')
              .where(
                'time',
                isGreaterThanOrEqualTo: DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                ),
              )
              .where(
                'time',
                isLessThan: DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day + 1,
                ),
              )
              .orderBy('time')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyTodaySection(isTablet);
        }

        final docs = snapshot.data!.docs;
        return _buildTodaySection(docs, isTablet);
      },
    );
  }

  Widget _buildEmptyTodaySection(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'أنشطة اليوم',
          style: TextStyle(
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_busy,
                  size: 48,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'لا توجد أنشطة مجدولة لليوم',
                style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTodaySection(List<QueryDocumentSnapshot> docs, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'أنشطة اليوم',
              style: TextStyle(
                fontSize: isTablet ? 22 : 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AllActivitiesScreen(),
                  ),
                );
              },
              child: const Text(
                'عرض المزيد',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4F46E5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: isTablet ? 280 : 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildTodayActivityCard(data, isTablet, docs[index].id);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTodayActivityCard(
    Map<String, dynamic> data,
    bool isTablet,
    String activityId,
  ) {
    final name = data['name'] ?? 'نشاط';
    final location = data['location'] ?? 'غير معروف';
    final time = (data['time'] as Timestamp).toDate();
    final imageId = data['imageId'] as int?;
    final rawImageBytes = data['imageBytes'];
    Uint8List? imageBytes;

    // Handle different data types that might come from Firestore
    if (rawImageBytes != null) {
      if (rawImageBytes is Uint8List) {
        imageBytes = rawImageBytes;
      } else if (rawImageBytes is List) {
        imageBytes = Uint8List.fromList(rawImageBytes.cast<int>());
      }
    }

    final type = data['type'] ?? '';
    final maxParticipants = data['maxParticipants'] ?? 0;
    final currentParticipants = data['currentParticipants'] ?? 0;

    final formattedTime =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Container(
      width: isTablet ? 280 : 240,
      height: isTablet ? 280 : 240, // Fixed height to prevent overflow
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            //           activityId: activityId,
            //         ),
            //   ),
            // );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Enhanced Image or Icon
                Container(
                  height: isTablet ? 110 : 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        _getActivityColor(type).withOpacity(0.1),
                        _getActivityColor(type).withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: FutureBuilder<Uint8List?>(
                    future: ImageDB.getImageFromData(imageId, imageBytes),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            snapshot.data!,
                            height: isTablet ? 110 : 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        );
                      }
                      return Center(
                        child: Icon(
                          _getActivityIcon(type),
                          size: isTablet ? 40 : 35,
                          color: _getActivityColor(type),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                // Title and Type
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: isTablet ? 15 : 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (type.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getActivityColor(type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _getActivityColor(type).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 9,
                            color: _getActivityColor(type),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Time
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'اليوم الساعة $formattedTime',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const Spacer(), // This will push the bottom content down
                // Participants and Join Button
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 14,
                      color: const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$currentParticipants/$maxParticipants',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor:
                              maxParticipants > 0
                                  ? (currentParticipants / maxParticipants)
                                      .clamp(0.0, 1.0)
                                  : 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  currentParticipants >= maxParticipants
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        onTap:
                            currentParticipants >= maxParticipants
                                ? null
                                : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('انضم إلى $name'),
                                      backgroundColor: const Color(0xFF10B981),
                                    ),
                                  );
                                },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            currentParticipants >= maxParticipants
                                ? Icons.block
                                : Icons.add,
                            size: 14,
                            color:
                                currentParticipants >= maxParticipants
                                    ? const Color(0xFF9CA3AF)
                                    : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyInterests(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اهتماماتي',
          style: TextStyle(
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: isTablet ? 120 : 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: interests.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder:
                (ctx, i) => InterestCard(
                  title: interests[i],
                  color:
                      [
                        Colors.amber.shade200,
                        Colors.red.shade200,
                        Colors.lightBlue.shade200,
                        Colors.blue.shade300,
                      ][i],
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildPopularGroups(bool isTablet, bool isLargeScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مجموعات شائعة',
          style: TextStyle(
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: groups.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isLargeScreen ? 4 : (isTablet ? 3 : 2),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isTablet ? 3.2 / 4 : 3 / 4,
          ),
          itemBuilder:
              (ctx, i) => PopularGroupCard(
                imagePath: groups[i]['image']!,
                title: groups[i]['title']!,
                subtitle: groups[i]['subtitle']!,
              ),
        ),
      ],
    );
  }
}
