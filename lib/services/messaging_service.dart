import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/community_model.dart';
import '../services/notification_center_service.dart';

class MessagingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? activeChatUserId;
  bool isViewingInbox = false;
  StreamSubscription<Message>? _globalIncomingSubscription;

  void initializeGlobalMessageListener(String userId) {
    if (_globalIncomingSubscription != null) return;
    _globalIncomingSubscription = watchIncomingMessages(userId).listen((message) async {
      if (activeChatUserId != null && activeChatUserId == message.senderId) {
        return; // Mute notifications for active chat
      }
      await NotificationCenterService().addMessageNotification(
        senderName: message.senderName,
        preview: message.content,
      );
    });
  }

  void stopGlobalMessageListener() {
    _globalIncomingSubscription?.cancel();
    _globalIncomingSubscription = null;
  }

  // ==================== MESSAGE OPERATIONS ====================

  /// Gửi tin nhắn
  Future<Message> sendMessage({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String content,
    String? senderAvatar,
    String? fileUrl,
    String? fileName,
    String? replyToMessageId,
    String? replyToContent,
  }) async {
    try {
      final now = DateTime.now();
      final authenticatedUserId = _supabase.auth.currentUser?.id;

      if (authenticatedUserId == null || authenticatedUserId.isEmpty) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      // Always trust Supabase auth identity for RLS checks.
      final effectiveSenderId = authenticatedUserId;

      final inserted = await _supabase.from('messages').insert({
        'sender_id': effectiveSenderId,
        'sender_name': senderName,
        'sender_avatar': senderAvatar,
        'receiver_id': receiverId,
        'content': content,
        'file_url': fileUrl,
        'file_name': fileName,
        'sent_at': now.toIso8601String(),
        'is_read': false,
        'reply_to_message_id': replyToMessageId,
        'reply_to_content': replyToContent,
      }).select().single();

      // Update conversation
      await _updateOrCreateConversation(effectiveSenderId, receiverId, content, now);

      return Message.fromJson(inserted as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Lỗi gửi tin nhắn: $e');
    }
  }

  /// Lấy tin nhắn giữa hai người dùng
  Future<List<Message>> getMessages(String userId, String otherUserId) async {
    try {
      final data = await _supabase.from('messages').select().or(
          'and(sender_id.eq.$userId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$userId)')
          .order('sent_at', ascending: true)
          .limit(100);

      return (data as List)
          .map((message) => Message.fromJson(message))
          .toList();
    } catch (e) {
      throw Exception('Lỗi lấy tin nhắn: $e');
    }
  }

  /// Lấy tin nhắn với phân trang
  Future<List<Message>> getMessagesPaginated(
    String userId,
    String otherUserId, {
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final data = await _supabase
          .from('messages')
          .select()
          .or(
              'and(sender_id.eq.$userId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$userId)')
          .order('sent_at', ascending: false)
          .range(offset, offset + limit - 1);

      final messages = (data as List)
          .map((message) => Message.fromJson(message))
          .toList();

      // Reverse to get chronological order
      return messages.reversed.toList();
    } catch (e) {
      throw Exception('Lỗi lấy tin nhắn: $e');
    }
  }

  /// Đánh dấu tin nhắn là đã đọc
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _supabase.from('messages').update({
        'is_read': true,
      }).eq('id', messageId);
    } catch (e) {
      throw Exception('Lỗi cập nhật tin nhắn: $e');
    }
  }

  /// Đánh dấu tất cả tin nhắn từ người dùng là đã đọc
  Future<void> markAllMessagesAsRead(String senderId, String receiverId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('sender_id', senderId)
          .eq('receiver_id', receiverId);

      // Reset unread count in conversation list for the receiver side.
      await _supabase
          .from('conversations')
          .update({'unread_count': 0})
          .eq('user_id', receiverId)
          .eq('participant_id', senderId);
    } catch (e) {
      throw Exception('Lỗi cập nhật tin nhắn: $e');
    }
  }

  /// Realtime stream cho tin nhắn giữa hai người dùng.
  Stream<List<Message>> watchMessages(String userId, String otherUserId) {
    final controller = StreamController<List<Message>>();
    final channelName =
      'messages_chat_${userId}_${otherUserId}_${DateTime.now().millisecondsSinceEpoch}';

    Future<void> emitMessages() async {
      try {
        final messages = await getMessages(userId, otherUserId);
        if (!controller.isClosed) {
          controller.add(messages);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    final channel = _supabase.channel(channelName)
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'messages',
        callback: (payload) {
          final row = payload.newRecord.isNotEmpty
              ? payload.newRecord
              : payload.oldRecord;
          final sender = row['sender_id']?.toString();
          final receiver = row['receiver_id']?.toString();

          final isThisConversation =
              (sender == userId && receiver == otherUserId) ||
              (sender == otherUserId && receiver == userId);

          if (isThisConversation) {
            unawaited(emitMessages());
          }
        },
      )
      ..subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          unawaited(emitMessages());
        }
        if (status == RealtimeSubscribeStatus.channelError &&
            error != null &&
            !controller.isClosed) {
          controller.addError(error);
        }
      });

    controller.onCancel = () async {
      await _supabase.removeChannel(channel);
    };

    unawaited(emitMessages());
    return controller.stream;
  }

  /// Realtime stream cho danh sách conversations.
  Stream<List<Conversation>> watchConversations(String userId) {
    final controller = StreamController<List<Conversation>>();
    final channelName =
      'conversations_${userId}_${DateTime.now().millisecondsSinceEpoch}';

    Future<void> emitConversations() async {
      try {
        final items = await getConversations(userId);
        if (!controller.isClosed) {
          controller.add(items);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    final channel = _supabase.channel(channelName)
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'conversations',
        callback: (payload) {
          final row = payload.newRecord.isNotEmpty
              ? payload.newRecord
              : payload.oldRecord;
          final rowUserId = row['user_id']?.toString();
          if (rowUserId == userId) {
            unawaited(emitConversations());
          }
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'messages',
        callback: (payload) {
          final row = payload.newRecord.isNotEmpty
              ? payload.newRecord
              : payload.oldRecord;
          final sender = row['sender_id']?.toString();
          final receiver = row['receiver_id']?.toString();
          if (sender == userId || receiver == userId) {
            unawaited(emitConversations());
          }
        },
      )
      ..subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          unawaited(emitConversations());
        }
        if (status == RealtimeSubscribeStatus.channelError &&
            error != null &&
            !controller.isClosed) {
          controller.addError(error);
        }
      });

    controller.onCancel = () async {
      await _supabase.removeChannel(channel);
    };

    unawaited(emitConversations());
    return controller.stream;
  }

  /// Realtime stream cho tin nhắn nhận vào của một user.
  Stream<Message> watchIncomingMessages(String userId) {
    final controller = StreamController<Message>();
    final channelName =
      'incoming_messages_${userId}_${DateTime.now().millisecondsSinceEpoch}';

    final channel = _supabase.channel(channelName)
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        callback: (payload) {
          final row = payload.newRecord;
          final receiver = row['receiver_id']?.toString();
          if (receiver == userId && !controller.isClosed) {
            controller.add(Message.fromJson(row));
          }
        },
      )
      ..subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.channelError &&
            error != null &&
            !controller.isClosed) {
          controller.addError(error);
        }
      });

    controller.onCancel = () async {
      await _supabase.removeChannel(channel);
    };

    return controller.stream;
  }

  /// Xóa tin nhắn
  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase.from('messages').delete().eq('id', messageId);
    } catch (e) {
      throw Exception('Lỗi xóa tin nhắn: $e');
    }
  }

  /// Sửa tin nhắn
  Future<void> editMessage(String messageId, String newContent) async {
    try {
      await _supabase.from('messages').update({
        'content': newContent,
        'edited_at': DateTime.now().toIso8601String(),
      }).eq('id', messageId);
    } catch (e) {
      throw Exception('Lỗi sửa tin nhắn: $e');
    }
  }

  // ==================== CONVERSATION OPERATIONS ====================

  /// Lấy danh sách cuộc trò chuyện cho người dùng
  Future<List<Conversation>> getConversations(String userId) async {
    try {
      final data = await _supabase
          .from('conversations')
          .select()
          .eq('user_id', userId)
          .order('last_message_time', ascending: false);

      final direct = (data as List)
          .map((conv) => Conversation.fromJson(conv))
          .toList();

      if (direct.isNotEmpty) {
        return direct;
      }

      return await _buildConversationsFromMessages(userId);
    } catch (e) {
      try {
        return await _buildConversationsFromMessages(userId);
      } catch (_) {
        throw Exception('Lỗi lấy cuộc trò chuyện: $e');
      }
    }
  }

  /// Lấy một cuộc trò chuyện cụ thể
  Future<Conversation?> getConversation(String userId, String participantId) async {
    try {
      final data = await _supabase
          .from('conversations')
          .select()
          .eq('user_id', userId)
          .eq('participant_id', participantId);

      if (data.isEmpty) {
        return null;
      }

      return Conversation.fromJson(data.first);
    } catch (e) {
      return null;
    }
  }

  /// Lấy số lượng tin nhắn chưa đọc cho người dùng
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      final data =
          await _supabase.from('messages').select().eq('receiver_id', userId).eq('is_read', false);

      return data.length;
    } catch (e) {
      return 0;
    }
  }

  /// Lấy số lượng tin nhắn chưa đọc từ một người dùng cụ thể
  Future<int> getUnreadMessageCountFromUser(String senderId, String receiverId) async {
    try {
      final data = await _supabase
          .from('messages')
          .select()
          .eq('sender_id', senderId)
          .eq('receiver_id', receiverId)
          .eq('is_read', false);

      return data.length;
    } catch (e) {
      return 0;
    }
  }

  /// Tìm kiếm tin nhắn
  Future<List<Message>> searchMessages(
    String userId,
    String otherUserId,
    String query,
  ) async {
    try {
      final data = await _supabase
          .from('messages')
          .select()
          .or(
              'and(sender_id.eq.$userId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$userId)')
          .ilike('content', '%$query%')
          .order('sent_at', ascending: false);

      return (data as List)
          .map((message) => Message.fromJson(message))
          .toList();
    } catch (e) {
      throw Exception('Lỗi tìm kiếm: $e');
    }
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Update hoặc tạo conversation
  Future<void> _updateOrCreateConversation(
    String userId,
    String otherUserId,
    String lastMessage,
    DateTime lastMessageTime,
  ) async {
    try {
      final senderProfile = await _getProfileSummary(userId);
      final receiverProfile = await _getProfileSummary(otherUserId);

      // Sender side conversation row (unread remains 0)
      await _upsertConversationRow(
        ownerUserId: userId,
        participantId: otherUserId,
        participantName: receiverProfile['name'] ?? 'User',
        participantAvatar: receiverProfile['avatar'],
        lastMessage: lastMessage,
        lastMessageTime: lastMessageTime,
        incrementUnread: false,
      );

      // Receiver side conversation row (unread +1)
      await _upsertConversationRow(
        ownerUserId: otherUserId,
        participantId: userId,
        participantName: senderProfile['name'] ?? 'User',
        participantAvatar: senderProfile['avatar'],
        lastMessage: lastMessage,
        lastMessageTime: lastMessageTime,
        incrementUnread: true,
      );
    } catch (e) {
      print('Conversation sync warning: $e');
    }
  }

  Future<List<Conversation>> _buildConversationsFromMessages(String userId) async {
    final rows = await _supabase
        .from('messages')
        .select()
        .or('sender_id.eq.$userId,receiver_id.eq.$userId')
        .order('sent_at', ascending: false)
        .limit(500);

    if (rows.isEmpty) return [];

    final Map<String, Map<String, dynamic>> latestByPeer = {};
    final Map<String, int> unreadByPeer = {};
    final Map<String, Map<String, String?>> profileCache = {};

    for (final item in rows as List) {
      final row = item as Map<String, dynamic>;
      final senderId = row['sender_id']?.toString() ?? '';
      final receiverId = row['receiver_id']?.toString() ?? '';

      final peerId = senderId == userId ? receiverId : senderId;
      if (peerId.isEmpty) continue;

      latestByPeer.putIfAbsent(peerId, () => row);

      final isUnread = receiverId == userId && (row['is_read'] as bool? ?? false) == false;
      if (isUnread) {
        unreadByPeer[peerId] = (unreadByPeer[peerId] ?? 0) + 1;
      }
    }

    final List<Conversation> result = [];
    for (final entry in latestByPeer.entries) {
      final peerId = entry.key;
      final row = entry.value;
      final senderId = row['sender_id']?.toString() ?? '';
      final sentAtRaw = row['sent_at']?.toString();
      final sentAt = sentAtRaw != null
          ? DateTime.tryParse(sentAtRaw) ?? DateTime.now()
          : DateTime.now();

      final profile = profileCache.putIfAbsent(
        peerId,
        () => {'name': null, 'avatar': null},
      );
      if (profile['name'] == null) {
        profileCache[peerId] = await _getProfileSummary(peerId);
      }
      final peerProfile = profileCache[peerId]!;

      final participantName = senderId != userId
          ? ((row['sender_name']?.toString().trim().isNotEmpty == true)
              ? row['sender_name'].toString().trim()
              : (peerProfile['name'] ?? 'User'))
          : (peerProfile['name'] ?? 'User');

      final participantAvatar = senderId != userId
          ? ((row['sender_avatar']?.toString().trim().isNotEmpty == true)
              ? row['sender_avatar']?.toString()
              : peerProfile['avatar'])
          : peerProfile['avatar'];

      result.add(
        Conversation(
          id: 'fallback_${userId}_$peerId',
          userId: userId,
          participantId: peerId,
          participantName: participantName,
          participantAvatar: participantAvatar,
          lastMessage: row['content']?.toString() ?? '',
          lastMessageTime: sentAt,
          unreadCount: unreadByPeer[peerId] ?? 0,
          isOnline: false,
        ),
      );
    }

    result.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    return result;
  }

  Future<Map<String, String?>> _getProfileSummary(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('display_name, avatar_url, username')
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
        return {'name': 'User', 'avatar': null};
      }

      final displayName = (data['display_name'] as String?)?.trim();
      final username = (data['username'] as String?)?.trim();
      return {
        'name': (displayName != null && displayName.isNotEmpty)
            ? displayName
            : ((username != null && username.isNotEmpty) ? username : 'User'),
        'avatar': data['avatar_url'] as String?,
      };
    } catch (_) {
      return {'name': 'User', 'avatar': null};
    }
  }

  Future<void> _upsertConversationRow({
    required String ownerUserId,
    required String participantId,
    required String participantName,
    required String? participantAvatar,
    required String lastMessage,
    required DateTime lastMessageTime,
    required bool incrementUnread,
  }) async {
    final existing = await _supabase
        .from('conversations')
        .select('id, unread_count')
        .eq('user_id', ownerUserId)
        .eq('participant_id', participantId)
        .limit(1);

    if (existing.isNotEmpty) {
      final oldUnread = (existing.first['unread_count'] as num?)?.toInt() ?? 0;
      await _supabase
          .from('conversations')
          .update({
            'participant_name': participantName,
            'participant_avatar': participantAvatar,
            'last_message': lastMessage,
            'last_message_time': lastMessageTime.toIso8601String(),
            'unread_count': incrementUnread ? oldUnread + 1 : 0,
          })
          .eq('id', existing.first['id']);
      return;
    }

    await _supabase.from('conversations').insert({
      'user_id': ownerUserId,
      'participant_id': participantId,
      'participant_name': participantName,
      'participant_avatar': participantAvatar,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime.toIso8601String(),
      'unread_count': incrementUnread ? 1 : 0,
      'is_online': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Format time difference
  String formatTimeDifference(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
