import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';
import '../services/community_service.dart';
import '../services/file_upload_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';

class CreatePostScreen extends StatefulWidget {
  final VoidCallback? onPostCreated;
  
  const CreatePostScreen({Key? key, this.onPostCreated}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final List<String> _selectedCategories = [];
  XFile? _selectedImage;
  File? _selectedFile;
  bool _isLoading = false;
  double _uploadProgress = 0;

  final List<String> categories = ['Discussion', 'Resources', 'Study Groups'];
  final List<Color> categoryColors = [
    const Color(0xFFFF9800),
    const Color(0xFF9C27B0),
    const Color(0xFF4CAF50),
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  bool get _isEnglish => context.read<LanguageService>().isEnglish;

  Future<void> _pickImage() async {
    try {
      final image = await FileUploadService().pickImageFromGallery();
      if (image != null) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      _showErrorSnackbar(_isEnglish ? 'Error selecting image: $e' : 'Lỗi chọn ảnh: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final file = await FileUploadService().pickFile();
      if (file != null) {
        setState(() => _selectedFile = file);
      }
    } catch (e) {
      _showErrorSnackbar(_isEnglish ? 'Error selecting file: $e' : 'Lỗi chọn file: $e');
    }
  }

  Future<void> _createPost() async {
    if (_contentController.text.isEmpty) {
      _showErrorSnackbar(_isEnglish ? 'Please enter post content' : 'Vui lòng nhập nội dung bài đăng');
      return;
    }

    if (_selectedCategories.isEmpty) {
      _showErrorSnackbar(_isEnglish ? 'Please select at least one category' : 'Vui lòng chọn ít nhất một danh mục');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final communityService = context.read<CommunityService>();
      final fileUploadService = FileUploadService();

      final userId = authService.userId;
      final userName = authService.userName;
      if (userId == null) {
        throw Exception(_isEnglish ? 'User not logged in' : 'Người dùng chưa đăng nhập');
      }

      String? imageUrl;
      if (_selectedImage != null) {
        setState(() => _uploadProgress = 0.3);
        imageUrl = await fileUploadService.uploadImage(
          _selectedImage!,
          userId: userId,
          folderName: 'posts',
        );
      }

      String? fileUrl;
      String? fileName;
      String? fileMimeType;
      if (_selectedFile != null) {
        setState(() => _uploadProgress = 0.6);
        fileName = _selectedFile!.path.split('/').last;
        fileMimeType = fileUploadService.getMimeType(_selectedFile!.path);
        fileUrl = await fileUploadService.uploadFile(
          _selectedFile!,
          userId: userId,
          customName: fileName,
        );
      }

      setState(() => _uploadProgress = 0.9);

      await communityService.createPost(
        userId: userId,
        userName: userName ?? 'User',
        content: _contentController.text,
        imageUrl: imageUrl,
        fileUrl: fileUrl,
        fileName: fileName,
        fileMimeType: fileMimeType,
        categoryTags: _selectedCategories,
      );

      setState(() => _uploadProgress = 1.0);

      if (!mounted) return;
      widget.onPostCreated?.call();
      Navigator.pop(context);
      _showSuccessSnackbar(_isEnglish ? 'Post created successfully!' : 'Bài đăng đã được tạo thành công!');
    } catch (e) {
      _showErrorSnackbar(_isEnglish ? 'Error: $e' : 'Lỗi: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.primaryColor, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEnglish ? 'Create Post' : 'Tạo bài đăng',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content Input
                  TextField(
                    controller: _contentController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: _isEnglish ? 'What do you want to share?' : 'Bạn muốn chia sẻ điều gì?',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF9CA3AF),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE5E7EB),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE5E7EB),
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // Selected Image Preview
                  if (_selectedImage != null)
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(
                                File(_selectedImage!.path),
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_selectedImage != null) const SizedBox(height: 16),

                  // Selected File Preview
                  if (_selectedFile != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFE0F4FF),
                        border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.file_present,
                            color: AppColors.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedFile!.path.split('/').last,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _selectedFile = null),
                            child: Icon(
                              Icons.close,
                              color: AppColors.primaryColor,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_selectedFile != null) const SizedBox(height: 16),

                  // Category Selection
                  Text(
                    _isEnglish ? 'Categories' : 'Danh mục',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: List.generate(
                      categories.length,
                      (index) {
                        final isSelected = _selectedCategories.contains(categories[index]);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedCategories.remove(categories[index]);
                              } else {
                                _selectedCategories.add(categories[index]);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: isSelected
                                  ? categoryColors[index]
                                  : const Color(0xFFF3F4F6),
                              border: Border.all(
                                color: isSelected
                                    ? categoryColors[index]
                                    : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Text(
                              categories[index],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Upload Progress
                  if (_isLoading && _uploadProgress > 0)
                    Column(
                      children: [
                        LinearProgressIndicator(
                          value: _uploadProgress,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _isLoading ? null : _pickImage,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primaryColor,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  color: AppColors.primaryColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isEnglish ? 'Image' : 'Ảnh',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: _isLoading ? null : _pickFile,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primaryColor,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.file_present,
                                  color: AppColors.primaryColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'File',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: _isLoading ? null : _createPost,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: _isLoading
                                  ? AppColors.primaryColor.withOpacity(0.5)
                                  : AppColors.primaryColor,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isLoading)
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white.withOpacity(0.8),
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.send_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                const SizedBox(width: 6),
                                Text(
                                  _isLoading ? (_isEnglish ? 'Posting...' : 'Đang...') : (_isEnglish ? 'Post' : 'Đăng'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
