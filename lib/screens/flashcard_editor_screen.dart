import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/language_service.dart';
import '../models/dictionary_model.dart';
import '../services/lesson_service.dart';

class FlashcardEditorScreen extends StatefulWidget {
  final String lessonName;
  final String description;
  final List<DictionaryEntry> extractedWords;
  final String imagePath;

  const FlashcardEditorScreen({
    Key? key,
    required this.lessonName,
    required this.description,
    required this.extractedWords,
    required this.imagePath,
  }) : super(key: key);

  @override
  State<FlashcardEditorScreen> createState() => _FlashcardEditorScreenState();
}

class _FlashcardEditorScreenState extends State<FlashcardEditorScreen> {
  late List<DictionaryEntry> _vocabularyList;
  bool _isSaving = false;
  final LessonService _lessonService = LessonService();

  bool get _isEnglish => context.watch<LanguageService>().isEnglish;

  @override
  void initState() {
    super.initState();
    _vocabularyList = List.from(widget.extractedWords);
  }

  void _editWord(int index) {
    final word = _vocabularyList[index];
    final wordController = TextEditingController(text: word.term);
    final phoneticController = TextEditingController(text: word.pronunciation);
    final meaningController = TextEditingController(text: word.meaning);
    final exampleController = TextEditingController(text: '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _isEnglish ? 'Edit Flashcard' : 'Chỉnh sửa Flashcard',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: wordController,
                decoration: InputDecoration(
                  labelText: _isEnglish ? 'Word' : 'Từ vựng',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneticController,
                decoration: InputDecoration(
                  labelText: _isEnglish ? 'Phonetic' : 'Phiên âm',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: meaningController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: _isEnglish ? 'Meaning' : 'Nghĩa',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: exampleController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: _isEnglish ? 'Example' : 'Ví dụ',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_isEnglish ? 'Cancel' : 'Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _vocabularyList[index] = DictionaryEntry(
                  id: word.id,
                  term: wordController.text.trim(),
                  language: word.language,
                  pronunciation: phoneticController.text.trim(),
                  wordClass: word.wordClass,
                  meaning: meaningController.text.trim(),
                  isCommon: word.isCommon,
                  frequency: word.frequency,
                );
              });
              Navigator.pop(context);
            },
            child: Text(_isEnglish ? 'Save' : 'Lưu'),
          ),
        ],
      ),
    );
  }

  void _deleteWord(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _isEnglish ? 'Delete Flashcard' : 'Xóa Flashcard',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          _isEnglish
              ? 'Are you sure you want to delete this flashcard?'
              : 'Bạn có chắc chắn muốn xóa flashcard này?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_isEnglish ? 'Cancel' : 'Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _vocabularyList.removeAt(index);
              });
              Navigator.pop(context);
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

  Future<void> _saveLesson() async {
    // Cache language value before async operations
    final isEnglish = context.read<LanguageService>().isEnglish;
    
    if (_vocabularyList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEnglish
                ? 'Please add at least one flashcard'
                : 'Vui lòng thêm ít nhất một flashcard',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = _lessonService.supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // TODO: Implement save custom lesson to Supabase
      // This should:
      // 1. Create a new custom lesson in database
      // 2. Store vocabulary words as flashcards
      // 3. Associate with user account
      
      // For now, show success message
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEnglish
                  ? 'Lesson created successfully!'
                  : 'Tạo bài học thành công!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to my lessons screen with success flag
        Navigator.of(context).popUntil((route) => route.settings.name == '/my_lessons' || route.isFirst);
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEnglish
                  ? 'Error saving lesson: $e'
                  : 'Lỗi lưu bài học: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                    _isEnglish ? 'Edit Flashcards' : 'Chỉnh sửa Flashcard',
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

            // Lesson info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lessonName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_vocabularyList.length} ${_isEnglish ? 'flashcards' : 'flashcard'}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Flashcard list
            Expanded(
              child: _vocabularyList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.style_outlined,
                            size: 80,
                            color: const Color(0xFF9CA3AF),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isEnglish
                                ? 'No flashcards found'
                                : 'Không tìm thấy flashcard',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _vocabularyList.length,
                      itemBuilder: (context, index) {
                        final word = _vocabularyList[index];
                        return _buildFlashcardItem(word, index);
                      },
                    ),
            ),

            // Bottom button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveLesson,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    disabledBackgroundColor: AppColors.primaryColor.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.save,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isEnglish ? 'Save Lesson' : 'Lưu bài học',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardItem(DictionaryEntry word, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Confidence indicator (based on isCommon and frequency)
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: word.isCommon
                    ? Colors.green
                    : word.frequency > 50
                        ? Colors.orange
                        : Colors.red,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Word content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        word.term,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      if (word.pronunciation.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            word.pronunciation,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    word.meaning,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    word.wordClass,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF9CA3AF),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  color: AppColors.primaryColor,
                  onPressed: () => _editWord(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  color: Colors.red,
                  onPressed: () => _deleteWord(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
