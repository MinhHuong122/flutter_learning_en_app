import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../widgets/custom_bottom_nav.dart';
import '../services/language_service.dart';
import '../services/lesson_service.dart';
import '../models/lesson_model.dart';
import '../providers/lesson_provider.dart';
import 'home_screen.dart';
import 'chat_ai_screen.dart';
import 'archive_screen.dart';
import 'account_screen.dart';
import 'lesson_detail_screen.dart';

class ProcessScreen extends StatefulWidget {
  const ProcessScreen({Key? key}) : super(key: key);

  @override
  State<ProcessScreen> createState() => _ProcessScreenState();
}

class _ProcessScreenState extends State<ProcessScreen> with WidgetsBindingObserver {
  int _currentIndex = 1;
  final LessonService _lessonService = LessonService();
  
  bool get _isEnglish => context.read<LanguageService>().isEnglish;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load lessons once (cached globally)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonProvider>().loadLessonsOnce();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload progress when user returns to this screen
    if (state == AppLifecycleState.resumed) {
      print('🔄 ProcessScreen: App resumed, reloading progress...');
      if (mounted) {
        // Force refresh from DB to update progress cache
        context.read<LessonProvider>().refresh().then((_) {
          if (mounted) setState(() {});
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Map<String, dynamic> _getProgressData() {
    final provider = context.read<LessonProvider>();
    final stats = provider.getProgressStats();
    final allLessons = provider.allLessons;
    
    List<Map<String, dynamic>> ongoingLessons = [];
    List<Map<String, dynamic>> completedLessons = [];
    
    for (var lesson in allLessons) {
      final progress = provider.getProgress(lesson.id);
      if (progress > 0 && progress < 100) {
        ongoingLessons.add({
          'lesson': lesson,
          'progress': progress,
        });
      } else if (progress == 100) {
        completedLessons.add({
          'lesson': lesson,
          'progress': progress,
        });
      }
    }

    return {
      'overallProgress': stats['overallProgress'],
      'totalLessons': stats['totalLessons'],
      'completedLessons': stats['completedLessons'],
      'ongoingLessons': ongoingLessons,
      'completedLessonsList': completedLessons,
    };
  }
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
        setState(() => _currentIndex = index);
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ChatAiScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ArchiveScreen()),
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
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    _isEnglish ? 'Learning Progress' : 'Tiến độ học tập',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<LessonProvider>().refresh(),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Consumer<LessonProvider>(
                    builder: (context, provider, child) {
                      final data = _getProgressData();
                      final overallProgress = (data['overallProgress'] as double).toStringAsFixed(0);
                      final totalLessons = data['totalLessons'] as int;
                      final completedLessons = data['completedLessons'] as int;
                      final ongoingLessons = data['ongoingLessons'] as List;
                      final completedLessonsList = data['completedLessonsList'] as List;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // Progress Circle Section
                          Center(
                            child: Column(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 180,
                                      height: 180,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primaryColor
                                                .withOpacity(0.2),
                                            blurRadius: 40,
                                            spreadRadius: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 180,
                                      height: 180,
                                      child: CircularProgressIndicator(
                                        value: double.parse(overallProgress) / 100,
                                        strokeWidth: 12,
                                        backgroundColor:
                                            const Color(0xFFE5E7EB),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.primaryColor,
                                        ),
                                      ),
                                    ),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '$overallProgress%',
                                          style: const TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        Text(
                                          _isEnglish ? 'Overall' : 'Tổng thể',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _isEnglish
                                      ? "Great job! You've completed $completedLessons out of $totalLessons courses."
                                      : "Tuyệt vời! Bạn đã hoàn thành $completedLessons/$totalLessons khóa học.",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF6B7280),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Stats Grid
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.menu_book_outlined,
                                  iconBgColor: const Color(0xFFFFE8D6),
                                  iconColor: const Color(0xFFF97316),
                                  value: totalLessons.toString(),
                                  label: _isEnglish ? 'Total' : 'Tổng cộng',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.schedule,
                                  iconBgColor: const Color(0xFFDEF7FF),
                                  iconColor: AppColors.primaryColor,
                                  value: ongoingLessons.length.toString(),
                                  label: _isEnglish ? 'Ongoing' : 'Đang học',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.emoji_events_outlined,
                                  iconBgColor: const Color(0xFFF3E8FF),
                                  iconColor: const Color(0xFFA855F7),
                                  value: completedLessons.toString(),
                                  label: _isEnglish ? 'Finished' : 'Hoàn thành',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Ongoing Courses
                          if (ongoingLessons.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isEnglish ? 'Ongoing Courses' : 'Khóa học đang diễn ra',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                            ...ongoingLessons.map((item) {
                              final lesson = item['lesson'] as Lesson;
                              final progress = (item['progress'] as double).toInt();
                              final gradientColors = _getLessonGradient((lesson.id.hashCode).abs());
                              
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LessonDetailScreen(lesson: lesson),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildCourseCard(
                                    title: lesson.title,
                                    category: 'Lesson',
                                    description: lesson.description,
                                    progress: progress,
                                    gradientColors: gradientColors,
                                    icon: Icons.school_outlined,
                                  ),
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 24),
                          ],

                          // Completed Courses
                          if (completedLessonsList.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _isEnglish ? 'Completed Courses' : 'Khóa học đã hoàn thành',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ],
                              ),
                            const SizedBox(height: 16),
                            ...completedLessonsList.map((item) {
                              final lesson = item['lesson'] as Lesson;
                              final progress = (item['progress'] as double).toInt();
                              final gradientColors = _getLessonGradient((lesson.id.hashCode).abs() + 5);
                              
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LessonDetailScreen(lesson: lesson),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildCourseCard(
                                    title: lesson.title,
                                    category: 'Lesson',
                                    description: lesson.description,
                                    progress: progress,
                                    gradientColors: gradientColors,
                                    icon: Icons.school_outlined,
                                  ),
                                ),
                              );
                            }).toList(),
                          ],

                          const SizedBox(height: 40),
                        ],
                      );
                    },
                  ),
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

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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

  Widget _buildCourseCard({
    required String title,
    required String category,
    required String description,
    required int progress,
    required List<Color> gradientColors,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            category,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Icon circle with opacity
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white.withOpacity(0.5),
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEnglish ? 'Progress' : 'Tiến độ',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                  ),
                    child: Text(
                    '$progress%',
                    style: const TextStyle(
                      fontSize: 11,
                        fontWeight: FontWeight.w700,
                      color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 6,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        ],
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

  Widget _buildOngoingCourseCard({
    required String title,
    required int progress,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),

          // Progress Bar with percentage
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEnglish ? 'Progress' : 'Tiến độ',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    '$progress%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
