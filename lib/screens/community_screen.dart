import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../widgets/custom_bottom_nav.dart';
import '../services/language_service.dart';
import '../services/community_service.dart';
import '../services/auth_service.dart';
import '../models/community_model.dart';
import 'home_screen.dart';
import 'process_screen.dart';
import 'chat_ai_screen.dart';
import 'account_screen.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import 'community_profile_screen.dart';

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
    const Color(0xFFE0F4FF),
    const Color(0xFFFFF3E0),
    const Color(0xFFF3E5F5),
    const Color(0xFFE8F5E9),
  ];

  late TextEditingController _searchController;
  List<CommunityPost> _posts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                  // Category Chips
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedCategory == index;
                        return Padding(
                          padding: EdgeInsets.only(right: index == categories.length - 1 ? 0 : 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedCategory = index);
                              _loadPosts();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: isSelected ? categoryColors[index] : categoryBgColors[index],
                              ),
                              child: Center(
                              child: Text(
                                categories[index],
                                  textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : (index == 0
                                          ? AppColors.primaryColor
                                          : (index == 1
                                              ? const Color(0xFFFF9800)
                                              : (index == 2
                                                  ? const Color(0xFF9C27B0)
                                                  : const Color(0xFF4CAF50)))),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Feed
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _posts.isEmpty
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
            Container(
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
}
