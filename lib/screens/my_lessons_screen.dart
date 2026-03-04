import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/language_service.dart';
import 'create_lesson_screen.dart';

class MyLessonsScreen extends StatefulWidget {
  const MyLessonsScreen({Key? key}) : super(key: key);

  @override
  State<MyLessonsScreen> createState() => _MyLessonsScreenState();
}

class _MyLessonsScreenState extends State<MyLessonsScreen> {
  bool _isLoading = true;
  List<CustomLesson> _customLessons = [];

  bool get _isEnglish => context.watch<LanguageService>().isEnglish;

  @override
  void initState() {
    super.initState();
    _loadCustomLessons();
  }

  Future<void> _loadCustomLessons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load custom lessons from Supabase
      // For now, use empty list
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _customLessons = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEnglish
                  ? 'Error loading lessons: $e'
                  : 'Lỗi tải bài học: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToCreateLesson() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateLessonScreen(),
      ),
    );

    // Refresh list if a lesson was created
    if (result == true) {
      _loadCustomLessons();
    }
  }

  void _deleteLesson(String lessonId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _isEnglish ? 'Delete Lesson' : 'Xóa bài học',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          _isEnglish
              ? 'Are you sure you want to delete this lesson? This action cannot be undone.'
              : 'Bạn có chắc chắn muốn xóa bài học này? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_isEnglish ? 'Cancel' : 'Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Delete lesson from Supabase
              Navigator.pop(context);
              _loadCustomLessons();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              _isEnglish ? 'Delete' : 'Xóa',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
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
                    _isEnglish ? 'My Lessons' : 'Bài học của tôi',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _customLessons.isEmpty
                      ? _buildEmptyState()
                      : _buildLessonsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateLesson,
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _isEnglish ? 'Create' : 'Tạo mới',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor.withOpacity(0.1),
              ),
              child: Icon(
                Icons.school_outlined,
                size: 60,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isEnglish ? 'No Lessons Yet' : 'Chưa có bài học',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isEnglish
                  ? 'Create your first custom lesson by\ntapping the button below'
                  : 'Tạo bài học tùy chỉnh đầu tiên của bạn\nbằng cách nhấn nút bên dưới',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToCreateLesson,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                _isEnglish ? 'Create Lesson' : 'Tạo bài học',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _customLessons.length,
      itemBuilder: (context, index) {
        final lesson = _customLessons[index];
        return _buildLessonCard(lesson);
      },
    );
  }

  Widget _buildLessonCard(CustomLesson lesson) {
    final colors = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      [const Color(0xFFEC4899), const Color(0xFFF97316)],
      [const Color(0xFF10B981), const Color(0xFF06B6D4)],
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
    ];
    final colorPair = colors[lesson.name.hashCode % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colorPair,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorPair[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // TODO: Navigate to lesson detail/practice
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        lesson.name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteLesson(lesson.id);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit, size: 20),
                              const SizedBox(width: 8),
                              Text(_isEnglish ? 'Edit' : 'Chỉnh sửa'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, size: 20, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(
                                _isEnglish ? 'Delete' : 'Xóa',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (lesson.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    lesson.description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.style,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${lesson.flashcardCount} ${_isEnglish ? 'cards' : 'thẻ'}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            lesson.createdAt,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
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
}

// Temporary model for custom lessons
class CustomLesson {
  final String id;
  final String name;
  final String description;
  final int flashcardCount;
  final String createdAt;

  CustomLesson({
    required this.id,
    required this.name,
    required this.description,
    required this.flashcardCount,
    required this.createdAt,
  });
}
