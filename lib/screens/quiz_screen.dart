import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/lesson_model.dart';
import '../services/lesson_service.dart';
import '../services/language_service.dart';
import '../providers/lesson_provider.dart';
import '../utils/constants.dart';

class QuizScreen extends StatefulWidget {
  final Lesson lesson;
  final Function(bool completed)? onComplete;

  const QuizScreen({
    Key? key,
    required this.lesson,
    this.onComplete,
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late LessonService _lessonService;
  int _currentQuestionIndex = 0;
  Map<String, dynamic>? _lessonData;
  bool _isLoading = true;
  String? _selectedAnswer;
  List<String?> _userAnswers = [];
  int _correctCount = 0;
  bool _showResults = false;
  bool _showExplanation = false;
  
  // For matching questions
  Map<String, String> _matchedPairs = {};
  String? _selectedMatchItem;
  
  // For fill blank questions
  final TextEditingController _fillBlankController = TextEditingController();
  late FocusNode _fillBlankFocusNode;
  bool _fillBlankSubmitted = false;

  // For dictation questions
  final TextEditingController _dictationController = TextEditingController();
  late FocusNode _dictationFocusNode;
  bool _dictationSubmitted = false;
  bool _dictationPlayed = false;

  // For conversation questions
  final TextEditingController _conversationController = TextEditingController();
  late FocusNode _conversationFocusNode;
  bool _conversationSubmitted = false;

  bool get _isEnglish => context.read<LanguageService>().isEnglish;

  @override
  void initState() {
    super.initState();
    _lessonService = LessonService();
    _fillBlankFocusNode = FocusNode();
    _dictationFocusNode = FocusNode();
    _conversationFocusNode = FocusNode();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final data = await _lessonService.getLessonDetails(widget.lesson.id);
      if (mounted) {
        setState(() {
          _lessonData = data;
          _isLoading = false;
          _userAnswers = List<String?>.filled(
            (data?['questions'] as List?)?.length ?? 0,
            null,
          );
        });
        
        // DEBUG: Print question types
        if (data != null) {
          final questions = data['questions'] as List<LessonQuestion>?;
          if (questions != null) {
            print('📚 QUESTIONS LOADED: ${questions.length} total');
            for (int i = 0; i < questions.length; i++) {
              final q = questions[i];
              final text = q.questionText.length > 50 
                  ? q.questionText.substring(0, 50) 
                  : q.questionText;
              print('  Q$i: type="${q.questionType}" | text="$text..."');
            }
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

  void _selectAnswer(String optionId) {
    if (_showExplanation) return;
    
    setState(() {
      _selectedAnswer = optionId;
    });
  }

  void _submitChoiceAnswer(LessonQuestion question) {
    if (_selectedAnswer == null) return;

    final options = _lessonData!['options'] as Map<String, List<LessonOption>>;
    final currentOptions = options[question.id] ?? [];
    final selected = currentOptions.where((o) => o.id == _selectedAnswer).toList();
    final isCorrect = selected.isNotEmpty && selected.first.isCorrect;

    setState(() {
      _userAnswers[_currentQuestionIndex] = _selectedAnswer;
      if (isCorrect) {
        _correctCount++;
      }
      _showExplanation = true;
    });

    _showPenguinPopup(isCorrect);

    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (mounted) {
        await _moveToNextQuestion();
      }
    });
  }

  void _submitFillBlank(String correctAnswer) {
    if (_fillBlankSubmitted) return;
    bool isCorrect = false;
    
    setState(() {
      _fillBlankSubmitted = true;
      final userAnswer = _fillBlankController.text.trim().toLowerCase();
      isCorrect = userAnswer == correctAnswer.toLowerCase();
      
      _userAnswers[_currentQuestionIndex] = userAnswer;
      if (isCorrect) {
        _correctCount++;
      }
      _showExplanation = true;
    });

    _showPenguinPopup(isCorrect);

    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (mounted) {
        await _moveToNextQuestion();
      }
    });
  }

  void _submitMatching() {
    final questions = _lessonData!['questions'] as List<LessonQuestion>;
    final currentQuestion = questions[_currentQuestionIndex];
    final options = _lessonData!['options'] as Map<String, List<LessonOption>>;
    final currentOptions = options[currentQuestion.id] ?? [];
    
    int correctMatches = 0;
    for (var option in currentOptions) {
      if (option.matchPairId != null && _matchedPairs[option.id] == option.matchPairId) {
        correctMatches++;
      }
    }
    
    // Count unique pairs
    final totalPairs = currentOptions.where((o) => o.matchPairId != null).length ~/ 2;
    
    final isCorrect = correctMatches >= totalPairs;

    if (isCorrect) {
      _correctCount++;
    }
    
    setState(() {
      _showExplanation = true;
    });

    _showPenguinPopup(isCorrect);

    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (mounted) {
        await _moveToNextQuestion();
      }
    });
  }

  Future<void> _moveToNextQuestion() async {
    final questions = _lessonData!['questions'] as List<LessonQuestion>;
    
    // Unfocus all text fields
    _fillBlankFocusNode.unfocus();
    _dictationFocusNode.unfocus();
    
    if (_currentQuestionIndex < questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _showExplanation = false;
        _matchedPairs.clear();
        _selectedMatchItem = null;
        _fillBlankController.clear();
        _fillBlankSubmitted = false;
        _dictationController.clear();
        _dictationSubmitted = false;
        _dictationPlayed = false;
        _conversationController.clear();
        _conversationSubmitted = false;
      });
    } else {
      setState(() => _showResults = true);
      // Save progress immediately when quiz is completed
      await _saveProgress();
      if (widget.onComplete != null) {
        widget.onComplete!(true);
      }
    }
  }

  Future<void> _saveProgress() async {
    try {
      final user = _lessonService.supabase.auth.currentUser;
      if (user == null) {
        print('❌ Error: User not authenticated for progress save');
        return;
      }

      final questions = _lessonData!['questions'] as List<LessonQuestion>? ?? [];
      // For normal lessons, completion progress is based on finishing the quiz,
      // while score is kept in correctAnswers.
      final progressPercentage = questions.isEmpty ? 0 : 100;
      final isCompleted = questions.isNotEmpty;

      print('🔄 Saving quiz progress...');
      print('📊 Quiz: ${widget.lesson.title}');
      print('📊 Score: $_correctCount/${questions.length} (${progressPercentage}%)');

      final result = await _lessonService.updateUserProgress(
        userId: user.id,
        lessonId: widget.lesson.id,
        completed: isCompleted,
        progressPercentage: progressPercentage,
        correctAnswers: _correctCount,
        totalAttempts: questions.length,
      );

      if (result) {
        print('✅ Quiz progress saved successfully!');
        final provider = context.read<LessonProvider>();
        provider.markSystemLessonActivity(widget.lesson.parentLessonId ?? widget.lesson.id);
      } else {
        print('❌ Failed to save quiz progress');
      }
    } catch (e) {
      print('❌ Error saving quiz progress: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_showResults) {
      return _buildResultScreen();
    }

    if (_lessonData == null) {
      return Scaffold(
        body: Center(
          child: Text(_isEnglish ? 'Error loading quiz' : 'Lỗi tải bài quiz'),
        ),
      );
    }

    final questions = _lessonData!['questions'] as List<LessonQuestion>;
    if (questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(_isEnglish ? 'No questions found' : 'Không tìm thấy câu hỏi'),
        ),
      );
    }

    final currentQuestion = questions[_currentQuestionIndex];
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(questions.length),
            _buildProgressBar(questions.length),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: _buildQuestionCard(currentQuestion),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int totalQuestions) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, size: 20),
            ),
          ),
          Column(
            children: [
              Text(
                widget.lesson.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              Text(
                '${_currentQuestionIndex + 1}/$totalQuestions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_correctCount/${_currentQuestionIndex + (_showExplanation ? 1 : 0)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int totalQuestions) {
    return LinearProgressIndicator(
      value: (_currentQuestionIndex + 1) / totalQuestions,
      minHeight: 6,
      backgroundColor: const Color(0xFFE5E7EB),
      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
    );
  }

  Widget _buildQuestionCard(LessonQuestion question) {
    final questionType = _resolveQuestionType(question);
    final processedText = _processQuestionText(question);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question type badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getQuestionTypeColor(questionType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getQuestionTypeLabel(questionType),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getQuestionTypeColor(questionType),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Question text (processed with keyword replacement)
        Text(
          processedText,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
            height: 1.4,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Vietnamese text for translation
        if (question.vietnameseText != null && question.vietnameseText!.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              question.vietnameseText!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
        
        const SizedBox(height: 20),
        
        // Audio button
        if (question.audioUrl != null && question.audioUrl!.isNotEmpty)
          _buildAudioButton(question.questionText),
        
        const SizedBox(height: 20),
        
        // Question content based on type
        _buildQuestionContent(question),
        
        // Explanation
        if (_showExplanation && question.explanation != null)
          _buildExplanation(question.explanation!),
        
        if (!['fill_blank', 'matching', 'dictation', 'conversation', 'unscramble', 'spelling']
            .contains(_resolveQuestionType(question))) ...[
          const SizedBox(height: 24),
          _buildActionButton(question),
        ],
      ],
    );
  }

  String _processQuestionText(LessonQuestion question) {
    final answer = question.correctAnswer ?? '';
    return question.questionText.replaceAll('{keyword}', answer);
  }

  Widget _buildUnifiedSubmitButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22C55E),
          disabledBackgroundColor: const Color(0xFFE5E7EB),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  void _showPenguinPopup(bool isCorrect) {
    if (isCorrect) {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
    } else {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) {
            Navigator.of(dialogContext).pop();
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    isCorrect
                        ? 'assets/image/happy.png'
                        : 'assets/image/sad.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isCorrect
                      ? (_isEnglish ? 'Great Job!' : 'Đúng rồi!')
                      : (_isEnglish ? 'Try Again!' : 'Sai rồi!'),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build action button (Check answer or Continue)
  Widget _buildActionButton(LessonQuestion question) {
    final isAnswered = _selectedAnswer != null || 
                       _fillBlankSubmitted || 
                       _dictationSubmitted ||
                       _matchedPairs.isNotEmpty;
    
    final buttonText = _showExplanation 
        ? (_isEnglish ? 'Continue' : 'Tiếp tục')
        : (_isEnglish ? 'Check Answer' : 'Kiểm tra đáp án');
    
    return _buildUnifiedSubmitButton(
      label: buttonText,
      onPressed: isAnswered
          ? () {
              if (!_showExplanation) {
                _submitAnswer(question);
              } else {
                _moveToNextQuestion();
              }
            }
          : null,
    );
  }

  /// Submit answer - handles different question types
  void _submitAnswer(LessonQuestion question) {
    final questionType = _resolveQuestionType(question);
    
    switch (questionType) {
      case 'fill_blank':
      case 'unscramble':
      case 'spelling':
        _submitFillBlank(question.correctAnswer ?? '');
        break;
      case 'matching':
        _submitMatching();
        break;
      case 'dictation':
        _submitDictation(question.correctAnswer ?? '');
        break;
      case 'multiple_choice':
      case 'mcq_en_vi':
      case 'mcq_vi_en':
      case 'true_false':
      case 'translation':
      case 'listening_choice':
      case 'listening':
        _submitChoiceAnswer(question);
        break;
      case 'conversation':
      default:
        break;
    }
  }

  Widget _buildQuestionContent(LessonQuestion question) {
    final questionType = _resolveQuestionType(question);
    print('🧩 Render dispatch: ${question.id} => $questionType');
    return KeyedSubtree(
      key: ValueKey('${question.id}-$questionType'),
      child: _buildByType(questionType, question),
    );
  }

  String _resolveQuestionType(LessonQuestion question) {
    final rawType = _normalizeQuestionType(question.questionType);
    final preview = question.questionText.length > 60
        ? '${question.questionText.substring(0, 60)}...'
        : question.questionText;

    print('🔍 DEBUG - Raw type from DB: "$rawType" | Text: "$preview"');

    // Priority 1: use DB type when available.
    if (rawType.isNotEmpty) {
      print('✅ Using DB type: $rawType');
      return rawType;
    }

    // Priority 2: detect from content/options.
    final detectedType = _detectQuestionType(question);
    print('🔍 Detected type: $detectedType');
    return detectedType;
  }

  String _normalizeQuestionType(String? type) {
    final normalized = (type ?? '').toLowerCase().trim();

    switch (normalized) {
      case 'mcq':
      case 'multiple-choice':
        return 'multiple_choice';
      case 'listen_choice':
        return 'listening_choice';
      default:
        return normalized;
    }
  }

  /// Render by resolved type
  Widget _buildByType(String type, LessonQuestion question) {
    print('🎯 buildByType() => $type for ${question.id}');
    switch (type) {
      case 'mcq_en_vi':
      case 'true_false':
        return _buildMultipleChoice(question);
      case 'mcq_vi_en':
      case 'translation':
        return _buildTranslation(question);
      case 'fill_blank':
      case 'unscramble':
      case 'spelling':
        return _buildFillBlank(question);
      case 'matching':
        return _buildMatching(question);
      case 'dictation':
        return _buildDictation(question);
      case 'conversation':
        return _buildConversation(question);
      case 'listening_choice':
      case 'listening':
        return _buildListeningChoice(question);
      case 'multiple_choice':
        return _buildMultipleChoice(question);
      default:
        return _buildMultipleChoice(question);
    }
  }

  String _detectQuestionType(LessonQuestion question) {
    final text = question.questionText.toLowerCase().trim();

    // 1. Translation
    if (text.contains('translate') ||
        text.contains('dịch') ||
        text.contains('what does') ||
        text.contains('nghĩa là') ||
        text.contains('có nghĩa')) {
      return 'translation';
    }

    // 2. Fill blank
    if (text.contains('fill') ||
        text.contains('blank') ||
        text.contains('điền') ||
        text.contains('___') ||
        text.contains('_____') ||
        text.contains('the _______') ||
        text.contains('chỗ trống')) {
      return 'fill_blank';
    }

    if (text.contains('sắp xếp') ||
        text.contains('unscramble') ||
        text.contains('chữ cái')) {
      return 'unscramble';
    }

    // 3. Dictation
    if (text.contains('listen and spell') ||
        text.contains('listen and type') ||
        text.contains('nghe và gõ') ||
        text.contains('chính tả') ||
        text.contains('spell the word') ||
        text.contains('type what you hear')) {
      return 'dictation';
    }

    if (text.contains('viết đúng chính tả') ||
        text.contains('spelling from meaning')) {
      return 'spelling';
    }

    // 4. Matching by content
    if (text.contains('match') ||
        text.contains('ghép') ||
        text.contains('nối') ||
        text.contains('pair')) {
      return 'matching';
    }

    // 5. Conversation
    if (text.contains('conversation') ||
        text.contains('hội thoại') ||
        text.contains('dialogue') ||
        text.contains('dialog') ||
        text.contains('a:') ||
        text.contains('b:') ||
        text.contains('respond') ||
        text.contains('trả lời')) {
      return 'conversation';
    }

    // 6. Listening choice
    if (text.contains('listen and select') ||
        text.contains('listen and choose') ||
        text.contains('nghe và chọn')) {
      return 'listening_choice';
    }

    // 7. Option-based matching detection
    try {
      final options = _lessonData!['options'] as Map<String, List<LessonOption>>;
      final currentOptions = options[question.id] ?? [];

      if (currentOptions.isNotEmpty && currentOptions.any((o) => o.matchPairId != null)) {
        return 'matching';
      }
    } catch (e) {
      print('⚠️ Error checking matching options: $e');
    }

    return 'multiple_choice';
  }

  Widget _buildMultipleChoice(LessonQuestion question) {
    final options = _lessonData!['options'] as Map<String, List<LessonOption>>;
    final currentOptions = options[question.id] ?? [];
    
    return Column(
      children: currentOptions.map((option) {
        final isSelected = _selectedAnswer == option.id;
        final showResult = _showExplanation && isSelected;
        final showSelected = !_showExplanation && isSelected;
        final isCorrect = option.isCorrect;
        
        return GestureDetector(
          onTap: () => _selectAnswer(option.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: showResult
                  ? (isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1))
                  : (showSelected
                      ? AppColors.primaryColor.withOpacity(0.1)
                      : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: showResult
                    ? (isCorrect ? Colors.green : Colors.red)
                    : (showSelected
                        ? AppColors.primaryColor
                        : const Color(0xFFE5E7EB)),
                width: (showResult || showSelected) ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: showResult
                        ? (isCorrect ? Colors.green : Colors.red)
                        : (showSelected
                            ? AppColors.primaryColor
                            : const Color(0xFFF3F4F6)),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + currentOptions.indexOf(option)),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: (showResult || showSelected)
                            ? Colors.white
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.optionText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      if (option.optionImageUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              option.optionImageUrl!,
                              height: 80,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (showResult || showSelected)
                  Icon(
                    showResult
                        ? (isCorrect ? Icons.check_circle : Icons.cancel)
                        : Icons.check_circle,
                    color: showResult
                        ? (isCorrect ? Colors.green : Colors.red)
                        : AppColors.primaryColor,
                    size: 24,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFillBlank(LessonQuestion question) {
    print('✏️ _buildFillBlank() CALLED! Question: "${question.questionText.substring(0, 30)}..."');
    final correctAnswer = question.correctAnswer ?? '';
    print('✏️ Correct answer: "$correctAnswer"');
    final userAnswer = _fillBlankController.text.trim().toLowerCase();
    final isCorrect = _fillBlankSubmitted && userAnswer == correctAnswer.toLowerCase();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        // Input Field with fixed height
        SizedBox(
          height: 140,
          child: TextField(
          controller: _fillBlankController,
          enabled: !_fillBlankSubmitted,
            focusNode: _fillBlankFocusNode,
            minLines: 3,
            maxLines: null,
            autofocus: true,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: _isEnglish ? 'Type your answer here...' : 'Nhập câu trả lời...',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF9CA3AF),
              ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
            ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: GoogleFonts.inter(
            fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1F2937),
            ),
            onChanged: (value) {
              print('✏️ TEXT CHANGED: $value');
              setState(() {}); // Update button state
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildUnifiedSubmitButton(
          label: _isEnglish ? 'SUBMIT' : 'KIỂM TRA',
          onPressed: _fillBlankSubmitted || _fillBlankController.text.isEmpty
              ? null
              : () => _submitFillBlank(correctAnswer),
        ),
        if (_fillBlankSubmitted) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCorrect
                  ? Colors.green.withOpacity(0.12)
                  : Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                color: isCorrect
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? Colors.green[600] : Colors.red[600],
                  size: 20,
                  ),
                const SizedBox(width: 12),
                  Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                      isCorrect
                            ? (_isEnglish ? 'Correct!' : 'Đúng rồi!')
                            : (_isEnglish ? 'Incorrect' : 'Sai rồi'),
                        style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                          color: isCorrect ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isEnglish
                            ? 'Correct answer: $correctAnswer'
                            : 'Câu trả lời đúng: $correctAnswer',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isCorrect ? Colors.green[600] : Colors.red[600],
                    ),
                  ),
                ],
              ),
            ),
              ],
            ),
          ),
      ],
      ],
    );
  }

  Widget _buildMatching(LessonQuestion question) {
    final options = _lessonData!['options'] as Map<String, List<LessonOption>>;
    final currentOptions = options[question.id] ?? [];
    
    // Split into left and right columns
    final leftItems = currentOptions.where((o) => o.optionOrder % 2 == 1).toList();
    final rightItems = currentOptions.where((o) => o.optionOrder % 2 == 0).toList();
    
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column
            Expanded(
              child: Column(
                children: leftItems.map((item) {
                  final isSelected = _selectedMatchItem == item.id;
                  final isMatched = _matchedPairs.containsKey(item.id);
                  
                  return GestureDetector(
                    onTap: () {
                      if (!isMatched) {
                        setState(() {
                          _selectedMatchItem = isSelected ? null : item.id;
                        });
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryColor.withOpacity(0.1)
                            : (isMatched ? Colors.green.withOpacity(0.1) : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryColor
                              : (isMatched ? Colors.green : const Color(0xFFE5E7EB)),
                          width: isSelected || isMatched ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        item.optionText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Right column
            Expanded(
              child: Column(
                children: rightItems.map((item) {
                  final isMatched = _matchedPairs.containsValue(item.matchPairId);
                  
                  return GestureDetector(
                    onTap: () {
                      if (_selectedMatchItem != null && !isMatched) {
                        setState(() {
                          _matchedPairs[_selectedMatchItem!] = item.matchPairId ?? '';
                          _selectedMatchItem = null;
                        });
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isMatched ? Colors.green.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isMatched ? Colors.green : const Color(0xFFE5E7EB),
                          width: isMatched ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        item.optionText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        _buildUnifiedSubmitButton(
          label: _isEnglish ? 'SUBMIT' : 'KIỂM TRA',
          onPressed: _matchedPairs.length >= leftItems.length
              ? _submitMatching
              : null,
        ),
      ],
    );
  }

  Widget _buildTranslation(LessonQuestion question) {
    return _buildMultipleChoice(question);
  }

  Widget _buildConversation(LessonQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question.conversationContext != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              question.conversationContext!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
        const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: TextField(
              controller: _conversationController,
              enabled: !_conversationSubmitted,
              focusNode: _conversationFocusNode,
              minLines: 2,
              maxLines: 3,
              autofocus: true,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: _isEnglish ? 'Type your reply...' : 'Nhập câu trả lời...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF9CA3AF),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1F2937),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 16),
          _buildUnifiedSubmitButton(
            label: _isEnglish ? 'SUBMIT' : 'KIỂM TRA',
            onPressed: _conversationSubmitted || _conversationController.text.trim().isEmpty
                ? null
                : () {
                    final answer = _conversationController.text.trim();
                    final expected = (question.correctAnswer ?? '').trim().toLowerCase();
                    final isCorrect = expected.isEmpty
                        ? answer.isNotEmpty
                        : answer.toLowerCase().contains(expected);

                    setState(() {
                      _conversationSubmitted = true;
                      _userAnswers[_currentQuestionIndex] = answer;
                      if (isCorrect) {
                        _correctCount++;
                      }
                      _showExplanation = true;
                    });

                    _showPenguinPopup(isCorrect);

                    Future.delayed(const Duration(milliseconds: 2000), () {
                      if (mounted) {
                        _moveToNextQuestion();
                      }
                    });
                  },
          ),
      ],
    );
  }

  Widget _buildListeningChoice(LessonQuestion question) {
    final optionsMap = _lessonData!['options'] as Map<String, List<LessonOption>>;
    final currentOptions = optionsMap[question.id] ?? [];

    if (currentOptions.isEmpty) {
      return _buildMultipleChoice(question);
    }

    final options = currentOptions.map((o) => o.optionText).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.headphones,
                color: AppColors.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isEnglish
                      ? 'Listen to the audio and select the correct word'
                      : 'Nghe âm thanh và chọn từ đúng',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._buildListeningOptions(question, currentOptions, options),
      ],
    );
  }

  List<Widget> _buildListeningOptions(
    LessonQuestion question,
    List<LessonOption> optionModels,
    List<String> options,
  ) {
    return options.asMap().entries.map((entry) {
      int idx = entry.key;
      String option = entry.value;
      final model = optionModels[idx];
      bool isSelected = _selectedAnswer == model.id;
      bool showResult = _showExplanation && isSelected;
      bool showSelected = !_showExplanation && isSelected;
      bool isCorrect = model.isCorrect;

      return GestureDetector(
        onTap: () => _selectAnswer(model.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: showResult
                ? (isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1))
                : (showSelected
                    ? AppColors.primaryColor.withOpacity(0.1)
                    : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: showResult
                  ? (isCorrect ? Colors.green : Colors.red)
                  : (showSelected
                      ? AppColors.primaryColor
                      : const Color(0xFFE5E7EB)),
              width: (showResult || showSelected) ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: showResult
                      ? (isCorrect ? Colors.green : Colors.red)
                      : (showSelected
                          ? AppColors.primaryColor
                          : const Color(0xFFF3F4F6)),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + idx),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: (showResult || showSelected)
                          ? Colors.white
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.trim(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
              if (showResult || showSelected)
                Icon(
                  showResult
                      ? (isCorrect ? Icons.check_circle : Icons.cancel)
                      : Icons.check_circle,
                  color: showResult
                      ? (isCorrect ? Colors.green : Colors.red)
                      : AppColors.primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildDictation(LessonQuestion question) {
    final correctAnswer = question.correctAnswer ?? '';
    final isCorrect = _dictationSubmitted &&
        _dictationController.text.trim().toLowerCase() == correctAnswer.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.mic,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEnglish ? 'Listen and Type' : 'Nghe và Gõ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: _isEnglish
                          ? 'Listen to the pronunciation and type exactly what you hear: '
                          : 'Nghe cách phát âm và gõ chính xác những gì bạn nghe: ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    TextSpan(
                      text: correctAnswer,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!_dictationPlayed)
          ElevatedButton.icon(
            onPressed: () {
              _lessonService.speak(correctAnswer);
              setState(() => _dictationPlayed = true);
            },
            icon: const Icon(Icons.volume_up),
            label: Text(_isEnglish ? 'Play Audio' : 'Phát Âm Thanh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        if (_dictationPlayed) ...[
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              _lessonService.speak(correctAnswer);
            },
            icon: const Icon(Icons.replay),
            label: Text(_isEnglish ? 'Play Again' : 'Phát Lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor.withOpacity(0.7),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: TextField(
            controller: _dictationController,
            enabled: !_dictationSubmitted && _dictationPlayed,
            focusNode: _dictationFocusNode,
            minLines: 2,
            maxLines: 3,
            autofocus: _dictationPlayed,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: _isEnglish ? 'Type your answer here...' : 'Gõ câu trả lời ở đây...',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF9CA3AF),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1F2937),
            ),
            onChanged: (value) {
              setState(() {}); // Update button state
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildUnifiedSubmitButton(
          label: _isEnglish ? 'SUBMIT' : 'KIỂM TRA',
          onPressed: (!_dictationSubmitted && _dictationPlayed)
              ? () => _submitDictation(correctAnswer)
              : null,
        ),
        if (_dictationSubmitted)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCorrect ? Colors.green : Colors.red,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCorrect
                          ? (_isEnglish ? 'Correct!' : 'Chính xác!')
                          : (_isEnglish
                              ? 'Correct answer: $correctAnswer'
                              : 'Đáp án đúng: $correctAnswer'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isCorrect ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _submitDictation(String correctAnswer) {
    if (_dictationSubmitted) return;
    bool isCorrect = false;

    setState(() {
      _dictationSubmitted = true;
      final userAnswer = _dictationController.text.trim().toLowerCase();
      isCorrect = userAnswer == correctAnswer.toLowerCase();

      _userAnswers[_currentQuestionIndex] = userAnswer;
      if (isCorrect) {
        _correctCount++;
      }
      _showExplanation = true;
    });

    _showPenguinPopup(isCorrect);

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _moveToNextQuestion();
      }
    });
  }

  Widget _buildAudioButton(String text) {
    return GestureDetector(
      onTap: () => _lessonService.speak(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.volume_up,
              color: AppColors.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _isEnglish ? 'Listen' : 'Nghe',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanation(String explanation) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                _isEnglish ? 'Explanation' : 'Giải thích',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF4B5563),
              height: 1.5,
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
      backgroundColor: const Color(0xFFF8FAFC),
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
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isPassed
                              ? [const Color(0xFF34D399), const Color(0xFF059669)]
                              : [const Color(0xFFFB923C), const Color(0xFFF97316)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isPassed ? Colors.green : Colors.orange).withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$percentage%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _isEnglish ? 'Score' : 'Điểm',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Message
                    Text(
                      isPassed
                          ? (_isEnglish ? 'Excellent Work!' : 'Xuất sắc!')
                          : (_isEnglish ? 'Keep Practicing!' : 'Cố gắng thêm!'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Text(
                      _isEnglish
                          ? 'You got $_correctCount out of $totalQuestions correct'
                          : 'Bạn trả lời đúng $_correctCount/$totalQuestions câu',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Stats
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            _isEnglish ? 'Correct' : 'Đúng',
                            _correctCount.toString(),
                            Colors.green,
                            Icons.check_circle,
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: const Color(0xFFE5E7EB),
                          ),
                          _buildStatItem(
                            _isEnglish ? 'Wrong' : 'Sai',
                            (totalQuestions - _correctCount).toString(),
                            Colors.red,
                            Icons.cancel,
                          ),
                        ],
                      ),
                    ),
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
                    child: ElevatedButton(
                      onPressed: () {
                        // Wait a moment to ensure data is saved before navigating back
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6B7280),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isEnglish ? 'Back' : 'Quay lại',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentQuestionIndex = 0;
                          _selectedAnswer = null;
                          _userAnswers = List<String?>.filled(
                            (_lessonData?['questions'] as List?)?.length ?? 0,
                            null,
                          );
                          _correctCount = 0;
                          _showResults = false;
                          _showExplanation = false;
                          _matchedPairs.clear();
                          _selectedMatchItem = null;
                          _fillBlankController.clear();
                          _fillBlankSubmitted = false;
                          _conversationController.clear();
                          _conversationSubmitted = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isEnglish ? 'Retry' : 'Làm lại',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  Color _getQuestionTypeColor(String type) {
    switch (type) {
      case 'multiple_choice':
        return const Color(0xFF818CF8);
      case 'mcq_en_vi':
        return const Color(0xFF6366F1);
      case 'mcq_vi_en':
        return const Color(0xFF8B5CF6);
      case 'true_false':
        return const Color(0xFF10B981);
      case 'fill_blank':
        return const Color(0xFFF59E0B);
      case 'unscramble':
        return const Color(0xFFF97316);
      case 'matching':
        return const Color(0xFF34D399);
      case 'listening':
        return const Color(0xFF14B8A6);
      case 'listening_choice':
        return const Color(0xFF0EA5E9);
      case 'translation':
        return const Color(0xFFF472B6);
      case 'conversation':
        return const Color(0xFF60A5FA);
      case 'dictation':
        return const Color(0xFFEC4899);
      case 'spelling':
        return const Color(0xFFD946EF);
      default:
        return AppColors.primaryColor;
    }
  }

  String _getQuestionTypeLabel(String type) {
    switch (type) {
      case 'multiple_choice':
        return _isEnglish ? 'Multiple Choice' : 'Chọn đáp án';
      case 'mcq_en_vi':
        return _isEnglish ? 'EN -> VI Choice' : 'Chọn nghĩa EN -> VI';
      case 'mcq_vi_en':
        return _isEnglish ? 'VI -> EN Choice' : 'Chọn từ VI -> EN';
      case 'true_false':
        return _isEnglish ? 'True / False' : 'Đúng / Sai';
      case 'fill_blank':
        return _isEnglish ? 'Fill in the Blank' : 'Điền vào chỗ trống';
      case 'unscramble':
        return _isEnglish ? 'Unscramble Word' : 'Sắp xếp chữ cái';
      case 'matching':
        return _isEnglish ? 'Matching' : 'Nối cặp';
      case 'listening':
        return _isEnglish ? 'Listening' : 'Nghe';
      case 'listening_choice':
        return _isEnglish ? 'Listen & Choose' : 'Nghe và Chọn';
      case 'translation':
        return _isEnglish ? 'Translation' : 'Dịch';
      case 'conversation':
        return _isEnglish ? 'Conversation' : 'Hội thoại';
      case 'dictation':
        return _isEnglish ? 'Dictation' : 'Chính tả';
      case 'spelling':
        return _isEnglish ? 'Spelling' : 'Chính tả theo nghĩa';
      default:
        return type;
    }
  }

  @override
  void dispose() {
    _fillBlankController.dispose();
    _fillBlankFocusNode.dispose();
    _dictationController.dispose();
    _dictationFocusNode.dispose();
    _conversationController.dispose();
    _conversationFocusNode.dispose();
    _lessonService.stop();
    super.dispose();
  }
}
