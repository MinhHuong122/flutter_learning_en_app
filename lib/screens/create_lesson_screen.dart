import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/language_service.dart';
import 'lesson_camera_screen.dart';

class CreateLessonScreen extends StatefulWidget {
  const CreateLessonScreen({Key? key}) : super(key: key);

  @override
  State<CreateLessonScreen> createState() => _CreateLessonScreenState();
}

class _CreateLessonScreenState extends State<CreateLessonScreen> {
  final TextEditingController _lessonNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool get _isEnglish => context.read<LanguageService>().isEnglish;

  @override
  void dispose() {
    _lessonNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_formKey.currentState!.validate()) {
      // Navigate to camera screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LessonCameraScreen(
            lessonName: _lessonNameController.text.trim(),
            description: _descriptionController.text.trim(),
          ),
        ),
      );
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
                    _isEnglish ? 'Create Lesson' : 'Tạo bài học',
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

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // Icon Section - Significantly Smaller
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                                color: const Color(0xFFDFE8FF),
                          ),
                          child: Icon(
                            Icons.school_outlined,
                                size: 48,
                            color: AppColors.primaryColor,
                          ),
                        ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Title
                      Center(
                        child: Text(
                          _isEnglish ? 'Ready to capture?' : 'Sẵn sàng chụp?',
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                          fontWeight: FontWeight.w700,
                            color: const Color(0xFF1C3355),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Center(
                        child: Text(
                        _isEnglish
                              ? 'Capture vocabulary directly from images\nto build your lesson.'
                              : 'Chụp từ vựng trực tiếp từ hình ảnh\nđể xây dựng bài học của bạn.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF4A6085),
                          height: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Form Section with Gap
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      // Lesson Name Input
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                      Text(
                                _isEnglish ? 'LESSON NAME' : 'TÊN BÀI HỌC',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                          fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4A6085),
                                  letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _lessonNameController,
                        decoration: InputDecoration(
                          hintText: _isEnglish
                                      ? 'e.g. Italian Coffee Culture'
                                      : 'Ví dụ: Văn hóa cà phê Ý',
                                  hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                                    color: const Color(0xFF9DB3DD),
                          ),
                          filled: true,
                                  fillColor: Colors.white,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                                    vertical: 12,
                                  ),
                                  suffixIcon: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Icon(
                                      Icons.edit,
                                      color: AppColors.primaryColor.withOpacity(0.4),
                                      size: 20,
                                    ),
                                  ),
                                  suffixIconConstraints:
                                      const BoxConstraints(minWidth: 40, minHeight: 40),
                          ),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF1C3355),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return _isEnglish
                                ? 'Please enter a lesson name'
                                : 'Vui lòng nhập tên bài học';
                          }
                          return null;
                        },
                              ),
                            ],
                      ),

                          const SizedBox(height: 16),

                      // Description Input (Optional)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                      Text(
                                _isEnglish ? 'DESCRIPTION (OPTIONAL)' : 'MÔ TẢ (TÙY CHỌN)',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                          fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4A6085),
                                  letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                                maxLines: 2,
                                minLines: 2,
                        decoration: InputDecoration(
                          hintText: _isEnglish
                                      ? 'What is this lesson about?'
                                      : 'Bài học này về cái gì?',
                                  hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                                    color: const Color(0xFF9DB3DD),
                          ),
                          filled: true,
                                  fillColor: Colors.white,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                                    vertical: 12,
                          ),
                        ),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF1C3355),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Info Card
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F3FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDFE8FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.photo_camera,
                              color: AppColors.primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isEnglish ? 'Image-to-Word' : 'Hình ảnh-thành-Từ',
                                    style: GoogleFonts.manrope(
                                  fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1C3355),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isEnglish
                                        ? 'AI detects and translates objects\nin your photos for this lesson.'
                                        : 'AI phát hiện và dịch các đối tượng\ntrong ảnh của bạn cho bài học này.',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF4A6085),
                                      height: 1.4,
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
                ),
              ),
            ),

            // Bottom button with gradient
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryColor,
                        AppColors.primaryLight.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _onNext,
                      borderRadius: BorderRadius.circular(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isEnglish ? 'Next' : 'Tiếp theo',
                            style: GoogleFonts.manrope(
                          fontSize: 16,
                              fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
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
}
