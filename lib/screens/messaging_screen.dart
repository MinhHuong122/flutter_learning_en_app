import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/messaging_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/file_upload_service.dart';
import '../models/community_model.dart';

class MessagingScreen extends StatefulWidget {
  final String? recipientId;
  final String? recipientName;
  final String? recipientAvatar;

  const MessagingScreen({
    Key? key,
    this.recipientId,
    this.recipientName,
    this.recipientAvatar,
  }) : super(key: key);

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  late TextEditingController _messageController;
  late TextEditingController _searchController;
  List<Message> _messages = [];
  List<Conversation> _conversations = [];
  List<Conversation> _filteredConversations = [];
  bool _isLoading = true;
  bool _isLoadingConversations = true;
  bool _isSending = false;
  bool _isConversationMode = false;
  late ScrollController _scrollController;
  late MessagingService _messagingService;
  StreamSubscription<List<Message>>? _messagesSubscription;
  StreamSubscription<List<Conversation>>? _conversationsSubscription;
  final FileUploadService _fileUploadService = FileUploadService();
  bool _isBlockedConversation = false;
  bool _isMutedConversation = false;
  String? _customNickname;

  bool get _isEnglish => context.read<LanguageService>().isEnglish;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
    _messagingService = context.read<MessagingService>();

    final currentUserId = context.read<AuthService>().userId;
    final targetRecipientId = widget.recipientId;
    _isConversationMode =
        targetRecipientId != null &&
        targetRecipientId.isNotEmpty &&
        targetRecipientId != currentUserId;

    if (_isConversationMode) {
      _messagingService.activeChatUserId = targetRecipientId;
      _loadMessages();
      _startMessagesRealtime();
    } else {
      _loadConversations();
      _startConversationsRealtime();
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _conversationsSubscription?.cancel();
    if (_isConversationMode) {
      _messagingService.activeChatUserId = null;
    }
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startMessagesRealtime() {
    final authService = context.read<AuthService>();
    final messagingService = context.read<MessagingService>();
    final userId = authService.userId;
    final recipientId = widget.recipientId;

    if (userId == null || recipientId == null || recipientId.isEmpty) {
      return;
    }

    _messagesSubscription?.cancel();
    _messagesSubscription = messagingService
        .watchMessages(userId, recipientId)
        .listen((messages) async {
      if (!mounted) return;

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      await messagingService.markAllMessagesAsRead(recipientId, userId);

      Future.delayed(const Duration(milliseconds: 60), _scrollToBottom);
    }, onError: (e) {
      if (!mounted) return;
      _showErrorSnackbar(_isEnglish ? 'Error: $e' : 'Lỗi: $e');
      setState(() => _isLoading = false);
    });
  }

  void _startConversationsRealtime() {
    final authService = context.read<AuthService>();
    final messagingService = context.read<MessagingService>();
    final userId = authService.userId;

    if (userId == null || userId.isEmpty) {
      return;
    }

    _conversationsSubscription?.cancel();
    _conversationsSubscription =
        messagingService.watchConversations(userId).listen((items) {
      if (!mounted) return;

      final query = _searchController.text.trim().toLowerCase();
      final filtered = query.isEmpty
          ? items
          : items.where((conv) {
              return conv.participantName.toLowerCase().contains(query) ||
                  conv.lastMessage.toLowerCase().contains(query);
            }).toList();

      setState(() {
        _conversations = items;
        _filteredConversations = filtered;
        _isLoadingConversations = false;
      });
    }, onError: (e) {
      if (!mounted) return;
      _showErrorSnackbar(_isEnglish ? 'Error: $e' : 'Lỗi: $e');
      setState(() => _isLoadingConversations = false);
    });
  }

  Future<void> _loadConversations() async {
    try {
      final authService = context.read<AuthService>();
      final messagingService = context.read<MessagingService>();
      final userId = authService.userId;

      if (userId == null) {
        if (mounted) {
          setState(() {
            _isLoadingConversations = false;
          });
        }
        return;
      }

      final conversations = await messagingService.getConversations(userId);
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _filteredConversations = conversations;
          _isLoadingConversations = false;
        });
      }
    } catch (e) {
      _showErrorSnackbar(_isEnglish ? 'Error: $e' : 'Lỗi: $e');
      if (mounted) {
        setState(() => _isLoadingConversations = false);
      }
    }
  }

  void _filterConversations(String query) {
    if (query.trim().isEmpty) {
      setState(() => _filteredConversations = _conversations);
      return;
    }

    final lower = query.toLowerCase();
    setState(() {
      _filteredConversations = _conversations.where((conv) {
        return conv.participantName.toLowerCase().contains(lower) ||
            conv.lastMessage.toLowerCase().contains(lower);
      }).toList();
    });
  }

  void _openConversation(Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessagingScreen(
          recipientId: conversation.participantId,
          recipientName: conversation.participantName,
          recipientAvatar: conversation.participantAvatar,
        ),
      ),
    ).then((_) => _loadConversations());
  }

  Future<void> _loadMessages() async {
    try {
      final authService = context.read<AuthService>();
      final messagingService = context.read<MessagingService>();
      final userId = authService.userId;

      if (userId != null) {
        final messages =
            await messagingService.getMessages(userId, widget.recipientId!);
        setState(() {
          _messages = messages;
          _isLoading = false;
        });

        // Mark messages as read
        for (final msg in messages) {
          if (msg.receiverId == userId && !msg.isRead) {
            await messagingService.markMessageAsRead(msg.id);
          }
        }

        // Scroll to bottom
        Future.delayed(Duration(milliseconds: 100), () {
          _scrollToBottom();
        });
      }
    } catch (e) {
      _showErrorSnackbar(_isEnglish ? 'Error: $e' : 'Lỗi: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_isBlockedConversation) {
      _showErrorSnackbar(
        _isEnglish
            ? 'You blocked this conversation'
            : 'Bạn đã chặn cuộc trò chuyện này',
      );
      return;
    }

    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() => _isSending = true);

    try {
      final authService = context.read<AuthService>();
      final messagingService = context.read<MessagingService>();
      final userId = authService.userId;
      final userName = authService.userName;

      final message = await messagingService.sendMessage(
        senderId: userId ?? '',
        senderName: userName ?? 'User',
        receiverId: widget.recipientId!,
        content: text,
        senderAvatar: null,
      );

      _messageController.clear();

      setState(() {
        _messages.add(message);
        _isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      _showErrorSnackbar(_isEnglish ? 'Error: $e' : 'Lỗi: $e');
      setState(() => _isSending = false);
    }
  }

  Future<void> _sendStructuredMessage({
    required String content,
    String? fileUrl,
    String? fileName,
  }) async {
    if (_isBlockedConversation) {
      _showErrorSnackbar(
        _isEnglish
            ? 'You blocked this conversation'
            : 'Bạn đã chặn cuộc trò chuyện này',
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final authService = context.read<AuthService>();
      final messagingService = context.read<MessagingService>();
      final userId = authService.userId;
      final userName = authService.userName;

      final message = await messagingService.sendMessage(
        senderId: userId ?? '',
        senderName: userName ?? 'User',
        receiverId: widget.recipientId!,
        content: content,
        senderAvatar: null,
        fileUrl: fileUrl,
        fileName: fileName,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(message);
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar(_isEnglish ? 'Error: $e' : 'Lỗi: $e');
      setState(() => _isSending = false);
    }
  }

  Future<void> _sendPrivateImage() async {
    Navigator.pop(context);

    try {
      final authService = context.read<AuthService>();
      final userId = authService.userId;
      if (userId == null || userId.isEmpty) {
        _showErrorSnackbar(_isEnglish ? 'Session expired' : 'Phiên đăng nhập đã hết hạn');
        return;
      }

      final image = await _fileUploadService.pickImageFromGallery();
      if (image == null) return;

      final imageUrl = await _fileUploadService.uploadImage(
        image,
        userId: userId,
        folderName: 'messages',
      );

      await _sendStructuredMessage(
        content: _isEnglish ? '[Image]' : '[Ảnh]',
        fileUrl: imageUrl,
        fileName: 'image',
      );
    } catch (e) {
      _showErrorSnackbar(_isEnglish ? 'Error selecting image: $e' : 'Lỗi chọn ảnh: $e');
    }
  }

  Future<void> _sendPrivateFile() async {
    Navigator.pop(context);

    try {
      final authService = context.read<AuthService>();
      final userId = authService.userId;
      if (userId == null || userId.isEmpty) {
        _showErrorSnackbar(_isEnglish ? 'Session expired' : 'Phiên đăng nhập đã hết hạn');
        return;
      }

      final File? file = await _fileUploadService.pickFile();
      if (file == null) return;

      final fileUrl = await _fileUploadService.uploadFile(file, userId: userId);
      final fileName = file.path.split('\\').last;

      await _sendStructuredMessage(
        content: _isEnglish ? '[File] $fileName' : '[Tệp] $fileName',
        fileUrl: fileUrl,
        fileName: fileName,
      );
    } catch (e) {
      _showErrorSnackbar(_isEnglish ? 'Error selecting file: $e' : 'Lỗi chọn tệp: $e');
    }
  }

  Future<void> _sendSticker(String sticker) async {
    Navigator.pop(context);
    await _sendStructuredMessage(content: sticker);
  }

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEnglish ? 'Send privately' : 'Gửi riêng tư',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachmentAction(
                    icon: Icons.emoji_emotions_outlined,
                    label: _isEnglish ? 'Sticker' : 'Sticker',
                    onTap: () => _showStickerPicker(),
                  ),
                  _buildAttachmentAction(
                    icon: Icons.image_outlined,
                    label: _isEnglish ? 'Image' : 'Ảnh',
                    onTap: _sendPrivateImage,
                  ),
                  _buildAttachmentAction(
                    icon: Icons.attach_file,
                    label: _isEnglish ? 'File' : 'Tệp',
                    onTap: _sendPrivateFile,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryColor),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showStickerPicker() {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final stickers = <String>['😀', '😂', '😍', '🔥', '👍', '❤️', '🎉', '😎', '🙏', '🤝'];
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: stickers
                .map(
                  (s) => GestureDetector(
                    onTap: () => _sendSticker(s),
                    child: Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(s, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  void _showConversationSettings() {
    final nicknameController = TextEditingController(text: _customNickname ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEnglish ? 'Chat settings' : 'Cài đặt trò chuyện',
                style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isBlockedConversation,
                activeColor: AppColors.primaryColor,
                contentPadding: EdgeInsets.zero,
                title: Text(_isEnglish ? 'Block messages' : 'Chặn tin nhắn'),
                onChanged: (v) => setState(() => _isBlockedConversation = v),
              ),
              SwitchListTile(
                value: _isMutedConversation,
                activeColor: AppColors.primaryColor,
                contentPadding: EdgeInsets.zero,
                title: Text(_isEnglish ? 'Mute notifications' : 'Tắt thông báo'),
                onChanged: (v) => setState(() => _isMutedConversation = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nicknameController,
                decoration: InputDecoration(
                  labelText: _isEnglish ? 'Set nickname' : 'Đặt biệt danh',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _customNickname = nicknameController.text.trim().isEmpty
                          ? null
                          : nicknameController.text.trim();
                    });
                    Navigator.pop(context);
                  },
                  child: Text(_isEnglish ? 'Save' : 'Lưu'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConversationMode) {
      return _buildConversationListUI();
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _customNickname ?? widget.recipientName ?? (_isEnglish ? 'Chat' : 'Trò chuyện'),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            Text(
              _isEnglish ? 'Online' : 'Trực tuyến',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.primaryColor),
            onPressed: _showConversationSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.mail_outline,
                              size: 48,
                              color: const Color(0xFFE5E7EB),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isEnglish ? 'Start a conversation' : 'Bắt đầu cuộc trò chuyện',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final userId = context.read<AuthService>().userId;
                          final isCurrentUser = message.senderId == userId;

                          return _buildMessageBubble(message, isCurrentUser);
                        },
                      ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: const Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                  onPressed: _showAttachmentPicker,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: _isEnglish ? 'Type a message...' : 'Nhập tin nhắn...',
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
                  onTap: _isSending ? null : _sendMessage,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isSending
                          ? AppColors.primaryColor.withValues(alpha: 0.5)
                          : AppColors.primaryColor,
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(
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

  Widget _buildConversationListUI() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Row(
                children: [
                  Text(
                    _isEnglish ? 'Messages' : 'Tin nhắn',
                    style: GoogleFonts.manrope(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1F2937),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_square,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterConversations,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                    hintText: _isEnglish
                        ? 'Search contacts or messages...'
                        : 'Tìm kiếm liên hệ hoặc tin nhắn...',
                    hintStyle: GoogleFonts.manrope(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoadingConversations
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredConversations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: Color(0xFFCBD5E1),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _isEnglish
                                    ? 'No conversations yet'
                                    : 'Chưa có cuộc trò chuyện nào',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: _filteredConversations.length,
                          itemBuilder: (context, index) {
                            final conversation = _filteredConversations[index];
                            return _buildConversationTile(conversation, index == 0);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation, bool highlight) {
    final hasUnread = conversation.unreadCount > 0;
    final avatarUrl = conversation.participantAvatar;

    return GestureDetector(
      onTap: () => _openConversation(conversation),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlight ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(32),
          border: highlight
              ? Border.all(color: const Color(0xFFE2E8F0))
              : Border.all(color: Colors.transparent),
          boxShadow: highlight
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE0F2FE),
                    image: (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: (avatarUrl == null || avatarUrl.isEmpty)
                      ? Center(
                          child: Text(
                            conversation.participantName.isNotEmpty
                                ? conversation.participantName[0].toUpperCase()
                                : 'U',
                            style: GoogleFonts.manrope(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        )
                      : null,
                ),
                if (conversation.isOnline)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.participantName.isEmpty
                              ? (_isEnglish ? 'Unknown user' : 'Người dùng')
                              : conversation.participantName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatConversationTime(conversation.lastMessageTime),
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                          color: hasUnread
                              ? AppColors.primaryColor
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                            color: hasUnread
                                ? const Color(0xFF1F2937)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryColor,
                          ),
                          child: Center(
                            child: Text(
                              conversation.unreadCount > 9
                                  ? '9+'
                                  : conversation.unreadCount.toString(),
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatConversationTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return _isEnglish ? 'Now' : 'Vừa xong';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inHours < 24) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    if (difference.inDays == 1) return _isEnglish ? 'Yesterday' : 'Hôm qua';
    return '${dateTime.day}/${dateTime.month}';
  }

  Widget _buildMessageBubble(Message message, bool isCurrentUser) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: isCurrentUser ? 0 : 0,
        right: isCurrentUser ? 0 : 0,
      ),
      child: Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isCurrentUser
                ? AppColors.primaryColor
                : const Color(0xFFF3F4F6),
          ),
          child: Column(
            crossAxisAlignment:
                isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isCurrentUser
                      ? Colors.white
                      : const Color(0xFF1F2937),
                ),
              ),
              if (message.fileUrl != null && message.fileUrl!.isNotEmpty) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: isCurrentUser
                          ? Colors.white.withValues(alpha: 0.2)
                          : const Color(0xFFE5E7EB),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (message.fileName ?? '').toLowerCase().endsWith('.jpg') ||
                                  (message.fileName ?? '').toLowerCase().endsWith('.jpeg') ||
                                  (message.fileName ?? '').toLowerCase().endsWith('.png')
                              ? Icons.image_outlined
                              : Icons.insert_drive_file_outlined,
                          size: 16,
                          color: isCurrentUser ? Colors.white : const Color(0xFF374151),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            message.fileName ?? (_isEnglish ? 'Attachment' : 'Tệp đính kèm'),
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isCurrentUser ? Colors.white : const Color(0xFF374151),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                _formatTime(message.sentAt),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: isCurrentUser
                      ? Colors.white.withValues(alpha: 0.7)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
