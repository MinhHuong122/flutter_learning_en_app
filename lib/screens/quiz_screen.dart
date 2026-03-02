import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/lesson_model.dart';
import '../services/lesson_service.dart';
import '../services/language_service.dart';
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
  bool _fillBlankSubmitted = false;

  bool get _isEnglish => context.read<LanguageService>().isEnglish;

  @override
  void initState() {
    super.initState();
    _lessonService = LessonService();
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
      }
    } catch (e) {
      print('Error loading questions: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectAnswer(String optionId, bool isCorrect) {
    if (_selectedAnswer != null) return; // Already answered
    
    setState(() {
      _selectedAnswer = optionId;
      _userAnswers[_currentQuestionIndex] = optionId;
      if (isCorrect) {
        _correctCount++;
      }
      _showExplanation = true;
    });

    // Move to next question after delay
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _moveToNextQuestion();
      }
    });
  }

  void _submitFillBlank(String correctAnswer) {
    if (_fillBlankSubmitted) return;
    
    setState(() {
      _fillBlankSubmitted = true;
      final userAnswer = _fillBlankController.text.trim().toLowerCase();
      final isCorrect = userAnswer == correctAnswer.toLowerCase();
      
      _userAnswers[_currentQuestionIndex] = userAnswer;
      if (isCorrect) {
        _correctCount++;
      }
      _showExplanation = true;
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _moveToNextQuestion();
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
    
    if (correctMatches >= totalPairs) {
      _correctCount++;
    }
    
    setState(() {
      _showExplanation = true;
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _moveToNextQuestion();
      }
    });
  }

  void _moveToNextQuestion() {
    final questions = _lessonData!['questions'] as List<LessonQuestion>;
    
    if (_currentQuestionIndex < questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _showExplanation = false;
        _matchedPairs.clear();
        _selectedMatchItem = null;
        _fillBlankController.clear();
        _fillBlankSubmitted = false;
      });
    } else {
      setState(() => _showResults = true);
      if (widget.onComplete != null) {
        widget.onComplete!(true);
      }
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
                padding: const EdgeInsets.all(20),
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
    final questionType = question.questionType ?? 'multiple_choice';
    
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
        
        // Question text
        Text(
          question.questionText,
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
      ],
    );
  }

  Widget _buildQuestionContent(LessonQuestion question) {
    final questionType = question.questionType ?? 'multiple_choice';
    
    switch (questionType) {
      case 'multiple_choice':
        return _buildMultipleChoice(question);
      case 'fill_blank':
        return _buildFillBlank(question);
      case 'matching':
        return _buildMatching(question);
      case 'listening':
        return _buildListening(question);
      case 'translation':
        return _buildTranslation(question);
      case 'conversation':
        return _buildConversation(question);
      default:
        return _buildMultipleChoice(question);
    }
  }

  Widget _buildMultipleChoice(LessonQuestion question) {
    final options = _lessonData!['options'] as Map<String, List<LessonOption>>;
    final currentOptions = options[question.id] ?? [];
    
    return Column(
      children: currentOptions.map((option) {
        final isSelected = _selectedAnswer == option.id;
        final showResult = _showExplanation && isSelected;
        final isCorrect = option.isCorrect;
        
        return GestureDetector(
          onTap: () => _selectAnswer(option.id, option.isCorrect),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: showResult
                  ? (isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1))
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: showResult
                    ? (isCorrect ? Colors.green : Colors.red)
                    : const Color(0xFFE5E7EB),
                width: showResult ? 2 : 1,
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
                        : const Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + currentOptions.indexOf(option)),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: showResult ? Colors.white : const Color(0xFF6B7280),
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
                if (showResult)
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? Colors.green : Colors.red,
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
    final correctAnswer = question.correctAnswer ?? '';
    final isCorrect = _fillBlankSubmitted && 
        _fillBlankController.text.trim().toLowerCase() == correctAnswer.toLowerCase();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _fillBlankController,
          enabled: !_fillBlankSubmitted,
          decoration: InputDecoration(
            hintText: _isEnglish ? 'Type your answer here...' : 'Nhập câu trả lời...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
            ),
          ),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _fillBlankSubmitted
              ? null
              : () => _submitFillBlank(correctAnswer),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            disabledBackgroundColor: const Color(0xFFE5E7EB),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Text(
            _isEnglish ? 'Submit' : 'Gửi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        if (_fillBlankSubmitted)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCorrect
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
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
        
        ElevatedButton(
          onPressed: _matchedPairs.length >= leftItems.length
              ? _submitMatching
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            disabledBackgroundColor: const Color(0xFFE5E7EB),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            _isEnglish ? 'Check Answers' : 'Kiểm tra',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListening(LessonQuestion question) {
    return _buildMultipleChoice(question);
  }

  Widget _buildTranslation(LessonQuestion question) {
    return _buildFillBlank(question);
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
        _buildMultipleChoice(question),
      ],
    );
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
                      onPressed: () => Navigator.pop(context),
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
      case 'fill_blank':
        return const Color(0xFFF59E0B);
      case 'matching':
        return const Color(0xFF34D399);
      case 'listening':
        return const Color(0xFF14B8A6);
      case 'translation':
        return const Color(0xFFF472B6);
      case 'conversation':
        return const Color(0xFF60A5FA);
      default:
        return AppColors.primaryColor;
    }
  }

  String _getQuestionTypeLabel(String type) {
    switch (type) {
      case 'multiple_choice':
        return _isEnglish ? 'Multiple Choice' : 'Chọn đáp án';
      case 'fill_blank':
        return _isEnglish ? 'Fill in the Blank' : 'Điền vào chỗ trống';
      case 'matching':
        return _isEnglish ? 'Matching' : 'Nối cặp';
      case 'listening':
        return _isEnglish ? 'Listening' : 'Nghe';
      case 'translation':
        return _isEnglish ? 'Translation' : 'Dịch';
      case 'conversation':
        return _isEnglish ? 'Conversation' : 'Hội thoại';
      default:
        return type;
    }
  }

  @override
  void dispose() {
    _fillBlankController.dispose();
    _lessonService.stop();
    super.dispose();
  }
}
