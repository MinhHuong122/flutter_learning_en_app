#!/usr/bin/env python3
# Script to update chat_ai_screen.dart with translation support

file_path = r"d:\DHV\Year4\Semester2\DoAn\app_learn_english\lib\screens\chat_ai_screen.dart"

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Find and replace the systemPrompt - simpler one
old_segment = """'systemPrompt': 'You are PUPU AI, a virtual English learning assistant for Vietnamese users. Your main tasks are:"""
new_segment = """'systemPrompt': 'You are PUPU AI, an English learning assistant. Help users improve by correcting grammar, sentence structure, word usage, and offering helpful explanations. Respond in clear"""

if old_segment in content:
    content = content.replace(old_segment, new_segment)
    print("✅ Updated system prompt")

# Replace the try-catch block that parses JSON
old_block = """        try {
          // Parse JSON response containing both English and Vietnamese
          final jsonResponse = jsonDecode(apiResponse);
          String aiResponseEn = jsonResponse['english'] ?? 'Unable to get response';
          String aiResponseVi = jsonResponse['vietnamese'] ?? 'Không thể nhận được phản hồi';

          aiResponseEn = _cleanMarkdown(aiResponseEn);
          aiResponseVi = _cleanMarkdown(aiResponseVi);
          
          print('✅ AI Response (EN): $aiResponseEn');
          print('✅ AI Response (VI): $aiResponseVi');

          if (mounted) {
            setState(() {
              _addMessage(aiResponseEn, aiResponseVi, isUser: false);
              _isTyping = false;
            });
          }
        } catch (e) {
          print('Error parsing AI response: $e');
          // Fallback to treating entire response as English
          if (mounted) {
            setState(() {
              _addMessage(apiResponse, apiResponse, isUser: false);
              _isTyping = false;
            });
          }
        }"""

new_block = """        // Treat response as plain English text
        String aiResponseEn = apiResponse;
        aiResponseEn = _cleanMarkdown(aiResponseEn);
        print('✅ AI Response (EN): $aiResponseEn');
        
        // Get Vietnamese translation
        final aiResponseVi = await _translateToVietnamese(aiResponseEn);
        print('✅ AI Response (VI):  $aiResponseVi');

        if (mounted) {
          setState(() {
            _addMessage(aiResponseEn, aiResponseVi, isUser: false);
            _isTyping = false;
          });
        }"""

if old_block in content:
    content = content.replace(old_block, new_block)
    print("✅ Updated response handling")

# Add translation method
translate_method = '''

  Future<String> _translateToVietnamese(String text) async {
    if (text.isEmpty) return text;
    try {
      final encoded = Uri.encodeComponent(text);
      final url = Uri.parse('https://api.mymemory.translated.net/get?q=' + encoded + '&langpair=en|vi');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['responseStatus'] == 200) {
          return data['responseData']['translatedText'] as String;
        }
      }
    } catch (e) {
      print('Translation error: $e');
    }
    return text;
  }'''

# Find position to insert translation method - after _formatTime
pos = content.find("return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';")
if pos > 0:
    # Find next method start
    next_method_pos = content.find("\n  void _onBottomNavTap", pos)
    if next_method_pos > 0:
        content = content[:next_method_pos] + translate_method + content[next_method_pos:]
        print("✅ Added translation method")

# Write back
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ File updated successfully!")
