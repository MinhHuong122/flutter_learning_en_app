/// Model cho một bài đăng trong cộng đồng
class CommunityPost {
  String id;
  String userId;
  String userName;
  String? userAvatar; // URL hoặc tên người dùng
  String content;
  String? imageUrl; // URL ảnh bài đăng
  String? fileUrl; // URL file (PDF, Doc, etc)
  String? fileName; // Tên file
  String? fileMimeType; // MIME type của file
  // If this post is a share of another post
  String? sharedPostId;
  String? sharedPostContent;
  String? sharedPostImageUrl;
  String? sharedPostFileUrl;
  String? sharedPostFileName;
  String? sharedPostUserId;
  String? sharedPostUserName;
  String? sharedPostUserAvatar;
  DateTime? sharedPostCreatedAt;
  List<String> categoryTags; // ['Discussion', 'Resources', 'Study Groups']
  int likes;
  int comments;
  int shares;
  bool isLikedByMe; // User có like bài này không
  DateTime createdAt;
  DateTime? updatedAt;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    this.fileMimeType,
    this.sharedPostId,
    this.sharedPostContent,
    this.sharedPostImageUrl,
    this.sharedPostFileUrl,
    this.sharedPostFileName,
    this.sharedPostUserId,
    this.sharedPostUserName,
    this.sharedPostUserAvatar,
    this.sharedPostCreatedAt,
    this.categoryTags = const [],
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.isLikedByMe = false,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'user_name': userName,
        'user_avatar': userAvatar,
        'content': content,
        'image_url': imageUrl,
        'file_url': fileUrl,
        'file_name': fileName,
        'file_mime_type': fileMimeType,
        'shared_post_id': sharedPostId,
        'shared_post_content': sharedPostContent,
        'shared_post_image_url': sharedPostImageUrl,
        'shared_post_file_url': sharedPostFileUrl,
        'shared_post_file_name': sharedPostFileName,
        'shared_post_user_id': sharedPostUserId,
        'shared_post_user_name': sharedPostUserName,
        'shared_post_user_avatar': sharedPostUserAvatar,
        'shared_post_created_at': sharedPostCreatedAt?.toIso8601String(),
        'category_tags': categoryTags,
        'likes': likes,
        'comments': comments,
        'shares': shares,
        'is_liked_by_me': isLikedByMe,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  // Create from JSON
  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        userName: json['user_name'] as String? ?? '',
        userAvatar: json['user_avatar'] as String?,
        content: json['content'] as String? ?? '',
        imageUrl: json['image_url'] as String?,
        fileUrl: json['file_url'] as String?,
        fileName: json['file_name'] as String?,
        fileMimeType: json['file_mime_type'] as String?,
        sharedPostId: json['shared_post_id'] as String?,
        sharedPostContent: json['shared_post_content'] as String?,
        sharedPostImageUrl: json['shared_post_image_url'] as String?,
        sharedPostFileUrl: json['shared_post_file_url'] as String?,
        sharedPostFileName: json['shared_post_file_name'] as String?,
        sharedPostUserId: json['shared_post_user_id'] as String?,
        sharedPostUserName: json['shared_post_user_name'] as String?,
        sharedPostUserAvatar: json['shared_post_user_avatar'] as String?,
        sharedPostCreatedAt: json['shared_post_created_at'] != null
          ? DateTime.parse(json['shared_post_created_at'] as String)
          : null,
        categoryTags: List<String>.from(json['category_tags'] as List<dynamic>? ?? []),
        likes: (json['likes'] as num?)?.toInt() ?? 0,
        comments: (json['comments'] as num?)?.toInt() ?? 0,
        shares: (json['shares'] as num?)?.toInt() ?? 0,
        isLikedByMe: json['is_liked_by_me'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      );

  // Copy with method
  CommunityPost copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
    String? fileMimeType,
    String? sharedPostId,
    String? sharedPostContent,
    String? sharedPostImageUrl,
    String? sharedPostFileUrl,
    String? sharedPostFileName,
    String? sharedPostUserId,
    String? sharedPostUserName,
    String? sharedPostUserAvatar,
    DateTime? sharedPostCreatedAt,
    List<String>? categoryTags,
    int? likes,
    int? comments,
    int? shares,
    bool? isLikedByMe,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      CommunityPost(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        userAvatar: userAvatar ?? this.userAvatar,
        content: content ?? this.content,
        imageUrl: imageUrl ?? this.imageUrl,
        fileUrl: fileUrl ?? this.fileUrl,
        fileName: fileName ?? this.fileName,
        fileMimeType: fileMimeType ?? this.fileMimeType,
        sharedPostId: sharedPostId ?? this.sharedPostId,
        sharedPostContent: sharedPostContent ?? this.sharedPostContent,
        sharedPostImageUrl: sharedPostImageUrl ?? this.sharedPostImageUrl,
        sharedPostFileUrl: sharedPostFileUrl ?? this.sharedPostFileUrl,
        sharedPostFileName: sharedPostFileName ?? this.sharedPostFileName,
        sharedPostUserId: sharedPostUserId ?? this.sharedPostUserId,
        sharedPostUserName: sharedPostUserName ?? this.sharedPostUserName,
        sharedPostUserAvatar: sharedPostUserAvatar ?? this.sharedPostUserAvatar,
        sharedPostCreatedAt: sharedPostCreatedAt ?? this.sharedPostCreatedAt,
        categoryTags: categoryTags ?? this.categoryTags,
        likes: likes ?? this.likes,
        comments: comments ?? this.comments,
        shares: shares ?? this.shares,
        isLikedByMe: isLikedByMe ?? this.isLikedByMe,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// Model cho bình luận
class CommunityComment {
  String id;
  String postId;
  String userId;
  String userName;
  String? userAvatar;
  String content;
  int likes;
  bool isLikedByMe;
  DateTime createdAt;
  List<CommunityComment>? replies; // Nested replies

  CommunityComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    this.likes = 0,
    this.isLikedByMe = false,
    required this.createdAt,
    this.replies,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'post_id': postId,
        'user_id': userId,
        'user_name': userName,
        'user_avatar': userAvatar,
        'content': content,
        'likes': likes,
        'is_liked_by_me': isLikedByMe,
        'created_at': createdAt.toIso8601String(),
        'replies': replies?.map((r) => r.toJson()).toList(),
      };

  factory CommunityComment.fromJson(Map<String, dynamic> json) => CommunityComment(
        id: json['id'] as String? ?? '',
        postId: json['post_id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        userName: json['user_name'] as String? ?? '',
        userAvatar: json['user_avatar'] as String?,
        content: json['content'] as String? ?? '',
        likes: (json['likes'] as num?)?.toInt() ?? 0,
        isLikedByMe: json['is_liked_by_me'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
        replies: json['replies'] != null
            ? (json['replies'] as List<dynamic>).map((r) => CommunityComment.fromJson(r as Map<String, dynamic>)).toList()
            : null,
      );

  CommunityComment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    int? likes,
    bool? isLikedByMe,
    DateTime? createdAt,
    List<CommunityComment>? replies,
  }) =>
      CommunityComment(
        id: id ?? this.id,
        postId: postId ?? this.postId,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        userAvatar: userAvatar ?? this.userAvatar,
        content: content ?? this.content,
        likes: likes ?? this.likes,
        isLikedByMe: isLikedByMe ?? this.isLikedByMe,
        createdAt: createdAt ?? this.createdAt,
        replies: replies ?? this.replies,
      );
}

/// Model cho profile người dùng
class CommunityUserProfile {
  String userId;
  String userName;
  String email;
  String? avatarUrl;
  String? bio;
  int followersCount;
  int followingCount;
  int postsCount;
  bool isFollowedByMe;
  DateTime joinedDate;
  List<String> interests;

  CommunityUserProfile({
    required this.userId,
    required this.userName,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.isFollowedByMe = false,
    required this.joinedDate,
    this.interests = const [],
  });

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'user_name': userName,
        'email': email,
        'avatar_url': avatarUrl,
        'bio': bio,
        'followers_count': followersCount,
        'following_count': followingCount,
        'posts_count': postsCount,
        'is_followed_by_me': isFollowedByMe,
        'joined_date': joinedDate.toIso8601String(),
        'interests': interests,
      };

  factory CommunityUserProfile.fromJson(Map<String, dynamic> json) => CommunityUserProfile(
        userId: json['user_id'] as String? ?? '',
        userName: json['user_name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        bio: json['bio'] as String?,
        followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
        followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
        postsCount: (json['posts_count'] as num?)?.toInt() ?? 0,
        isFollowedByMe: json['is_followed_by_me'] as bool? ?? false,
        joinedDate: DateTime.parse(json['joined_date'] as String? ?? DateTime.now().toIso8601String()),
        interests: List<String>.from(json['interests'] as List<dynamic>? ?? []),
      );

  CommunityUserProfile copyWith({
    String? userId,
    String? userName,
    String? email,
    String? avatarUrl,
    String? bio,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    bool? isFollowedByMe,
    DateTime? joinedDate,
    List<String>? interests,
  }) =>
      CommunityUserProfile(
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bio: bio ?? this.bio,
        followersCount: followersCount ?? this.followersCount,
        followingCount: followingCount ?? this.followingCount,
        postsCount: postsCount ?? this.postsCount,
        isFollowedByMe: isFollowedByMe ?? this.isFollowedByMe,
        joinedDate: joinedDate ?? this.joinedDate,
        interests: interests ?? this.interests,
      );
}

/// Enum cho loại tương tác
enum PostInteraction {
  like,
  share,
  save,
}

/// Model cho tin nhắn trực tiếp
class Message {
  String id;
  String senderId;
  String senderName;
  String? senderAvatar;
  String receiverId;
  String content;
  String? fileUrl; // URL file if message contains file
  String? fileName; // File name if message contains file
  DateTime sentAt;
  bool isRead;
  String? replyToMessageId; // For reply to specific message
  String? replyToContent; // Content of message being replied to

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.receiverId,
    required this.content,
    this.fileUrl,
    this.fileName,
    required this.sentAt,
    this.isRead = false,
    this.replyToMessageId,
    this.replyToContent,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_id': senderId,
        'sender_name': senderName,
        'sender_avatar': senderAvatar,
        'receiver_id': receiverId,
        'content': content,
        'file_url': fileUrl,
        'file_name': fileName,
        'sent_at': sentAt.toIso8601String(),
        'is_read': isRead,
        'reply_to_message_id': replyToMessageId,
        'reply_to_content': replyToContent,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String? ?? '',
        senderId: json['sender_id'] as String? ?? '',
        senderName: json['sender_name'] as String? ?? '',
        senderAvatar: json['sender_avatar'] as String?,
        receiverId: json['receiver_id'] as String? ?? '',
        content: json['content'] as String? ?? '',
        fileUrl: json['file_url'] as String?,
        fileName: json['file_name'] as String?,
        sentAt: DateTime.parse(json['sent_at'] as String? ?? DateTime.now().toIso8601String()),
        isRead: json['is_read'] as bool? ?? false,
        replyToMessageId: json['reply_to_message_id'] as String?,
        replyToContent: json['reply_to_content'] as String?,
      );

  Message copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? receiverId,
    String? content,
    String? fileUrl,
    String? fileName,
    DateTime? sentAt,
    bool? isRead,
    String? replyToMessageId,
    String? replyToContent,
  }) =>
      Message(
        id: id ?? this.id,
        senderId: senderId ?? this.senderId,
        senderName: senderName ?? this.senderName,
        senderAvatar: senderAvatar ?? this.senderAvatar,
        receiverId: receiverId ?? this.receiverId,
        content: content ?? this.content,
        fileUrl: fileUrl ?? this.fileUrl,
        fileName: fileName ?? this.fileName,
        sentAt: sentAt ?? this.sentAt,
        isRead: isRead ?? this.isRead,
        replyToMessageId: replyToMessageId ?? this.replyToMessageId,
        replyToContent: replyToContent ?? this.replyToContent,
      );
}

/// Model cho cuộc trò chuyện (conversation)
class Conversation {
  String id;
  String userId; // ID người dùng hiện tại
  String participantId;
  String participantName;
  String? participantAvatar;
  String lastMessage;
  DateTime lastMessageTime;
  int unreadCount;
  bool isOnline; // Real-time status
  DateTime? lastSeenAt;

  Conversation({
    required this.id,
    required this.userId,
    required this.participantId,
    required this.participantName,
    this.participantAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.lastSeenAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'participant_id': participantId,
        'participant_name': participantName,
        'participant_avatar': participantAvatar,
        'last_message': lastMessage,
        'last_message_time': lastMessageTime.toIso8601String(),
        'unread_count': unreadCount,
        'is_online': isOnline,
        'last_seen_at': lastSeenAt?.toIso8601String(),
      };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        participantId: json['participant_id'] as String? ?? '',
        participantName: json['participant_name'] as String? ?? '',
        participantAvatar: json['participant_avatar'] as String?,
        lastMessage: json['last_message'] as String? ?? '',
        lastMessageTime: DateTime.parse(json['last_message_time'] as String? ?? DateTime.now().toIso8601String()),
        unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
        isOnline: json['is_online'] as bool? ?? false,
        lastSeenAt: json['last_seen_at'] != null ? DateTime.parse(json['last_seen_at'] as String) : null,
      );

  Conversation copyWith({
    String? id,
    String? userId,
    String? participantId,
    String? participantName,
    String? participantAvatar,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isOnline,
    DateTime? lastSeenAt,
  }) =>
      Conversation(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        participantId: participantId ?? this.participantId,
        participantName: participantName ?? this.participantName,
        participantAvatar: participantAvatar ?? this.participantAvatar,
        lastMessage: lastMessage ?? this.lastMessage,
        lastMessageTime: lastMessageTime ?? this.lastMessageTime,
        unreadCount: unreadCount ?? this.unreadCount,
        isOnline: isOnline ?? this.isOnline,
        lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      );
}
