import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../utils/constants.dart';
import '../widgets/custom_bottom_nav.dart';
import '../services/language_service.dart';
import '../services/community_service.dart';
import '../services/auth_service.dart';
import '../services/file_history_service.dart';
import '../services/storage_quota_service.dart';
import '../models/community_model.dart';
import 'home_screen.dart';
import 'process_screen.dart';

import 'account_screen.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import 'community_profile_screen.dart';
import 'storage_upgrade_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _currentIndex = 3;
  int _selectedCategory = 0;
  
  final List<String> _backendCategories = ['All', 'Discussion', 'Resources', 'Study Groups'];
  
  List<String> get categories {
    if (_isEnglish) {
      return ['All', 'Discussion', 'Resources', 'Study Groups'];
    } else {
      return ['Tất cả', 'Thảo luận', 'Tài nguyên', 'Nhóm học tập'];
    }
  }
  
  final List<Color> categoryColors = [
    AppColors.primaryColor,
    const Color(0xFFFF9800),
    const Color(0xFF9C27B0),
    const Color(0xFF4CAF50),
  ];
  final List<Color> categoryBgColors = [
    const Color(0xFFD4E8F7), // Pastel blue
    const Color(0xFFFFE4B5), // Pastel orange
    const Color(0xFFE6D4F0), // Pastel purple
    const Color(0xFFD4EDD4), // Pastel green
  ];

  late TextEditingController _searchController;
  List<CommunityPost> _posts = [];
  List<Map<String, dynamic>> _sharedLessons = [];
  bool _isLoading = false;
  int _selectedChip = 0; // 0: All, 1: Discussion, 2: Resources, 3: Study Groups, 4: Shared Lessons
  Set<String> _savedLessonIds = {}; // Track saved lessons to avoid duplicates

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadPosts();
    _loadSharedLessons(); // Load shared lessons on first launch
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSharedLessons() async {
    if (!mounted) return;
    final isEnglish = context.read<LanguageService>().isEnglish;
    setState(() => _isLoading = true);
    try {
      final communityService = context.read<CommunityService>();
      final lessons = await communityService.getSharedLessons();
      if (!mounted) return;
      // Load saved lessons for current user
      await _loadSavedLessonIds();
      setState(() => _sharedLessons = lessons);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar(isEnglish ? 'Error: $e' : 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSavedLessonIds() async {
    try {
      final authService = context.read<AuthService>();
      final userId = authService.userId;
      if (userId == null) return;

      final communityService = context.read<CommunityService>();
      final supabase = communityService.supabase;

      final response = await supabase
          .from('shared_lesson_saves')
          .select('shared_lesson_id')
          .eq('user_id', userId);

      if (!mounted) return;
      setState(() {
        _savedLessonIds = Set<String>.from(
          (response as List).map((item) => item['shared_lesson_id'].toString())
        );
      });
    } catch (e) {
      // Silent fail - not critical
    }
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    final isEnglish = context.read<LanguageService>().isEnglish;
    setState(() => _isLoading = true);
    try {
      final communityService = context.read<CommunityService>();
      final category = _selectedCategory == 0 ? null : _backendCategories[_selectedCategory];
      final posts = await communityService.getPosts(category: category);
      if (!mounted) return;
      setState(() => _posts = posts);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar(isEnglish ? 'Error: $e' : 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToChatAi() async {
    // TODO: Implement ChatAiScreen navigation
  }

  Future<void> _refreshPage() async {
    // Refresh both posts and shared lessons
    await Future.wait([
      _loadPosts(),
      _loadSharedLessons(),
    ]);
  }

  Future<void> _searchPosts(String query) async {
    if (!mounted) return;
    final isEnglish = context.read<LanguageService>().isEnglish;
    if (query.isEmpty) {
      _loadPosts();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final communityService = context.read<CommunityService>();
      final posts = await communityService.searchPosts(query);
      if (!mounted) return;
      setState(() => _posts = posts);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar(isEnglish ? 'Error: $e' : 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  bool get _isEnglish => context.read<LanguageService>().isEnglish;

  void _onBottomNavTap(int index) {
    if (index == _currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProcessScreen()),
        );
        break;
      case 2:
        _navigateToChatAi();
        break;
      case 3:
        setState(() => _currentIndex = index);
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AccountScreen()),
        );
        break;
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEnglish ? 'Community' : 'Cộng đồng',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            _isEnglish ? 'Connect with fellow learners' : 'Kết nối với các học viên khác',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          final authService = context.read<AuthService>();
                          final userId = authService.userId;
                          if (userId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CommunityProfileScreen(
                                  userId: userId,
                                  isCurrentUser: true,
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE0F4FF),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primaryColor,
                          size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFFF3F4F6),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _searchPosts,
                      decoration: InputDecoration(
                        hintText: _isEnglish ? 'Search discussions...' : 'Tìm kiếm bài viết...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF9CA3AF),
                        ),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.search,
                          color: const Color(0xFF9CA3AF),
                          size: 20,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Unified Chips Bar (Posts Categories + Shared Lessons)
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length + 1,
                      itemBuilder: (context, index) => Padding(
                        padding: EdgeInsets.only(right: index == categories.length ? 0 : 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedChip = index;
                              if (index == categories.length) {
                                // Shared Lessons
                                _loadSharedLessons();
                              } else if (index == 0) {
                                // All - Load both posts and shared lessons
                                _selectedCategory = 0;
                                _loadPosts();
                                _loadSharedLessons();
                              } else {
                                // Category filter
                                _selectedCategory = index;
                                _loadPosts();
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: _selectedChip == index
                                  ? (index == categories.length 
                                      ? const Color(0xFFE85C5C)
                                      : categoryColors[index])
                                  : (index == categories.length
                                      ? const Color(0xFFFFD4D4)
                                      : categoryBgColors[index]),
                              border: index == categories.length && _selectedChip != index
                                  ? Border.all(color: const Color(0xFFE5E7EB))
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                index == categories.length
                                    ? (_isEnglish ? 'Shared Lessons' : 'Bài học chia sẻ')
                                    : categories[index],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedChip == index
                                      ? Colors.white
                                      : (index < 4
                                          ? categoryColors[index]
                                          : const Color(0xFFDC2626)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Feed
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshPage,
                color: AppColors.primaryColor,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _selectedChip == 0
                      ? (_posts.isEmpty && _sharedLessons.isEmpty
                          ? Center(
                              child: Text(
                                _isEnglish ? 'No content yet' : 'Chưa có nội dung nào',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              children: [
                                ..._posts.map((post) => GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PostDetailScreen(post: post),
                                    ),
                                  ),
                                  child: _buildPostCard(post),
                                )),
                                ..._sharedLessons.map((lesson) => _buildSharedLessonCard(lesson)),
                                const SizedBox(height: 80),
                              ],
                            ))
                      : _selectedChip < 4
                          ? (_posts.isEmpty
                              ? Center(
                                  child: Text(
                                    _isEnglish ? 'No posts yet' : 'Chưa có bài đăng nào',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                )
                              : ListView(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  children: [
                                    ..._posts.map((post) => GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PostDetailScreen(post: post),
                                        ),
                                      ),
                                      child: _buildPostCard(post),
                                    )),
                                    const SizedBox(height: 80),
                                  ],
                                ))
                          : (_sharedLessons.isEmpty
                              ? Center(
                                  child: Text(
                                    _isEnglish ? 'No shared lessons yet' : 'Chưa có bài học chia sẻ nào',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                )
                              : ListView(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  children: [
                                    ..._sharedLessons.map((lesson) => _buildSharedLessonCard(lesson)),
                                    const SizedBox(height: 80),
                                  ],
                                )),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            backgroundColor: Colors.white,
            builder: (BuildContext context) {
              return FractionallySizedBox(
                heightFactor: 0.85, // 85% of screen = ~2.5-3 screen height
                child: CreatePostScreen(
                  onPostCreated: () {
                    Navigator.pop(context);
                    _loadPosts();
                  },
                ),
              );
            },
          );
        },
        backgroundColor: Colors.white,
        elevation: 8,
        child: const Icon(Icons.add, size: 28, color: AppColors.primaryColor),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User header
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CommunityProfileScreen(
                  userId: post.userId,
                  isCurrentUser: false,
                ),
              ),
            ),
            child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primaryColor, AppColors.primaryLight],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                  child: (post.userAvatar != null && post.userAvatar!.isNotEmpty)
                      ? ClipOval(
                          child: Image.network(
                            post.userAvatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                  child: Text(
                                post.userName.isNotEmpty
                                    ? post.userName[0].toUpperCase()
                                    : 'U',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            post.userName.isNotEmpty
                                ? post.userName[0].toUpperCase()
                                : 'U',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        post.userName,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                        _formatTime(post.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
          const SizedBox(height: 12),

          // Content
          Text(
            post.content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF4B5563),
              height: 1.5,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // If this post is a share, show nested original post preview
          if (post.sharedPostContent != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.primaryColor, AppColors.primaryLight],
                          ),
                        ),
                        child: (post.sharedPostUserAvatar != null && post.sharedPostUserAvatar!.isNotEmpty)
                            ? ClipOval(
                                child: Image.network(post.sharedPostUserAvatar!, fit: BoxFit.cover),
                              )
                            : Center(
                                child: Text(
                                  post.sharedPostUserName != null && post.sharedPostUserName!.isNotEmpty
                                      ? post.sharedPostUserName![0].toUpperCase()
                                      : 'U',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.sharedPostUserName ?? (_isEnglish ? 'Original' : 'Bản gốc'),
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            if (post.sharedPostCreatedAt != null)
                              Text(
                                _formatTime(post.sharedPostCreatedAt!),
                                style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF9CA3AF)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.sharedPostContent ?? '',
                    style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF4B5563)),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (post.sharedPostImageUrl != null)
                    GestureDetector(
                      onTap: () => _showImageFullScreen(post.sharedPostImageUrl!),
                      child: Container(
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(post.sharedPostImageUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  if (post.sharedPostFileUrl != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFEFF6FF),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.insert_drive_file, size: 16, color: AppColors.primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              post.sharedPostFileName ?? (_isEnglish ? 'Attachment' : 'Tệp đính kèm'),
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          // Image
          if (post.imageUrl != null)
            GestureDetector(
              onTap: () => _showImageFullScreen(post.imageUrl!),
              child: Container(
                width: double.infinity,
                height: 180,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(post.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          // File Download
          if (post.fileUrl != null)
            GestureDetector(
              onTap: () => _recordFileDownload(post),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFFE0F4FF),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.download,
                      size: 16,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      post.fileName ?? (_isEnglish ? 'Download resource' : 'Tải tài nguyên'),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (post.fileUrl != null) const SizedBox(height: 12),

          // Actions
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: const Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                    label: '${post.likes}',
                    onTap: () => _toggleLike(post),
                    isLiked: post.isLikedByMe,
                  ),
                ),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: '${post.comments}',
                    onTap: () => _navigateToPostDetail(post),
                  ),
                ),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.share_outlined,
                    label: '',
                    onTap: () => _sharePost(post),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLiked = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: isLiked ? Colors.red : const Color(0xFF9CA3AF),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleLike(CommunityPost post) async {
    try {
      final authService = context.read<AuthService>();
      final userId = authService.userId;
      if (userId == null) {
        _showErrorSnackbar(_isEnglish ? 'Please login first' : 'Vui lòng đăng nhập trước');
        return;
      }
      
      final communityService = context.read<CommunityService>();
      await communityService.likePost(post.id, userId);
      _loadPosts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEnglish ? 'Liked!' : 'Đã thích!'),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.primaryColor,
        ),
      );
    } catch (e) {
      _showErrorSnackbar(_isEnglish ? 'Error: $e' : 'Lỗi: $e');
    }
  }

  void _navigateToPostDetail(CommunityPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(post: post),
      ),
    ).then((_) {
      // Reload posts when back from post detail
      _loadPosts();
    });
  }

  Future<void> _sharePost(CommunityPost post) async {
    try {
      final authService = context.read<AuthService>();
      final userId = authService.userId;
      final userName = authService.userName ?? 'User';
      
      if (userId == null) {
        _showErrorSnackbar(_isEnglish ? 'Please login first' : 'Vui lòng đăng nhập trước');
        return;
      }

      final communityService = context.read<CommunityService>();
      await communityService.sharePost(
        originalPostId: post.id,
        userId: userId,
        userName: userName,
      );
      _loadPosts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEnglish ? 'Shared!' : 'Đã chia sẻ!'),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.primaryColor,
        ),
      );
    } catch (e) {
      _showErrorSnackbar(_isEnglish ? 'Error: $e' : 'Lỗi: $e');
    }
  }

  void _showImageFullScreen(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return _isEnglish ? 'Just now' : 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return _isEnglish 
          ? '${difference.inMinutes} minutes ago'
          : '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return _isEnglish 
          ? '${difference.inHours} hours ago'
          : '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return _isEnglish 
          ? '${difference.inDays} days ago'
          : '${difference.inDays} ngày trước';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  Future<void> _recordFileDownload(CommunityPost post) async {
    try {
      // Request storage permissions
      if (Platform.isAndroid) {
        final status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          // Fallback to WRITE_EXTERNAL_STORAGE
          await Permission.storage.request();
        }
      }

      if (post.fileUrl == null || post.fileUrl!.isEmpty) {
        _showErrorSnackbar(_isEnglish ? 'File URL not available' : 'URL file không có');
        return;
      }

      setState(() => _isLoading = true);

      // Check storage quota before downloading
      final quotaService = StorageQuotaService();
      
      // Estimate file size - we'll use a reasonable estimate (10MB average)
      const estimatedFileSizeBytes = 10 * 1024 * 1024; // 10MB estimate
      
      final canDownload = await quotaService.canDownloadFile(estimatedFileSizeBytes);
      if (!canDownload) {
        if (mounted) {
          setState(() => _isLoading = false);
          
          // Show storage full dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(_isEnglish ? 'Storage Full' : 'Dung lượng đầy'),
              content: Text(
                _isEnglish 
                    ? 'You have reached your storage limit. Please upgrade to continue downloading.'
                    : 'Bạn đã hết giới hạn dung lượng. Vui lòng nâng cấp để tiếp tục tải.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_isEnglish ? 'Cancel' : 'Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StorageUpgradeScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
                  child: Text(_isEnglish ? 'Upgrade Now' : 'Nâng cấp ngay'),
                ),
              ],
            ),
          );
        }
        return;
      }
      Directory? downloadsDir;
      try {
        // Try getDownloadsDirectory first
        downloadsDir = await getDownloadsDirectory();
        
        // Fallback: construct path manually if null
        if (downloadsDir == null) {
          final downloadPath = '/storage/emulated/0/Download';
          downloadsDir = Directory(downloadPath);
        }
      } catch (e) {
        // Silent catch
      }

      // Last resort: use /storage/emulated/0/Download directly
      downloadsDir ??= Directory('/storage/emulated/0/Download');

      if (!await downloadsDir.exists()) {
        try {
          await downloadsDir.create(recursive: true);
        } catch (e) {
          _showErrorSnackbar(_isEnglish ? 'Cannot access downloads folder: $e' : 'Không thể truy cập thư mục tải xuống: $e');
          if (mounted) setState(() => _isLoading = false);
          return;
        }
      }

      // Get unique file path
      final fileName = post.fileName ?? 'download_${DateTime.now().millisecondsSinceEpoch}';
      final filePath = _getUniqueFilePath(downloadsDir.path, fileName);
      final file = File(filePath);

      // Create cancel token for download
      final CancelToken cancelToken = CancelToken();
      
      // Progress state for dialog
      double downloadProgress = 0.0;
      late StateSetter setDialogState;

      // Show beautiful progress dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) {
              setDialogState = setState;
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Row(
                        children: [
                          Icon(Icons.cloud_download, color: AppColors.primaryColor, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _isEnglish ? 'Downloading File' : 'Đang Tải File',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Progress bar with animation
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              value: downloadProgress,
                              minHeight: 12,
                              backgroundColor: const Color(0xFFE5E7EB),
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Progress text
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isEnglish ? 'Progress' : 'Tiến độ',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              Text(
                                '${(downloadProgress * 100).toStringAsFixed(0)}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // File name
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.insert_drive_file, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                fileName,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF4B5563),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Cancel button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            cancelToken.cancel();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5E7EB),
                            foregroundColor: const Color(0xFF1F2937),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            _isEnglish ? 'Cancel Download' : 'Hủy Tải',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }

      // Download file with cancel token
      final dio = Dio(BaseOptions(receiveTimeout: const Duration(seconds: 60)));
      
      try {
        await dio.download(
          post.fileUrl!,
          filePath,
          cancelToken: cancelToken,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              downloadProgress = received / total;
              try {
                setDialogState(() {});
              } catch (e) {
                // Dialog closed
              }
            }
          },
        );
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) {
          // Download cancelled by user
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          // Delete incomplete file
          if (await file.exists()) {
            await file.delete();
          }
          return;
        }
        rethrow;
      }

      // Close progress dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Verify file was actually downloaded
      if (!await file.exists()) {
        _showErrorSnackbar(_isEnglish ? 'Download failed: File not saved' : 'Tải xuống thất bại: File không được lưu');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Get actual file size in MB
      final fileSize = await file.length();
      final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);

      // Extract file type from fileName
      String fileType = 'doc';
      if (post.fileName != null) {
        final ext = post.fileName!.split('.').last.toLowerCase();
        fileType = ext;
      }

      // Record file download to history with verified file path and actual size
      await FileHistoryService().addFileToHistory(
        fileName: post.fileName ?? 'Unknown File',
        fileSize: '$fileSizeMB MB',
        fileType: fileType,
        action: 'download',
        sourceScreen: 'community',
        filePath: filePath,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEnglish
                  ? '✅ File downloaded ($fileSizeMB MB)\nCheck Downloads folder'
                  : '✅ File đã tải ($fileSizeMB MB)\nXem thư mục Downloads',
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        setState(() => _isLoading = false);
      }
      String errorMsg = _isEnglish ? 'Download error' : 'Lỗi tải xuống';
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMsg = _isEnglish ? 'Connection timeout' : 'Hết thời gian kết nối';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMsg = _isEnglish ? 'Download timeout' : 'Hết thời gian tải';
      } else if (e.type == DioExceptionType.unknown && e.error is SocketException) {
        errorMsg = _isEnglish ? 'No internet connection' : 'Không có kết nối internet';
      }
      _showErrorSnackbar(errorMsg);
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        setState(() => _isLoading = false);
      }
      _showErrorSnackbar(_isEnglish ? 'Error: $e' : 'Lỗi: $e');
    }
  }

  /// Generate unique file path by appending (1), (2), etc if file already exists
  String _getUniqueFilePath(String dirPath, String fileName) {
    // Use path package for proper path joining
    final filePath = p.join(dirPath, fileName);
    final file = File(filePath);
    
    // If file doesn't exist, return as is
    if (!file.existsSync()) {
      return filePath;
    }

    // File exists, append number before extension
    final baseName = p.basenameWithoutExtension(fileName);
    final extension = p.extension(fileName); // Includes the dot

    // Try (1), (2), (3), etc.
    for (int i = 1; i <= 100; i++) {
      final newFileName = '$baseName ($i)$extension';
      final newFilePath = p.join(dirPath, newFileName);
      final newFile = File(newFilePath);
      if (!newFile.existsSync()) {
        return newFilePath;
      }
    }

    // Fallback with timestamp if all (1)-(100) exist
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return p.join(dirPath, '$baseName ($timestamp)$extension');
  }

  Future<void> _saveLessonToCustom(Map<String, dynamic> lesson) async {
    try {
      final authService = context.read<AuthService>();
      final userId = authService.userId;
      if (userId == null) {
        _showErrorSnackbar(_isEnglish ? 'Please login first' : 'Vui lòng đăng nhập trước');
        return;
      }

      // Check if lesson is already saved
      final lessonId = lesson['id'].toString();
      if (_savedLessonIds.contains(lessonId)) {
        _showAlreadySavedDialog(lesson);
        return;
      }

      final communityService = context.read<CommunityService>();
      final supabase = communityService.supabase;

      setState(() => _isLoading = true);

      // Create new custom lesson in ocr_lessons table
      final newLessonResponse = await supabase.from('ocr_lessons').insert({
        'user_id': userId,
        'title': lesson['title'] ?? 'Shared Lesson',
        'description': lesson['description'] ?? '',
      }).select();

      if (newLessonResponse.isEmpty) {
        throw Exception(_isEnglish ? 'Failed to create lesson' : 'Không thể tạo bài học');
      }

      final newLessonId = newLessonResponse[0]['id'];
      final sharedFlashcards = (lesson['shared_flashcards'] as List?) ?? [];

      // Copy flashcards to the new custom lesson
      if (sharedFlashcards.isNotEmpty) {
        final flashcardsToInsert = sharedFlashcards.map((card) {
          return {
            'lesson_id': newLessonId,
            'term': card['term'] ?? '',
            'meaning': card['meaning'] ?? '',
            'pronunciation': card['pronunciation'] ?? '',
            'word_class': card['word_class'] ?? 'noun',
            'example_sentence': card['example'] ?? '',
          };
        }).toList();

        await supabase.from('lesson_vocabulary').insert(flashcardsToInsert);
      }

      // Record the save in shared_lesson_saves
      await supabase.from('shared_lesson_saves').insert({
        'shared_lesson_id': lesson['id'],
        'user_id': userId,
        'saved_as_lesson_id': newLessonId,
      });

      if (mounted) setState(() => _isLoading = false);

      // Add to saved lessons set
      setState(() {
        _savedLessonIds.add(lessonId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnglish 
                ? '✅ Lesson saved to "My Lessons"!' 
                : '✅ Bài học đã được lưu vào "Bài học của tôi"!',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _isLoading = false);
      // Handle duplicate key error (code 23505)
      if (e.code == '23505') {
        _showAlreadySavedDialog(lesson);
        // Update saved lessons set
        setState(() {
          _savedLessonIds.add(lesson['id'].toString());
        });
      } else {
        _showErrorSnackbar(_isEnglish ? 'Error: ${e.message}' : 'Lỗi: ${e.message}');
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showErrorSnackbar(_isEnglish ? 'Error: $e' : 'Lỗi: $e');
    }
  }

  void _showAlreadySavedDialog(Map<String, dynamic> lesson) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isEnglish ? 'Already Saved' : 'Đã được lưu',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEnglish 
                  ? 'This lesson is already in your "My Lessons".' 
                  : 'Bài học này đã có trong "Bài học của tôi".',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isEnglish
                  ? 'Would you like to open it in your lessons?'
                  : 'Bạn có muốn mở nó trong bài học của bạn không?',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _isEnglish ? 'Close' : 'Đóng',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              // Optional: Navigate to My Lessons screen
              // Navigator.push(context, MaterialPageRoute(builder: (_) => MyLessonsScreen()));
            },
            child: Text(
              _isEnglish ? 'OK' : 'Xác nhận',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewLessonDetail(Map<String, dynamic> lesson) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        final flashcards = (lesson['shared_flashcards'] as List?) ?? [];
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson['title'] as String? ?? 'Untitled',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          if (lesson['description'] != null && (lesson['description'] as String).isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              lesson['description'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, size: 24),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: flashcards.length,
                  itemBuilder: (context, index) {
                    final card = flashcards[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${index + 1}/${flashcards.length}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5F2FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _isEnglish ? 'Flashcard' : 'Thẻ',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isEnglish ? 'Term' : 'Từ',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            card['term'] ?? 'Term',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isEnglish ? 'Meaning' : 'Định nghĩa',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            card['meaning'] ?? 'Meaning',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF4B5563),
                              height: 1.5,
                            ),
                          ),
                          if (card['example'] != null && (card['example'] as String).isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              _isEnglish ? 'Example' : 'Ví dụ',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              card['example'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF6B7280),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSharedLessonCard(Map<String, dynamic> lesson) {
    final flashcards = (lesson['shared_flashcards'] as List?) ?? [];
    final createdAt = lesson['created_at'] != null
        ? DateTime.parse(lesson['created_at'] as String)
        : DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson['title'] as String? ?? 'Untitled',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lesson['description'] != null && (lesson['description'] as String).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        lesson['description'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${lesson['flashcard_count'] ?? flashcards.length} ${_isEnglish ? 'cards' : 'thẻ'}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Time
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 4),
              Text(
                _formatTime(createdAt),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Preview Flashcards
          if (flashcards.isNotEmpty) ...[const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEnglish ? 'Preview' : 'Xem trước',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...flashcards.take(2).map((card) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card['term'] ?? 'Term',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          card['meaning'] ?? 'Meaning',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )),
                  if (flashcards.length > 2) ...[const SizedBox(height: 4),
                    Text(
                      _isEnglish ? '+${flashcards.length - 2} more' : '+${flashcards.length - 2} cái khác',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _savedLessonIds.contains(lesson['id'].toString())
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: const Color(0xFF6B7280),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => _showAlreadySavedDialog(lesson),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _isEnglish ? 'Saved' : 'Đã lưu',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => _saveLessonToCustom(lesson),
                        child: Text(
                          _isEnglish ? 'Save' : 'Lưu',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => _viewLessonDetail(lesson),
                  child: Text(
                    _isEnglish ? 'View All' : 'Xem tất cả',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

