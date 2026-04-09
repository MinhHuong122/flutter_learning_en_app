import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';
import '../services/language_service.dart';
import '../services/lesson_service.dart';

class FlashcardSwiperScreen extends StatefulWidget {
  final String lessonId;
  final String lessonName;
  final List<Map<String, dynamic>>? initialFlashcards;

  const FlashcardSwiperScreen({
    Key? key,
    required this.lessonId,
    required this.lessonName,
    this.initialFlashcards,
  }) : super(key: key);

  @override
  State<FlashcardSwiperScreen> createState() => _FlashcardSwiperScreenState();
}

class _FlashcardSwiperScreenState extends State<FlashcardSwiperScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late FlutterTts _flutterTts;
  List<Map<String, dynamic>> _flashcards = [];
  List<bool> _understood = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  double _dragOffset = 0;

  final LessonService _lessonService = LessonService();

  bool get _isEnglish => context.read<LanguageService>().isEnglish;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _initTTS();
    if (widget.initialFlashcards != null && widget.initialFlashcards!.isNotEmpty) {
      _flashcards = widget.initialFlashcards!;
      _understood = List<bool>.filled(_flashcards.length, false);
      _isLoading = false;
    } else {
      _loadFlashcards();
    }
  }

  void _initTTS() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }

  void _speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> _loadFlashcards() async {
    try {
      final cards = await _lessonService.getFlashcardsForLesson(widget.lessonId);
      setState(() {
        _flashcards = cards;
        _understood = List<bool>.filled(cards.length, false);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading flashcards: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEnglish ? 'Error loading flashcards: $e' : 'Lỗi tải flashcards: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _swipeLeft() {
    if (_currentIndex < _flashcards.length) {
      _recordStudyProgress(gotIt: true);
      _understood[_currentIndex] = true;
      _moveToNext();
    }
  }

  void _swipeRight() {
    if (_currentIndex < _flashcards.length) {
      _recordStudyProgress(gotIt: false);
      _understood[_currentIndex] = false;
      _moveToNext();
    }
  }

  Future<void> _recordStudyProgress({required bool gotIt}) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null || _flashcards.isEmpty || _currentIndex >= _flashcards.length) {
        return;
      }

      final wordId = _flashcards[_currentIndex]['id']?.toString();
      if (wordId == null || wordId.isEmpty) {
        return;
      }

      await _lessonService.updateOcrWordProgress(
        userId: userId,
        wordId: wordId,
        gotIt: gotIt,
      );
    } catch (e) {
      print('❌ Error recording OCR study progress: $e');
    }
  }

  void _moveToNext() {
    if (_currentIndex < _flashcards.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _showCompletionScreen();
    }
  }

  void _showCompletionScreen() {
    final understoodCount = _understood.where((u) => u).length;
    final total = _flashcards.length;
    final percentage = (understoodCount / total * 100).toStringAsFixed(1);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor.withOpacity(0.1),
              ),
              child: Icon(
                Icons.check_circle,
                size: 50,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isEnglish ? 'Well done!' : 'Tuyệt vời!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isEnglish
                  ? 'You understood $understoodCount out of $total cards'
                  : 'Bạn đã hiểu $understoodCount trên tổng số $total thẻ',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$percentage%',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isEnglish ? 'Exit' : 'Thoát',
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _currentIndex = 0;
                      _understood = List<bool>.filled(_flashcards.length, false);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isEnglish ? 'Retry All' : 'Lập lại tất cả',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBFF),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBFF).withOpacity(0.8),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top row: close, title, stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Close button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFF1A1C1E),
                            size: 24,
                          ),
                        ),
                      ),
                      // Center title
                      Column(
                        children: [
                          Text(
                            _isEnglish ? 'Daily Session' : 'Phiên họp hàng ngày',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF4AA9FF),
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            _isEnglish
                                ? '${_currentIndex + 1} / ${_flashcards.length} Words'
                                : '${_currentIndex + 1} / ${_flashcards.length} Từ',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A1C1E),
                            ),
                          ),
                        ],
                      ),
                      // Stats button
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                        ),
                        child: const Icon(
                          Icons.bar_chart,
                          color: Color(0xFF1A1C1E),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: SizedBox(
                      height: 8,
                      child: LinearProgressIndicator(
                        value: (_currentIndex + 1) / (_flashcards.length > 0 ? _flashcards.length : 1),
                        backgroundColor: const Color(0xFFD6E9FF),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4AA9FF)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4AA9FF)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isEnglish ? 'Loading flashcards...' : 'Đang tải flashcards...',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF44474E),
                          ),
                        ),
                      ],
                    ),
                  )
                : _flashcards.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.style_outlined,
                              size: 80,
                              color: const Color(0xFF44474E),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isEnglish ? 'No flashcards found' : 'Không tìm thấy flashcard',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: const Color(0xFF44474E),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          // Deck effect - background cards
                          Positioned(
                            child: Transform.rotate(
                              angle: 0.05,
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.8,
                                height: 420,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFFE1E2E9),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            child: Transform.rotate(
                              angle: -0.03,
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.85,
                                height: 430,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFFE1E2E9),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ),

                          // Main active card
                          if (_flashcards.isNotEmpty)
                            GestureDetector(
                              onHorizontalDragUpdate: (details) {
                                setState(() {
                                  _dragOffset = details.globalPosition.dx;
                                });
                              },
                              onHorizontalDragEnd: (details) {

                                if (details.velocity.pixelsPerSecond.dx > 300) {
                                  // Swipe right
                                  _swipeRight();
                                } else if (details.velocity.pixelsPerSecond.dx < -300) {
                                  // Swipe left
                                  _swipeLeft();
                                }
                                setState(() {
                                  _dragOffset = 0;
                                });
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.9,
                                constraints: const BoxConstraints(maxHeight: 520),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFFE1E2E9).withOpacity(0.5),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4AA9FF).withOpacity(0.2),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                      spreadRadius: -10,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      // Word & Phonetic
                                      Column(
                                        children: [
                                          const SizedBox(height: 16),
                                          Text(
                                            _flashcards[_currentIndex]['word'] ?? 'Unknown',
                                            style: GoogleFonts.manrope(
                                              fontSize: 52,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF1A1C1E),
                                              letterSpacing: -0.5,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          if (_flashcards[_currentIndex]['pronunciation'] != null &&
                                              (_flashcards[_currentIndex]['pronunciation'] as String).isNotEmpty)
                                            Text(
                                              _flashcards[_currentIndex]['pronunciation'] ?? '',
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xFF4AA9FF),
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                        ],
                                      ),

                                      // Content section
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            // Decorative separator
                                            Container(
                                              width: 48,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF4AA9FF).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(100),
                                              ),
                                            ),
                                            const SizedBox(height: 20),

                                            // Definition
                                            Text(
                                              _flashcards[_currentIndex]['definition'] ?? 'Unknown',
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w400,
                                                color: const Color(0xFF44474E),
                                                height: 1.5,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 12),

                                            // Example
                                            if (_flashcards[_currentIndex]['example'] != null &&
                                                (_flashcards[_currentIndex]['example'] as String).isNotEmpty)
                                              Text(
                                                _flashcards[_currentIndex]['example'] ?? '',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w400,
                                                  color: const Color(0xFF74777F),
                                                  fontStyle: FontStyle.italic,
                                                  height: 1.4,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),

                                      // Listen Button
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          final word = _flashcards[_currentIndex]['word'] ?? '';
                                          _speak(word);
                                        },
                                        icon: const Icon(Icons.volume_up, size: 20),
                                        label: Text(
                                          _isEnglish ? 'Listen' : 'Nghe',
                                          style: GoogleFonts.manrope(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF4AA9FF),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 28,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(100),
                                          ),
                                          elevation: 8,
                                          shadowColor: const Color(0xFF4AA9FF).withOpacity(0.25),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
          ),

          // Footer with Swipe Indicators
          if (!_isLoading && _flashcards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  // Swipe indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Got It (Left)
                      GestureDetector(
                        onTap: _swipeLeft,
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFE1E2E9),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.close,
                                  color: const Color(0xFF44474E),
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Column(
                              children: [
                                Text(
                                  _isEnglish ? 'GOT IT' : 'ĐÃ HIỂU',
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1A1C1E),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  _isEnglish ? 'Swipe Left' : 'Vuốt trái',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color: const Color(0xFF74777F),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Undo button
                      GestureDetector(
                        onTap: () {
                          if (_currentIndex > 0) {
                            setState(() {
                              _currentIndex--;
                            });
                          }
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFE1E2E9).withOpacity(0.5),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.undo,
                              color: const Color(0xFF44474E),
                              size: 24,
                            ),
                          ),
                        ),
                      ),

                      // Review (Right)
                      GestureDetector(
                        onTap: _swipeRight,
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFE1E2E9),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.check,
                                  color: const Color(0xFF44474E),
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Column(
                              children: [
                                Text(
                                  _isEnglish ? 'REVIEW' : 'XEM LẠI',
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1A1C1E),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  _isEnglish ? 'Swipe Right' : 'Vuốt phải',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color: const Color(0xFF74777F),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Tip section
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6E9FF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb,
                          color: const Color(0xFF4AA9FF),
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isEnglish
                                ? 'Swipe right if you want to see this word again later.'
                                : 'Vuốt phải nếu bạn muốn xem lại từ này sau.',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF00325A),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _flutterTts.stop();
    super.dispose();
  }
}
