import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../services/gemini_voice_coach.dart';
import '../utils/constants.dart';

/// Enum for voice interaction states
enum VoiceState {
  idle,        // Waiting for user to tap
  listening,   // Listening to user speech (device-native)
  thinking,    // AI is processing
  replying,    // Done processing
}

/// Callback function signature for when a voice message is processed
typedef OnVoiceMessageProcessed = Future<void> Function(String transcription, String aiResponse);

/// Voice Interaction Widget with device-native speech recognition
class VoiceInteractionOverlay extends StatefulWidget {
  final bool isEnglish;
  final OnVoiceMessageProcessed onMessageProcessed;
  final String? initialApiKey;

  const VoiceInteractionOverlay({
    Key? key,
    required this.isEnglish,
    required this.onMessageProcessed,
    this.initialApiKey,
  }) : super(key: key);

  @override
  State<VoiceInteractionOverlay> createState() => _VoiceInteractionOverlayState();
}

class _VoiceInteractionOverlayState extends State<VoiceInteractionOverlay> with TickerProviderStateMixin {
  VoiceState _state = VoiceState.listening;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  late GeminiVoiceCoach _voiceCoach;
  
  String _transcription = '';
  String _aiResponse = '';
  late AnimationController _recordingAnimationController;
  late AnimationController _thinkingAnimationController;
  bool _isProcessing = false;
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _voiceCoach = GeminiVoiceCoach(apiKey: widget.initialApiKey);
    
    // Setup recording animation (waveform effect)
    _recordingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    // Setup thinking animation (pulsing dots)
    _thinkingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _initSpeechToText();
  }

  @override
  void dispose() {
    _recordingAnimationController.dispose();
    _thinkingAnimationController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  /// Initialize speech-to-text and start listening
  Future<void> _initSpeechToText() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          print('❌ Speech init error: $error');
          _closeDialog();
          String errorMsg = widget.isEnglish
              ? 'Speech recognition not available: $error'
              : 'Nhận dạng giọng nói không khả dụng: $error';
          _showErrorSnackBar(errorMsg);
        },
        onStatus: (status) {
          print('🎤 Speech status: $status');
        },
      );

      if (!mounted) return;

      if (_speechEnabled) {
        print('✅ Speech recognition initialized successfully');
        _startListening();
      } else {
        _closeDialog();
        _showErrorSnackBar(
          widget.isEnglish 
            ? 'Speech recognition not available on this device' 
            : 'Nhận dạng giọng nói không khả dụng trên thiết bị này'
        );
      }
    } catch (e) {
      print('❌ Speech init exception: $e');
      _closeDialog();
      _showErrorSnackBar(
        widget.isEnglish 
          ? 'Failed to initialize speech: $e' 
          : 'Không thể khởi tạo giọng nói: $e'
      );
    }
  }

  /// Start listening to user speech
  Future<void> _startListening() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (!mounted) return;
      _closeDialog();
      _showErrorSnackBar(
        widget.isEnglish 
          ? 'Microphone permission required for voice input' 
          : 'Cần quyền truy cập microphone để nhập bằng giọng nói'
      );
      return;
    }

    if (_isProcessing || !_speechEnabled) {
      print('❌ Cannot start listening: processing=$_isProcessing, enabled=$_speechEnabled');
      return;
    }

    print('🎤 Starting speech recognition...');
    try {
      setState(() => _state = VoiceState.listening);

      await _speechToText.listen(
        onResult: (result) {
          print('📝 Speech result: "${result.recognizedWords}" (final: ${result.finalResult})');
          
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            _transcription = result.recognizedWords;
            print('✅ Transcribed: $_transcription');

            if (mounted) {
              setState(() => _state = VoiceState.thinking);
              _processTranscriptionAndGenerateResponse();
            }
          } else if (!result.finalResult) {
            print('⏳ Partial result: ${result.recognizedWords}');
          }
        },
        onSoundLevelChange: (level) {
          print('🔊 Sound level: $level');
        },
        localeId: widget.isEnglish ? 'en_US' : 'vi_VN',
        listenFor: const Duration(seconds: 30),  // Wait up to 30 seconds for speech
        pauseFor: const Duration(seconds: 3),    // Stop listening after 3 seconds of silence
      );
    } on Exception catch (e) {
      print('❌ Listening exception: $e');
      if (mounted) {
        String errorMsg = widget.isEnglish 
            ? 'Speech timeout - please try again and speak loudly' 
            : 'Hết thời gian lắng nghe - vui lòng thử lại và nói to hơn';
        
        if (e.toString().toLowerCase().contains('timeout') || 
            e.toString().toLowerCase().contains('no speech')) {
          errorMsg = widget.isEnglish 
              ? 'No speech detected - please speak into the microphone' 
              : 'Không phát hiện giọng nói - vui lòng nói vào microphone';
        } else if (e.toString().toLowerCase().contains('no permission') ||
                   e.toString().toLowerCase().contains('permission denied')) {
          errorMsg = widget.isEnglish
              ? 'Microphone permission denied'
              : 'Quyền microphone bị từ chối';
        }
        
        _showErrorSnackBar(errorMsg);
        
        // Try to restart listening after a brief pause
        if (mounted && !e.toString().toLowerCase().contains('permission')) {
          print('🔄 Retrying speech recognition...');
          setState(() => _state = VoiceState.listening);
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted && _state == VoiceState.listening && !_isProcessing) {
            await _startListening();
          }
        } else {
          _closeDialog();
        }
      }
    }
  }

  /// Process transcription and generate AI response
  Future<void> _processTranscriptionAndGenerateResponse() async {
    if (_isProcessing || _transcription.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      // Generate AI response using Gemini
      _aiResponse = await _voiceCoach.generateReply(
        _transcription,
        isEnglish: widget.isEnglish,
      );

      if (!mounted) return;

      // Check if response is an error message (contains "failed", "error", "request", "not configured")
      final isErrorResponse = _aiResponse.contains('failed') || 
                              _aiResponse.contains('error') ||
                              _aiResponse.contains('Error') ||
                              _aiResponse.contains('not configured') ||
                              _aiResponse.contains('Request');
      
      if (_aiResponse.isEmpty) {
        _showErrorSnackBar(
          widget.isEnglish 
            ? 'No response received' 
            : 'Không nhận được phản hồi'
        );
        if (mounted) {
          setState(() => _state = VoiceState.listening);
          await _startListening();
        }
        return;
      }

      // If Gemini failed, try Vercel fallback API
      if (isErrorResponse) {
        print('⚠️ Gemini API failed, trying Vercel fallback API...');
        await _callVercelFallbackAPI();
        return;
      }

      // Notify parent and close
      if (mounted) {
        setState(() => _state = VoiceState.replying);
        await widget.onMessageProcessed(_transcription, _aiResponse);

        // Wait a moment before closing
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _closeDialog();
        }
      }
    } catch (e) {
      print('❌ Processing error: $e');
      if (mounted) {
        _showErrorSnackBar(
          widget.isEnglish 
            ? 'Processing failed, trying fallback API...' 
            : 'Xử lý thất bại, thử API dự phòng...'
        );
        // Try Vercel fallback API
        await _callVercelFallbackAPI();
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Fallback API using Vercel endpoint
  Future<void> _callVercelFallbackAPI() async {
    if (!mounted) return;

    try {
      final url = Uri.parse('https://flutter-learning-en-app.vercel.app/api/chat');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': _transcription,
          'systemPrompt': 'You are PUPU AI, a virtual English learning assistant for Vietnamese users. Be friendly, helpful, and encouraging. Keep responses concise (2-3 sentences) for voice interaction.',
        }),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _aiResponse = responseData['response'] ?? 'Unable to get response';

        if (_aiResponse.isEmpty || _aiResponse.contains('error')) {
          _showErrorSnackBar(
            widget.isEnglish 
              ? 'Fallback API failed' 
              : 'API dự phòng thất bại'
          );
          _closeDialog();
          return;
        }

        print('✅ Fallback API response: $_aiResponse');

        if (mounted) {
          setState(() => _state = VoiceState.replying);
          await widget.onMessageProcessed(_transcription, _aiResponse);

          // Wait a moment before closing
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            _closeDialog();
          }
        }
      } else {
        print('❌ Fallback API error: ${response.statusCode}');
        _showErrorSnackBar(
          widget.isEnglish 
            ? 'Both APIs failed. Please try again.' 
            : 'Cả hai API đều thất bại. Vui lòng thử lại.'
        );
        _closeDialog();
      }
    } catch (e) {
      print('❌ Fallback API exception: $e');
      if (mounted) {
        _showErrorSnackBar(
          widget.isEnglish 
            ? 'Connection error: $e' 
            : 'Lỗi kết nối: $e'
        );
        _closeDialog();
      }
    }
  }

  void _closeDialog() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // State-specific UI
            if (_state == VoiceState.listening)
              _buildListeningUI()
            else if (_state == VoiceState.thinking)
              _buildThinkingUI()
            else if (_state == VoiceState.replying)
              _buildReplyingUI(),
          ],
        ),
      ),
    );
  }

  /// Listening UI - shows waveform animation
  Widget _buildListeningUI() {
    return Column(
      children: [
        // Animated waveform
        ScaleTransition(
          scale: Tween<double>(begin: 0.7, end: 1.2).animate(
            CurvedAnimation(parent: _recordingAnimationController, curve: Curves.easeInOut),
          ),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.1),
            ),
            child: Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.mic,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          widget.isEnglish ? 'Listening...' : 'Đang lắng nghe...',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          widget.isEnglish 
            ? 'Speak now, device-native recognition' 
            : 'Nói đi, nhận dạng trên thiết bị',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 24),

        // Cancel button
        GestureDetector(
          onTap: _closeDialog,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  /// Thinking UI - shows pulsing dots
  Widget _buildThinkingUI() {
    return Column(
      children: [
        // Pulsing circle
        ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.1).animate(
            CurvedAnimation(parent: _thinkingAnimationController, curve: Curves.easeInOut),
          ),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryColor.withOpacity(0.1),
            ),
            child: Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryColor.withOpacity(0.2),
                ),
                child: Center(
                  child: Icon(
                    Icons.auto_awesome,
                    color: AppColors.primaryColor,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          widget.isEnglish ? 'Processing...' : 'Đang xử lý...',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),

        // Pulsing dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.2).animate(
                  CurvedAnimation(
                    parent: _thinkingAnimationController,
                    curve: Interval(
                      index * 0.33,
                      (index + 1) * 0.33,
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Replying UI - success state
  Widget _buildReplyingUI() {
    return Column(
      children: [
        // Success icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withOpacity(0.1),
          ),
          child: const Center(
            child: Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          widget.isEnglish ? 'Done!' : 'Hoàn tất!',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          widget.isEnglish 
            ? 'Your message has been processed' 
            : 'Tin nhắn của bạn đã được xử lý',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

/// Helper widget for Walkie-Talkie voice button
class VoiceInteractionButton extends StatelessWidget {
  final bool isEnglish;
  final OnVoiceMessageProcessed onMessageProcessed;
  final String? apiKey;

  const VoiceInteractionButton({
    Key? key,
    required this.isEnglish,
    required this.onMessageProcessed,
    this.apiKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => VoiceInteractionOverlay(
            isEnglish: isEnglish,
            onMessageProcessed: onMessageProcessed,
            initialApiKey: apiKey,
          ),
        );
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryColor,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.mic,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

