import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/language_service.dart';

class WordPuzzleGame extends StatefulWidget {
  final int levelNumber;
  final String theme; // 'desert' or 'forest'
  final List<Map<String, dynamic>> words; // Từ vựng cho level

  const WordPuzzleGame({
    Key? key,
    required this.levelNumber,
    required this.theme,
    required this.words,
  }) : super(key: key);

  @override
  State<WordPuzzleGame> createState() => _WordPuzzleGameState();
}

class _WordPuzzleGameState extends State<WordPuzzleGame>
    with TickerProviderStateMixin {
  late Map<String, String> userAnswers;
  late Map<String, bool> correctCells;
  int correctCount = 0;
  bool isCompleted = false;
  late AnimationController _celebrationController;

  @override
  void initState() {
    super.initState();
    userAnswers = {};
    correctCells = {};
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  bool get _isEnglish => context.read<LanguageService>().isEnglish;
  Color get _primaryColor =>
      widget.theme == 'forest' ? const Color(0xFF10B981) : const Color(0xFFFDB54E);
  Color get _bgColor =>
      widget.theme == 'forest' ? const Color(0xFFECFDF5) : const Color(0xFFFFF5E6);

  String? _getLetterAt(int row, int col) {
    for (var word in widget.words) {
      final startRow = (word['startRow'] as num).toInt();
      final startCol = (word['startCol'] as num).toInt();
      final wordStr = word['word'] as String;
      
      if (word['direction'] == 'across') {
        if (row == startRow &&
            col >= startCol &&
            col < startCol + wordStr.length) {
          return wordStr[col - startCol];
        }
      } else if (word['direction'] == 'down') {
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
    for (var word in widget.words) {
      final startRow = (word['startRow'] as num).toInt();
      final startCol = (word['startCol'] as num).toInt();
      
      if ((word['direction'] == 'across' &&
              row == startRow &&
              col == startCol) ||
          (word['direction'] == 'down' &&
              col == startCol &&
              row == startRow)) {
        return word['number'] as int;
      }
    }
    return null;
  }

  void _checkAnswers() {
    int correct = 0;
    int total = 0;

    for (var word in widget.words) {
      final wordStr = word['word'] as String;
      final startRow = word['startRow'] as int;
      final startCol = word['startCol'] as int;
      final direction = word['direction'] as String;

      for (int i = 0; i < wordStr.length; i++) {
        int r = direction == 'across' ? startRow : startRow + i;
        int c = direction == 'across' ? startCol + i : startCol;
        String key = '$r-$c';

        total++;
        final userLetter = userAnswers[key]?.toUpperCase() ?? '';
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
                            bool isWrong =
                                userAnswers.containsKey(key) && !isCorrect;

                            return DragTarget<String>(
                              onAccept: (droppedLetter) {
                                setState(() {
                                  userAnswers[key] =
                                      droppedLetter.toUpperCase();
                                  correctCells.remove(key);
                                });
                              },
                              builder: (context, candidateData, rejectedData) {
                                Color bgColor = Colors.grey[300]!;
                                if (isPartOfWord) {
                                  if (isCorrect) {
                                    bgColor = Colors.green;
                                  } else if (isWrong) {
                                    bgColor = Colors.red.withOpacity(0.5);
                                  } else {
                                    bgColor = _primaryColor.withOpacity(0.3);
                                  }
                                }

                                return Container(
                                  decoration: BoxDecoration(
                                    color: bgColor,
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
                                      // Word number
                                      if (wordNumber != null)
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
                                      // User input
                                      if (isPartOfWord)
                                        Text(
                                          userAnswers[key] ?? '',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: isCorrect
                                                ? Colors.white
                                                : isWrong
                                                    ? Colors.white
                                                    : const Color(0xFF1F2937),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Clues with images and draggable words
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEnglish ? 'Hint: Drag words to grid' : 'Gợi ý: Kéo từ vào lưới',
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
                            children: widget.words.map((wordData) {
                              final word = wordData['word'] as String;
                              final number = wordData['number'] as int;
                              final direction = wordData['direction'] as String;
                              final directionLabel = direction == 'across'
                                  ? (_isEnglish ? 'Across' : 'Ngang')
                                  : (_isEnglish ? 'Down' : 'Dọc');

                              return _buildClueCard(
                                word: word,
                                number: number,
                                direction: directionLabel,
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
    required String word,
    required int number,
    required String direction,
  }) {
    return Draggable<String>(
      data: word,
      feedback: Material(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _primaryColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            word,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: _primaryColor.withOpacity(0.3),
          border: Border.all(
            color: _primaryColor,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          word,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _primaryColor,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: _primaryColor.withOpacity(0.2),
          border: Border.all(
            color: _primaryColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$number. $direction',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _primaryColor,
              ),
            ),
            Text(
              word,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
