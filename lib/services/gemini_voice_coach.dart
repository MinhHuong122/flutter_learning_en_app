import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiVoiceCoach {
  static const String _defaultModel = 'gemini-2.0-flash-exp';
  // Replace with your actual API key or use environment variable
  static const String _defaultApiKey = 'AIzaSyC2VellUpFjq-iFqpAi3ey4OVsqqcn5O3o';

  final String apiKey;
  final String model;

  GeminiVoiceCoach({String? apiKey, String? model})
      : apiKey = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY', defaultValue: _defaultApiKey),
        model = model ?? _defaultModel;

  Future<String> processVoice(File audioFile, {bool isEnglish = true}) async {
    if (apiKey.isEmpty) {
      return isEnglish
          ? 'Voice AI is not configured. Please set GEMINI_API_KEY.'
          : 'Chưa cấu hình Voice AI. Vui lòng thiết lập GEMINI_API_KEY.';
    }

    try {
      final bytes = await audioFile.readAsBytes();
      final mimeType = _detectMimeType(audioFile.path);

      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

      final body = {
        'contents': [
          {
            'parts': [
              {
                'text': '''
Bạn là giáo viên tiếng Anh thân thiện chuyên giúp người Việt sửa lỗi.

Hãy nghe audio người dùng nói và phân tích theo cấu trúc sau (trả lời bằng tiếng Việt):

1. Câu gốc: [transcript]
2. Câu sửa đúng: [câu đã sửa ngữ pháp và phát âm]
3. Lỗi phát hiện:
   - Ngữ pháp: ...
   - Phát âm: ... (ví dụ: phát âm /θ/ thành /s/, nhấn sai âm tiết, nói quá nhanh...)
4. Giải thích dễ hiểu:
5. Cách luyện tập: Gợi ý ngắn gọn 1-2 cách.

Giọng điệu khích lệ, không phê bình.
'''
              },
              {
                'inlineData': {
                  'mimeType': mimeType,
                  'data': base64Encode(bytes),
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 800,
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates == null || candidates.isEmpty) {
          return isEnglish
              ? 'No response from voice model.'
              : 'Không nhận được phản hồi từ mô hình giọng nói.';
        }

        final content = candidates.first['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        final text = (parts != null && parts.isNotEmpty)
            ? (parts.first['text']?.toString() ?? '')
            : '';

        return text.isEmpty
            ? (isEnglish
                ? 'No response from voice model.'
                : 'Không nhận được phản hồi từ mô hình giọng nói.')
            : text;
      }

      return isEnglish
          ? 'Voice request failed (${response.statusCode}).'
          : 'Yêu cầu giọng nói thất bại (${response.statusCode}).';
    } catch (e) {
      return isEnglish
          ? 'Voice processing error: $e'
          : 'Lỗi xử lý giọng nói: $e';
    }
  }

  /// Transcribe audio to text using Google Speech-to-Text API
  Future<String> transcribeAudio(File audioFile, {bool isEnglish = true}) async {
    if (apiKey.isEmpty) {
      return isEnglish
          ? 'Voice AI is not configured. Please set GEMINI_API_KEY.'
          : 'Chưa cấu hình Voice AI. Vui lòng thiết lập GEMINI_API_KEY.';
    }

    try {
      final bytes = await audioFile.readAsBytes();
      final base64Audio = base64Encode(bytes);

      // Using Google Speech-to-Text API
      final url =
          'https://speech.googleapis.com/v1/speech:recognize?key=$apiKey';

      final body = {
        'config': {
          'encoding': 'LINEAR16',  // WAV format (PCM 16-bit)
          'languageCode': isEnglish ? 'en-US' : 'vi-VN',
          'sampleRateHertz': 16000,
          'audioChannelCount': 1,
        },
        'audio': {
          'content': base64Audio,
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>?;
        
        if (results == null || results.isEmpty) {
          return isEnglish ? 'No speech detected.' : 'Không phát hiện được tiếng nói.';
        }

        final transcription = StringBuffer();
        for (final result in results) {
          final alternatives = result['alternatives'] as List<dynamic>?;
          if (alternatives != null && alternatives.isNotEmpty) {
            transcription.write(alternatives.first['transcript'] ?? '');
            transcription.write(' ');
          }
        }

        final text = transcription.toString().trim();
        return text.isEmpty ? 'No speech detected.' : text;
      } else if (response.statusCode == 400) {
        print('❌ Bad request: ${response.body}');
        return isEnglish ? 'Invalid audio format.' : 'Định dạng âm thanh không hợp lệ.';
      } else {
        print('❌ API error (${response.statusCode}): ${response.body}');
        return isEnglish 
            ? 'Transcription failed (${response.statusCode}).'
            : 'Sao chép âm thanh thất bại (${response.statusCode}).';
      }
    } catch (e) {
      print('❌ Transcription error: $e');
      return isEnglish ? 'Transcription error: $e' : 'Lỗi sao chép: $e';
    }
  }

  /// Generate AI response to user message via Gemini API
  Future<String> generateReply(String userMessage, {bool isEnglish = true}) async {
    if (apiKey.isEmpty) {
      return isEnglish
          ? 'Voice AI is not configured. Please set GEMINI_API_KEY.'
          : 'Chưa cấu hình Voice AI. Vui lòng thiết lập GEMINI_API_KEY.';
    }

    try {
      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

      final systemPrompt = '''You are PUPU AI, a virtual English learning assistant for Vietnamese users. Your main tasks are:
1. Help users improve their English skills
2. Correct grammar and word usage mistakes when users make them
3. Provide clear explanations and helpful feedback
4. Suggest better ways to express ideas
5. Explain vocabulary, grammar rules, and pronunciation when asked
6. Be encouraging and supportive
7. Ask follow-up questions to help users learn better

Always be friendly, patient, and focus on helping users learn English effectively. Respond naturally in English, keeping responses concise for voice interaction (2-3 sentences max when replying to voice input).''';

      final body = {
        'contents': [
          {
            'parts': [
              {'text': systemPrompt},
              {'text': userMessage}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 200,
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates == null || candidates.isEmpty) {
          return isEnglish ? 'No response from AI.' : 'Không nhận được phản hồi từ AI.';
        }

        final content = candidates.first['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        final text = (parts != null && parts.isNotEmpty)
            ? (parts.first['text']?.toString() ?? '')
            : '';

        return text.isEmpty ? 'No response.' : text.trim();
      }

      return 'Request failed (${response.statusCode}).';
    } catch (e) {
      print('❌ Reply generation error: $e');
      return isEnglish ? 'Error generating reply: $e' : 'Lỗi tạo phản hồi: $e';
    }
  }

  String _detectMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.m4a')) return 'audio/mp4';
    if (lower.endsWith('.aac')) return 'audio/aac';
    return 'audio/wav';
  }
}
