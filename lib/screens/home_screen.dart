import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../widgets/custom_bottom_nav.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../services/lesson_service.dart';
import '../services/auth_service.dart';
import '../services/messaging_service.dart';
import 'process_screen.dart';
import 'chat_ai_screen.dart';
import 'archive_screen.dart';
import 'account_screen.dart';
import 'notifications_screen.dart';
import 'dictionary_search_screen.dart';
import 'lessons_screen.dart';
import 'lesson_detail_screen.dart';
import 'community_screen.dart';
import 'favorites_screen.dart';
import 'my_lessons_screen.dart';
import 'exercise_screen.dart';
import 'flashcard_swipe_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lesson_model.dart';
import '../providers/lesson_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  String _userName = 'User';
  String _selectedFilter = 'all'; // 'all', 'popular', 'newest', 'advance'
  Lesson? _cachedCurrentLesson;
  Map<String, dynamic>? _cachedCurrentCustomLesson;
  List<Map<String, dynamic>> _cachedCurrentCustomFlashcards = [];
  final TextEditingController _searchController = TextEditingController();

  late MessagingService _messagingService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messagingService = context.read<MessagingService>();
    _loadUserName();
    // Load lessons once (cached globally) - but don't wait for it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadContinueLearning();
      
      final userId = context.read<AuthService>().userId;
      if (userId != null) {
        _messagingService.initializeGlobalMessageListener(userId);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload progress when user returns to home screen
    if (state == AppLifecycleState.resumed) {
      print('🔄 HomeScreen: App resumed, reloading lessons & progress...');
      if (mounted) {
        // Force refresh from DB to update progress cache
        context.read<LessonProvider>().refresh().then((_) {
          _preloadContinueLearning();
          if (mounted) setState(() {});
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _messagingService.stopGlobalMessageListener();
    super.dispose();
  }

  Future<void> _preloadContinueLearning() async {
    try {
      // Ensure provider has lesson data before finding current lesson.
      await context.read<LessonProvider>().loadLessonsOnce();
      await Future.wait([
        _preloadCurrentLesson(),
        _preloadCurrentCustomLesson(),
      ]);
    } catch (e) {
      print('Error preloading continue-learning data: $e');
    }
  }

  Future<void> _preloadCurrentLesson() async {
    try {
      final lesson = await _getCurrentlyLearningLesson();
      if (mounted) {
        setState(() => _cachedCurrentLesson = lesson);
      }
    } catch (e) {
      print('Error preloading current lesson: $e');
    }
  }

  Future<void> _preloadCurrentCustomLesson() async {
    try {
      final userId = context.read<AuthService>().userId;
      if (userId == null) {
        return;
      }

      final lesson = await _getCurrentlyLearningCustomLesson(userId);
      if (lesson == null) {
        if (mounted) {
          setState(() {
            _cachedCurrentCustomLesson = null;
            _cachedCurrentCustomFlashcards = [];
          });
        }
        return;
      }

      final lessonId = lesson['id'] as String?;
      if (lessonId == null || lessonId.isEmpty) {
        return;
      }

      // Preload cards so opening swipe screen is immediate.
      final cards = await LessonService().getFlashcardsForLesson(lessonId);
      if (mounted) {
        setState(() {
          _cachedCurrentCustomLesson = lesson;
          _cachedCurrentCustomFlashcards = cards;
        });
      }
    } catch (e) {
      print('Error preloading custom continue lesson: $e');
    }
  }

  Future<Map<String, dynamic>?> _getCurrentlyLearningCustomLesson(
    String userId,
  ) async {
    try {
      final lessons = await LessonService().loadCustomLessons(userId);
      if (lessons.isEmpty) return null;

      final List<Map<String, dynamic>> lessonsWithProgress = [];

      for (final lesson in lessons) {
        final lessonId = lesson['id'] as String?;
        if (lessonId == null || lessonId.isEmpty) {
          continue;
        }

        final progress = await LessonService().getCustomLessonProgress(userId, lessonId);
        lessonsWithProgress.add({
          ...lesson,
          'continueProgress': progress,
        });
      }

      if (lessonsWithProgress.isEmpty) {
        return null;
      }

      for (final lesson in lessonsWithProgress) {
        final progress = (lesson['continueProgress'] as num?)?.toDouble() ?? 0.0;
        if (progress > 0 && progress < 100) {
          print(
            '✅ Currently learning custom lesson (ongoing): ${lesson['name']} - ${progress.toStringAsFixed(1)}%',
          );
          return lesson;
        }
      }

      for (final lesson in lessonsWithProgress) {
        final progress = (lesson['continueProgress'] as num?)?.toDouble() ?? 0.0;
        if (progress == 0) {
          print('✅ Currently learning custom lesson (next to start): ${lesson['name']}');
          return lesson;
        }
      }

      lessonsWithProgress.sort((a, b) {
        final aDate = DateTime.tryParse((a['createdAt'] ?? '').toString()) ?? DateTime(1970);
        final bDate = DateTime.tryParse((b['createdAt'] ?? '').toString()) ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      print('✅ Currently learning custom lesson (latest): ${lessonsWithProgress.first['name']}');
      return lessonsWithProgress.first;
    } catch (e) {
      print('Error loading currently learning custom lesson: $e');
      return null;
    }
  }

  Future<void> _loadUserName() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _userName = 'User');
        return;
      }

      final response = await Supabase.instance.client
          .from('profiles')
          .select('display_name, username')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _userName = response['display_name'] ?? response['username'] ?? 'User';
        });
      }
    } catch (e) {
      print('Error loading user name: $e');
      if (mounted) {
        setState(() => _userName = 'User');
      }
    }
  }

  bool get _isEnglish => context.read<LanguageService>().isEnglish;

  String _getLabel(String key) {
    final labels = _isEnglish
        ? {
            'hello': 'Hello,',
            'courses': 'Courses',
            'all_topic': 'All Topic',
            'popular': 'Popular',
            'newest': 'Newest',
            'advance': 'Advance',
            'search': 'Search',
          }
        : {
            'hello': 'Xin chào,',
            'courses': 'Khóa học',
            'all_topic': 'Tất cả chủ đề',
            'popular': 'Nổi bật',
            'newest': 'Mới nhất',
            'advance': 'Nâng cao',
            'search': 'Tìm kiếm',
          };
    return labels[key] ?? '';
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        setState(() => _currentIndex = index);
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProcessScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatAiScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ArchiveScreen()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AccountScreen()),
        );
        break;
    }
  }

  void _showSearchContextMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _isEnglish ? 'Search In' : 'Tìm kiếm trong',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              _buildSearchContextItem(
                title: _isEnglish ? 'Lessons' : 'Bài học',
                icon: Icons.book_outlined,
                color: const Color(0xFF3B82F6),
                onTap: () {
                  Navigator.pop(context);
                  if (_searchController.text.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LessonsScreen(searchQuery: _searchController.text),
                      ),
                    );
                  }
                },
              ),
              _buildSearchContextItem(
                title: _isEnglish ? 'Dictionary' : 'Từ điển',
                icon: Icons.language,
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.pop(context);
                  if (_searchController.text.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DictionarySearchScreen(searchTerm: _searchController.text),
                      ),
                    );
                  }
                },
              ),
              _buildSearchContextItem(
                title: _isEnglish ? 'My Lessons' : 'Bài học của tôi',
                icon: Icons.library_books_outlined,
                color: const Color(0xFFF59E0B),
                onTap: () {
                  Navigator.pop(context);
                  if (_searchController.text.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MyLessonsScreen(searchQuery: _searchController.text),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchContextItem({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.15),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with greeting and avatar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getLabel('hello'),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userName,
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2937),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Notification icon
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          );
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF3F4F6),
                          ),
                          child: const Icon(
                            Icons.notifications,
                            color: Color(0xFF9CA3AF),
                            size: 24,
                          ),
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Expanded scrollable content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<LessonProvider>().refresh(),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Search and filter
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                onSubmitted: (value) {
                                  if (value.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => LessonsScreen(searchQuery: value),
                                      ),
                                    );
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: _getLabel('search'),
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 14,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _showSearchContextMenu,
                            child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.tune,
                              color: Colors.white,
                            ),
                          ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Dictionary Quick Access
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DictionarySearchScreen(),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF667EEA),
                                const Color(0xFF764BA2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667EEA).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isEnglish ? 'Dictionary' : 'Từ điển',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _isEnglish
                                          ? 'Look up words & meanings'
                                          : 'Tra cứu từ vựng & ý nghĩa',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                child: const Icon(
                                  Icons.search,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Feature Quick Access Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        children: [
                          _buildFeatureButton(
                            _isEnglish ? 'Create Lesson' : 'Tạo bài học',
                            Icons.add_circle_outline,
                            const Color(0xFF3B82F6),
                            const Color(0xFFEFF6FF),
                            () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MyLessonsScreen(),
                                ),
                              );
                              if (mounted) {
                                await _preloadContinueLearning();
                                setState(() {});
                              }
                            },
                          ),
                          _buildFeatureButton(
                            _isEnglish ? 'Community' : 'Cộng đồng',
                            Icons.people,
                            const Color(0xFF8B5CF6),
                            const Color(0xFFF5F3FF),
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CommunityScreen(),
                                ),
                              );
                            },
                          ),
                          _buildFeatureButton(
                            _isEnglish ? 'Exercises' : 'Bài tập',
                            Icons.assignment,
                            const Color(0xFF10B981),
                            const Color(0xFFECFDF5),
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ExerciseScreen(),
                                ),
                              );
                            },
                          ),
                          _buildFeatureButton(
                            _isEnglish ? 'Favorites' : 'Yêu thích',
                            Icons.favorite,
                            const Color(0xFFEF4444),
                            const Color(0xFFFEF2F2),
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const FavoritesScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Currently Learning Section - includes both system and OCR lessons
                    if (_cachedCurrentCustomLesson != null || _cachedCurrentLesson != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEnglish ? 'Continue Learning' : 'Tiếp tục học',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _cachedCurrentCustomLesson != null
                                ? _buildCustomContinueLearningCard(
                                    _cachedCurrentCustomLesson!,
                                  )
                                : _buildContinueLearningCard(_cachedCurrentLesson!),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _getLabel('courses'),
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LessonsScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  _isEnglish ? 'View All' : 'Xem tất cả',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Filter buttons grid
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 3.5,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            children: [
                              _buildFilterButton(
                                'all',
                                _getLabel('all_topic'),
                                Icons.local_fire_department,
                                _selectedFilter == 'all',
                              ),
                              _buildFilterButton(
                                'popular',
                                _getLabel('popular'),
                                Icons.bolt,
                                _selectedFilter == 'popular',
                              ),
                              _buildFilterButton(
                                'newest',
                                _getLabel('newest'),
                                Icons.star,
                                _selectedFilter == 'newest',
                              ),
                              _buildFilterButton(
                                'advance',
                                _getLabel('advance'),
                                Icons.bookmark,
                                _selectedFilter == 'advance',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Course cards horizontal scroll (Dynamic Lessons)
                    Consumer<LessonProvider>(
                      builder: (context, provider, child) {
                        final lessons = _getFilteredLessons();

                        if (lessons.isEmpty) {
                          return SizedBox(
                            height: 300,
                            child: Center(
                              child: Text(
                                _isEnglish ? 'No courses available' : 'Không có khóa học nào',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ),
                          );
                        }

                        return SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: lessons.length,
                            itemBuilder: (context, index) {
                              final lesson = lessons[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index < lessons.length - 1 ? 16 : 0,
                                ),
                                child: _buildCourseCardFromLesson(lesson, index),
                              );
                            },
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  List<Lesson> _getFilteredLessons() {
    final provider = context.read<LessonProvider>();
    return provider.getFilteredLessons(_selectedFilter);
  }

  Widget _buildFilterButton(
    String id,
    String label,
    IconData icon,
    bool isActive,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? AppColors.primaryColor.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? Colors.white.withOpacity(0.2)
                    : const Color(0xFFF3F4F6),
              ),
              child: Icon(
                icon,
                size: 14,
                color: isActive
                    ? Colors.white
                    : _getIconColor(id),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getIconColor(String id) {
    switch (id) {
      case 'popular':
        return const Color(0xFFEA580C);
      case 'newest':
        return const Color(0xFFA855F7);
      case 'advance':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Widget _buildCourseCardFromLesson(Lesson lesson, int index) {
    final colors = _getPastelCardColors(index);
    final categoryLabel = _getLessonTypeLabel(lesson.lessonType);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LessonDetailScreen(lesson: lesson),
          ),
        );
      },
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: colors['background'] as Color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (colors['primary'] as Color).withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            // Background icon (bottom-right corner)
            Positioned(
              right: -30,
              bottom: -30,
              child: Icon(
                _getLessonIcon(lesson.lessonType),
                size: 140,
                color: (colors['primary'] as Color).withOpacity(0.1),
              ),
            ),
            // Content - Column
            Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top section: Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (colors['primary'] as Color).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    lesson.level.toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: colors['primary'] as Color,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Middle section: Title and description
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Text(
              lesson.title,
              style: GoogleFonts.poppins(
                        color: colors['textPrimary'] as Color,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
                    const SizedBox(height: 6),
            Text(
              lesson.description,
              style: GoogleFonts.poppins(
                        color: colors['textSecondary'] as Color,
                fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
              ),
                      maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
                  ],
                ),
                const SizedBox(height: 12),
                // Bottom section: Info items
            Row(
              children: [
                    Expanded(
                      child: _buildCardInfoItem(
                        Icons.folder_open,
                        '${lesson.totalQuestions ?? 0} Lessons',
                        colors['primary'] as Color,
                        colors['textSecondary'] as Color,
                      ),
                    ),
                const SizedBox(width: 12),
                    Expanded(
                      child: _buildCardInfoItem(
                        Icons.schedule,
                        '${lesson.durationMinutes ?? 5}h',
                        colors['primary'] as Color,
                        colors['textSecondary'] as Color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getLessonGradient(int index) {
    final gradients = [
      [const Color(0xFF4FB5FF), const Color(0xFF6DD5FA)], // Blue sáng
      [const Color(0xFFA78BFA), const Color(0xFFC4B5FD)], // Purple sáng
      [const Color(0xFF34D399), const Color(0xFF6EE7B7)], // Green sáng
      [const Color(0xFFFFB75E), const Color(0xFFED8F03)], // Orange sáng
      [const Color(0xFFF472B6), const Color(0xFFFBBF24)], // Pink-Yellow sáng
      [const Color(0xFF22D3EE), const Color(0xFF67E8F9)], // Cyan sáng
      [const Color(0xFFEC4899), const Color(0xFFF97316)], // Pink-Orange
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], // Indigo-Purple
      [const Color(0xFF10B981), const Color(0xFF06B6D4)], // Emerald-Cyan
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)], // Amber-Red
    ];
    return gradients[index % gradients.length];
  }

  String _getLessonTypeLabel(String lessonType) {
    final labels = _isEnglish
        ? {
            'multiple_choice': 'Multiple Choice',
            'listening': 'Listening',
            'matching': 'Matching',
            'fill_blank': 'Fill Blanks',
            'conversation': 'Conversation',
            'repeat': 'Repeat',
          }
        : {
            'multiple_choice': 'Trắc nghiệm',
            'listening': 'Nghe',
            'matching': 'Nối cặp',
            'fill_blank': 'Điền chỗ trống',
            'conversation': 'Hội thoại',
            'repeat': 'Lặp lại',
          };
    return labels[lessonType] ?? lessonType;
  }

  IconData _getLessonIcon(String lessonType) {
    switch (lessonType) {
      case 'multiple_choice':
        return Icons.quiz;
      case 'listening':
        return Icons.headphones;
      case 'matching':
        return Icons.line_style;
      case 'fill_blank':
        return Icons.edit;
      case 'conversation':
        return Icons.chat_bubble;
      case 'repeat':
        return Icons.record_voice_over;
      default:
        return Icons.school;
    }
  }

  Widget _buildCourseInfo(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton(
    String label,
    IconData icon,
    Color iconColor,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: iconColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withOpacity(0.15),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<Lesson?> _getCurrentlyLearningLesson() async {
    try {
      final provider = context.read<LessonProvider>();
      final lessons = provider.allLessons;
      
      if (lessons.isEmpty) return null;

      // Priority 1: Find a lesson with progress 0 < p < 100 (ongoing)
      for (var lesson in lessons) {
        final progress = provider.getProgress(lesson.id);
        if (progress > 0 && progress < 100) {
          print('✅ Currently learning (ongoing): ${lesson.title} - ${progress.toStringAsFixed(1)}%');
          return lesson;
        }
      }

      // Priority 2: Find a lesson with progress == 0 (not started yet)
      for (var lesson in lessons) {
        final progress = provider.getProgress(lesson.id);
        if (progress == 0) {
          print('✅ Currently learning (next to start): ${lesson.title}');
          return lesson;
        }
      }

      // Fallback: Return first lesson
      print('✅ Currently learning (first): ${lessons.first.title}');
      return lessons.first;
    } catch (e) {
      print('Error loading currently learning lesson: $e');
      return null;
    }
  }

  double _calculateProgress(Lesson lesson) {
    try {
      final provider = context.read<LessonProvider>();
      final progress = provider.getProgress(lesson.id);
      return progress / 100.0; // Return as decimal (0.0-1.0)
    } catch (e) {
      print('Error calculating progress: $e');
      return 0.0;
    }
  }

  Map<String, Color> _getPastelCardColors(int index) {
    final colors = [
      {
        'background': const Color(0xFFE3F2FD),
        'primary': const Color(0xFF0062A3),
        'textPrimary': const Color(0xFF003F6A),
        'textSecondary': const Color(0xFF4A6085),
      },
      {
        'background': const Color(0xFFF3E5F5),
        'primary': const Color(0xFF9B26AF),
        'textPrimary': const Color(0xFF610071),
        'textSecondary': const Color(0xFF4A6085),
      },
      {
        'background': const Color(0xFFFFF8E1),
        'primary': const Color(0xFFB8860B),
        'textPrimary': const Color(0xFF754800),
        'textSecondary': const Color(0xFF825000),
      },
      {
        'background': const Color(0xFFFFE0B2),
        'primary': const Color(0xFF875400),
        'textPrimary': const Color(0xFF5B3700),
        'textSecondary': const Color(0xFF754800),
      },
      {
        'background': const Color(0xFFEDE7F6),
        'primary': const Color(0xFF6366F1),
        'textPrimary': const Color(0xFF4C1991),
        'textSecondary': const Color(0xFF4A6085),
      },
      {
        'background': const Color(0xFFF8BBD0),
        'primary': const Color(0xFFF595FF),
        'textPrimary': const Color(0xFF610071),
        'textSecondary': const Color(0xFF700082),
      },
    ];

    final colorMap = colors[index % colors.length];
    return {
      'background': colorMap['background']!,
      'primary': colorMap['primary']!,
      'textPrimary': colorMap['textPrimary']!,
      'textSecondary': colorMap['textSecondary']!,
    };
  }

  Widget _buildCardInfoItem(
    IconData icon,
    String label,
    Color primaryColor,
    Color secondaryColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: primaryColor,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: secondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueLearningCard(Lesson lesson) {
    final provider = context.read<LessonProvider>();
    final progress = provider.getProgress(lesson.id);
    final progressPercent = progress.toInt();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LessonDetailScreen(lesson: lesson),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAF8FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE8EAEF).withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1C3355).withOpacity(0.03),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon with circular background
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF595FF).withOpacity(0.25),
              ),
              child: Icon(
                _getLessonIcon(lesson.lessonType),
                color: const Color(0xFF9B26AF),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C3355),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isEnglish
                        ? 'Lesson • $progressPercent% Complete'
                        : 'Bài học • $progressPercent% Hoàn thành',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF4A6085),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress / 100.0,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFDFE8FF),
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF9B26AF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Play button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0062A3).withOpacity(0.1),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Color(0xFF0062A3),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomContinueLearningCard(Map<String, dynamic> lesson) {
    final lessonId = (lesson['id'] ?? '').toString();
    final lessonName = (lesson['name'] ?? 'Custom Lesson').toString();
    final flashcardCount = (lesson['flashcardCount'] as num?)?.toInt() ?? 0;
    final progress = (lesson['continueProgress'] as num?)?.toDouble() ?? 0.0;
    final progressPercent = progress.toInt();

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FlashcardSwiperScreen(
              lessonId: lessonId,
              lessonName: lessonName,
              initialFlashcards: _cachedCurrentCustomFlashcards,
            ),
          ),
        );
        if (mounted) {
          await _preloadContinueLearning();
          setState(() {});
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F8FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE8EAEF).withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1C3355).withOpacity(0.03),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withOpacity(0.15),
              ),
              child: const Icon(
                Icons.style,
                color: Color(0xFF2563EB),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lessonName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C3355),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isEnglish
                        ? 'Custom lesson • $flashcardCount cards • $progressPercent% Complete'
                        : 'Bài học cá nhân • $flashcardCount thẻ • $progressPercent% Hoàn thành',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF4A6085),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress / 100.0,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFDFE8FF),
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB).withOpacity(0.1),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Color(0xFF2563EB),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


