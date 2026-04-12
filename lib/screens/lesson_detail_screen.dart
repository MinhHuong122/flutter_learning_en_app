import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import '../models/lesson_model.dart';
import '../services/lesson_service.dart';
import '../services/language_service.dart';
import '../providers/lesson_provider.dart';
import '../services/lesson_favorites_service.dart';
import '../utils/constants.dart';
import 'quiz_screen.dart';
import 'vocabulary_cards_screen.dart'; // ✅ Import special-char-safe vocabulary display

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonDetailScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  late LessonService _lessonService;
  int _currentQuestionIndex = 0;
  Map<String, dynamic>? _lessonData;
  bool _isLoading = true;
  String? _selectedAnswer;
  List<String?> _userAnswers = [];
  int _correctCount = 0;
  bool _showResults = false;
  List<Lesson> _subLessons = [];
  Lesson? _currentSubLesson;
  bool _showQuestions = false;
  Map<int, bool> _lessonCompletion = {}; // Track completion status by index
  int? _currentLessonIndex; // Track which lesson is currently being worked on
  bool _isFavorite = false;
  final LessonFavoritesService _favoritesService = LessonFavoritesService();

  // ============= NEW: Vocabulary System State =============
  bool _showVocabularyCards = false; // Toggle vocabulary display
  
  // ====================================================

  bool get _isEnglish => context.read<LanguageService>().isEnglish;

  @override
  void initState() {
    super.initState();
    _lessonService = LessonService();
    _loadLessonData();
    _checkFavoriteStatus();
  }

  /// Reload completion status when user returns to this screen
  Future<void> _reloadSubLessonCompletions() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _subLessons.isEmpty) return;

    try {
      print('🔄 Reloading sub-lesson completions...');
      await _loadSubLessonProgressFromDB(user.id, _subLessons);
    } catch (e) {
      print('⚠️ Error reloading completions: $e');
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await _favoritesService.isFavorite(widget.lesson.id);
    if (mounted) setState(() => _isFavorite = isFav);
  }

  Future<void> _toggleFavorite() async {
    final isFav = await _favoritesService.toggleFavorite(widget.lesson.id);
    if (!mounted) return;

    if (isFav == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEnglish ? 'Cannot sync with server' : 'Không thể đồng bộ với server'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isFavorite = isFav);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFav
              ? (_isEnglish ? 'Added to favorites' : 'Đã thêm vào yêu thích')
              : (_isEnglish ? 'Removed from favorites' : 'Đã xóa khỏi yêu thích'),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: isFav ? Colors.pink : Colors.grey,
      ),
    );
  }

  Future<void> _loadLessonData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('❌ User not authenticated');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // If this is a parent lesson, load sub-lessons
      if (widget.lesson.isParent) {
        final subLessons = await _lessonService.getSubLessons(widget.lesson.id);
        if (mounted) {
          setState(() {
            _subLessons = subLessons;
            // Initialize completion tracking
            _lessonCompletion = {};
            for (int i = 0; i < subLessons.length; i++) {
              _lessonCompletion[i] = false;
            }
            _isLoading = false;
          });
          // Load completion status from DB
          await _loadSubLessonProgressFromDB(user.id, subLessons);
        }
      } else {
        // If it's a sub-lesson, load questions directly
        _loadQuestions();
      }
    } catch (e) {
      print('Error loading lesson: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSubLessonProgressFromDB(String userId, List<Lesson> subLessons) async {
    try {
      for (int i = 0; i < subLessons.length; i++) {
        final progress = await _lessonService.getUserProgress(userId, subLessons[i].id);
        if (progress != null && progress.completed) {
          if (mounted) {
            setState(() {
              _lessonCompletion[i] = true;
            });
          }
        }
      }
      print('✅ Loaded completion status for all sub-lessons');
    } catch (e) {
      print('⚠️ Error loading sub-lesson progress: $e');
    }
  }

  Future<void> _loadQuestions() async {
    try {
      final lesson = _currentSubLesson ?? widget.lesson;
      
      // Check if it's an alphabet/phonetics lesson
      if (_currentSubLesson != null && 
          (_currentSubLesson!.title.contains('Alphabet') || 
           _currentSubLesson!.title.contains('Vowels') || 
           _currentSubLesson!.title.contains('Consonants'))) {
        // Load data for alphabet screen (stays in this screen)
        final data = await _lessonService.getLessonDetails(lesson.id);
        if (mounted) {
          setState(() {
            _lessonData = data;
            _isLoading = false;
            _showQuestions = true;
            _userAnswers = List<String?>.filled(
              (data?['questions'] as List?)?.length ?? 0,
              null,
            );
          });
        }
      } else {
        // 🆕 Show vocabulary cards first (Part 1 of lesson)
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null && _currentSubLesson != null) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _showVocabularyCards = true;
            });
          }
          return;
        }
        
        // Navigate to QuizScreen for quiz lessons (Part 2 of lesson)
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuizScreen(
                lesson: lesson,
                onComplete: (completed) {
                  if (completed && _currentLessonIndex != null) {
                    setState(() {
                      _lessonCompletion[_currentLessonIndex!] = true;
                    });
                  }
                },
              ),
            ),
          );
          
          // Return to course detail after quiz
          if (mounted) {
            setState(() {
              _currentSubLesson = null;
              _showQuestions = false;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading questions: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 🆕 Handle completion of vocabulary cards phase
  void _handleVocabularyComplete() async {
    setState(() {
      _showVocabularyCards = false;
      _isLoading = true;
    });

    // Load questions for Part 2 of lesson
    try {
      final lesson = _currentSubLesson ?? widget.lesson;
      final data = await _lessonService.getLessonDetails(lesson.id);
      
      if (mounted) {
        if (data != null && 
            data['questions'] != null && 
            (data['questions'] as List).isNotEmpty) {
          // Open the dedicated quiz screen so question types are rendered correctly
          setState(() {
            _lessonData = data;
            _showQuestions = false;
            _isLoading = false;
          });
          _navigateToQuizScreen(lesson);
        } else {
          // Vocabulary lessons can be completed without quiz questions.
          if (lesson.lessonType == 'vocabulary') {
            if (_currentLessonIndex != null) {
              await _saveSubLessonProgress(
                subLessonId: lesson.id,
                completed: true,
                progressPercentage: 100,
              );
            }

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isEnglish
                      ? 'Vocabulary completed. No quiz questions for this lesson.'
                      : 'Hoàn thành từ vựng. Bài này không có câu hỏi quiz.',
                ),
              ),
            );

            setState(() {
              if (_currentLessonIndex != null) {
                _lessonCompletion[_currentLessonIndex!] = true;
              }
              _currentSubLesson = null;
              _showQuestions = false;
              _showVocabularyCards = false;
              _isLoading = false;
            });
            return;
          }

          // For non-vocabulary lesson types, still fallback to QuizScreen.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEnglish
                    ? 'No questions found for this lesson. Opening Quiz screen...'
                    : 'Không tìm thấy câu hỏi cho bài này. Đang mở Quiz...',
              ),
            ),
          );
          _navigateToQuizScreen(lesson);
        }
      }
    } catch (e) {
      print('Error loading questions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải câu hỏi: $e')),
        );
        final lesson = _currentSubLesson ?? widget.lesson;
        _navigateToQuizScreen(lesson);
      }
    }
  }

  void _navigateToQuizScreen(Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          lesson: lesson,
          onComplete: (completed) {
            if (completed && _currentLessonIndex != null) {
              setState(() {
                _lessonCompletion[_currentLessonIndex!] = true;
              });
            }
          },
        ),
      ),
    ).then((_) {
      // ✅ Reload completions when returning from quiz screen
      if (mounted && widget.lesson.isParent) {
        print('✅ Returned from quiz, reloading all sub-lesson completions...');
        _reloadSubLessonCompletions();
      }
      // Reset UI state
      if (mounted) {
        setState(() {
          _currentSubLesson = null;
          _showQuestions = false;
          _showVocabularyCards = false;
          _isLoading = false;
        });
      }
    });
  }

  void _selectAnswer(String optionId, bool isCorrect) {
    setState(() {
      _selectedAnswer = optionId;
      _userAnswers[_currentQuestionIndex] = optionId;
      if (isCorrect) {
        _correctCount++;
      }
    });

    // Move to next question automatically after a short delay
    Future.delayed(const Duration(milliseconds: 800), () async {
      if (mounted && _currentQuestionIndex < (_lessonData?['questions'] as List).length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _selectedAnswer = null;
        });
      } else if (mounted) {
        // Show results
        setState(() => _showResults = true);
        await _saveProgress();
      }
    });
  }

  Future<void> _saveProgress() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('❌ Error: User not authenticated');
        return;
      }

      final questions = _lessonData?['questions'] as List<LessonQuestion>? ?? [];
      // For normal lessons, progress is completion-based.
      // Accuracy is still tracked by correctAnswers.
      final progressPercentage = questions.isEmpty ? 0 : 100;

      print('🔄 Saving progress for lesson ${widget.lesson.id}...');
      print('📊 Progress data - Correct: $_correctCount / Total: ${questions.length} (${progressPercentage}%)');

      final result = await _lessonService.updateUserProgress(
        userId: user.id,
        lessonId: widget.lesson.id,
        completed: questions.isNotEmpty,
        progressPercentage: progressPercentage,
        correctAnswers: _correctCount,
        totalAttempts: questions.length,
      );

      if (result) {
        print('✅ Progress saved successfully!');
        context.read<LessonProvider>().markSystemLessonActivity(
          widget.lesson.parentLessonId ?? widget.lesson.id,
        );
        // Show success toast
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEnglish ? 'Progress saved' : 'Đã lưu tiến độ'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('❌ Failed to save progress');
      }
    } catch (e) {
      print('❌ Error saving progress: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEnglish ? 'Error saving progress' : 'Lỗi lưu tiến độ'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Save sub-lesson progress when completing alphabet or quiz
  Future<void> _saveSubLessonProgress({
    required String subLessonId,
    required bool completed,
    required int progressPercentage,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('❌ Error: User not authenticated');
        return;
      }

      print('💾 Saving sub-lesson progress: $subLessonId ($progressPercentage%)');

      final result = await _lessonService.updateUserProgress(
        userId: user.id,
        lessonId: subLessonId,
        completed: completed,
        progressPercentage: progressPercentage,
        correctAnswers: progressPercentage,
        totalAttempts: 100,
      );

      if (result) {
        print('✅ Sub-lesson progress saved!');
        context.read<LessonProvider>().markSystemLessonActivity(widget.lesson.id);
      } else {
        print('❌ Failed to save sub-lesson progress');
      }
    } catch (e) {
      print('❌ Error saving sub-lesson progress: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 🆕 Show vocabulary cards first (Part 1 of lesson)
    if (_showVocabularyCards) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && _currentSubLesson != null) {
        return VocabularyCardsScreen(
          lessonId: _currentSubLesson!.id,
          userId: user.id,
          isEnglish: _isEnglish,
          onComplete: _handleVocabularyComplete,
          cardLimit: 10,
        );
      }
    }

    // If showing questions, show the question screen
    if (_showQuestions || !widget.lesson.isParent) {
      if (_showResults) {
        return _buildResultScreen();
      }
      if (_lessonData == null) {
        return Scaffold(
          body: Center(
            child: Text(_isEnglish ? 'Error loading lesson' : 'Lỗi tải bài học'),
          ),
        );
      }
      // Check if it's an alphabet/phonetics lesson
      if (_currentSubLesson != null && 
          (_currentSubLesson!.title.contains('Alphabet') || 
           _currentSubLesson!.title.contains('Vowels') || 
           _currentSubLesson!.title.contains('Consonants'))) {
        return _buildAlphabetScreen();
      }
      return _buildLessonScreen();
    }

    // Otherwise show course detail screen with sub-lessons
    return _buildCourseDetailScreen();
  }

  Widget _buildCourseDetailScreen() {
    final totalDuration = _subLessons.fold<int>(
      0,
      (sum, lesson) => sum + (lesson.durationMinutes ?? 0),
    );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              size: 24,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                        Text(
                          _isEnglish ? 'Course Details' : 'Chi tiết Khóa học',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        GestureDetector(
                          onTap: _toggleFavorite,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                )
                              ],
                            ),
                            child: Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              size: 22,
                              color: _isFavorite ? Colors.red : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Course Banner with YouTube Video
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor.withOpacity(0.2),
                              blurRadius: 16,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: _buildCourseVideoBanner(),
                      ),
                    ),
                  ),

                  // Course Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.lesson.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                  height: 1.2,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Color(0xFFEAB308),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '4.8',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.lesson.description,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stats
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _buildStatCard(
                          backgroundColor: const Color(0xFFE0F2FE),
                          icon: Icons.description_outlined,
                          iconColor: AppColors.primaryColor,
                          label: _isEnglish ? 'Lessons' : 'Bài học',
                          value: _subLessons.length.toString(),
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          backgroundColor: const Color(0xFFFFEDD5),
                          icon: Icons.schedule_outlined,
                          iconColor: const Color(0xFFFB923C),
                          label: _isEnglish ? 'Time' : 'Thời gian',
                          value: '${totalDuration}m',
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          backgroundColor: const Color(0xFFEDE9FE),
                          icon: Icons.person_outline,
                          iconColor: const Color(0xFFA78BFA),
                          label: _isEnglish ? 'Level' : 'Trình độ',
                          value: widget.lesson.level.replaceFirst(
                            widget.lesson.level[0],
                            widget.lesson.level[0].toUpperCase(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Course Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _isEnglish ? 'Course Content' : 'Nội dung Khóa học',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Lessons List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ..._subLessons
                            .asMap()
                            .entries
                            .map((entry) =>
                                _buildLessonItem(entry.key + 1, entry.value))
                            .toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Start Button at Bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: GestureDetector(
                  onTap: _subLessons.isNotEmpty
                      ? () {
                          setState(() {
                            _currentSubLesson = _subLessons[0];
                            _showQuestions = false;
                            _isLoading = true;
                          });
                          _loadQuestions();
                        }
                      : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isEnglish ? 'Start Learning' : 'Bắt đầu học',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required Color backgroundColor,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build course banner with YouTube video - Thumbnail + Play button
  Widget _buildCourseVideoBanner() {
    // Get video URL from lesson
    String? videoUrl = widget.lesson.videoUrl;
    
    print('🎬 VIDEO BANNER: videoUrl = $videoUrl');
    
    if (videoUrl == null || videoUrl.isEmpty) {
      print('⚠️ VIDEO BANNER: No video URL found, showing placeholder');
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor.withOpacity(0.3),
              AppColors.primaryColor.withOpacity(0.1),
            ],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.play_circle_outline,
            size: 64,
            color: Color(0xFF6DD5FA),
          ),
        ),
      );
    }

    // Extract video ID
    String extractVideoId(String url) {
      String videoId = '';
      url = url.trim();
      
      if (url.contains('youtube.com/embed/')) {
        videoId = url.split('youtube.com/embed/')[1].split('?')[0];
      } else if (url.contains('youtu.be/')) {
        videoId = url.split('youtu.be/')[1].split('?')[0];
      } else if (url.contains('youtube.com/watch?v=')) {
        videoId = url.split('v=')[1].split('&')[0];
      } else if (url.contains('v=')) {
        videoId = url.split('v=')[1].split('&')[0];
      } else {
        videoId = url;
      }
      
      videoId = videoId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
      print('🎬 VIDEO BANNER: Extracted videoId = "$videoId" (length: ${videoId.length})');
      return videoId;
    }

    final videoId = extractVideoId(videoUrl);
    final youtubeUrl = 'https://www.youtube.com/watch?v=$videoId';
    final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
    
    return GestureDetector(
      onTap: () async {
        print('🎬 VIDEO BANNER: Opening YouTube - $youtubeUrl');
        try {
          final Uri uri = Uri.parse(youtubeUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            // Fallback: try to launch without mode
            await launchUrl(uri);
          }
        } catch (e) {
          print('❌ Error launching YouTube: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isEnglish ? 'Cannot open video' : 'Không thể mở video'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Thumbnail Image
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.black,
            ),
            child: Image.network(
              thumbnailUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if thumbnail load fails
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryColor.withOpacity(0.3),
                        AppColors.primaryColor.withOpacity(0.1),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Dark overlay
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
            ),
          ),
          // Play Button
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.95),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.play_arrow,
                size: 48,
                color: Color(0xFFFF0000), // YouTube red
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonItem(int index, Lesson lesson) {
    // Determine if this lesson is locked
    bool isLocked = false;
    bool isCompleted = _lessonCompletion[index - 1] ?? false;
    bool isCurrent = _currentLessonIndex == (index - 1) && !isCompleted;
    
    // Locking logic: lesson is locked if any previous lesson is not completed
    if (index > 1) {
      for (int i = 0; i < index - 1; i++) {
        if (!(_lessonCompletion[i] ?? false)) {
          isLocked = true;
          break;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: isLocked
            ? null
            : () {
                setState(() {
                  _currentSubLesson = lesson;
                  _currentLessonIndex = index - 1;
                  _showQuestions = false;
                  _isLoading = true;
                });
                _loadQuestions();
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isCurrent
                ? AppColors.primaryColor.withOpacity(0.08)
                : (isLocked ? const Color(0xFFF9FAFB) : Colors.white),
            border: Border.all(
              color: isCurrent
                  ? AppColors.primaryColor.withOpacity(0.3)
                  : (isLocked ? const Color(0xFFE5E7EB) : const Color(0xFFE5E7EB)),
              width: isCurrent ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Opacity(
            opacity: isLocked ? 0.6 : 1.0,
            child: Row(
              children: [
                // Number Circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent
                        ? AppColors.primaryColor
                        : _getColorForIndex(index),
                  ),
                  child: Center(
                    child: Text(
                      index.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Lesson Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCurrent
                            ? (_isEnglish
                                ? 'Current Lesson • ${lesson.durationMinutes}m'
                                : 'Bài hiện tại • ${lesson.durationMinutes}m')
                            : '${lesson.durationMinutes}m',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                          color: isCurrent
                              ? AppColors.primaryColor
                              : (isLocked ? const Color(0xFFCBD5E1) : const Color(0xFF9CA3AF)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Action Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent
                        ? AppColors.primaryColor
                        : (isCompleted ? const Color(0xFF34D399) : const Color(0xFFF3F4F6)),
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle
                        : (isCurrent ? Icons.equalizer : (isLocked ? Icons.lock : Icons.play_arrow)),
                    size: 18,
                    color: isCurrent || isCompleted ? Colors.white : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForIndex(int index) {
    const colors = [
      Color(0xFF14B8A6), // teal
      Color(0xFF3B82F6), // blue
      Color(0xFFF97316), // orange
      Color(0xFF8B5CF6), // purple
    ];
    return colors[(index - 1) % colors.length];
  }

  Widget _buildAlphabetScreen() {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () async {
                      // ✅ Save progress before exiting
                      if (_currentLessonIndex != null && _currentSubLesson != null) {
                        await _saveSubLessonProgress(
                          subLessonId: _currentSubLesson!.id,
                          completed: true,
                          progressPercentage: 100, // Alphabet lessons are 100% when viewed
                        );
                        // Mark as completed in UI
                        if (mounted) {
                        setState(() {
                          _lessonCompletion[_currentLessonIndex!] = true;
                          _currentSubLesson = null;
                          _showQuestions = false;
                        });
                          // ✅ Reload ALL completions to ensure unlocking works
                          await _reloadSubLessonCompletions();
                        }
                      }
                    },
                    child: const Icon(Icons.arrow_back, size: 24),
                  ),
                  Expanded(
                    child: Text(
                      _currentSubLesson?.title ?? widget.lesson.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),

            // Grid Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: _buildAlphabetCards(),
                  ),
                ),
              ),
            ),

            // Volume Control at Bottom
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: const Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.volume_up,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Slider(
                            value: 1.0,
                            onChanged: (value) {
                              _lessonService.setVolume(value);
                            },
                            activeColor: AppColors.primaryColor,
                            inactiveColor: const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '100%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
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

  List<Widget> _buildAlphabetCards() {
    // Get content based on sub-lesson title
    final lessonTitle = _currentSubLesson?.title ?? '';
    
    List<Map<String, dynamic>> alphabets = [];

    if (lessonTitle.contains('Vowels')) {
      // Only Vowels
      alphabets = [
        {'letter': 'a', 'phonetic': '/eɪ/', 'icon': Icons.abc},
        {'letter': 'e', 'phonetic': '/iː/', 'icon': Icons.egg},
        {'letter': 'i', 'phonetic': '/aɪ/', 'icon': Icons.info},
        {'letter': 'o', 'phonetic': '/oʊ/', 'icon': Icons.circle_outlined},
        {'letter': 'u', 'phonetic': '/juː/', 'icon': Icons.umbrella},
        {'letter': 'ʌ', 'phonetic': '/ʌ/', 'icon': Icons.arrow_downward},
        {'letter': 'ə', 'phonetic': '/ə/', 'icon': Icons.blur_on},
        {'letter': 'æ', 'phonetic': '/æ/', 'icon': Icons.aod},
      ];
    } else if (lessonTitle.contains('Consonants')) {
      // Only Consonants
      alphabets = [
        {'letter': 'b', 'phonetic': '/biː/', 'icon': Icons.sports_soccer},
        {'letter': 'c', 'phonetic': '/siː/', 'icon': Icons.pets},
        {'letter': 'd', 'phonetic': '/diː/', 'icon': Icons.cruelty_free},
        {'letter': 'f', 'phonetic': '/ef/', 'icon': Icons.set_meal},
        {'letter': 'g', 'phonetic': '/dʒiː/', 'icon': Icons.sports_golf},
        {'letter': 'h', 'phonetic': '/eɪtʃ/', 'icon': Icons.home},
        {'letter': 'j', 'phonetic': '/dʒeɪ/', 'icon': Icons.sports_basketball},
        {'letter': 'k', 'phonetic': '/keɪ/', 'icon': Icons.vpn_key},
        {'letter': 'l', 'phonetic': '/el/', 'icon': Icons.line_weight},
        {'letter': 'm', 'phonetic': '/em/', 'icon': Icons.movie},
        {'letter': 'n', 'phonetic': '/en/', 'icon': Icons.notifications},
        {'letter': 'p', 'phonetic': '/piː/', 'icon': Icons.location_city},
        {'letter': 'q', 'phonetic': '/kjuː/', 'icon': Icons.help_outline},
        {'letter': 'r', 'phonetic': '/ɑːr/', 'icon': Icons.radio},
        {'letter': 's', 'phonetic': '/es/', 'icon': Icons.star},
        {'letter': 't', 'phonetic': '/tiː/', 'icon': Icons.restaurant},
        {'letter': 'v', 'phonetic': '/viː/', 'icon': Icons.volume_up},
        {'letter': 'w', 'phonetic': '/dʌbəljuː/', 'icon': Icons.water},
        {'letter': 'x', 'phonetic': '/eks/', 'icon': Icons.close},
        {'letter': 'y', 'phonetic': '/waɪ/', 'icon': Icons.emoji_nature},
        {'letter': 'z', 'phonetic': '/zed/', 'icon': Icons.zoom_in},
      ];
    } else {
      // Basic Alphabet - 26 Standard English Letters
      alphabets = [
        {'letter': 'a', 'phonetic': '/eɪ/', 'icon': Icons.abc},
        {'letter': 'b', 'phonetic': '/biː/', 'icon': Icons.sports_soccer},
        {'letter': 'c', 'phonetic': '/siː/', 'icon': Icons.pets},
        {'letter': 'd', 'phonetic': '/diː/', 'icon': Icons.cruelty_free},
        {'letter': 'e', 'phonetic': '/iː/', 'icon': Icons.egg},
        {'letter': 'f', 'phonetic': '/ef/', 'icon': Icons.set_meal},
        {'letter': 'g', 'phonetic': '/dʒiː/', 'icon': Icons.sports_golf},
        {'letter': 'h', 'phonetic': '/eɪtʃ/', 'icon': Icons.home},
        {'letter': 'i', 'phonetic': '/aɪ/', 'icon': Icons.info},
        {'letter': 'j', 'phonetic': '/dʒeɪ/', 'icon': Icons.sports_basketball},
        {'letter': 'k', 'phonetic': '/keɪ/', 'icon': Icons.vpn_key},
        {'letter': 'l', 'phonetic': '/el/', 'icon': Icons.line_weight},
        {'letter': 'm', 'phonetic': '/em/', 'icon': Icons.movie},
        {'letter': 'n', 'phonetic': '/en/', 'icon': Icons.notifications},
        {'letter': 'o', 'phonetic': '/oʊ/', 'icon': Icons.circle_outlined},
        {'letter': 'p', 'phonetic': '/piː/', 'icon': Icons.location_city},
        {'letter': 'q', 'phonetic': '/kjuː/', 'icon': Icons.help_outline},
        {'letter': 'r', 'phonetic': '/ɑːr/', 'icon': Icons.radio},
        {'letter': 's', 'phonetic': '/es/', 'icon': Icons.star},
        {'letter': 't', 'phonetic': '/tiː/', 'icon': Icons.restaurant},
        {'letter': 'u', 'phonetic': '/juː/', 'icon': Icons.umbrella},
        {'letter': 'v', 'phonetic': '/viː/', 'icon': Icons.volume_up},
        {'letter': 'w', 'phonetic': '/dʌbəljuː/', 'icon': Icons.water},
        {'letter': 'x', 'phonetic': '/eks/', 'icon': Icons.close},
        {'letter': 'y', 'phonetic': '/waɪ/', 'icon': Icons.emoji_nature},
        {'letter': 'z', 'phonetic': '/zed/', 'icon': Icons.zoom_in},
      ];
    }

    return alphabets.map((item) {
      return GestureDetector(
        onTap: () {
          _lessonService.speak('${item['letter']}');
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        size: 20,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    // Letter and Phonetic
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['letter'] as String,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['phonetic'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Hover effect indicator
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.volume_up,
                    size: 14,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLessonScreen() {
    final questions = _lessonData!['questions'] as List<LessonQuestion>;
    final options = _lessonData!['options'] as Map<String, List<LessonOption>>;

    if (questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(_isEnglish ? 'No questions found' : 'Không tìm thấy câu hỏi'),
        ),
      );
    }

    final currentQuestion = questions[_currentQuestionIndex];
    final currentOptions = options[currentQuestion.id] ?? [];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(questions.length),

            // Progress bar
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / questions.length,
              minHeight: 4,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primaryColor,
              ),
            ),

            // Question
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question text
                    Text(
                      currentQuestion.questionText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Audio button if available
                    if (currentQuestion.audioUrl != null &&
                        currentQuestion.audioUrl!.isNotEmpty)
                      GestureDetector(
                        onTap: () =>
                            _lessonService.speak(currentQuestion.questionText),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.volume_up,
                                color: AppColors.primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isEnglish ? 'Listen to pronunciation' : 'Nghe phát âm',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Options
                    ...currentOptions.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final option = entry.value;
                      final isSelected = _selectedAnswer == option.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => _selectAnswer(option.id, option.isCorrect),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (option.isCorrect
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1))
                                  : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? (option.isCorrect
                                        ? Colors.green
                                        : Colors.red)
                                    : const Color(0xFFE5E7EB),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? (option.isCorrect
                                            ? Colors.green
                                            : Colors.red)
                                        : const Color(0xFFE5E7EB),
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + idx), // A, B, C, D...
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option.optionText,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    option.isCorrect
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color:
                                        option.isCorrect ? Colors.green : Colors.red,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    // Explanation
                    if (_selectedAnswer != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isEnglish ? 'Explanation:' : 'Giải thích:',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currentQuestion.explanation ??
                                    'No explanation available',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4B5563),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int totalQuestions) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(Icons.arrow_back, size: 24),
          ),
          Column(
            children: [
              Text(
                widget.lesson.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                '${_currentQuestionIndex + 1}/$totalQuestions',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$_correctCount/$totalQuestions',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final questions = _lessonData!['questions'] as List<LessonQuestion>;
    final totalQuestions = questions.length;
    final percentage = (((_correctCount / totalQuestions) * 100).toInt());
    final isPassed = percentage >= 70;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Result circle
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPassed ? Colors.green : Colors.orange,
                        boxShadow: [
                          BoxShadow(
                            color: (isPassed ? Colors.green : Colors.orange)
                                .withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$percentage%',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Message
                    Text(
                      isPassed
                          ? (_isEnglish ? 'Great Job!' : 'Tuyệt vời!')
                          : (_isEnglish ? 'Good Try!' : 'Cố gắng nha!'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      _isEnglish
                          ? 'You got $_correctCount out of $totalQuestions correct'
                          : 'Bạn trả lời đúng $_correctCount trong $totalQuestions câu',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Stats
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            _isEnglish ? 'Correct' : 'Đúng',
                            _correctCount.toString(),
                            Colors.green,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: const Color(0xFFE5E7EB),
                          ),
                          _buildStatItem(
                            _isEnglish ? 'Wrong' : 'Sai',
                            (totalQuestions - _correctCount).toString(),
                            Colors.red,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Mark lesson as completed when going back
                        if (_currentLessonIndex != null) {
                          setState(() {
                            _lessonCompletion[_currentLessonIndex!] = true;
                            _currentSubLesson = null;
                            _showQuestions = false;
                          });
                        }
                        // Wait a moment to ensure data is saved, then navigate back
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Center(
                          child: Text(
                            _isEnglish ? 'Back' : 'Quay lại',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentQuestionIndex = 0;
                          _selectedAnswer = null;
                          _userAnswers = List<String?>.filled(
                            (_lessonData?['questions'] as List?)?.length ?? 0,
                            null,
                          );
                          _correctCount = 0;
                          _showResults = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            _isEnglish ? 'Retry' : 'Làm lại',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _lessonService.stop();
    super.dispose();
  }
}
