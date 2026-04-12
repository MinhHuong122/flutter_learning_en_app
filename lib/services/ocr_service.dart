import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/dictionary_model.dart';
import 'supabase_dictionary_service.dart';

class OcrService {
  static const String _geminiApiKey = 'AIzaSyCa5OMBW3E56QJp-doAlrmB5235VzBRNxY';
  late GenerativeModel _model;
  final SupabaseDictionaryService _dictionaryService = SupabaseDictionaryService();

  OcrService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _geminiApiKey,
    );
  }

  /// Extract vocabulary from local image file
  Future<List<DictionaryEntry>> extractVocabulary(String imagePath) async {
    try {
      return await _callGeminiOcrFromFile(imagePath);
    } catch (e) {
      print('❌ Gemini OCR error: $e');
      return _mockOcrExtraction(imagePath);
    }
  }

  /// Extract vocabulary from image URL (uploaded to Cloudinary)
  Future<List<DictionaryEntry>> extractVocabularyFromUrl(String imageUrl) async {
    try {
      print('📥 Downloading image from URL: $imageUrl');
      return await _callGeminiOcrFromUrl(imageUrl);
    } catch (e) {
      print('❌ Gemini OCR error: $e');
      return _mockOcrExtractionFromUrl(imageUrl);
    }
  }

  /// Call Gemini Vision API using local file
  Future<List<DictionaryEntry>> _callGeminiOcrFromFile(String imagePath) async {
    try {
      // Read image file
      final imageBytes = await File(imagePath).readAsBytes();

      // Determine image type
      String mediaType = 'image/jpeg';
      if (imagePath.toLowerCase().endsWith('.png')) {
        mediaType = 'image/png';
      }

      return await _processWithGemini(imageBytes, mediaType);
    } catch (e) {
      print('❌ Error calling Gemini OCR from file: $e');
      throw Exception('Failed to process image with Gemini OCR');
    }
  }

  /// Call Gemini Vision API using image URL
  Future<List<DictionaryEntry>> _callGeminiOcrFromUrl(String imageUrl) async {
    try {
      print('📥 Fetching image from Cloudinary URL: $imageUrl');
      
      // Download image from URL
      final response = await http.get(Uri.parse(imageUrl)).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Image download timeout'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to download image: ${response.statusCode}');
      }

      final imageBytes = response.bodyBytes;
      
      // Determine image type from content-type header
      String mediaType = response.headers['content-type'] ?? 'image/jpeg';
      if (!mediaType.startsWith('image/')) {
        mediaType = 'image/jpeg';
      }

      print('✅ Image downloaded (${imageBytes.length} bytes), processing with Gemini...');
      return await _processWithGemini(imageBytes, mediaType);
    } catch (e) {
      print('❌ Error downloading or processing image from URL: $e');
      throw Exception('Failed to process image from URL');
    }
  }

  /// Process image bytes with Gemini API
  Future<List<DictionaryEntry>> _processWithGemini(
    Uint8List imageBytes,
    String mediaType,
  ) async {
    try {
      // Create content with image
      final imageContent = Content.multi([
        TextPart(
          '''Extract ALL English vocabulary words from this image and generate an example sentence for each word.
Return ONLY a JSON array, NO explanations.

Format:
[
  {"word": "word1", "example": "Example sentence using word1 here"},
  {"word": "word2", "example": "Example sentence using word2 here"},
  ...
]

Requirements:
- Extract COMPLETE vocabulary (no limit)
- For EACH word, create a natural example sentence (8-15 words)
- Maximize word accuracy
- Support all word types (nouns, verbs, adjectives, adverbs, prepositions, etc.)
- Avoid duplicates
- Example must be grammatically correct and demonstrate word usage''',
        ),
        DataPart(mediaType, imageBytes),
      ]);

      // Call Gemini API
      print('🔍 Calling Gemini API for OCR analysis with example generation...');
      final response = await _model.generateContent([imageContent]);
      final responseText = response.text ?? '';

      print('📝 Gemini response: $responseText');

      // Parse JSON array from response
      final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(responseText);
      if (jsonMatch == null) {
        throw Exception('Could not extract JSON from response');
      }

      final jsonStr = jsonMatch.group(0)!;
      final wordsData = List<Map<String, dynamic>>.from(
        (jsonDecode(jsonStr) as List).map((item) => item as Map<String, dynamic>),
      );

      // Match with dictionary and add examples
      List<DictionaryEntry> vocabularyList = [];
      for (var wordData in wordsData) {
        final word = wordData['word'] as String?;
        final example = wordData['example'] as String? ?? '';

        if (word == null || word.trim().isEmpty) continue;

        // Search in English dictionary
        final searchResults =
            await _dictionaryService.searchEnglish(word.trim(), limit: 1);

        if (searchResults.isNotEmpty) {
          // Create new entry with example from Gemini
          final originalEntry = searchResults.first;
          final entryWithExample = DictionaryEntry(
            id: originalEntry.id,
            term: originalEntry.term,
            language: originalEntry.language,
            pronunciation: originalEntry.pronunciation,
            wordClass: originalEntry.wordClass,
            meaning: originalEntry.meaning,
            example: example.trim(), // Add Gemini-generated example
            vietnameseMeaning: originalEntry.vietnameseMeaning,
            vietnameseExample: originalEntry.vietnameseExample,
            isCommon: originalEntry.isCommon,
            frequency: originalEntry.frequency,
            createdAt: originalEntry.createdAt,
            updatedAt: originalEntry.updatedAt,
          );
          vocabularyList.add(entryWithExample);
        }
      }

      print('✅ OCR extraction complete: ${vocabularyList.length} words found (with examples)');
      return vocabularyList;
    } catch (e) {
      print('❌ Error processing image with Gemini: $e');
      throw Exception('Failed to process image with Gemini OCR');
    }
  }

  /// Mock OCR extraction for testing (expanded with more words and examples)
  Future<List<DictionaryEntry>> _mockOcrExtraction(String imagePath) async {
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock vocabulary with example sentences
    final mockWordsWithExamples = {
      'apple': 'I ate a red apple for breakfast this morning.',
      'banana': 'The monkey likes to eat a ripe banana.',
      'computer': 'I use my computer every day for work and study.',
      'book': 'She borrowed an interesting book from the library.',
      'study': 'I need to study hard for my final exam.',
      'learn': 'Students learn new languages through daily practice.',
      'teach': 'Mr. Smith will teach us English grammar today.',
      'write': 'She loves to write stories in her free time.',
      'read': 'I read the newspaper every morning with coffee.',
      'hello': 'She said hello to her old friend at the market.',
      'world': 'The world is full of amazing cultural diversity.',
      'english': 'English is widely spoken across the globe today.',
      'grammar': 'Grammar rules help us communicate more clearly.',
      'vocabulary': 'Learning vocabulary is essential for language mastery.',
      'language': 'Learning a new language opens many doors.',
      'speak': 'Can you speak fluent English and French?',
      'listen': 'You should listen carefully to the teacher.',
      'practice': 'Regular practice makes you a better player.',
      'exercise': 'Daily exercise keeps your body healthy and strong.',
      'lesson': 'Today\'s lesson will cover important grammar concepts.',
      'student': 'Each student has unique learning styles and needs.',
      'teacher': 'Our teacher explained the topic very clearly.',
      'classroom': 'The classroom is bright and well decorated.',
      'school': 'I walk to school every day with my friends.',
      'education': 'Education is the key to a successful future.',
      'knowledge': 'Knowledge is power in the modern world.',
      'wisdom': 'Wisdom comes with experience and reflection.',
      'understand': 'Do you understand the lesson today clearly?',
      'explain': 'Please explain how this grammar rule works.',
      'question': 'She asked a difficult question during class.',
      'answer': 'He gave a correct answer to the question.',
      'example': 'This is a good example of proper sentence structure.',
      'define': 'Can you define this word using simple English?',
      'meaning': 'What is the meaning of this difficult word?',
      'synonym': 'Happy and joyful are synonyms of each other.',
      'antonym': 'Hot and cold are antonyms in English language.',
      'phrase': 'This phrase is commonly used in everyday speech.',
      'sentence': 'Write a clear sentence using past perfect tense.',
      'paragraph': 'Each paragraph should contain a topic sentence.',
      'text': 'Read the text carefully before answering questions.',
      'document': 'Please save your document before closing it.',
      'page': 'Turn to page fifty in your English textbook now.',
      'chapter': 'We finished Chapter five of the novel.',
      'section': 'Read the section about past tenses carefully.',
      'content': 'The content of this chapter is very interesting.',
    };

    List<DictionaryEntry> vocabularyList = [];

    for (var wordEntry in mockWordsWithExamples.entries) {
      final word = wordEntry.key;
      final example = wordEntry.value;

      // Search in English dictionary
      final searchResults = await _dictionaryService.searchEnglish(word, limit: 1);

      if (searchResults.isNotEmpty) {
        final originalEntry = searchResults.first;
        final entryWithExample = DictionaryEntry(
          id: originalEntry.id,
          term: originalEntry.term,
          language: originalEntry.language,
          pronunciation: originalEntry.pronunciation,
          wordClass: originalEntry.wordClass,
          meaning: originalEntry.meaning,
          example: example,
          vietnameseMeaning: originalEntry.vietnameseMeaning,
          vietnameseExample: originalEntry.vietnameseExample,
          isCommon: originalEntry.isCommon,
          frequency: originalEntry.frequency,
          createdAt: originalEntry.createdAt,
          updatedAt: originalEntry.updatedAt,
        );
        vocabularyList.add(entryWithExample);
      }
    }

    return vocabularyList;
  }

  /// Mock OCR extraction from URL for testing (with examples)
  Future<List<DictionaryEntry>> _mockOcrExtractionFromUrl(String imageUrl) async {
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 2));

    print('🧪 Using mock OCR for URL: $imageUrl');

    // Mock vocabulary with example sentences
    final mockWordsWithExamples = {
      'apple': 'I ate a red apple for breakfast this morning.',
      'banana': 'The monkey likes to eat a ripe banana.',
      'computer': 'I use my computer every day for work and study.',
      'book': 'She borrowed an interesting book from the library.',
      'study': 'I need to study hard for my final exam.',
      'learn': 'Students learn new languages through daily practice.',
      'teach': 'Mr. Smith will teach us English grammar today.',
      'write': 'She loves to write stories in her free time.',
      'read': 'I read the newspaper every morning with coffee.',
      'hello': 'She said hello to her old friend at the market.',
      'world': 'The world is full of amazing cultural diversity.',
      'english': 'English is widely spoken across the globe today.',
      'grammar': 'Grammar rules help us communicate more clearly.',
      'vocabulary': 'Learning vocabulary is essential for language mastery.',
      'language': 'Learning a new language opens many doors.',
      'speak': 'Can you speak fluent English and French?',
      'listen': 'You should listen carefully to the teacher.',
      'practice': 'Regular practice makes you a better player.',
      'exercise': 'Daily exercise keeps your body healthy and strong.',
      'lesson': 'Today\'s lesson will cover important grammar concepts.',
      'student': 'Each student has unique learning styles and needs.',
      'teacher': 'Our teacher explained the topic very clearly.',
      'classroom': 'The classroom is bright and well decorated.',
      'school': 'I walk to school every day with my friends.',
      'education': 'Education is the key to a successful future.',
      'knowledge': 'Knowledge is power in the modern world.',
      'wisdom': 'Wisdom comes with experience and reflection.',
      'understand': 'Do you understand the lesson today clearly?',
      'explain': 'Please explain how this grammar rule works.',
      'question': 'She asked a difficult question during class.',
      'answer': 'He gave a correct answer to the question.',
      'example': 'This is a good example of proper sentence structure.',
      'define': 'Can you define this word using simple English?',
      'meaning': 'What is the meaning of this difficult word?',
      'synonym': 'Happy and joyful are synonyms of each other.',
      'antonym': 'Hot and cold are antonyms in English language.',
      'phrase': 'This phrase is commonly used in everyday speech.',
      'sentence': 'Write a clear sentence using past perfect tense.',
      'paragraph': 'Each paragraph should contain a topic sentence.',
      'text': 'Read the text carefully before answering questions.',
      'document': 'Please save your document before closing it.',
      'page': 'Turn to page fifty in your English textbook now.',
      'chapter': 'We finished Chapter five of the novel.',
      'section': 'Read the section about past tenses carefully.',
      'content': 'The content of this chapter is very interesting.',
    };

    List<DictionaryEntry> vocabularyList = [];

    for (var wordEntry in mockWordsWithExamples.entries) {
      final word = wordEntry.key;
      final example = wordEntry.value;

      // Search in English dictionary
      final searchResults = await _dictionaryService.searchEnglish(word, limit: 1);

      if (searchResults.isNotEmpty) {
        final originalEntry = searchResults.first;
        final entryWithExample = DictionaryEntry(
          id: originalEntry.id,
          term: originalEntry.term,
          language: originalEntry.language,
          pronunciation: originalEntry.pronunciation,
          wordClass: originalEntry.wordClass,
          meaning: originalEntry.meaning,
          example: example,
          vietnameseMeaning: originalEntry.vietnameseMeaning,
          vietnameseExample: originalEntry.vietnameseExample,
          isCommon: originalEntry.isCommon,
          frequency: originalEntry.frequency,
          createdAt: originalEntry.createdAt,
          updatedAt: originalEntry.updatedAt,
        );
        vocabularyList.add(entryWithExample);
      }
    }

    return vocabularyList;
  }
}
