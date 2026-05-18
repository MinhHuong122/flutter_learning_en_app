import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/community_service.dart';

import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../models/community_model.dart';
import 'file_preview_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final CommunityPost post;

  const PostDetailScreen({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late CommunityPost _post;
  late TextEditingController _commentController;
  List<CommunityComment> _comments = [];
  bool _isLoadingComments = false;
  bool _isLiked = false;

  bool get _isEnglish => context.read<LanguageService>().isEnglish;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _commentController = TextEditingController();
    _refreshPost();
    _loadComments();
    _checkIfLiked();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _refreshPost(),
      _loadComments(),
      _checkIfLiked(),
    ]);
  }

  Future<void> _refreshPost() async {
    try {
      final communityService = context.read<CommunityService>();
      final freshPost = await communityService.getPostById(_post.id);
      if (!mounted) return;
      setState(() => _post = freshPost);
    } catch (_) {
      // Keep current post data if refresh fails.
    }
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final communityService = context.read<CommunityService>();
      final comments = await communityService.getCommentsForPost(_post.id);
      setState(() {
        _comments = comments;
        _post = _post.copyWith(comments: comments.length);
      });
    } catch (e) {
      _showErrorSnackbar(_isEnglish ? 'Failed to load comments: $e' : 'Lỗi tải bình luận: $e');
    } finally {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _checkIfLiked() async {
    try {
      final authService = context.read<AuthService>();
      final userId = authService.userId;
      if (userId != null) {
        final communityService = context.read<CommunityService>();
        final isLiked = await communityService.isPostLikedByUser(_post.id, userId);
        setState(() => _isLiked = isLiked);
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _toggleLike() async {
    try {
      final authService = context.read<AuthService>();
      final userId = authService.userId;
      if (userId == null) return;

      final communityService = context.read<CommunityService>();

      if (_isLiked) {
        await communityService.unlikePost(_post.id, userId);
        setState(() => _isLiked = false);
      } else {
        await communityService.likePost(_post.id, userId);
        setState(() => _isLiked = true);
      }

      await _refreshPost();
    } catch (e) {
      _showErrorSnackbar(_isEnglish ? 'Error: $e' : 'Lỗi: $e');
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) {
      _showErrorSnackbar(_isEnglish ? 'Please enter a comment' : 'Vui lòng nhập bình luận');
      return;
    }

    try {
      final authService = context.read<AuthService>();
      final userId = authService.userId;
      final userName = authService.userName;
      if (userId == null) return;

      final communityService = context.read<CommunityService>();

      await communityService.createComment(
        postId: _post.id,
        userId: userId,
        userName: userName ?? 'User',
        content: _commentController.text,
        userAvatar: null,
      );

      _commentController.clear();

      await _loadComments();
      await _refreshPost();
    } catch (e) {
      _showErrorSnackbar(_isEnglish ? 'Error: $e' : 'Lỗi: $e');
    }
  }

  Future<void> _sharePost() async {
    try {
      final authService = context.read<AuthService>();
      final userId = authService.userId;
      final userName = authService.userName;
      if (userId == null) return;

      final communityService = context.read<CommunityService>();

      await communityService.sharePost(
        originalPostId: _post.id,
        userId: userId,
        userName: userName ?? 'User',
        userAvatar: null,
      );

      setState(() => _post = _post.copyWith(shares: _post.shares + 1));
      _showSuccessSnackbar(_isEnglish ? 'Shared successfully!' : 'Chia sẻ thành công!');
    } catch (e) {
      _showErrorSnackbar(_isEnglish ? 'Error: $e' : 'Lỗi: $e');
    }
  }

  Future<void> _openFilePreview() async {
    if (_post.fileUrl == null) {
      _showErrorSnackbar(_isEnglish ? 'No file available to preview' : 'Không có file để xem trước');
      return;
    }

    try {
      final fileName = (_post.fileName == null || _post.fileName!.trim().isEmpty)
          ? (_isEnglish ? 'Attachment' : 'Tệp đính kèm')
          : _post.fileName!;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FilePreviewScreen(
            fileUrl: _post.fileUrl!,
            fileName: fileName,
            isEnglish: _isEnglish,
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackbar(_isEnglish ? 'File preview error: $e' : 'Lỗi xem trước file: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showPostActionMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primaryColor),
              title: Text(
                _isEnglish ? 'Edit Post' : 'Chỉnh sửa bài viết',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                _showEditPostDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(
                _isEnglish ? 'Delete Post' : 'Xóa bài viết',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeletePostDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPostDialog() {
    final controller = TextEditingController(text: _post.content);
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
                await context.read<CommunityService>().updatePost(
                  _post.id,
                  content: controller.text.trim(),
                );
                _refreshPost();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_isEnglish ? 'Post updated' : 'Đã cập nhật bài viết')),
                );
              } catch (e) {
                _showErrorSnackbar(e.toString());
              }
            },
            child: Text(_isEnglish ? 'Save' : 'Lưu'),
          ),
        ],
      ),
    );
  }

  void _showDeletePostDialog() {
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
                await context.read<CommunityService>().deletePost(_post.id);
                if (!mounted) return;
                Navigator.pop(context, true); // Exit post detail screen and signal refresh
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_isEnglish ? 'Post deleted' : 'Đã xóa bài viết')),
                );
              } catch (e) {
                _showErrorSnackbar(e.toString());
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(_isEnglish ? 'Delete' : 'Xóa'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEnglish ? 'Post Details' : 'Chi tiết bài viết',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Post Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshAll,
              color: AppColors.primaryColor,
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                  // Main Post
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User header
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryColor,
                                    AppColors.primaryLight,
                                  ],
                                ),
                              ),
                              child: (_post.userAvatar != null &&
                                      _post.userAvatar!.isNotEmpty)
                                  ? ClipOval(
                                      child: Image.network(
                                        _post.userAvatar!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            _post.userName.isNotEmpty
                                                ? _post.userName[0].toUpperCase()
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
                                        _post.userName.isNotEmpty
                                            ? _post.userName[0].toUpperCase()
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
                                    _post.userName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                  Text(
                                    _formatTime(_post.createdAt),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (context.read<AuthService>().userId != null && context.read<AuthService>().userId == _post.userId)
                              GestureDetector(
                                onTap: _showPostActionMenu,
                                child: const Icon(Icons.more_horiz, color: Color(0xFF9CA3AF), size: 24),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Content
                        Text(
                          _post.content,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF4B5563),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Image
                        if (_post.imageUrl != null)
                          GestureDetector(
                            onTap: () => _showImageFullScreen(_post.imageUrl!),
                            child: Container(
                              width: double.infinity,
                              height: 200,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: NetworkImage(_post.imageUrl!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),

                        // File
                        if (_post.fileUrl != null)
                          GestureDetector(
                            onTap: _openFilePreview,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: const Color(0xFFE0F4FF),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.download,
                                    color: AppColors.primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _post.fileName ?? 'File',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Stats
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStat('${_post.likes}', _isEnglish ? 'Likes' : 'Lượt thích'),
                              _buildStat('${_post.comments}', _isEnglish ? 'Comments' : 'Bình luận'),
                              _buildStat('${_post.shares}', _isEnglish ? 'Shares' : 'Chia sẻ'),
                            ],
                          ),
                        ),

                        // If this post is a share, render original post preview
                        if (_post.sharedPostContent != null)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
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
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [AppColors.primaryColor, AppColors.primaryLight],
                                        ),
                                      ),
                                      child: (_post.sharedPostUserAvatar != null && _post.sharedPostUserAvatar!.isNotEmpty)
                                          ? ClipOval(child: Image.network(_post.sharedPostUserAvatar!, fit: BoxFit.cover))
                                          : Center(
                                              child: Text(
                                                _post.sharedPostUserName != null && _post.sharedPostUserName!.isNotEmpty
                                                    ? _post.sharedPostUserName![0].toUpperCase()
                                                    : 'U',
                                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_post.sharedPostUserName ?? (_isEnglish ? 'Original' : 'Bản gốc'), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
                                          if (_post.sharedPostCreatedAt != null)
                                            Text(_formatTime(_post.sharedPostCreatedAt!), style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9CA3AF))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(_post.sharedPostContent ?? '', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF4B5563))),
                                const SizedBox(height: 8),
                                if (_post.sharedPostImageUrl != null)
                                  GestureDetector(
                                    onTap: () => _showImageFullScreen(_post.sharedPostImageUrl!),
                                    child: Container(
                                      width: double.infinity,
                                      height: 180,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        image: DecorationImage(image: NetworkImage(_post.sharedPostImageUrl!), fit: BoxFit.cover),
                                      ),
                                    ),
                                  ),
                                if (_post.sharedPostFileUrl != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                                    child: Row(children: [Icon(Icons.insert_drive_file, color: AppColors.primaryColor), const SizedBox(width: 8), Expanded(child: Text(_post.sharedPostFileName ?? 'File', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryColor)))]),
                                  ),
                              ],
                            ),
                          ),

                        // Actions
                        Container(
                          padding: const EdgeInsets.only(top: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  icon: _isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  label: _isEnglish ? 'Like' : 'Thích',
                                  onTap: _toggleLike,
                                  isActive: _isLiked,
                                ),
                              ),
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.chat_bubble_outline,
                                  label: _isEnglish ? 'Comment' : 'Bình luận',
                                  onTap: () {},
                                ),
                              ),
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.share_outlined,
                                  label: _isEnglish ? 'Share' : 'Chia sẻ',
                                  onTap: _sharePost,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Comments Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_isEnglish ? 'Comments' : 'Bình luận'} (${_comments.length})',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_isLoadingComments)
                          const CircularProgressIndicator()
                        else if (_comments.isEmpty)
                          Text(
                            _isEnglish ? 'No comments yet' : 'Chưa có bình luận nào',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF9CA3AF),
                            ),
                          )
                        else
                          Column(
                            children: _comments
                                .map((comment) =>
                                    _buildCommentCard(comment))
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),

          // Comment Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFE5E7EB),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: _isEnglish ? 'Write a comment...' : 'Viết bình luận...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF9CA3AF),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Color(0xFFE5E7EB),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Color(0xFFE5E7EB),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addComment,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryColor,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String count, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          label.contains('Like') || label.contains('thích')
              ? Icons.favorite_border
              : label.contains('Comment') || label.contains('luận')
                  ? Icons.chat_bubble_outline
                  : Icons.share_outlined,
          size: 16,
          color: const Color(0xFF9CA3AF),
        ),
        const SizedBox(width: 6),
        Text(
          count,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: isActive ? Colors.red : const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isActive ? Colors.red : const Color(0xFF9CA3AF),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(CommunityComment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF9FAFB),
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
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryLight,
                    ],
                  ),
                ),
                child: (comment.userAvatar != null && comment.userAvatar!.isNotEmpty)
                    ? ClipOval(
                        child: Image.network(
                          comment.userAvatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              comment.userName.isNotEmpty
                                  ? comment.userName[0].toUpperCase()
                                  : 'U',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          comment.userName.isNotEmpty
                              ? comment.userName[0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
                      comment.userName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      _formatTime(comment.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageFullScreen(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (dialogContext) => GestureDetector(
        onTap: () => Navigator.pop(dialogContext),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Image.network(imageUrl, fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ],
            ),
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
