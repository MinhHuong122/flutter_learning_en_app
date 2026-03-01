import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../widgets/custom_bottom_nav.dart';
import '../services/language_service.dart';
import 'home_screen.dart';
import 'process_screen.dart';
import 'archive_screen.dart';
import 'account_screen.dart';

class ChatMessage {
  final String text;
  final String textVi;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.textVi,
    required this.isUser,
    required this.timestamp,
  });
}

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const String _vercelApiUrl =
      'https://flutter-learning-en-app.vercel.app/api/chat';
  
  int _currentIndex = 2;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _addMessage(
      'Welcome to PUPU AI! 👋 I\'m your AI study buddy. How can I help you today?',
      'Chào mừng đến với PUPU AI! 👋 Tôi là trợ lý học tập AI của bạn. Tôi có thể giúp gì cho bạn hôm nay?',
      isUser: false,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isEnglish => context.read<LanguageService>().isEnglish;

  void _addMessage(String contentEn, String contentVi, {required bool isUser}) {
    setState(() {
      _messages.add(ChatMessage(
        text: contentEn,
        textVi: contentVi,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _cleanMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')
        .replaceAll(RegExp(r'__(.*?)__'), r'$1')
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1')
        .replaceAll(RegExp(r'_(.*?)_'), r'$1')
        .replaceAll(RegExp(r'`(.*?)`'), r'$1')
        .replaceAll(RegExp(r'#{1,6}\s'), '')
        .replaceAll(RegExp(r'!\[.*?\]\((.*?)\)'), '[image]')
        .replaceAll(RegExp(r'\[.*?\]\((.*?)\)'), r'$1')
        .trim();
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

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
        setState(() => _currentIndex = index);
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ArchiveScreen()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AccountScreen()),
        );
        break;
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _addMessage(message, message, isUser: true);
    _messageController.clear();

    setState(() {
      _isTyping = true;
    });

    _callGeminiAPI(message);
  }

  Future<void> _callGeminiAPI(String userMessage) async {
    final isEnglish = _isEnglish;
    
    try {
      final url = Uri.parse(_vercelApiUrl);
      print('🔄 Calling Vercel AI API...');
      print('Message: $userMessage');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': userMessage,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('API request timeout');
        },
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String aiResponse = responseData['response'] ?? 'Unable to get response';

        aiResponse = _cleanMarkdown(aiResponse);
        print('✅ AI Response: $aiResponse');

        if (mounted) {
          setState(() {
            _addMessage(aiResponse, aiResponse, isUser: false);
            _isTyping = false;
          });
        }
      } else if (response.statusCode == 429) {
        print('⚠️ Rate Limited: ${response.statusCode}');
        if (mounted) {
          setState(() {
            _addMessage(
              isEnglish
                  ? 'The AI service is currently busy. Please wait a moment and try again.'
                  : 'Dịch vụ AI hiện đang bận. Vui lòng chờ một lát và thử lại.',
              'Dịch vụ AI hiện đang bận. Vui lòng chờ một lát và thử lại.',
              isUser: false,
            );
            _isTyping = false;
          });
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('❌ Authentication Error: ${response.statusCode}');
        if (mounted) {
          setState(() {
            _addMessage(
              isEnglish
                  ? 'Authentication error. Please check the API configuration.'
                  : 'Lỗi xác thực. Vui lòng kiểm tra cấu hình API.',
              'Lỗi xác thực. Vui lòng kiểm tra cấu hình API.',
              isUser: false,
            );
            _isTyping = false;
          });
        }
      } else {
        print('❌ API Error: ${response.statusCode}');
        if (mounted) {
          setState(() {
            _addMessage(
              isEnglish
                  ? 'Sorry, I encountered an error (${response.statusCode}). Please try again.'
                  : 'Xin lỗi, tôi gặp lỗi (${response.statusCode}). Vui lòng thử lại.',
              'Xin lỗi, tôi gặp lỗi (${response.statusCode}). Vui lòng thử lại.',
              isUser: false,
            );
            _isTyping = false;
          });
        }
      }
    } on TimeoutException {
      print('❌ Timeout');
      if (mounted) {
        setState(() {
          _addMessage(
            isEnglish
                ? 'Connection timeout. Please check your internet and try again.'
                : 'Kết nối bị timeout. Vui lòng kiểm tra internet và thử lại.',
            'Kết nối bị timeout. Vui lòng kiểm tra internet và thử lại.',
            isUser: false,
          );
          _isTyping = false;
        });
      }
    } catch (e) {
      print('❌ Exception: $e');
      if (mounted) {
        setState(() {
          _addMessage(
            isEnglish
                ? 'Sorry, something went wrong. Please try again.'
                : 'Xin lỗi, có sự cố. Vui lòng thử lại.',
            'Xin lỗi, có sự cố. Vui lòng thử lại.',
            isUser: false,
          );
          _isTyping = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTyping && index == _messages.length) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),

            // Input Area
            _buildInputArea(),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFF4B5563),
                size: 20,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'PUPU AI',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isEnglish ? 'Online' : 'Trực tuyến',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF3F4F6),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            ),
            child: Icon(
              Icons.videocam,
              color: AppColors.primaryColor,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF3F4F6),
            ),
            child: const Icon(
              Icons.expand_circle_down,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: _isEnglish ? 'Ask anything...' : 'Hỏi bất cứ điều gì...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF3F4F6),
            ),
            child: const Icon(
              Icons.mic_none,
              color: Color(0xFF9CA3AF),
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isTyping ? null : _sendMessage,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
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
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final content = _isEnglish ? message.text : message.textVi;
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: isUser
          ? _buildUserBubble(content, message.timestamp)
          : _buildAIBubble(content, message.timestamp),
    );
  }

  Widget _buildAIBubble(String content, DateTime timestamp) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryColor.withOpacity(0.2),
            border: Border.all(
              color: AppColors.primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.smart_toy,
            color: AppColors.primaryColor,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF1F2937),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(timestamp),
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserBubble(String content, DateTime timestamp) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF1F2937),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Read ',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    Text(
                      _formatTime(timestamp),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryColor.withOpacity(0.2),
            border: Border.all(
              color: AppColors.primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.smart_toy,
            color: AppColors.primaryColor,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _buildTypingDot(0),
              const SizedBox(width: 4),
              _buildTypingDot(1),
              const SizedBox(width: 4),
              _buildTypingDot(2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, double value, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryColor.withOpacity(
              0.3 + (0.7 * ((value + index * 0.3) % 1)),
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }
}
