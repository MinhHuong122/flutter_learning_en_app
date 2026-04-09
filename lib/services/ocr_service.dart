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
          '''Extract ALL English vocabulary words from this image carefully and accurately.
Include every word you can find. Return ONLY a JSON array, NO explanations.
Format: ["word1", "word2", "word3", ...]
Requirements:
- Extract COMPLETE vocabulary (no limit)
- Maximize word accuracy
- Support all word types (nouns, verbs, adjectives, adverbs, prepositions, etc.)
- Avoid duplicates''',
        ),
        DataPart(mediaType, imageBytes),
      ]);

      // Call Gemini API
      print('🔍 Calling Gemini API for OCR analysis...');
      final response = await _model.generateContent([imageContent]);
      final responseText = response.text ?? '';

      print('📝 Gemini response: $responseText');

      // Parse JSON array from response
      final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(responseText);
      if (jsonMatch == null) {
        throw Exception('Could not extract JSON from response');
      }

      final jsonStr = jsonMatch.group(0)!;
      final wordsList = List<String>.from(jsonDecode(jsonStr) as List);

        // Match with dictionary
        List<DictionaryEntry> vocabularyList = [];
      for (var word in wordsList) {
        if (word.trim().isEmpty) continue;
          
          // Search in English dictionary
        final searchResults =
            await _dictionaryService.searchEnglish(word.trim(), limit: 1);
          
          if (searchResults.isNotEmpty) {
            vocabularyList.add(searchResults.first);
          }
        }

      print('✅ OCR extraction complete: ${vocabularyList.length} words found');
      return vocabularyList;
    } catch (e) {
      print('❌ Error processing image with Gemini: $e');
      throw Exception('Failed to process image with Gemini OCR');
    }
  }

  /// Mock OCR extraction for testing (expanded with more words)
  Future<List<DictionaryEntry>> _mockOcrExtraction(String imagePath) async {
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Extended mock vocabulary list
    final mockWords = [
      'apple', 'banana', 'computer', 'book', 'study',
      'learn', 'teach', 'write', 'read', 'hello',
      'world', 'english', 'grammar', 'vocabulary', 'language',
      'speak', 'listen', 'practice', 'exercise', 'lesson',
      'student', 'teacher', 'classroom', 'school', 'education',
      'knowledge', 'wisdom', 'understand', 'explain', 'question',
      'answer', 'example', 'define', 'meaning', 'synonym',
      'antonym', 'phrase', 'sentence', 'paragraph', 'text',
      'document', 'page', 'chapter', 'section', 'content',
    ];

    List<DictionaryEntry> vocabularyList = [];

    for (var word in mockWords) {
      // Search in English dictionary
      final searchResults = await _dictionaryService.searchEnglish(word, limit: 1);
      
      if (searchResults.isNotEmpty) {
        vocabularyList.add(searchResults.first);
      }
    }

    return vocabularyList;
  }

  /// Mock OCR extraction from URL for testing
  Future<List<DictionaryEntry>> _mockOcrExtractionFromUrl(String imageUrl) async {
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 2));

    print('🧪 Using mock OCR for URL: $imageUrl');
    
    // Extended mock vocabulary list
    final mockWords = [
      'apple', 'banana', 'computer', 'book', 'study',
      'learn', 'teach', 'write', 'read', 'hello',
      'world', 'english', 'grammar', 'vocabulary', 'language',
      'speak', 'listen', 'practice', 'exercise', 'lesson',
      'student', 'teacher', 'classroom', 'school', 'education',
      'knowledge', 'wisdom', 'understand', 'explain', 'question',
      'answer', 'example', 'define', 'meaning', 'synonym',
      'antonym', 'phrase', 'sentence', 'paragraph', 'text',
      'document', 'page', 'chapter', 'section', 'content',
    ];

    List<DictionaryEntry> vocabularyList = [];

    for (var word in mockWords) {
      // Search in English dictionary
      final searchResults = await _dictionaryService.searchEnglish(word, limit: 1);
      
      if (searchResults.isNotEmpty) {
        vocabularyList.add(searchResults.first);
      }
    }

    return vocabularyList;
  }
}
