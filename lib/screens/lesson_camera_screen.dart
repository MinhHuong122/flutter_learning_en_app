import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';
import '../services/language_service.dart';
import '../services/ocr_service.dart';
import '../services/cloudinary_service.dart';
import '../models/dictionary_model.dart';
import 'flashcard_editor_screen.dart';

class LessonCameraScreen extends StatefulWidget {
  final String lessonName;
  final String description;

  const LessonCameraScreen({
    Key? key,
    required this.lessonName,
    required this.description,
  }) : super(key: key);

  @override
  State<LessonCameraScreen> createState() => _LessonCameraScreenState();
}

class _LessonCameraScreenState extends State<LessonCameraScreen> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  List<File> _capturedImages = [];
  bool _isProcessing = false;

  bool get _isEnglish => context.read<LanguageService>().isEnglish;

  Future<void> _captureImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _capturedImages.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEnglish
                  ? 'Error capturing image: $e'
                  : 'Lỗi chụp ảnh: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _captureMultipleImages(ImageSource source) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _capturedImages.addAll(images.map((img) => File(img.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEnglish
                  ? 'Error selecting images: $e'
                  : 'Lỗi chọn ảnh: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processImages() async {
    if (_capturedImages.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Step 1: Upload image to Cloudinary
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEnglish ? '📤 Uploading image to Cloudinary...' : '📤 Đang tải ảnh lên Cloudinary...',
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      List<String> imageUrls = [];
      List<dynamic> allExtractedWords = [];

      // Upload all images
      for (var i = 0; i < _capturedImages.length; i++) {
        final imageUrl = await _cloudinaryService.uploadImage(_capturedImages[i]);
        imageUrls.add(imageUrl);
        print('✅ Image ${i + 1} uploaded to Cloudinary: $imageUrl');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEnglish ? '🔍 Processing images with OCR...' : '🔍 Đang xử lý ảnh với OCR...',
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Process all images with OCR
      for (var url in imageUrls) {
        final extractedWords = await _ocrService.extractVocabularyFromUrl(url);
        allExtractedWords.addAll(extractedWords);
      }

      if (mounted) {
        // Navigate to flashcard editor with extracted words
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FlashcardEditorScreen(
              lessonName: widget.lessonName,
              description: widget.description,
              extractedWords: allExtractedWords.cast<DictionaryEntry>(),
              imagePath: imageUrls.first, // Use first image URL
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEnglish
                  ? 'Error processing image: $e'
                  : 'Lỗi xử lý ảnh: $e',
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
      backgroundColor: const Color(0xFFF9F9FF),
      body: SafeArea(
        child: Column(
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
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF0F3FF),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFF1C3355),
                        size: 24,
                      ),
                    ),
                  ),
                  Text(
                    _isEnglish ? 'Camera' : 'Máy ảnh',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1C3355),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                  ),
                ],
              ),
            ),

            // Camera Viewfinder
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Camera preview container
                    AspectRatio(
                      aspectRatio: 0.9,
                      child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: const Color(0xFFD6E3FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1C3355).withOpacity(0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                      ),
                        child: Stack(
                        children: [
                            // Background image
                            if (_capturedImages.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Center(
                                  child: Image.file(
                                    _capturedImages.first,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.center,
                                  ),
                                ),
                              )
                            else
                              ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Container(
                                  color: const Color(0xFFD6E3FF),
                                  child: Center(
                                    child: Icon(
                                      Icons.camera_alt_rounded,
                                      size: 64,
                                      color: const Color(0xFF9DB3DD).withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),

                            // Corner reticles
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: const Color(0xFF4A6085).withOpacity(0.6),
                                      width: 2,
                                    ),
                                    left: BorderSide(
                                      color: const Color(0xFF4A6085).withOpacity(0.6),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: const Color(0xFF4A6085).withOpacity(0.6),
                                      width: 2,
                                    ),
                                    right: BorderSide(
                                      color: const Color(0xFF4A6085).withOpacity(0.6),
                                      width: 2,
                            ),
                          ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: const Color(0xFF4A6085).withOpacity(0.6),
                                      width: 2,
                                    ),
                                    left: BorderSide(
                                      color: const Color(0xFF4A6085).withOpacity(0.6),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: const Color(0xFF4A6085).withOpacity(0.6),
                                      width: 2,
                                    ),
                                    right: BorderSide(
                                      color: const Color(0xFF4A6085).withOpacity(0.6),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Image count indicator
                            if (_capturedImages.isNotEmpty)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_capturedImages.length} ${_isEnglish ? 'image(s)' : 'ảnh'}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),

                    // Focus tip box - only show when no images
                    if (_capturedImages.isEmpty) ...[
                      const SizedBox(height: 16),
                    Container(
                        padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF0F3FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDFE8FF),
                                borderRadius: BorderRadius.circular(6),
                      ),
                              child: Icon(
                                Icons.lightbulb,
                                color: AppColors.primaryColor,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isEnglish ? 'FOCUS TIP' : 'MẸO LẤY NẾT',
                                    style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryColor,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isEnglish
                                        ? 'Position the subject in the center of the frame for the best AI analysis.'
                                        : 'Đặt chủ đề ở giữa khung hình để phân tích AI tốt nhất.',
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
                      const SizedBox(height: 16),
                    ] else
                      const SizedBox(height: 8),
                  ],
                              ),
                            ),
                    ),

            // Bottom controls
            Container(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Column(
                children: [
                  // Camera, capture, and help buttons - MOVED UP
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Gallery button - select multiple
                        _buildSmallButton(
                            icon: Icons.photo_library,
                            label: _isEnglish ? 'Gallery' : 'Thư viện',
                          onTap: () => _captureMultipleImages(ImageSource.gallery),
                          ),

                        // Main capture button with gradient
                        GestureDetector(
                          onTap: _isProcessing ? null : () => _captureImage(ImageSource.camera),
                          child: Opacity(
                            opacity: _isProcessing ? 0.6 : 1.0,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primaryColor,
                                    const Color(0xFF00568F),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryColor.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                              child: Container(
                      decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF91C5FF),
                                    width: 3,
                                  ),
                      ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Help button
                        _buildSmallButton(
                          icon: Icons.help_outline,
                          label: _isEnglish ? 'Help' : 'Trợ giúp',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text(_isEnglish ? 'Tips' : 'Mẹo'),
                                content: Text(
                                  _isEnglish
                                      ? 'Position the subject in the center of the frame for the best AI analysis. You can select multiple images.'
                                      : 'Đặt chủ đề ở giữa khung hình để phân tích AI tốt nhất. Bạn có thể chọn nhiều ảnh.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(_isEnglish ? 'OK' : 'OK'),
                              ),
                                ],
                            ),
                            );
                          },
                          ),
                        ],
                      ),
                    ),

                  // Spacing below buttons
                  const SizedBox(height: 12),

                  // Image gallery preview
                  if (_capturedImages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: SizedBox(
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _capturedImages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.primaryColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.file(
                                        _capturedImages[index],
                                        fit: BoxFit.cover,
                ),
              ),
            ),
                                  Positioned(
                                    top: -10,
                                    right: -10,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _capturedImages.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        width: 28,
                                        height: 28,
                decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.red,
                  boxShadow: [
                    BoxShadow(
                                              color: Colors.red.withOpacity(0.4),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                    ),
                  ],
                ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // Process button (shows only when images are captured)
                  if (_capturedImages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _processImages,
                          icon: _isProcessing
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome, size: 20),
                          label: Text(
                            _isEnglish ? 'Scan' : 'Quét',
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                              ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            disabledBackgroundColor:
                                AppColors.primaryColor.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
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

  Widget _buildSmallButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isProcessing ? null : onTap,
        child: Column(
        mainAxisSize: MainAxisSize.min,
          children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isProcessing ? const Color(0xFFDFE8FF).withOpacity(0.5) : const Color(0xFFDFE8FF),
            ),
            child: Icon(
              icon,
              color: _isProcessing ? const Color(0xFF4A6085).withOpacity(0.5) : const Color(0xFF4A6085),
              size: 28,
            ),
          ),
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
              label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF4A6085),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
