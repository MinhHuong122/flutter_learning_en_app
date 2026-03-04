import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../widgets/custom_bottom_nav.dart';
import '../services/language_service.dart';
import '../services/lesson_service.dart';
import '../models/lesson_model.dart';
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

class _ProcessScreenState extends State<ProcessScreen> {
  int _currentIndex = 1;
  final LessonService _lessonService = LessonService();
  
  late Future<Map<String, dynamic>> _progressDataFuture;

  bool get _isEnglish => context.watch<LanguageService>().isEnglish;

  @override
  void initState() {
    super.initState();
    _progressDataFuture = _loadProgressData();
  }

  Future<Map<String, dynamic>> _loadProgressData() async {
    try {
      final userId = _lessonService.supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'overallProgress': 0.0,
          'totalLessons': 0,
          'completedLessons': 0,
          'ongoingLessons': [],
        };
      }

      final parentLessons = await _lessonService.getParentLessons();
      
      double totalProgress = 0.0;
      int completedCount = 0;
      List<Map<String, dynamic>> ongoingLessons = [];

      for (var lesson in parentLessons) {
        final subLessons = await _lessonService.getSubLessons(lesson.id);
        if (subLessons.isEmpty) continue;

        int totalProgressPercent = 0;
        for (var subLesson in subLessons) {
          final progress = await _lessonService.getUserProgress(userId, subLesson.id);
          if (progress != null) {
            totalProgressPercent += progress.progressPercentage;
          }
        }

        final lessonProgress = (totalProgressPercent / subLessons.length).toDouble();
        totalProgress += lessonProgress;

        if (lessonProgress == 100) {
          completedCount++;
        } else if (lessonProgress > 0) {
          ongoingLessons.add({
            'lesson': lesson,
            'progress': lessonProgress,
          });
        }
      }

      final overallProgress = parentLessons.isEmpty ? 0.0 : (totalProgress / parentLessons.length);

      return {
        'overallProgress': overallProgress,
        'totalLessons': parentLessons.length,
        'completedLessons': completedCount,
        'ongoingLessons': ongoingLessons,
      };
    } catch (e) {
      print('❌ Error loading progress data: $e');
      return {
        'overallProgress': 0.0,
        'totalLessons': 0,
        'completedLessons': 0,
        'ongoingLessons': [],
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
          MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF3F4F6),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF6B7280),
                        size: 20,
                      ),
                    ),
                  ),
                  Text(
                    _isEnglish ? 'Learning Progress' : 'Tiến độ học tập',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _progressDataFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return Center(
                          child: Text(
                            _isEnglish ? 'Error loading progress' : 'Lỗi tải tiến độ',
                          ),
                        );
                      }

                      final data = snapshot.data!;
                      final overallProgress = (data['overallProgress'] as double).toStringAsFixed(0);
                      final totalLessons = data['totalLessons'] as int;
                      final completedLessons = data['completedLessons'] as int;
                      final ongoingLessons = data['ongoingLessons'] as List;

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

                          // Ongoing Course Cards
                          if (ongoingLessons.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  _isEnglish ? 'No courses in progress' : 'Chưa có khóa học nào đang học',
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            )
                          else
                            ...ongoingLessons.map((item) {
                              final lesson = item['lesson'] as Lesson;
                              final progress = (item['progress'] as double).toInt();
                              
                              // Color mapping for lessons
                              final colors = [
                                const Color(0xFF6366F1),
                                const Color(0xFFEC4899),
                                const Color(0xFF8B5CF6),
                                const Color(0xFF14B8A6),
                                const Color(0xFFF59E0B),
                              ];
                              final colorIndex = lesson.id.hashCode % colors.length;
                              final bgColor = colors[colorIndex];
                              
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
                                    bgColor: bgColor,
                                    icon: Icons.school_outlined,
                                  ),
                                ),
                              );
                            }).toList(),

                          const SizedBox(height: 40),
                        ],
                      );
                    },
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

  Widget _buildCourseCard({
    required String title,
    required String category,
    required String description,
    required int progress,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
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
                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            category,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
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
                      ),
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
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Icon circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: Colors.white.withOpacity(0.6),
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEnglish ? 'Completed' : 'Đã hoàn thành',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$progress%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
                  backgroundColor: Colors.black.withOpacity(0.15),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
