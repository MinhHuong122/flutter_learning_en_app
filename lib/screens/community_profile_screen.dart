import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/community_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../models/community_model.dart';
import 'post_detail_screen.dart';
import 'messaging_screen.dart';
import 'create_post_screen.dart';

class CommunityProfileScreen extends StatefulWidget {
  final String userId;
  final bool isCurrentUser;

  const CommunityProfileScreen({
    Key? key,
    required this.userId,
    required this.isCurrentUser,
  }) : super(key: key);

  @override
  State<CommunityProfileScreen> createState() => _CommunityProfileScreenState();
}

class _CommunityProfileScreenState extends State<CommunityProfileScreen> {
  late CommunityUserProfile _userProfile;
  List<CommunityPost> _userPosts = [];
  List<CommunityPost> _sharedPosts = [];
  bool _isLoading = true;
  int _selectedTab = 0; // 0: Posts, 1: Shared

  bool get _isEnglish => context.read<LanguageService>().isEnglish;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final communityService = context.read<CommunityService>();

      final userProfile = await communityService.getUserProfile(widget.userId);
      final userPosts = await communityService.getUserPosts(widget.userId);
      final sharedPosts = await communityService.getUserSharedPosts(widget.userId);

      setState(() {
        _userProfile = userProfile;
        _userPosts = userPosts;
        _sharedPosts = sharedPosts;
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackbar(_isEnglish ? 'Error: $e' : 'Lỗi: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openMessage() {
    final currentUserId = context.read<AuthService>().userId;
    final isOwnProfile = currentUserId != null && currentUserId == widget.userId;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isOwnProfile
            ? const MessagingScreen()
            : MessagingScreen(
                recipientId: widget.userId,
                recipientName: _userProfile.userName,
                recipientAvatar: _userProfile.avatarUrl,
              ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showEditPostDialog(CommunityPost post) {
    final controller = TextEditingController(text: post.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEnglish ? 'Edit Post' : 'Chỉnh sửa bài viết'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_isEnglish ? 'Cancel' : 'Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (controller.text.trim().isEmpty) return;
              try {
                setState(() => _isLoading = true);
                await context.read<CommunityService>().updatePost(
                  post.id,
                  content: controller.text.trim(),
                );
                _loadUserData();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_isEnglish ? 'Post updated' : 'Đã cập nhật bài viết')),
                );
              } catch (e) {
                _showErrorSnackbar(e.toString());
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: Text(_isEnglish ? 'Save' : 'Lưu'),
          ),
        ],
      ),
    );
  }

  void _showDeletePostDialog(CommunityPost post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEnglish ? 'Delete Post' : 'Xóa bài viết'),
        content: Text(_isEnglish ? 'Are you sure you want to delete this post?' : 'Bạn có chắc chắn muốn xóa bài viết này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_isEnglish ? 'Cancel' : 'Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                setState(() => _isLoading = true);
                await context.read<CommunityService>().deletePost(post.id);
                _loadUserData();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_isEnglish ? 'Post deleted' : 'Đã xóa bài viết')),
                );
              } catch (e) {
                _showErrorSnackbar(e.toString());
                if (mounted) setState(() => _isLoading = false);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(_isEnglish ? 'Delete' : 'Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(elevation: 0, backgroundColor: const Color(0xFFF9F9FF)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF9F9FF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEnglish ? 'Community' : 'Cộng đồng',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryColor,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openMessage,
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryColor),
          ),
        ],
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        color: AppColors.primaryColor,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 20),
              _buildStatsCard(),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildTabChip(_isEnglish ? 'Posts' : 'Bài viết', 0),
                  const SizedBox(width: 12),
                  _buildTabChip(_isEnglish ? 'Shared' : 'Chia sẻ', 1),
                ],
              ),
              const SizedBox(height: 16),
              _selectedTab == 0 ? _buildPostsTab() : _buildSharedTab(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
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
                heightFactor: 0.85,
                child: CreatePostScreen(
                  onPostCreated: () {
                    Navigator.pop(context);
                    _loadUserData();
                  },
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 132,
          height: 132,
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF74B8FF), Color(0xFFFFDDB9)],
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: ClipOval(
              child: (_userProfile.avatarUrl != null && _userProfile.avatarUrl!.isNotEmpty)
                  ? Image.network(
                      _userProfile.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildAvatarFallback(),
                    )
                  : _buildAvatarFallback(),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _userProfile.userName,
          style: GoogleFonts.manrope(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1C3355),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          (_userProfile.bio != null && _userProfile.bio!.isNotEmpty)
              ? _userProfile.bio!
              : (_isEnglish ? 'Learning every day' : 'Mỗi ngày học một chút'),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: const Color(0xFF4A6085),
          ),
          textAlign: TextAlign.center,
        ),
        if (!widget.isCurrentUser) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: 170,
            child: ElevatedButton.icon(
              onPressed: _openMessage,
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: Text(_isEnglish ? 'Message' : 'Tin nhắn'),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatColumn('${_userProfile.postsCount}', _isEnglish ? 'Posts' : 'Bài viết')),
          Container(width: 1, height: 44, color: const Color(0xFFD6E3FF)),
          Expanded(child: _buildStatColumn('${_userProfile.followersCount}', _isEnglish ? 'Followers' : 'Người theo dõi')),
          Container(width: 1, height: 44, color: const Color(0xFFD6E3FF)),
          Expanded(child: _buildStatColumn('${_userProfile.followingCount}', _isEnglish ? 'Following' : 'Đang theo dõi')),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, int index) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE5F2FF) : const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isActive ? const Color(0xFF74B8FF) : const Color(0xFFD6E3FF),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
              color: isActive ? const Color(0xFF0062A3) : const Color(0xFF4A6085),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFFE8EEFF),
      child: Center(
        child: Text(
          _userProfile.userName.isNotEmpty ? _userProfile.userName[0].toUpperCase() : 'U',
          style: GoogleFonts.manrope(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0062A3),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1C3355),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A6085),
          ),
        ),
      ],
    );
  }

  Widget _buildPostsTab() {
    if (_userPosts.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD6E3FF)),
        ),
        child: Column(
          children: [
            const Icon(Icons.auto_awesome, size: 42, color: Color(0xFF9DB3DD)),
            const SizedBox(height: 12),
            Text(
              _isEnglish ? 'No posts yet' : 'Chưa có bài viết nào',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1C3355),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isEnglish
                  ? 'Follow to see new learning milestones from this profile.'
                  : 'Theo dõi để xem các cột mốc học tập mới từ hồ sơ này.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF4A6085)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
          ),
          child: _buildPostPreview(post),
        );
      },
    );
  }

  Widget _buildSharedTab() {
    if (_sharedPosts.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD6E3FF)),
        ),
        child: Text(
          _isEnglish ? 'No shared posts yet' : 'Chưa chia sẻ bài viết nào',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A6085),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _sharedPosts.length,
      itemBuilder: (context, index) {
        final post = _sharedPosts[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
          ),
          child: _buildPostPreview(post),
        );
      },
    );
  }

  Widget _buildPostPreview(CommunityPost post) {
    // If this profile belongs to the current user, they own all posts shown here
    final isMyPost = widget.isCurrentUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6E3FF)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C3355).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 220,
                child: Image.network(
                  post.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFE8EEFF),
                    child: const Center(
                      child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF9DB3DD), size: 36),
                    ),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    post.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C3355),
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isMyPost)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz, color: Color(0xFF9CA3AF), size: 24),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onSelected: (value) {
                            if (value == 'edit') {
                              _showEditPostDialog(post);
                            } else if (value == 'delete') {
                              _showDeletePostDialog(post);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit, size: 18),
                                  const SizedBox(width: 8),
                                  Text(_isEnglish ? 'Edit' : 'Chỉnh sửa'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete, color: Colors.red, size: 18),
                                  const SizedBox(width: 8),
                                  Text(_isEnglish ? 'Delete' : 'Xóa', style: const TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    Text(
                      _formatTime(post.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4A6085),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (post.fileUrl != null)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFE0F4FF),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.insert_drive_file,
                    size: 16,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      post.fileName ?? (_isEnglish ? 'Attached file' : 'Tệp đính kèm'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                const Icon(Icons.favorite_border, size: 16, color: Color(0xFF667BA2)),
                const SizedBox(width: 6),
                Text(
                  '${post.likes}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4A6085),
                  ),
                ),
                const SizedBox(width: 18),
                const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF667BA2)),
                const SizedBox(width: 6),
                Text(
                  '${post.comments}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4A6085),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.share_outlined, size: 18, color: Color(0xFF667BA2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return _isEnglish ? 'Just now' : 'Vừa xong';
    }
    if (difference.inMinutes < 60) {
      return _isEnglish
          ? '${difference.inMinutes} minutes ago'
          : '${difference.inMinutes} phút trước';
    }
    if (difference.inHours < 24) {
      return _isEnglish
          ? '${difference.inHours} hours ago'
          : '${difference.inHours} giờ trước';
    }
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
