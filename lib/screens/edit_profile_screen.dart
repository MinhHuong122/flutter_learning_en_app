import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../utils/constants.dart';
import '../services/language_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  File? _selectedImage;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Alonzo Lee');
    _emailController = TextEditingController(text: 'alonzo.lee@example.com');
    _bioController = TextEditingController(
      text: 'Passionate lifelong learner and UI designer. Currently focusing on advanced computer science and digital psychology.',
    );
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('profiles')
          .select('display_name, bio, avatar_url')
          .eq('id', user.id)
          .single();

      if (mounted) {
        _nameController.text = response['display_name'] ?? '';
        _emailController.text = user.email ?? '';
        _bioController.text = response['bio'] ?? '';
        _avatarUrl = response['avatar_url'];
        setState(() {});
      }
    } catch (e) {
      print('Error loading profile data: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  bool get _isEnglish => context.read<LanguageService>().isEnglish;

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(_isEnglish ? 'Take Photo' : 'Chụp ảnh'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (image != null && mounted) {
                    setState(() {
                      _selectedImage = File(image.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: Text(_isEnglish ? 'Choose from Gallery' : 'Chọn từ Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null && mounted) {
                    setState(() {
                      _selectedImage = File(image.path);
                    });
                  }
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _saveChanges() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      String? avatarUrl = _avatarUrl;

      // Upload image if selected
      if (_selectedImage != null) {
        final fileName = 'avatar_${user.id}_${DateTime.now().millisecondsSinceEpoch}.png';
        
        await Supabase.instance.client.storage
            .from('profiles')
            .upload(fileName, _selectedImage!);
        
        avatarUrl = Supabase.instance.client.storage
            .from('profiles')
            .getPublicUrl(fileName);
      }

      // Update profile in Supabase
      await Supabase.instance.client
          .from('profiles')
          .update({
            'display_name': _nameController.text,
            'bio': _bioController.text,
            'avatar_url': avatarUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
              SnackBar(
                content: Text(
                  _isEnglish
                      ? 'Profile updated successfully!'
                      : 'Hồ sơ đã được cập nhật thành công!',
                ),
                backgroundColor: AppColors.primaryColor,
                duration: const Duration(seconds: 2),
              ),
            );
        // Navigate back
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
              SnackBar(
                content: Text(
                  _isEnglish ? 'Error saving profile' : 'Lỗi khi lưu hồ sơ',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFF),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            _buildHeader(),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    // Profile Photo Section
                    _buildProfilePhotoSection(),
                    const SizedBox(height: 40),

                    // Form Fields
                    _buildFormFields(),
                  ],
                ),
              ),
            ),

            // Footer Action
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
        ),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF64748B),
                size: 18,
              ),
            ),
          ),
          Text(
            _isEnglish ? 'Edit Profile' : 'Chỉnh sửa hồ sơ',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(width: 40), // Spacer for centering
        ],
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(64),
                child: _selectedImage != null
                    ? Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      )
                    : _avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? Image.network(
                            _avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.primaryColor.withOpacity(0.1),
                                child: Icon(
                                  Icons.person,
                                  size: 64,
                                  color: AppColors.primaryColor,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            child: Icon(
                              Icons.person,
                              size: 64,
                              color: AppColors.primaryColor,
                            ),
                          ),
              ),
            ),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryColor,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.photo_camera,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _isEnglish ? 'Change Profile Photo' : 'Đổi ảnh hồ sơ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        // Full Name
        _buildFormField(
          label: _isEnglish ? 'Full Name' : 'Họ tên',
          icon: Icons.person_outline,
          controller: _nameController,
          hint: _isEnglish ? 'Enter your name' : 'Nhập tên của bạn',
        ),
        const SizedBox(height: 24),

        // Email Address
        _buildFormField(
          label: _isEnglish ? 'Email Address' : 'Địa chỉ email',
          icon: Icons.mail_outline,
          controller: _emailController,
          hint: _isEnglish ? 'Enter your email' : 'Nhập email của bạn',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),

        // Bio
        _buildBioField(),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFFC4B5FD),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(
                  icon,
                  color: const Color(0xFF9CA3AF),
                  size: 20,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              suffixIconConstraints: const BoxConstraints(),
            ),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isEnglish ? 'Bio' : 'Tiểu sử',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _bioController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: _isEnglish ? 'Tell us about yourself...' : 'Kể cho chúng tôi về bạn...',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFFC4B5FD),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12, top: 14),
                child: Icon(
                  Icons.notes,
                  color: const Color(0xFF9CA3AF),
                  size: 20,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 14,
              ),
            ),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _isEnglish ? 'Save Changes' : 'Lưu thay đổi',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
