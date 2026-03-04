import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../widgets/custom_bottom_nav.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../services/lesson_service.dart';
import 'process_screen.dart';
import 'chat_ai_screen.dart';
import 'archive_screen.dart';
import 'account_screen.dart';
import 'notifications_screen.dart';
import 'dictionary_search_screen.dart';
import 'lessons_screen.dart';
import 'lesson_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lesson_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _userName = 'User';
  String _selectedFilter = 'all'; // 'all', 'popular', 'newest', 'advance'

  @override
  void initState() {
    super.initState();
    _loadUserName();
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

  bool get _isEnglish => context.watch<LanguageService>().isEnglish;

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
          MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
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
                          Container(
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

                    // Courses section
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
                    FutureBuilder<List<Lesson>>(
                      future: _getFilteredLessons(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 380,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return SizedBox(
                            height: 380,
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

                        final lessons = snapshot.data!;

                        return SizedBox(
                          height: 380,
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
                                child: _buildCourseCardFromLesson(lesson),
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
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Future<List<Lesson>> _getFilteredLessons() async {
    List<Lesson> lessons = await LessonService().getParentLessons();

    if (_selectedFilter == 'popular') {
      // Parent lessons: popular = more questions, then newer, then lesson order
      lessons.sort((a, b) {
        final questionCompare = (b.totalQuestions ?? 0).compareTo(a.totalQuestions ?? 0);
        if (questionCompare != 0) return questionCompare;

        final createdA = a.createdAt;
        final createdB = b.createdAt;
        if (createdA != null && createdB != null) {
          final createdCompare = createdB.compareTo(createdA);
          if (createdCompare != 0) return createdCompare;
        } else if (createdA == null && createdB != null) {
          return 1;
        } else if (createdA != null && createdB == null) {
          return -1;
        }

        return a.lessonOrder.compareTo(b.lessonOrder);
      });
    } else if (_selectedFilter == 'newest') {
      // Parent lessons: newest = created_at desc, fallback to lesson order
      lessons.sort((a, b) {
        final createdA = a.createdAt;
        final createdB = b.createdAt;
        if (createdA != null && createdB != null) {
          final createdCompare = createdB.compareTo(createdA);
          if (createdCompare != 0) return createdCompare;
        } else if (createdA == null && createdB != null) {
          return 1;
        } else if (createdA != null && createdB == null) {
          return -1;
        }

        return a.lessonOrder.compareTo(b.lessonOrder);
      });
    } else if (_selectedFilter == 'advance') {
      // Filter only advanced lessons
      lessons = lessons.where((l) => l.level == 'advanced').toList();
    }

    return lessons;
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

  Widget _buildCourseCardFromLesson(Lesson lesson) {
    final gradient = _getLessonGradient(lesson.lessonType);
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
        width: 280,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    categoryLabel,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    lesson.level.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.1),
              ),
              child: Center(
                child: Icon(
                  _getLessonIcon(lesson.lessonType),
                  color: Colors.white.withOpacity(0.7),
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              lesson.title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              lesson.description,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                _buildCourseInfo(Icons.help_outline, '${lesson.totalQuestions ?? 0}Q'),
                const SizedBox(width: 12),
                _buildCourseInfo(Icons.schedule, '${lesson.durationMinutes ?? 5} min'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getLessonGradient(String lessonType) {
    switch (lessonType) {
      case 'multiple_choice':
        return [const Color(0xFF4FB5FF), const Color(0xFF6DD5FA)]; // Blue sáng
      case 'listening':
        return [const Color(0xFFA78BFA), const Color(0xFFC4B5FD)]; // Purple sáng
      case 'matching':
        return [const Color(0xFF34D399), const Color(0xFF6EE7B7)]; // Green sáng
      case 'fill_blank':
        return [const Color(0xFFFFB75E), const Color(0xFFED8F03)]; // Orange sáng
      case 'conversation':
        return [const Color(0xFFF472B6), const Color(0xFFFBBF24)]; // Pink-Yellow sáng
      case 'repeat':
        return [const Color(0xFF22D3EE), const Color(0xFF67E8F9)]; // Cyan sáng
      default:
        return [const Color(0xFF4FB5FF), const Color(0xFF6DD5FA)];
    }
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

