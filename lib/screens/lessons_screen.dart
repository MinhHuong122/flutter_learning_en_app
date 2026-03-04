import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/lesson_model.dart';
import '../services/lesson_service.dart';
import '../services/language_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_bottom_nav.dart';
import 'home_screen.dart';
import 'process_screen.dart';
import 'account_screen.dart';
import 'chat_ai_screen.dart';
import 'lesson_detail_screen.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({Key? key}) : super(key: key);

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  int _currentIndex = 0;
  final LessonService _lessonService = LessonService();
  String _selectedFilter = 'all'; // 'all', 'ongoing', 'completed'
  Map<String, double> _progressCache = {}; // Cache for calculated progress

  bool get _isEnglish => context.read<LanguageService>().isEnglish;

String _getTranslation(String key) {
  final translations = {
    'my_courses': _isEnglish ? 'My Courses' : 'Khóa học của tôi',
    'all': _isEnglish ? 'All' : 'Tất cả',
    'ongoing': _isEnglish ? 'Ongoing' : 'Đang học',
    'completed': _isEnglish ? 'Completed' : 'Hoàn thành',
    'find_course': _isEnglish ? 'Find a course you want to learn !' : 'Tìm khóa học bạn muốn học !',
    'check_now': _isEnglish ? 'Check Now' : 'Xem ngay',
    'completed_percent': _isEnglish ? 'Completed' : 'Hoàn thành',
    'no_lessons': _isEnglish ? 'No courses available' : 'Không có khóa học nào',
  };
  return translations[key] ?? key;
}

  void _onBottomNavTap(int index) {
    if (index == _currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProcessScreen()),
        );
        break;
      case 2:
        // Stay on current screen (Lessons)
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AccountScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Filter Chips
                    _buildFilterChips(),
                    
                    const SizedBox(height: 24),

                    // Banner
                    _buildBanner(),
                    
                    const SizedBox(height: 24),

                    // Course List
                    _buildCourseList(),
                    
                    const SizedBox(height: 100),
                  ],
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFF334155),
                size: 20,
              ),
            ),
          ),
          Text(
            _getTranslation('my_courses'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.search,
              color: Color(0xFF334155),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip('all', _getTranslation('all'), Icons.description),
            const SizedBox(width: 12),
            _buildChip('ongoing', _getTranslation('ongoing'), Icons.local_fire_department),
            const SizedBox(width: 12),
            _buildChip('completed', _getTranslation('completed'), Icons.task_alt),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String id, String label, IconData icon) {
    final isSelected = _selectedFilter == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : const Color(0xFFF1F5F9),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : (
                id == 'ongoing' ? const Color(0xFFFB923C) : 
                id == 'completed' ? const Color(0xFF818CF8) : 
                const Color(0xFF64748B)
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTranslation('find_course'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0C4A6E),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to search/all courses
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0EA5E9),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _getTranslation('check_now'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
            Positioned(
              right: -16,
              bottom: -16,
              child: Icon(
                Icons.school_outlined,
                size: 100,
                color: const Color(0xFF0EA5E9).withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseList() {
    return FutureBuilder<List<Lesson>>(
      future: _getLessonsFiltered(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                _getTranslation('no_lessons'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          );
        }

        final lessons = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: lessons
                .asMap()
                .entries
                .map((entry) => _buildCourseCard(entry.value, entry.key))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildCourseCard(Lesson lesson, int index) {
    final gradient = _getLessonGradientByIndex(index, lesson.title);
    final progress = _calculateProgress(lesson);

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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  _getLessonIcon(lesson.lessonType),
                  size: 48,
                  color: Colors.white.withOpacity(0.9),
                ),
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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lesson.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  // Progress
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getTranslation('completed_percent')} ${progress.toInt()}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Lesson>> _getLessonsFiltered() async {
    final userId = _lessonService.supabase.auth.currentUser?.id;
    if (userId == null) return [];
    
    List<Lesson> lessons = await _lessonService.getParentLessons();
    
    // Calculate and cache progress for all lessons
    _progressCache.clear();
    for (var lesson in lessons) {
      final progress = await _calculateRealProgress(lesson, userId);
      _progressCache[lesson.id] = progress;
      print('✅ Loaded lesson: ${lesson.title} - Progress: ${progress.toStringAsFixed(1)}%');
    }

    if (_selectedFilter == 'ongoing') {
      // Filter lessons with progress < 100%
      lessons = lessons.where((l) => _calculateProgress(l) < 100 && _calculateProgress(l) > 0).toList();
    } else if (_selectedFilter == 'completed') {
      // Filter lessons with progress == 100%
      lessons = lessons.where((l) => _calculateProgress(l) == 100).toList();
    }

    return lessons;
  }

  double _calculateProgress(Lesson lesson) {
    // Return cached progress if available
    return _progressCache[lesson.id] ?? 0.0;
  }

  Future<double> _calculateRealProgress(Lesson lesson, String userId) async {
    try {
      // Get all sub-lessons for this parent lesson
      final subLessons = await _lessonService.getSubLessons(lesson.id);
      if (subLessons.isEmpty) return 0.0;

      // Count completed sub-lessons and sum progress percentages
      int completedCount = 0;
      int totalProgressPercent = 0;
      
      for (var subLesson in subLessons) {
        final progress = await _lessonService.getUserProgress(userId, subLesson.id);
        if (progress != null) {
          if (progress.completed) {
            completedCount++;
          }
          totalProgressPercent += progress.progressPercentage;
        }
      }

      // Calculate percentage - use average of sub-lesson progress percentages
      // This way, partial progress is also reflected
      final percentage = subLessons.isEmpty ? 0.0 : (totalProgressPercent / subLessons.length).toDouble();
      
      if (percentage > 0) {
        print('📊 Progress for ${lesson.title}: $completedCount/${subLessons.length} completed, avg: ${percentage.toStringAsFixed(1)}%');
      }
      
      return percentage;
    } catch (e) {
      print('❌ Error calculating progress: $e');
      return 0.0;
    }
  }

  List<Color> _getLessonGradient(String lessonType) {
    switch (lessonType) {
      case 'multiple_choice':
        return [const Color(0xFF818CF8), const Color(0xFFA5B4FC)]; // Indigo
      case 'listening':
        return [const Color(0xFF5EEAD4), const Color(0xFF99F6E4)]; // Teal
      case 'matching':
        return [const Color(0xFFFDBA74), const Color(0xFFFED7AA)]; // Orange
      case 'fill_blank':
        return [const Color(0xFFF472B6), const Color(0xFFFBBF24)]; // Pink-Yellow
      case 'conversation':
        return [const Color(0xFF34D399), const Color(0xFF6EE7B7)]; // Green
      case 'repeat':
        return [const Color(0xFF60A5FA), const Color(0xFF93C5FD)]; // Blue
      default:
        return [const Color(0xFF818CF8), const Color(0xFFA5B4FC)];
    }
  }

  List<Color> _getLessonGradientByTitle(String title) {
    final titleLower = title.toLowerCase();
    
    if (titleLower.contains('alphabet') || titleLower.contains('bảng chữ')) {
      return [const Color(0xFF818CF8), const Color(0xFFA5B4FC)]; // Indigo
    } else if (titleLower.contains('color') || titleLower.contains('màu')) {
      return [const Color(0xFF5EEAD4), const Color(0xFF99F6E4)]; // Teal
    } else if (titleLower.contains('number') || titleLower.contains('số')) {
      return [const Color(0xFFFDBA74), const Color(0xFFFED7AA)]; // Orange
    } else if (titleLower.contains('drink') || titleLower.contains('nước')) {
      return [const Color(0xFFF472B6), const Color(0xFFFBBF24)]; // Pink-Yellow
    } else if (titleLower.contains('food') || titleLower.contains('thức ăn') || titleLower.contains('món ăn')) {
      return [const Color(0xFF34D399), const Color(0xFF6EE7B7)]; // Green
    } else if (titleLower.contains('animal') || titleLower.contains('động vật')) {
      return [const Color(0xFF60A5FA), const Color(0xFF93C5FD)]; // Blue
    } else if (titleLower.contains('phrase') || titleLower.contains('cụm từ')) {
      return [const Color(0xFFEC4899), const Color(0xFFF472B6)]; // Pink
    } else if (titleLower.contains('verb') || titleLower.contains('động từ')) {
      return [const Color(0xFFF59E0B), const Color(0xFFD97706)]; // Amber
    } else {
      return _getPastelGradientBySeed(title); // Auto diversify for new lessons
    }
  }

  List<Color> _getLessonGradientByIndex(int index, String title) {
    const pastelGradients = [
      [Color(0xFF818CF8), Color(0xFFA5B4FC)], // Indigo
      [Color(0xFF5EEAD4), Color(0xFF99F6E4)], // Teal
      [Color(0xFFFDBA74), Color(0xFFFED7AA)], // Orange
      [Color(0xFFF472B6), Color(0xFFFBBF24)], // Pink-Yellow
      [Color(0xFF34D399), Color(0xFF6EE7B7)], // Green
      [Color(0xFF60A5FA), Color(0xFF93C5FD)], // Blue
      [Color(0xFFEC4899), Color(0xFFF472B6)], // Pink
      [Color(0xFFF59E0B), Color(0xFFD97706)], // Amber
    ];

    if (index >= 0) {
      return pastelGradients[index % pastelGradients.length];
    }

    return _getPastelGradientBySeed(title);
  }

  List<Color> _getPastelGradientBySeed(String seed) {
    const pastelGradients = [
      [Color(0xFF818CF8), Color(0xFFA5B4FC)], // Indigo
      [Color(0xFF5EEAD4), Color(0xFF99F6E4)], // Teal
      [Color(0xFFFDBA74), Color(0xFFFED7AA)], // Orange
      [Color(0xFFF472B6), Color(0xFFFBBF24)], // Pink-Yellow
      [Color(0xFF34D399), Color(0xFF6EE7B7)], // Green
      [Color(0xFF60A5FA), Color(0xFF93C5FD)], // Blue
      [Color(0xFFEC4899), Color(0xFFF472B6)], // Pink
      [Color(0xFFF59E0B), Color(0xFFD97706)], // Amber
    ];

    final index = _stableColorIndex(seed, pastelGradients.length);
    return pastelGradients[index];
  }

  int _stableColorIndex(String seed, int length) {
    if (seed.isEmpty || length <= 0) return 0;

    int hash = 0;
    for (final unit in seed.toLowerCase().codeUnits) {
      hash = ((hash * 31) + unit) & 0x7fffffff;
    }
    return hash % length;
  }

  IconData _getLessonIcon(String lessonType) {
    switch (lessonType) {
      case 'multiple_choice':
        return Icons.quiz_outlined;
      case 'listening':
        return Icons.headphones_outlined;
      case 'matching':
        return Icons.dashboard_outlined;
      case 'fill_blank':
        return Icons.edit_outlined;
      case 'conversation':
        return Icons.chat_bubble_outline;
      case 'repeat':
        return Icons.record_voice_over_outlined;
      default:
        return Icons.school_outlined;
    }
  }
}


