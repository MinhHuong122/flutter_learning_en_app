import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../utils/constants.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/voice_interaction_overlay.dart';
import '../services/language_service.dart';
import '../services/gemini_voice_coach.dart';
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

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'text': text,
    'textVi': textVi,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };

  // Create from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    text: json['text'] as String,
    textVi: json['textVi'] as String,
    isUser: json['isUser'] as bool,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

class ChatAiScreen extends StatefulWidget {
  const ChatAiScreen({Key? key}) : super(key: key);

  @override
  State<ChatAiScreen> createState() => _ChatAiScreenState();
}

class _ChatAiScreenState extends State<ChatAiScreen> {
  static const String _vercelApiUrl =
      'https://flutter-learning-en-app.vercel.app/api/chat';
  
  int _currentIndex = 2;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<ChatMessage> _chatHistory = [];
  bool _isTyping = false;
  bool _isRecording = false;
  int? _currentSpeakingMessageIndex; // Track which message is currently being spoken
  final Map<int, bool> _showTranslation = {}; // Track which messages show translation
  final Map<int, bool> _messageMuted = {}; // Track which AI messages are muted
  final AudioRecorder _audioRecorder = AudioRecorder();
  final GeminiVoiceCoach _voiceCoach = GeminiVoiceCoach();
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeechToText();
    _loadChatHistory();
  }

  void _initTts() {
    _flutterTts.setLanguage("en-US");
    _flutterTts.setPitch(1.0);
    _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _initSpeechToText() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          print('Speech recognition error: $error');
          if (mounted) {
            setState(() => _isRecording = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isEnglish ? 'Microphone error: $error' : 'Lỗi micro: $error',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        onStatus: (status) {
          print('Speech recognition status: $status');
        },
      );
    } catch (e) {
      print('Error initializing speech to text: $e');
    }
  }

  Future<void> _speak(String text, {int? messageIndex}) async {
    // Check if the message is muted
    if (messageIndex != null && _messageMuted[messageIndex] == true) {
      return;
    }
    
    // Track which message is being spoken
    if (messageIndex != null) {
      _currentSpeakingMessageIndex = messageIndex;
    }
    
    try {
      await _flutterTts.speak(text);
    } finally {
      // Clear the current speaking message when done
      if (_currentSpeakingMessageIndex == messageIndex) {
        _currentSpeakingMessageIndex = null;
      }
    }
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    _currentSpeakingMessageIndex = null;
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatHistoryJson = prefs.getString('chat_history');
      
      if (chatHistoryJson != null) {
        final List<dynamic> jsonList = jsonDecode(chatHistoryJson);
        final loadedMessages = jsonList
            .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
            .toList();

        final now = DateTime.now();
        final todayMessages = loadedMessages
            .where((msg) => _isSameDate(msg.timestamp, now))
            .toList();
        
        if (mounted) {
          setState(() {
            _chatHistory.clear();
            _chatHistory.addAll(loadedMessages);
            _messages.clear();
            _messages.addAll(todayMessages);
          });
        }

        if (_messages.isEmpty) {
          _addMessage(
            'Welcome to PUPU AI! 👋 I\'m your English learning assistant. I\'ll help you improve your English by correcting your grammar, word usage, and providing helpful explanations. Feel free to chat, ask questions, or practice with me. Let\'s learn together!',
            'Chào mừng đến với PUPU AI! 👋 Tôi là trợ lý học tiếng Anh ảo cho bạn. Tôi sẽ giúp bạn cải thiện tiếng Anh bằng cách sửa ngữ pháp, cách dùng từ và cung cấp giải thích hữu ích. Cứ thoải mái trò chuyện, đặt câu hỏi hay thực hành cùng tôi. Chúng ta cùng học thôi!',
            isUser: false,
          );
        } else {
          _scrollToBottom();
        }
      } else {
        // First time - show welcome message
        _addMessage(
          'Welcome to PUPU AI! 👋 I\'m your English learning assistant. I\'ll help you improve your English by correcting your grammar, word usage, and providing helpful explanations. Feel free to chat, ask questions, or practice with me. Let\'s learn together!',
          'Chào mừng đến với PUPU AI! 👋 Tôi là trợ lý học tiếng Anh ảo cho bạn. Tôi sẽ giúp bạn cải thiện tiếng Anh bằng cách sửa ngữ pháp, cách dùng từ và cung cấp giải thích hữu ích. Cứ thoải mái trò chuyện, đặt câu hỏi hay thực hành cùng tôi. Chúng ta cùng học thôi!',
          isUser: false,
        );
      }
    } catch (e) {
      print('Error loading chat history: $e');
      _addMessage(
        'Welcome to PUPU AI! 👋 I\'m your English learning assistant. I\'ll help you improve your English by correcting your grammar, word usage, and providing helpful explanations. Feel free to chat, ask questions, or practice with me. Let\'s learn together!',
        'Chào mừng đến với PUPU AI! 👋 Tôi là trợ lý học tiếng Anh ảo cho bạn. Tôi sẽ giúp bạn cải thiện tiếng Anh bằng cách sửa ngữ pháp, cách dùng từ và cung cấp giải thích hữu ích. Cứ thoải mái trò chuyện, đặt câu hỏi hay thực hành cùng tôi. Chúng ta cùng học thôi!',
        isUser: false,
      );
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _chatHistory.map((msg) => msg.toJson()).toList();
      await prefs.setString('chat_history', jsonEncode(jsonList));
      print('✅ Chat history saved');
    } catch (e) {
      print('Error saving chat history: $e');
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _audioRecorder.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isEnglish => context.read<LanguageService>().isEnglish;

  void _addMessage(String contentEn, String contentVi, {required bool isUser}) {
    final newMessage = ChatMessage(
      text: contentEn,
      textVi: contentVi,
      isUser: isUser,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(newMessage);
      _chatHistory.add(newMessage);
    });
    _saveChatHistory(); // Save after adding
    _scrollToBottom();
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')  // Remove **bold**
        .replaceAll(RegExp(r'__(.*?)__'), r'$1')      // Remove __bold__
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1')      // Remove *italic*
        .replaceAll(RegExp(r'_(.*?)_'), r'$1')        // Remove _italic_
        .replaceAll(RegExp(r'`(.*?)`'), r'$1')        // Remove `code`
        .replaceAll(RegExp(r'#{1,6}\s'), '')          // Remove # headers
        .replaceAll(RegExp(r'!\[.*?\]\((.*?)\)'), '[image]')  // Remove ![alt](url)
        .replaceAll(RegExp(r'\[.*?\]\((.*?)\)'), r'$1')       // Remove [text](url)
        .replaceAll('*', '')                          // Remove all remaining asterisks
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
      print('🔄 Calling Gemini API...');
      print('Message: $userMessage');

      // Use the Gemini API via voice coach service
      String apiResponse = await _voiceCoach.generateReply(userMessage, isEnglish: isEnglish);
      
      print('📡 Response received');

      if (apiResponse.isEmpty || apiResponse.contains('not configured') || apiResponse.contains('failed')) {
        // Fallback to original Vercel API if Gemini fails
        print('⚠️ Gemini API failed, trying Vercel API...');
        await _callVercelAPI(userMessage);
        return;
      }

      // Clean the response
      String aiResponseEn = _cleanMarkdown(apiResponse);
      
      // Translate to Vietnamese
      String aiResponseVi = await _translateToVietnamese(aiResponseEn);
      
      print('✅ AI Response (EN): $aiResponseEn');
      print('✅ AI Response (VI): $aiResponseVi');

      if (mounted) {
        setState(() {
          _addMessage(aiResponseEn, aiResponseVi, isUser: false);
          _isTyping = false;
        });
        final messageIndex = _messages.length - 1;
        _speak(aiResponseEn, messageIndex: messageIndex);
      }
    } catch (e) {
      print('❌ Exception: $e');
      if (mounted) {
        setState(() {
          _addMessage(
            'Sorry, something went wrong. Please try again.',
            'Xin lỗi, có sự cố. Vui lòng thử lại.',
            isUser: false,
          );
          _isTyping = false;
        });
      }
    }
  }

  Future<void> _callVercelAPI(String userMessage) async {
    final isEnglish = _isEnglish;
    
    try {
      final url = Uri.parse(_vercelApiUrl);
      print('🔄 Calling Vercel AI API (Fallback)...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
body: jsonEncode({
  'message': userMessage,
  'systemPrompt': 'You are PUPU AI, a virtual English learning assistant for Vietnamese users. Your main tasks are:\n1. Help users improve their English skills\n2. Correct grammar and word usage mistakes when users make them\n3. Provide clear explanations and helpful feedback\n4. Suggest better ways to express ideas\n5. Explain vocabulary, grammar rules, and pronunciation when asked\n6. Be encouraging and supportive\n7. Ask follow-up questions to help users learn better\n\nAlways be friendly, patient, and focus on helping users learn English effectively. Respond naturally in English.',
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
        String apiResponse = responseData['response'] ?? 'Unable to get response';

        // Clean the response
        String aiResponseEn = _cleanMarkdown(apiResponse);
        
        // Translate to Vietnamese
        String aiResponseVi = await _translateToVietnamese(aiResponseEn);
        
        print('✅ AI Response (EN): $aiResponseEn');
        print('✅ AI Response (VI): $aiResponseVi');

        if (mounted) {
          setState(() {
            _addMessage(aiResponseEn, aiResponseVi, isUser: false);
            _isTyping = false;
          });
          final messageIndex = _messages.length - 1;
          _speak(aiResponseEn, messageIndex: messageIndex);
        }
      } else if (response.statusCode == 429) {
        print('⚠️ Rate Limited: ${response.statusCode}');
        if (mounted) {
          setState(() {
            _addMessage(
              'The AI service is currently busy. Please wait a moment and try again.',
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
              'Authentication error. Please check the API configuration.',
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
              'Sorry, I encountered an error (${response.statusCode}). Please try again.',
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
            'Connection timeout. Please check your internet and try again.',
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
            'Sorry, something went wrong. Please try again.',
            'Xin lỗi, có sự cố. Vui lòng thử lại.',
            isUser: false,
          );
          _isTyping = false;
        });
      }
    }
  }

  Future<void> _toggleVoiceInput() async {
    if (_isTyping) return;

    if (_isRecording) {
      await _speechToText.stop();
      setState(() => _isRecording = false);
      return;
    }

    // Request microphone permission
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnglish
                ? 'Microphone permission is required for voice input'
                : 'Cần quyền microphone để nhập bằng giọng nói',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_speechEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnglish 
                ? 'Speech recognition not available on this device' 
                : 'Nhận dạng giọng nói không khả dụng trên thiết bị này',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isRecording = true);

    try {
      // Listen using device's native speech recognition (works offline)
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            final transcription = result.recognizedWords;
            print('✅ Transcribed (device): $transcription');

            if (mounted) {
              setState(() => _isRecording = false);
              _addMessage(transcription, transcription, isUser: true);
              _callGeminiAPI(transcription);
            }
          }
        },
        localeId: _isEnglish ? 'en_US' : 'vi_VN',
      );
    } catch (e) {
      print('❌ Speech recognition error: $e');
      if (mounted) {
        setState(() => _isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEnglish 
                  ? 'Error: $e' 
                  : 'Lỗi: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
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
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'PUPU AI',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
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
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              _showChatHistory();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF3F4F6),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              ),
              child: Icon(
                Icons.history,
                color: AppColors.primaryColor,
                size: 18,
              ),
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
          // Voice Interaction Overlay Button
          VoiceInteractionButton(
            isEnglish: _isEnglish,
            onMessageProcessed: (transcription, aiResponse) async {
              // Add transcribed message from user
              _addMessage(transcription, transcription, isUser: true);
              
              // Add AI response
              String aiResponseVi = await _translateToVietnamese(aiResponse);
              _addMessage(aiResponse, aiResponseVi, isUser: false);
              
              // Delay to ensure message is rendered with mute button available
              await Future.delayed(const Duration(milliseconds: 200));
              
              // Speak the response (now mute button is visible)
              final messageIndex = _messages.length - 1;
              await _speak(aiResponse, messageIndex: messageIndex);
            },
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
    final isUser = message.isUser;
    final messageIndex = _messages.indexOf(message);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: isUser
          ? _buildUserBubble(message, messageIndex)
          : _buildAIBubble(message, messageIndex),
    );
  }

  Widget _buildAIBubble(ChatMessage message, int messageIndex) {
    final content = _isEnglish ? message.text : message.textVi;
    final showTranslation = _showTranslation[messageIndex] ?? false;
    final isMuted = _messageMuted[messageIndex] ?? false;
    final isCurrentlySpeaking = _currentSpeakingMessageIndex == messageIndex;
    final timestamp = message.timestamp;

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
          child: ClipOval(
            child: Image.asset(
              'assets/image/info.png',
              fit: BoxFit.cover,
            ),
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
              // Translation section
              if (showTranslation)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      _isEnglish ? message.textVi : message.text,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              // Time and action buttons row
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(timestamp),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Mute/Unmute button
                    GestureDetector(
                      onTap: () async {
                        final wasUnmuted = !isMuted;
                        
                        if (wasUnmuted) {
                          // was unmuted, now muting - stop speaking immediately
                          await _stopSpeaking();
                        }
                        
                        setState(() {
                          _messageMuted[messageIndex] = !isMuted;
                        });
                        
                        if (!wasUnmuted) {
                          // was muted, now unmuting - start speaking again
                          await _speak(content, messageIndex: messageIndex);
                        }
                      },
                      child: Text(
                        isMuted
                            ? (_isEnglish ? 'Unmute' : 'Bật âm')
                            : (_isEnglish ? 'Mute' : 'Tắt âm'),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMuted ? Colors.red : AppColors.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Translate button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showTranslation[messageIndex] = !showTranslation;
                        });
                      },
                      child: Text(
                        showTranslation
                            ? (_isEnglish ? 'Hide' : 'Ẩn')
                            : (_isEnglish ? 'Translate' : 'Dịch'),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildUserBubble(ChatMessage message, int messageIndex) {
    final content = _isEnglish ? message.text : message.textVi;
    final timestamp = message.timestamp;

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
          child: ClipOval(
            child: Image.asset(
              'assets/image/info.png',
              fit: BoxFit.cover,
            ),
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

  Map<String, List<ChatMessage>> _groupMessagesByDate() {
    final grouped = <String, List<ChatMessage>>{};
    final now = DateTime.now();

    for (final message in _chatHistory) {
      final msgDate = DateTime(message.timestamp.year, message.timestamp.month, message.timestamp.day);
      final nowDate = DateTime(now.year, now.month, now.day);
      final difference = nowDate.difference(msgDate).inDays;

      String key;
      if (difference == 0) {
        key = _isEnglish ? 'Today' : 'Hôm nay';
      } else if (difference == 1) {
        key = _isEnglish ? 'Yesterday' : 'Hôm qua';
      } else if (difference < 7) {
        key = _isEnglish ? '$difference days ago' : '$difference ngày trước';
      } else if (difference < 30) {
        final weeks = (difference / 7).floor();
        key = _isEnglish ? '$weeks week${weeks > 1 ? 's' : ''} ago' : '$weeks tuần trước';
      } else {
        final months = (difference / 30).floor();
        key = _isEnglish ? '$months month${months > 1 ? 's' : ''} ago' : '$months tháng trước';
      }

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(message);
    }

    return grouped;
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return _isEnglish ? 'Today' : 'Hôm nay';
    } else if (dateOnly == yesterday) {
      return _isEnglish ? 'Yesterday' : 'Hôm qua';
    } else {
      return '${dateOnly.day}/${dateOnly.month}/${dateOnly.year}';
    }
  }

  void _showChatHistory() {
    final groupedMessages = _groupMessagesByDate();
    final sortedKeys = groupedMessages.keys.toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEnglish ? 'Chat History' : 'Lịch sử trò chuyện',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Chat history by date list
            Expanded(
              child: _chatHistory.isEmpty
                  ? Center(
                      child: Text(
                        _isEnglish ? 'No chat history' : 'Không có lịch sử',
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: sortedKeys.length,
                      itemBuilder: (context, index) {
                        final dateKey = sortedKeys[index];
                        final messagesForDate = groupedMessages[dateKey]!;
                        final firstMessage = messagesForDate.first;
                        final lastMessage = messagesForDate.last;
                        final messageCount = messagesForDate.length;
                        final startTime = '${firstMessage.timestamp.hour.toString().padLeft(2, '0')}:${firstMessage.timestamp.minute.toString().padLeft(2, '0')}';
                        final endTime = '${lastMessage.timestamp.hour.toString().padLeft(2, '0')}:${lastMessage.timestamp.minute.toString().padLeft(2, '0')}';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _showDetailedChatHistory(dateKey, messagesForDate);
                            },
                            onLongPress: () {
                              Navigator.pop(context);
                              _showDeleteHistoryOption(dateKey, messagesForDate);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dateKey,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _isEnglish
                                              ? '$messageCount messages • $startTime - $endTime'
                                              : '$messageCount tin nhắn • $startTime - $endTime',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Color(0xFF9CA3AF),
                                    size: 24,
                                  ),
                                ],
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
    );
  }

  void _showDetailedChatHistory(String dateLabel, List<ChatMessage> messages) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          _isEnglish
                              ? '${messages.length} messages'
                              : '${messages.length} tin nhắn',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Messages list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isUser = message.isUser;
                  final messageContent =
                      _isEnglish ? message.text : message.textVi;
                  final timeStr =
                      '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!isUser)
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  AppColors.primaryColor.withOpacity(0.1),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/image/info.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? AppColors.primaryColor
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  messageContent,
                                  style: TextStyle(
                                    color: isUser
                                        ? Colors.white
                                        : const Color(0xFF1F2937),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    color: isUser
                                        ? Colors.white70
                                        : const Color(0xFF9CA3AF),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isUser) const SizedBox(width: 8),
                        if (isUser)
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  AppColors.primaryColor.withOpacity(0.2),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteHistoryOption(String dateLabel, List<ChatMessage> messages) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  _isEnglish
                      ? 'Delete "$dateLabel" history'
                      : 'Xoá lịch sử "$dateLabel"',
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteHistoryChunk(messages);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: Text(_isEnglish ? 'Cancel' : 'Huỷ'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteHistoryChunk(List<ChatMessage> messagesToDelete) async {
    if (messagesToDelete.isEmpty) return;

    setState(() {
      _chatHistory.removeWhere((msg) => messagesToDelete.contains(msg));
      _messages.removeWhere((msg) => messagesToDelete.contains(msg));
    });
    await _saveChatHistory();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnglish ? 'History deleted' : 'Đã xoá lịch sử',
          ),
          backgroundColor: AppColors.primaryColor,
        ),
      );
    }
  }

  Future<String> _translateToVietnamese(String text) async {
    if (text.isEmpty) return text;
    try {
      final encoded = Uri.encodeComponent(text);
      final url = Uri.parse(
        'https://api.mymemory.translated.net/get?q=' + encoded + '&langpair=en|vi'
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['responseStatus'] == 200) {
          return data['responseData']['translatedText'] as String;
        }
      }
    } catch (e) {
      print('Translation error: ' + e.toString());
    }
    return text;
  }
}
