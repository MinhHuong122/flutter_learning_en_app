import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/community_model.dart';

class CommunityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  SupabaseClient get supabase => _supabase;

  Future<Map<String, int>> _countByPostId({
    required String table,
    required String postIdColumn,
    required List<String> postIds,
  }) async {
    if (postIds.isEmpty) return {};

    try {
      final rows = await _supabase
          .from(table)
          .select(postIdColumn)
          .inFilter(postIdColumn, postIds);

      final counts = <String, int>{};
      for (final row in rows as List) {
        final id = row[postIdColumn] as String?;
        if (id == null) continue;
        counts[id] = (counts[id] ?? 0) + 1;
      }
      return counts;
    } catch (_) {
      return {};
    }
  }

  Future<int> _countPostLikes(String postId) async {
    try {
      final rows = await _supabase
          .from('post_likes')
          .select('id')
          .eq('post_id', postId);
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _countPostComments(String postId) async {
    try {
      final rows = await _supabase
          .from('community_comments')
          .select('id')
          .eq('post_id', postId);
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _syncPostCounts(String postId) async {
    // Keep backward compatibility; counters are now computed from source tables.
    // Avoid updating community_posts directly from client because it often
    // requires broad UPDATE RLS permissions.
    return;
  }

  Future<int> _countPostShares(String postId) async {
    try {
      final rows = await _supabase
          .from('community_posts')
          .select('id')
          .eq('shared_post_id', postId);
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, String?>> _getCanonicalUserInfo(
    String userId, {
    String? fallbackName,
    String? fallbackAvatar,
  }) async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select('display_name, username, avatar_url')
          .eq('id', userId)
          .maybeSingle();

      final displayName = (profile?['display_name'] as String?)?.trim();
      final username = (profile?['username'] as String?)?.trim();
      final resolvedName =
          (displayName != null && displayName.isNotEmpty)
              ? displayName
              : (username != null && username.isNotEmpty)
                  ? username
                  : (fallbackName != null && fallbackName.isNotEmpty)
                      ? fallbackName
                      : 'User';

      return {
        'user_name': resolvedName,
        'user_avatar': (profile?['avatar_url'] as String?) ?? fallbackAvatar,
      };
    } catch (_) {
      return {
        'user_name':
            (fallbackName != null && fallbackName.isNotEmpty) ? fallbackName : 'User',
        'user_avatar': fallbackAvatar,
      };
    }
  }

  Future<Map<String, Map<String, String?>>> _getUserInfoMap(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};

    try {
      final rows = await _supabase
          .from('profiles')
          .select('id, display_name, username, avatar_url')
          .inFilter('id', userIds);

      final result = <String, Map<String, String?>>{};
      for (final row in rows as List) {
        result[row['id'] as String] = {
          'display_name': row['display_name'] as String?,
          'username': row['username'] as String?,
          'avatar_url': row['avatar_url'] as String?,
        };
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  // ==================== POST OPERATIONS ====================

  /// Tạo bài đăng mới
  Future<CommunityPost> createPost({
    required String userId,
    required String userName,
    required String content,
    String? userAvatar,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
    String? fileMimeType,
    List<String> categoryTags = const [],
  }) async {
    try {
      final now = DateTime.now();
      final userInfo = await _getCanonicalUserInfo(
        userId,
        fallbackName: userName,
        fallbackAvatar: userAvatar,
      );

      final response = await _supabase.from('community_posts').insert({
        'user_id': userId,
        'user_name': userInfo['user_name'],
        'user_avatar': userInfo['user_avatar'],
        'content': content,
        'image_url': imageUrl,
        'file_url': fileUrl,
        'file_name': fileName,
        'file_mime_type': fileMimeType,
        'category_tags': categoryTags,
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'created_at': now.toIso8601String(),
      }).select();

      // Get the ID returned by Supabase
      final postId = response[0]['id'] as String;

      return CommunityPost(
        id: postId,
        userId: userId,
        userName: userInfo['user_name'] ?? userName,
        userAvatar: userInfo['user_avatar'],
        content: content,
        imageUrl: imageUrl,
        fileUrl: fileUrl,
        fileName: fileName,
        fileMimeType: fileMimeType,
        categoryTags: categoryTags,
        likes: 0,
        comments: 0,
        shares: 0,
        createdAt: now,
      );
    } catch (e) {
      throw Exception('Lỗi tạo bài đăng: $e');
    }
  }

  /// Lấy tất cả bài đăng
  Future<List<CommunityPost>> getPosts({
    String? category,
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('community_posts').select();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('content', '%$searchQuery%');
      }

      var data = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1) as List;

      // Filter by category in Dart (since array filtering is complex in Supabase)
      if (category != null && category != 'All') {
        data = data.where((post) {
          final tags = List<String>.from(post['category_tags'] ?? []);
          return tags.contains(category);
        }).toList();
      }

      final userId = _supabase.auth.currentUser?.id ?? '';
      final postIds = data
          .map((post) => post['id'] as String?)
          .whereType<String>()
          .toList();
      final userIds = data
          .map((post) => post['user_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      final profileMap = await _getUserInfoMap(userIds);
      final likeCountMap = await _countByPostId(
        table: 'post_likes',
        postIdColumn: 'post_id',
        postIds: postIds,
      );
      final commentCountMap = await _countByPostId(
        table: 'community_comments',
        postIdColumn: 'post_id',
        postIds: postIds,
      );
      final shareCountMap = await _countByPostId(
        table: 'community_posts',
        postIdColumn: 'shared_post_id',
        postIds: postIds,
      );

      // Check like status for each post
      final posts = <CommunityPost>[];
      for (final post in data) {
        bool isLiked = false;
        final postId = post['id'] as String;
        if (userId.isNotEmpty) {
          isLiked = await isPostLikedByUser(postId, userId);
        }

        final postUserId = post['user_id'] as String?;
        final profile = postUserId != null ? profileMap[postUserId] : null;
        final displayName = (profile?['display_name']?.trim().isNotEmpty == true)
            ? profile!['display_name']
            : profile?['username'];

        posts.add(CommunityPost.fromJson({
          ...post,
          'likes': likeCountMap[postId] ?? 0,
          'comments': commentCountMap[postId] ?? 0,
          'shares': shareCountMap[postId] ?? 0,
          'user_name': displayName ?? post['user_name'],
          'user_avatar': profile?['avatar_url'] ?? post['user_avatar'],
          'is_liked_by_me': isLiked,
        }));
      }
      return posts;
    } catch (e) {
      throw Exception('Lỗi lấy bài đăng: $e');
    }
  }

  /// Lấy bài đăng theo ID
  Future<CommunityPost> getPostById(String postId) async {
    try {
      final data = await _supabase
          .from('community_posts')
          .select()
          .eq('id', postId)
          .single();

      final likes = await _countPostLikes(postId);
      final comments = await _countPostComments(postId);
      final shares = await _countPostShares(postId);

      final userInfo = await _getCanonicalUserInfo(
        data['user_id'] as String,
        fallbackName: data['user_name'] as String?,
        fallbackAvatar: data['user_avatar'] as String?,
      );

      return CommunityPost.fromJson({
        ...data,
        'likes': likes,
        'comments': comments,
        'shares': shares,
        'user_name': userInfo['user_name'],
        'user_avatar': userInfo['user_avatar'],
      });
    } catch (e) {
      throw Exception('Lỗi lấy bài đăng: $e');
    }
  }

  /// Cập nhật bài đăng
  Future<void> updatePost(
    String postId, {
    required String content,
    List<String>? categoryTags,
    String? imageUrl,
  }) async {
    try {
      await _supabase.from('community_posts').update({
        'content': content,
        if (categoryTags != null) 'category_tags': categoryTags,
        if (imageUrl != null) 'image_url': imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', postId);
    } catch (e) {
      throw Exception('Lỗi cập nhật bài đăng: $e');
    }
  }

  /// Xóa bài đăng
  Future<void> deletePost(String postId) async {
    try {
      await _supabase.from('community_posts').delete().eq('id', postId);
    } catch (e) {
      throw Exception('Lỗi xóa bài đăng: $e');
    }
  }

  // ==================== LIKE OPERATIONS ====================

  /// Like bài đăng
  Future<void> likePost(String postId, String userId) async {
    try {
      // Check if already liked
      final existing = await _supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId);

      if (existing.isNotEmpty) {
        return; // Already liked
      }

      await _supabase.from('post_likes').insert({
        'post_id': postId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      await _syncPostCounts(postId);
    } catch (e) {
      throw Exception('Lỗi like bài đăng: $e');
    }
  }

  /// Unlike bài đăng
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _supabase
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);

      await _syncPostCounts(postId);
    } catch (e) {
      throw Exception('Lỗi unlike bài đăng: $e');
    }
  }

  /// Kiểm tra bài đăng có được like hay không
  Future<bool> isPostLikedByUser(String postId, String userId) async {
    try {
      final data = await _supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId);

      return data.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ==================== COMMENT OPERATIONS ====================

  /// Tạo bình luận
  Future<CommunityComment> createComment({
    required String postId,
    required String userId,
    required String userName,
    required String content,
    String? userAvatar,
    String? parentCommentId, // For nested replies
  }) async {
    try {
      final now = DateTime.now();
      final userInfo = await _getCanonicalUserInfo(
        userId,
        fallbackName: userName,
        fallbackAvatar: userAvatar,
      );

      final response = await _supabase.from('community_comments').insert({
        'post_id': postId,
        'user_id': userId,
        'user_name': userInfo['user_name'],
        'user_avatar': userInfo['user_avatar'],
        'content': content,
        'parent_comment_id': parentCommentId,
        'likes': 0,
        'created_at': now.toIso8601String(),
      }).select();

      final commentId = response[0]['id'] as String;

      await _syncPostCounts(postId);

      return CommunityComment(
        id: commentId,
        postId: postId,
        userId: userId,
        userName: userInfo['user_name'] ?? userName,
        userAvatar: userInfo['user_avatar'],
        content: content,
        createdAt: now,
      );
    } catch (e) {
      throw Exception('Lỗi tạo bình luận: $e');
    }
  }

  /// Lấy bình luận cho bài đăng
  Future<List<CommunityComment>> getCommentsForPost(String postId) async {
    try {
      final data = await _supabase
          .from('community_comments')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: false);

      final userIds = (data as List)
          .map((comment) => comment['user_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      final profileMap = await _getUserInfoMap(userIds);

      return data
          .map((comment) {
            final commentUserId = comment['user_id'] as String?;
            final profile = commentUserId != null ? profileMap[commentUserId] : null;
            final displayName =
                (profile?['display_name']?.trim().isNotEmpty == true)
                    ? profile!['display_name']
                    : profile?['username'];
            return CommunityComment.fromJson({
              ...comment,
              'user_name': displayName ?? comment['user_name'],
              'user_avatar': profile?['avatar_url'] ?? comment['user_avatar'],
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Lỗi lấy bình luận: $e');
    }
  }

  /// Lấy replies của một bình luận
  Future<List<CommunityComment>> getRepliesForComment(String commentId) async {
    try {
      final data = await _supabase
          .from('community_comments')
          .select()
          .eq('parent_comment_id', commentId)
          .order('created_at', ascending: true);

      return (data as List)
          .map((comment) => CommunityComment.fromJson(comment))
          .toList();
    } catch (e) {
      throw Exception('Lỗi lấy replies: $e');
    }
  }

  /// Like bình luận
  Future<void> likeComment(String commentId, String userId) async {
    try {
      final existing = await _supabase
          .from('comment_likes')
          .select()
          .eq('comment_id', commentId)
          .eq('user_id', userId);

      if (existing.isNotEmpty) {
        return;
      }

      await _supabase.from('comment_likes').insert({
        'comment_id': commentId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Comment like counters are derived or can be updated server-side via triggers.
    } catch (e) {
      throw Exception('Lỗi like bình luận: $e');
    }
  }

  /// Unlike bình luận
  Future<void> unlikeComment(String commentId, String userId) async {
    try {
      await _supabase
          .from('comment_likes')
          .delete()
          .eq('comment_id', commentId)
          .eq('user_id', userId);

      // Comment like counters are derived or can be updated server-side via triggers.
    } catch (e) {
      throw Exception('Lỗi unlike bình luận: $e');
    }
  }

  /// Xóa bình luận
  Future<void> deleteComment(String commentId, String postId) async {
    try {
      await _supabase.from('community_comments').delete().eq('id', commentId);

      await _syncPostCounts(postId);
    } catch (e) {
      throw Exception('Lỗi xóa bình luận: $e');
    }
  }

  // ==================== SHARE OPERATIONS ====================

  /// Share bài đăng (tạo bài đăng mới với reference)
  Future<CommunityPost> sharePost({
    required String originalPostId,
    required String userId,
    required String userName,
    String? userAvatar,
    String? comment,
  }) async {
    try {
      final now = DateTime.now();
      final userInfo = await _getCanonicalUserInfo(
        userId,
        fallbackName: userName,
        fallbackAvatar: userAvatar,
      );

      // Create new post referencing the original
      final response = await _supabase.from('community_posts').insert({
        'user_id': userId,
        'user_name': userInfo['user_name'],
        'user_avatar': userInfo['user_avatar'],
        'content': comment ?? '[Chia sẻ bài viết]',
        'shared_post_id': originalPostId,
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'created_at': now.toIso8601String(),
      }).select();

      final postId = response[0]['id'] as String;

      return CommunityPost(
        id: postId,
        userId: userId,
        userName: userInfo['user_name'] ?? userName,
        userAvatar: userInfo['user_avatar'],
        content: comment ?? '[Chia sẻ bài viết]',
        createdAt: now,
      );
    } catch (e) {
      throw Exception('Lỗi chia sẻ bài đăng: $e');
    }
  }

  // ==================== USER PROFILE OPERATIONS ====================

  /// Lấy profile người dùng
  Future<CommunityUserProfile> getUserProfile(String userId) async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select('display_name, username, bio, avatar_url')
          .eq('id', userId)
          .maybeSingle();

      final posts = await _supabase
          .from('community_posts')
          .select('id')
          .eq('user_id', userId);
      final followers = await _supabase
          .from('user_follows')
          .select('id')
          .eq('following_id', userId);
      final following = await _supabase
          .from('user_follows')
          .select('id')
          .eq('follower_id', userId);

      bool isFollowedByMe = false;
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != null && currentUserId != userId) {
        final follow = await _supabase
            .from('user_follows')
            .select('id')
            .eq('follower_id', currentUserId)
            .eq('following_id', userId)
            .maybeSingle();
        isFollowedByMe = follow != null;
      }

      final displayName = (profile?['display_name'] as String?)?.trim();
      final username = (profile?['username'] as String?)?.trim();

      return CommunityUserProfile(
        userId: userId,
        userName: (displayName != null && displayName.isNotEmpty)
            ? displayName
            : (username != null && username.isNotEmpty)
                ? username
                : 'User',
        email: '',
        avatarUrl: profile?['avatar_url'] as String?,
        bio: profile?['bio'] as String?,
        followersCount: followers.length,
        followingCount: following.length,
        postsCount: posts.length,
        isFollowedByMe: isFollowedByMe,
        joinedDate: DateTime.now(),
      );
    } catch (e) {
      // Create default profile if not exists
      return CommunityUserProfile(
        userId: userId,
        userName: 'User',
        email: '',
        joinedDate: DateTime.now(),
      );
    }
  }

  /// Cập nhật profile người dùng
  Future<void> updateUserProfile({
    required String userId,
    String? userName,
    String? bio,
    String? avatarUrl,
    List<String>? interests,
  }) async {
    try {
      await _supabase.from('community_user_profiles').upsert({
        'user_id': userId,
        if (userName != null) 'user_name': userName,
        if (bio != null) 'bio': bio,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (interests != null) 'interests': interests,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Lỗi cập nhật profile: $e');
    }
  }

  /// Lấy bài đăng của người dùng
  Future<List<CommunityPost>> getUserPosts(String userId, {int limit = 20}) async {
    try {
      final data = await _supabase
          .from('community_posts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      final userInfo = await _getCanonicalUserInfo(userId);

      return (data as List)
          .map((post) => CommunityPost.fromJson({
                ...post,
                'user_name': userInfo['user_name'] ?? post['user_name'],
                'user_avatar': userInfo['user_avatar'] ?? post['user_avatar'],
              }))
          .toList();
    } catch (e) {
      throw Exception('Lỗi lấy bài đăng người dùng: $e');
    }
  }

  /// Lấy bài đăng được chia sẻ bởi người dùng
  Future<List<CommunityPost>> getUserSharedPosts(String userId,
      {int limit = 20}) async {
    try {
      final data = await _supabase
          .from('community_posts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      final userInfo = await _getCanonicalUserInfo(userId);

      return (data as List)
          .map((post) => CommunityPost.fromJson({
                ...post,
                'user_name': userInfo['user_name'] ?? post['user_name'],
                'user_avatar': userInfo['user_avatar'] ?? post['user_avatar'],
              }))
          .toList();
    } catch (e) {
      throw Exception('Lỗi lấy bài chia sẻ: $e');
    }
  }

  // ==================== UTILITY FUNCTIONS ====================

  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (DateTime.now().microsecond % 1000).toString();
  }

  /// Search posts
  Future<List<CommunityPost>> searchPosts(String query) async {
    try {
      final data = await _supabase
          .from('community_posts')
          .select()
          .ilike('content', '%$query%')
          .order('created_at', ascending: false)
          .limit(50);

      final userIds = (data as List)
          .map((post) => post['user_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      final profileMap = await _getUserInfoMap(userIds);

      return data
          .map((post) {
            final postUserId = post['user_id'] as String?;
            final profile = postUserId != null ? profileMap[postUserId] : null;
            final displayName = (profile?['display_name']?.trim().isNotEmpty == true)
                ? profile!['display_name']
                : profile?['username'];
            return CommunityPost.fromJson({
              ...post,
              'user_name': displayName ?? post['user_name'],
              'user_avatar': profile?['avatar_url'] ?? post['user_avatar'],
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Lỗi tìm kiếm: $e');
    }
  }

  /// Get trending posts
  Future<List<CommunityPost>> getTrendingPosts({int limit = 10}) async {
    try {
      final data = await _supabase
          .from('community_posts')
          .select()
          .gte('created_at',
              DateTime.now().subtract(Duration(days: 7)).toIso8601String())
          .order('likes', ascending: false)
          .limit(limit);

      final userIds = (data as List)
          .map((post) => post['user_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      final profileMap = await _getUserInfoMap(userIds);

      return data
          .map((post) {
            final postUserId = post['user_id'] as String?;
            final profile = postUserId != null ? profileMap[postUserId] : null;
            final displayName = (profile?['display_name']?.trim().isNotEmpty == true)
                ? profile!['display_name']
                : profile?['username'];
            return CommunityPost.fromJson({
              ...post,
              'user_name': displayName ?? post['user_name'],
              'user_avatar': profile?['avatar_url'] ?? post['user_avatar'],
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Lỗi lấy trending: $e');
    }
  }

  // ==================== SHARED LESSONS OPERATIONS ====================

  /// Lấy tất cả shared lessons
  Future<List<Map<String, dynamic>>> getSharedLessons() async {
    try {
      final data = await _supabase
          .from('shared_lessons')
          .select('*, shared_flashcards(*)')
          .order('created_at', ascending: false);

      return (data as List).map((lesson) {
        return {
          'id': lesson['id'] as String,
          'title': lesson['title'] as String,
          'description': lesson['description'] as String?,
          'flashcard_count': lesson['flashcard_count'] as int?,
          'user_id': lesson['user_id'] as String,
          'created_at': lesson['created_at'] as String?,
          'shared_flashcards': lesson['shared_flashcards'] as List? ?? [],
        };
      }).toList();
    } catch (e) {
      throw Exception('Lỗi lấy shared lessons: $e');
    }
  }

  /// Lấy shared lessons của một user
  Future<List<Map<String, dynamic>>> getUserSharedLessons(String userId) async {
    try {
      final data = await _supabase
          .from('shared_lessons')
          .select('*, shared_flashcards(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (data as List).map((lesson) {
        return {
          'id': lesson['id'] as String,
          'title': lesson['title'] as String,
          'description': lesson['description'] as String?,
          'flashcard_count': lesson['flashcard_count'] as int?,
          'user_id': lesson['user_id'] as String,
          'created_at': lesson['created_at'] as String?,
          'shared_flashcards': lesson['shared_flashcards'] as List? ?? [],
        };
      }).toList();
    } catch (e) {
      throw Exception('Lỗi lấy shared lessons của user: $e');
    }
  }

  /// Lấy thông tin shared lesson chi tiết
  Future<Map<String, dynamic>?> getSharedLessonDetail(String lessonId) async {
    try {
      final data = await _supabase
          .from('shared_lessons')
          .select('*, shared_flashcards(*)')
          .eq('id', lessonId)
          .maybeSingle();

      if (data == null) return null;

      return {
        'id': data['id'] as String,
        'title': data['title'] as String,
        'description': data['description'] as String?,
        'flashcard_count': data['flashcard_count'] as int?,
        'user_id': data['user_id'] as String,
        'created_at': data['created_at'] as String?,
        'shared_flashcards': data['shared_flashcards'] as List? ?? [],
      };
    } catch (e) {
      throw Exception('Lỗi lấy chi tiết shared lesson: $e');
    }
  }
}

