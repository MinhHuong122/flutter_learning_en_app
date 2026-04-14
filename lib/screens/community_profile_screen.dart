import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/constants.dart';
import '../services/community_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/file_history_service.dart';
import '../services/storage_quota_service.dart';
import '../models/community_model.dart';
import 'post_detail_screen.dart';
import 'messaging_screen.dart';
import 'storage_upgrade_screen.dart';


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
  List<Map<String, dynamic>> _userSharedLessons = [];
  bool _isLoading = true;
  int _selectedTab = 0; // 0: Posts, 1: Shared Lessons

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
      final userSharedLessons = await communityService.getUserSharedLessons(widget.userId);

      setState(() {
        _userProfile = userProfile;
        _userPosts = userPosts;
        _sharedPosts = sharedPosts;
        _userSharedLessons = userSharedLessons;
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackbar(_isEnglish ? 'Error: $e' : 'Lỗi: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshPage() async {
    await _loadUserData();
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

  /// Download file from community post with progress dialog
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

      // Check storage quota before downloading
      final quotaService = StorageQuotaService();
      
      // Estimate file size - we'll use a reasonable estimate (10MB average)
      const estimatedFileSizeBytes = 10 * 1024 * 1024; // 10MB estimate
      
      final canDownload = await quotaService.canDownloadFile(estimatedFileSizeBytes);
      if (!canDownload) {
        // Show storage full dialog
        if (mounted) {
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

      // Get downloads directory - use external storage + /Download
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

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!await file.exists()) {
        _showErrorSnackbar(_isEnglish ? 'Download failed' : 'Tải xuống thất bại');
        return;
      }

      final fileSize = await file.length();
      final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);

      String fileType = 'doc';
      if (post.fileName != null) {
        final ext = post.fileName!.split('.').last.toLowerCase();
        fileType = ext;
      }

      await FileHistoryService().addFileToHistory(
        fileName: post.fileName ?? 'Unknown File',
        fileSize: '$fileSizeMB MB',
        fileType: fileType,
        action: 'download',
        sourceScreen: 'community',
        filePath: filePath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEnglish
                  ? '✅ File downloaded ($fileSizeMB MB)'
                  : '✅ File đã tải ($fileSizeMB MB)',
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      String errorMsg = _isEnglish ? 'Download error' : 'Lỗi tải xuống';
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMsg = _isEnglish ? 'Connection timeout' : 'Hết thời gian kết nối';
      }
      _showErrorSnackbar(errorMsg);
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showErrorSnackbar(_isEnglish ? 'Error: $e' : 'Lỗi: $e');
    }
  }

  /// Generate unique file path by appending (1), (2), etc
  String _getUniqueFilePath(String dirPath, String fileName) {
    // Use path package for proper path joining
    final filePath = p.join(dirPath, fileName);
    final file = File(filePath);
    if (!file.existsSync()) {
      return filePath;
    }

    final baseName = p.basenameWithoutExtension(fileName);
    final extension = p.extension(fileName); // Includes the dot

    for (int i = 1; i <= 100; i++) {
      final newFileName = '$baseName ($i)$extension';
      final newFilePath = p.join(dirPath, newFileName);
      final newFile = File(newFilePath);
      if (!newFile.existsSync()) {
        return newFilePath;
      }
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return p.join(dirPath, '$baseName ($timestamp)$extension');
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
          icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 3, 3, 3)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEnglish ? 'Community' : 'Cộng đồng',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openMessage,
            icon: const Icon(Icons.chat_bubble_outline, color: Color.fromARGB(255, 0, 0, 0)),
          ),
        ],
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        color: AppColors.primaryColor,
        child: SingleChildScrollView(
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
                  _buildTabChip(_isEnglish ? 'Shared Lessons' : 'Bài học chia sẻ', 1),
                ],
              ),
              const SizedBox(height: 16),
              _selectedTab == 0 ? _buildPostsTab() : _buildSharedTab(),
            ],
          ),
        ),
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
    // Calculate total likes from all posts
    int totalLikes = 0;
    for (final post in _userPosts) {
      totalLikes += post.likes;
    }
    
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
          Expanded(child: _buildStatColumn('${_userSharedLessons.length}', _isEnglish ? 'Lessons' : 'Bài học')),
          Container(width: 1, height: 44, color: const Color(0xFFD6E3FF)),
          Expanded(child: _buildStatColumn('$totalLikes', _isEnglish ? 'Likes' : 'Lượt thích')),
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
    if (_userSharedLessons.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD6E3FF)),
        ),
        child: Text(
          _isEnglish ? 'No shared lessons yet' : 'Chưa chia sẻ bài học nào',
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
      itemCount: _userSharedLessons.length,
      itemBuilder: (context, index) {
        final lesson = _userSharedLessons[index];
        return _buildSharedLessonCard(lesson);
      },
    );
  }

  Widget _buildSharedLessonCard(Map<String, dynamic> lesson) {
    final flashcards = (lesson['shared_flashcards'] as List?) ?? [];
    final createdAt = lesson['created_at'] != null
        ? DateTime.parse(lesson['created_at'] as String)
        : DateTime.now();

    return GestureDetector(
      onTap: () => _showSharedLessonDetail(lesson),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD6E3FF)),
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
          ],
        ),
      ),
    );
  }

  void _showSharedLessonDetail(Map<String, dynamic> lesson) {
    final flashcards = (lesson['shared_flashcards'] as List?) ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Close button at top right
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Title
                    Text(
                      lesson['title'] as String? ?? 'Untitled',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    // Description
                    if (lesson['description'] != null && (lesson['description'] as String).isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        lesson['description'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Flashcards List
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
                            card['term'] ?? card['front'] ?? 'Term',
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
                            card['meaning'] ?? card['back'] ?? 'Meaning',
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

  Widget _buildPostPreview(CommunityPost post) {
    // If this profile belongs to the current user, they own all posts shown here
    final isMyPost = widget.isCurrentUser;

    return GestureDetector(
      onLongPress: isMyPost
          ? () => _showPostActionMenu(post)
          : null,
      child: Container(
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
            // Image section with category tag
            if (post.imageUrl != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 240,
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
                  // Category tag
                  Positioned(
                    top: 16,
                    left: 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAD8FD).withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _isEnglish ? 'Learning' : 'Học tập',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF3D0048),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            // Content section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Time
                  Row(
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
                      const SizedBox(width: 12),
                      Text(
                        _formatTime(post.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4A6085),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // File attachment (if any)
            if (post.fileUrl != null)
              GestureDetector(
                onTap: () => _recordFileDownload(post),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
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
              ),

            // Footer - Stats and Actions
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: const Color(0xFFE5E7EB).withValues(alpha: 0.5)),
                ),
              ),
              child: Row(
                children: [
                  // Like button with count
                  GestureDetector(
                    onTap: () {}, // Can be connected to like functionality
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 20,
                          color: const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.likes}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4A6085),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Comment button with count
                  GestureDetector(
                    onTap: () {}, // Can be connected to comments
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 20,
                          color: const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.comments}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4A6085),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Share button
                  Icon(
                    Icons.share_outlined,
                    size: 20,
                    color: const Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPostActionMenu(CommunityPost post) {
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
                _showEditPostDialog(post);
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
                _showDeletePostDialog(post);
              },
            ),
          ],
        ),
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
