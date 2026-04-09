import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/vocabulary_service.dart';
import '../utils/constants.dart';

/// Screen for displaying vocabulary cards with special character support
class VocabularyCardsScreen extends StatefulWidget {
  final String lessonId;
  final String userId;
  final bool isEnglish;
  final VoidCallback onComplete;
  final int cardLimit;

  const VocabularyCardsScreen({
    Key? key,
    required this.lessonId,
    required this.userId,
    required this.isEnglish,
    required this.onComplete,
    this.cardLimit = 5,
  }) : super(key: key);

  @override
  State<VocabularyCardsScreen> createState() => _VocabularyCardsScreenState();
}

class _VocabularyCardsScreenState extends State<VocabularyCardsScreen>
    with SingleTickerProviderStateMixin {
  late final VocabularyService _vocabService;
  late final FlutterTts _flutterTts;
  late List<VocabularyCard> _cards;
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _vocabService = VocabularyService();
    _flutterTts = FlutterTts();
    _initTTS();
    _loadVocabulary();
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _playAudio(String text) async {
    if (_isPlayingAudio) return;
    
    try {
      if (!mounted) return;
      setState(() => _isPlayingAudio = true);
      
      await _flutterTts.speak(text);
      
      // Use Future to reset state after a delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _isPlayingAudio = false);
        }
      });
    } catch (e) {
      print('Error playing audio: $e');
      if (mounted) {
        setState(() => _isPlayingAudio = false);
      }
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _loadVocabulary() async {
    try {
      final cards = await _vocabService.getRandomVocabulary(
        lessonId: widget.lessonId,
        userId: widget.userId,
        limit: widget.cardLimit,
      );
      
      if (mounted) {
        setState(() {
          _cards = cards;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading vocabulary: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _markAsKnown() {
    if (_currentIndex < _cards.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _showCompletionDialog();
    }
  }

  void _continueToNext() {
    if (_currentIndex < _cards.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.isEnglish ? 'Great Job! 🎉' : 'Rất tốt! 🎉',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          widget.isEnglish
              ? 'You have completed all vocabulary cards.'
              : 'Bạn đã hoàn thành tất cả thẻ từ vựng.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onComplete();
            },
            child: Text(
              widget.isEnglish ? 'Continue' : 'Tiếp tục',
              style: const TextStyle(color: AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isEnglish ? 'Vocabulary' : 'Từ Vựng'),
          elevation: 0,
        ),
        body: Center(
          child: Text(
            widget.isEnglish ? 'No vocabulary found' : 'Không tìm thấy từ vựng',
          ),
        ),
      );
    }

    final card = _cards[_currentIndex];
    final progress = ((_currentIndex + 1) / _cards.length * 100).toInt();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEnglish ? 'Vocabulary' : 'Từ Vựng',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isEnglish
                            ? 'Word ${_currentIndex + 1} of ${_cards.length}'
                            : 'Từ ${_currentIndex + 1} trong ${_cards.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '$progress%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / _cards.length,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Vocabulary card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      color: Colors.white,
                    ),
                    child: Stack(
                      children: [
                        // Background decoration
                        Positioned(
                          top: -20,
                          right: -20,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryColor.withOpacity(0.1),
                            ),
                          ),
                        ),
                        // Main content
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Word class badge
                              if (card.wordClass != null && card.wordClass!.isNotEmpty)
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    card.wordClass!.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryColor,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              // Word term
                              Text(
                                card.term,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Pronunciation
                              if (card.pronunciation != null && card.pronunciation!.isNotEmpty)
                                Text(
                                  card.pronunciation!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF64748B),
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              const SizedBox(height: 20),
                              // Audio button
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryColor.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _playAudio(card.term),
                                    customBorder: const CircleBorder(),
                                    child: Icon(
                                      _isPlayingAudio ? Icons.stop : Icons.volume_up,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Divider
                              Container(
                                height: 1,
                                color: const Color(0xFFE2E8F0),
                              ),
                              const SizedBox(height: 20),
                              // Translation label
                              Text(
                                widget.isEnglish ? 'Translation' : 'Dịch',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Vietnamese meaning
                              Text(
                                card.vietnameseMeaning ?? card.meaning,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // "I already know this" button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _markAsKnown,
                      icon: const Icon(Icons.check_circle),
                      label: Text(
                        widget.isEnglish
                            ? 'I already know this'
                            : 'Tôi đã biết',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFF22C55E).withOpacity(0.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // "Continue learning" button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _continueToNext,
                      icon: const Icon(Icons.chevron_right),
                      label: Text(
                        widget.isEnglish
                            ? 'Continue learning'
                            : 'Tiếp tục học',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        side: const BorderSide(
                          color: AppColors.primaryColor,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
}
