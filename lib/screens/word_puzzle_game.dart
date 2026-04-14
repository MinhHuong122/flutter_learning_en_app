import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/language_service.dart';
import '../models/word_question.dart';

class WordPuzzleGame extends StatefulWidget {
  final int levelNumber;
  final List<WordQuestion> questions;

  const WordPuzzleGame({
    Key? key,
    required this.levelNumber,
    required this.questions,
  }) : super(key: key);

  @override
  State<WordPuzzleGame> createState() => _WordPuzzleGameState();
}

class _WordPuzzleGameState extends State<WordPuzzleGame>
    with TickerProviderStateMixin {
  late Map<String, TextEditingController> answerControllers;
  late Map<String, bool> correctCells;
  int correctCount = 0;
  bool isCompleted = false;
  late AnimationController _celebrationController;

  @override
  void initState() {
    super.initState();
    answerControllers = {};
    correctCells = {};
    // Create a TextEditingController for each grid cell
    for (int row = 0; row < 10; row++) {
      for (int col = 0; col < 10; col++) {
        String key = '$row-$col';
        answerControllers[key] = TextEditingController();
      }
    }
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    for (var controller in answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _isEnglish => context.read<LanguageService>().isEnglish;
  
  static const Color _primaryColor = Color(0xFF10B981); // Unified green
  static const Color _bgColor = Color(0xFFECFDF5);

  String? _getLetterAt(int row, int col) {
    for (var question in widget.questions) {
      final startRow = question.startRow;
      final startCol = question.startCol;
      final wordStr = question.word;
      
      if (question.direction == 'across') {
        if (row == startRow &&
            col >= startCol &&
            col < startCol + wordStr.length) {
          return wordStr[col - startCol];
        }
      } else if (question.direction == 'down') {
        if (col == startCol &&
            row >= startRow &&
            row < startRow + wordStr.length) {
          return wordStr[row - startRow];
        }
      }
    }
    return null;
  }

  int? _getWordNumberAt(int row, int col) {
    for (var question in widget.questions) {
      final startRow = question.startRow;
      final startCol = question.startCol;
      
      if ((question.direction == 'across' &&
              row == startRow &&
              col == startCol) ||
          (question.direction == 'down' &&
              col == startCol &&
              row == startRow)) {
        return question.number;
      }
    }
    return null;
  }

  void _checkAnswers() {
    int correct = 0;
    int total = 0;

    for (var question in widget.questions) {
      final wordStr = question.word;
      final startRow = question.startRow;
      final startCol = question.startCol;
      final direction = question.direction;

      for (int i = 0; i < wordStr.length; i++) {
        int r = direction == 'across' ? startRow : startRow + i;
        int c = direction == 'across' ? startCol + i : startCol;
        String key = '$r-$c';

        total++;
        final userLetter = answerControllers[key]?.text.toUpperCase() ?? '';
        final correctLetter = wordStr[i].toUpperCase();

        if (userLetter == correctLetter) {
          correct++;
          correctCells[key] = true;
        } else {
          correctCells[key] = false;
        }
      }
    }

    setState(() {
      correctCount = correct;
      if (correct == total) {
        isCompleted = true;
        _celebrationController.forward();
      }
    });

    final message = _isEnglish
        ? correct == total
            ? '🎉 Perfect! All answers correct!'
            : '📝 $correct out of $total correct. Keep trying!'
        : correct == total
            ? '🎉 Hoàn hảo! Tất cả đều đúng!'
            : '📝 $correct trên $total đúng. Tiếp tục cố gắng!';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: correct == total ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gridSize = 10;

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
                    _isEnglish
                        ? 'Level ${widget.levelNumber}'
                        : 'Cấp độ ${widget.levelNumber}',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _isEnglish
                            ? 'Word Crossword Puzzle'
                            : 'Trò chơi đố từ chéo',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _primaryColor,
                        ),
                      ),
                    ),

                    // Crossword Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _bgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _primaryColor.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridSize,
                            childAspectRatio: 1,
                            mainAxisSpacing: 2,
                            crossAxisSpacing: 2,
                          ),
                          itemCount: gridSize * gridSize,
                          itemBuilder: (context, index) {
                            int row = index ~/ gridSize;
                            int col = index % gridSize;
                            String key = '$row-$col';

                            String? letter = _getLetterAt(row, col);
                            bool isPartOfWord = letter != null;
                            int? wordNumber = _getWordNumberAt(row, col);
                            bool isCorrect = correctCells[key] ?? false;
                            bool hasAnswer = answerControllers[key]?.text.isNotEmpty ?? false;
                            bool isWrong = hasAnswer && !isCorrect;

                            return Container(
                              decoration: BoxDecoration(
                                color: !isPartOfWord
                                    ? Colors.grey[300]!
                                    : isCorrect
                                        ? Colors.green
                                        : isWrong
                                            ? Colors.red.withOpacity(0.5)
                                            : _primaryColor.withOpacity(0.3),
                                border: Border.all(
                                  color: isPartOfWord
                                      ? _primaryColor
                                      : Colors.grey[400]!,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Word number indicator
                                  if (wordNumber != null && isPartOfWord)
                                    Positioned(
                                      top: 1,
                                      left: 1,
                                      child: Text(
                                        '$wordNumber',
                                        style: GoogleFonts.poppins(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          color: _primaryColor,
                                        ),
                                      ),
                                    ),
                                  // Text input field
                                  if (isPartOfWord)
                                    TextField(
                                      controller: answerControllers[key],
                                      textAlign: TextAlign.center,
                                      maxLength: 1,
                                      enabled: !isCorrect,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isCorrect
                                            ? Colors.white
                                            : isWrong
                                                ? Colors.white
                                                : const Color(0xFF1F2937),
                                      ),
                                      decoration: InputDecoration(
                                        counterText: '',
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          if (value.isNotEmpty) {
                                            final userLetter = value.toUpperCase();
                                            final correctLetter = letter!.toUpperCase();
                                            if (userLetter == correctLetter) {
                                              correctCells[key] = true;
                                            } else {
                                              correctCells[key] = false;
                                            }
                                          } else {
                                            correctCells.remove(key);
                                          }
                                        });
                                        // Move to next cell if filled
                                        if (value.isNotEmpty) {
                                          FocusScope.of(context).nextFocus();
                                        }
                                      },
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[a-zA-Z]'),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Clues section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEnglish ? 'Clues: Type letters in grid' : 'Gợi ý: Gõ từ vào lưới',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: widget.questions.map((question) {
                              final directionLabel = question.direction == 'across'
                                  ? (_isEnglish ? 'Across' : 'Ngang')
                                  : (_isEnglish ? 'Down' : 'Dọc');

                              return _buildClueCard(
                                question: question,
                                directionLabel: directionLabel,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Check button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                          ),
                          onPressed: _checkAnswers,
                          child: Text(
                            _isEnglish ? 'Check Answers' : 'Kiểm tra đáp án',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Celebration overlay
      floatingActionButton: isCompleted
          ? FloatingActionButton.extended(
              backgroundColor: Colors.green,
              onPressed: () => Navigator.pop(context, true),
              label: Text(
                _isEnglish ? 'Next Level' : 'Màn tiếp theo',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              icon: const Icon(Icons.arrow_forward),
            )
          : null,
    );
  }

  Widget _buildClueCard({
    required WordQuestion question,
    required String directionLabel,
  }) {
    const primaryColor = Color(0xFF10B981);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.2),
        border: Border.all(
          color: primaryColor,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${question.number}. $directionLabel',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          Text(
            question.question ?? question.word,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}