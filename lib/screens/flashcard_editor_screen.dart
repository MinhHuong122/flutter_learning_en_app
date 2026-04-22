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
  final String? lessonId; // For editing existing lessons

  const FlashcardEditorScreen({
    Key? key,
    required this.lessonName,
    required this.description,
    required this.extractedWords,
    required this.imagePath,
    this.lessonId,
  }) : super(key: key);

  @override
  State<FlashcardEditorScreen> createState() => _FlashcardEditorScreenState();
}

class _FlashcardEditorScreenState extends State<FlashcardEditorScreen> {
  late List<DictionaryEntry> _vocabularyList;
  late String _lessonName;
  late String _description;
  bool _isSaving = false;
  bool _isLoadingData = false;
  bool _hasChanges = false; // Track if user made any changes
  final LessonService _lessonService = LessonService();

  bool get _isEnglish => context.read<LanguageService>().isEnglish;

  @override
  void initState() {
    super.initState();
    print('🎬 FlashcardEditorScreen initiated - lessonId: ${widget.lessonId}');
    _vocabularyList = List.from(widget.extractedWords);
    _lessonName = widget.lessonName;
    _description = widget.description;
    
    // If lessonId is provided, load vocabulary from database
    if (widget.lessonId != null) {
      _loadLessonVocabulary();
    }
  }

  Future<void> _loadLessonVocabulary() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingData = true;
    });
    
    try {
      print('📚 Loading vocabulary for lesson: ${widget.lessonId}');
      final vocabulary = await _lessonService.getLessonVocabulary(widget.lessonId!);
      print('✅ Loaded ${vocabulary.length} vocabulary items');
      
      if (mounted) {
        setState(() {
          _vocabularyList = vocabulary;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print('❌ Error loading vocabulary: $e');
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEnglish
                  ? 'Error loading vocabulary: $e'
                  : 'Lỗi tải từ vựng: $e',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _editLessonName() {
    final nameController = TextEditingController(text: _lessonName);
    final descriptionController = TextEditingController(text: _description);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black.withOpacity(0.6),
              ),
            ),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEnglish ? 'Edit Lesson' : 'Chỉnh sửa Bài học',
                        style: GoogleFonts.quicksand(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Lesson Name Field
                      _buildFloatingLabelField(
                        controller: nameController,
                        label: _isEnglish ? 'Lesson Name' : 'Tên Bài học',
                      ),
                      const SizedBox(height: 24),

                      // Description Field
                      _buildFloatingLabelField(
                        controller: descriptionController,
                        label: _isEnglish ? 'Description' : 'Mô tả',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 40),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              _isEnglish ? 'Cancel' : 'Hủy',
                              style: GoogleFonts.quicksand(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (nameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      _isEnglish
                                          ? 'Please enter lesson name'
                                          : 'Vui lòng nhập tên bài học',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                _lessonName = nameController.text.trim();
                                _description = descriptionController.text.trim();
                                _hasChanges = true;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF31718F),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              elevation: 8,
                              shadowColor: const Color(0xFF31718F).withOpacity(0.2),
                            ),
                            child: Text(
                              _isEnglish ? 'Save' : 'Lưu',
                              style: GoogleFonts.quicksand(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
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

  Future<bool> _confirmExitDialog() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFEF3C7),
                ),
                child: const Icon(
                  Icons.warning_outlined,
                  size: 40,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                _hasChanges
                    ? (_isEnglish ? 'Discard Changes?' : 'Bỏ qua thay đổi?')
                    : (_isEnglish ? 'Leave Editor?' : 'Thoát chỉnh sửa?'),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                _hasChanges
                  ? (_isEnglish
                    ? 'You have unsaved changes. Do you want to go back?'
                    : 'Bạn có những thay đổi chưa lưu. Bạn có muốn quay lại?')
                  : (_isEnglish
                    ? 'Do you want to go back or continue editing?'
                    : 'Bạn muốn quay lại hay tiếp tục chỉnh sửa?'),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            _isEnglish ? 'Continue Editing' : 'Tiếp tục chỉnh sửa',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            _isEnglish ? 'Go Back' : 'Quay lại',
                            style: GoogleFonts.poppins(
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
            ],
          ),
        ),
      ),
    );

    return shouldLeave ?? false;
  }

  Future<void> _showConfirmExitDialog() async {
    final shouldLeave = await _confirmExitDialog();
    if (!mounted) return;
    if (shouldLeave) {
      Navigator.pop(context);
    }
  }

  Future<bool> _handleBackPressed() async {
    return _confirmExitDialog();
  }

  void _editWord(int index) {
    final word = _vocabularyList[index];
    final wordController = TextEditingController(text: word.term);
    final phoneticController = TextEditingController(text: word.pronunciation);
    final meaningController = TextEditingController(text: word.meaning);
    final exampleController = TextEditingController(text: word.example);
    final wordClassController = TextEditingController(text: word.wordClass);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Backdrop
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black.withOpacity(0.6),
              ),
            ),
            // Modal
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                      Text(
                        _isEnglish ? 'Edit Flashcard' : 'Chỉnh sửa Flashcard',
                        style: GoogleFonts.quicksand(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Word Field
                      _buildFloatingLabelField(
                controller: wordController,
                        label: _isEnglish ? 'Word' : 'Từ vựng',
              ),
                      const SizedBox(height: 24),

                      // Phonetic Field
                      _buildFloatingLabelField(
                controller: phoneticController,
                        label: _isEnglish ? 'Phonetic' : 'Phiên âm',
              ),
                      const SizedBox(height: 24),

                      // Meaning Field
                      _buildFloatingLabelField(
                controller: meaningController,
                        label: _isEnglish ? 'Meaning' : 'Nghĩa',
                        maxLines: 3,
              ),
                      const SizedBox(height: 24),

                      // Example Field
                      _buildFloatingLabelField(
                controller: exampleController,
                        label: _isEnglish ? 'Example' : 'Ví dụ',
                maxLines: 2,
                      ),
                      const SizedBox(height: 40),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
                            child: Text(
                              _isEnglish ? 'Cancel' : 'Hủy',
                              style: GoogleFonts.quicksand(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
          ),
                          const SizedBox(width: 16),
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
                  example: exampleController.text.trim(),
                  vietnameseMeaning: word.vietnameseMeaning,
                  vietnameseExample: word.vietnameseExample,
                  isCommon: word.isCommon,
                  frequency: word.frequency,
                );
                _hasChanges = true; // Mark as changed
              });
              Navigator.pop(context);
            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF31718F),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              elevation: 8,
                              shadowColor: const Color(0xFF31718F).withOpacity(0.2),
                            ),
                            child: Text(
                              _isEnglish ? 'Save' : 'Lưu',
                              style: GoogleFonts.quicksand(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
          ),
        ],
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

  Widget _buildFloatingLabelField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return Focus(
      onFocusChange: (_) => setState(() {}),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.quicksand(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          labelStyle: GoogleFonts.quicksand(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          floatingLabelAlignment: FloatingLabelAlignment.start,
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0),
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0),
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(
              color: Color(0xFF31718F),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  void _deleteWord(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black.withOpacity(0.6)),
            ),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 340),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: Colors.red.withOpacity(0.7),
                      size: 56,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isEnglish ? 'Delete Flashcard?' : 'Xóa Flashcard?',
                      style: GoogleFonts.quicksand(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
          ),
        ),
                    const SizedBox(height: 12),
                    Text(
          _isEnglish
                          ? 'This action cannot be undone.'
                          : 'Hành động này không thể được hoàn tác.',
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
        ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
            onPressed: () => Navigator.pop(context),
                            child: Text(
                              _isEnglish ? 'Cancel' : 'Hủy',
                              style: GoogleFonts.quicksand(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _vocabularyList.removeAt(index);
                _hasChanges = true; // Mark as changed
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
            ),
            child: Text(
              _isEnglish ? 'Delete' : 'Xóa',
                              style: GoogleFonts.quicksand(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
            ),
          ),
        ],
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

  void _addNewFlashcard() {
    final wordController = TextEditingController();
    final phoneticController = TextEditingController();
    final meaningController = TextEditingController();
    final exampleController = TextEditingController();
    final wordClassController = TextEditingController(text: 'noun');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black.withOpacity(0.6),
              ),
            ),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEnglish ? 'Add New Flashcard' : 'Thêm Flashcard mới',
                        style: GoogleFonts.quicksand(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Word Field
                      _buildFloatingLabelField(
                        controller: wordController,
                        label: _isEnglish ? 'Word *' : 'Từ vựng *',
                      ),
                      const SizedBox(height: 24),

                      // Phonetic Field
                      _buildFloatingLabelField(
                        controller: phoneticController,
                        label: _isEnglish ? 'Phonetic' : 'Phiên âm',
                      ),
                      const SizedBox(height: 24),

                      // Meaning Field
                      _buildFloatingLabelField(
                        controller: meaningController,
                        label: _isEnglish ? 'Meaning *' : 'Nghĩa *',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      // Example Field
                      _buildFloatingLabelField(
                        controller: exampleController,
                        label: _isEnglish ? 'Example' : 'Ví dụ',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),

                      // Word Class Dropdown
                      DropdownButtonFormField(
                        value: wordClassController.text,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: _isEnglish ? 'Word Class' : 'Loại từ',
                          labelStyle: GoogleFonts.quicksand(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          floatingLabelAlignment: FloatingLabelAlignment.start,
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: Color(0xFF31718F),
                              width: 2,
                            ),
                          ),
                        ),
                        items: ['noun', 'verb', 'adjective', 'adverb', 'preposition', 'pronoun', 'conjunction', 'other']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            wordClassController.text = value;
                          }
                        },
                      ),
                      const SizedBox(height: 40),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              _isEnglish ? 'Cancel' : 'Hủy',
                              style: GoogleFonts.quicksand(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {
                              final word = wordController.text.trim();
                              final meaning = meaningController.text.trim();

                              if (word.isEmpty || meaning.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      _isEnglish
                                          ? 'Please fill in word and meaning'
                                          : 'Vui lòng điền từ vựng và nghĩa',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                _vocabularyList.add(
                                  DictionaryEntry(
                                    id: -(DateTime.now().millisecondsSinceEpoch),
                                    term: word,
                                    language: 'en',
                                    pronunciation: phoneticController.text.trim(),
                                    wordClass: wordClassController.text,
                                    meaning: meaning,
                                    example: exampleController.text.trim(),
                                    vietnameseMeaning: null,
                                    vietnameseExample: null,
                                    isCommon: false,
                                    frequency: 0,
                                  ),
                                );
                                _hasChanges = true; // Mark as changed
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF31718F),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              elevation: 8,
                              shadowColor: const Color(0xFF31718F).withOpacity(0.2),
                            ),
                            child: Text(
                              _isEnglish ? 'Add' : 'Thêm',
                              style: GoogleFonts.quicksand(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
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
        throw Exception(_isEnglish ? 'User not logged in' : 'Người dùng chưa đăng nhập');
      }

      // Prepare vocabulary data for saving
      final vocabularyData = _vocabularyList
          .map((word) => {
                'term': word.term,
                'meaning': word.meaning,
                'pronunciation': word.pronunciation,
                'wordClass': word.wordClass,
                'example': word.example,
              })
          .toList();

      // Check if editing or creating new
      if (widget.lessonId != null) {
        // Update existing lesson
        final result = await _lessonService.updateCustomLesson(
          lessonId: widget.lessonId!,
          title: _lessonName,
          description: _description,
          vocabularyWords: vocabularyData,
        );

        if (result == null) {
          throw Exception(_isEnglish ? 'Failed to update lesson' : 'Không thể cập nhật bài học');
        }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEnglish
                    ? 'Lesson updated successfully! ${result['vocabularyCount']} words saved'
                    : 'Cập nhật bài học thành công! ${result['vocabularyCount']} từ đã lưu',
              ),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.of(context).pop(true);
        }
      } else {
        // First, save any new English words to the dictionary database
        await _lessonService.saveNewEnglishWords(vocabularyData);

        // Then create the custom lesson
        final result = await _lessonService.createCustomLesson(
          userId: userId,
          title: _lessonName,
          description: _description,
          vocabularyWords: vocabularyData,
        );

        if (result == null) {
          throw Exception(_isEnglish ? 'Failed to save lesson' : 'Không thể lưu bài học');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEnglish
                    ? 'Lesson created successfully! ${result['vocabularyCount']} words saved'
                    : 'Tạo bài học thành công! ${result['vocabularyCount']} từ đã lưu',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to my lessons screen with success flag
          Navigator.of(context).popUntil((route) => route.isFirst);
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
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
              isEnglish ? 'Error saving lesson: $e' : 'Lỗi lưu bài học: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 Building FlashcardEditorScreen - lessonId: ${widget.lessonId}, vocab count: ${_vocabularyList.length}, loading: $_isLoadingData');
    return WillPopScope(
      onWillPop: _handleBackPressed,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
          // Fixed Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _showConfirmExitDialog,
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
                  Expanded(
                    child: Text(
                    _isEnglish ? 'Edit Flashcards' : 'Chỉnh sửa Flashcard',
                      textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),

          // Main Content
          Expanded(
            child: _isLoadingData
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isEnglish ? 'Loading vocabulary...' : 'Đang tải từ vựng...',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    child: Column(
                children: [
            // Lesson info
                  Container(
                width: double.infinity,
                    padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.primaryColor.withOpacity(0.2),
                        width: 1,
                      ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _editLessonName,
                            child: Text(
                              _lessonName,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _editLessonName,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryColor.withOpacity(0.15),
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 18,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                        const SizedBox(height: 6),
                    Text(
                      '${_vocabularyList.length} ${_isEnglish ? 'flashcards' : 'flashcard'}',
                      style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Add new flashcard button
                  GestureDetector(
                    onTap: _addNewFlashcard,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.primaryColor,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle,
                            color: AppColors.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isEnglish ? 'Add Flashcard' : 'Thêm Flashcard',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

                  const SizedBox(height: 24),

            // Flashcard list
                  _vocabularyList.isEmpty
                      ? Column(
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
                      )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _vocabularyList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final word = _vocabularyList[index];
                            return _buildFlashcardItem(word, index);
                          },
                        ),
                ],
              ),
              ),
            ),

          // Fixed Bottom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveLesson,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    disabledBackgroundColor: AppColors.primaryColor.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.primaryColor.withOpacity(0.3),
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
        ],
        ),
      ),
    );
  }

  Widget _buildFlashcardItem(DictionaryEntry word, int index) {
    // Select color based on index
    final colors = [
      const Color(0xFFF43F5E), // rose-400
      const Color(0xFF0EA5E9), // sky-400
      const Color(0xFFFBBF24), // amber-400
      const Color(0xFF10B981), // emerald-400
    ];
    final barColor = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Colored left bar
            Container(
            width: 6,
              decoration: BoxDecoration(
              color: barColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
            ),
          ),

          // Content
            Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        word.term,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF9CA3AF),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    word.meaning,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF4B5563),
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    word.wordClass,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9CA3AF),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              ),
            ),

            // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  color: AppColors.primaryColor,
                  onPressed: () => _editWord(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
                const SizedBox(height: 12),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  color: const Color(0xFFEF4444),
                  onPressed: () => _deleteWord(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
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
