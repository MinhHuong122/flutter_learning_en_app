import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/dictionary_model.dart';
import 'supabase_dictionary_service.dart';

class OcrService {
  // TODO: Replace with your actual backend OCR API endpoint
  // This should be a Python backend running DeepSeek OCR
  static const String _baseUrl = 'http://your-backend-url.com/api';
  
  final SupabaseDictionaryService _dictionaryService = SupabaseDictionaryService();

  /// Extract vocabulary from image using OCR
  /// This method sends the image to your backend OCR service (DeepSeek OCR)
  /// and receives extracted text, then matches it with dictionary
  Future<List<DictionaryEntry>> extractVocabulary(String imagePath) async {
    try {
      // Method 1: Call actual OCR backend (recommended for production)
      // return await _callOcrBackend(imagePath);

      // Method 2: Mock data for testing (current implementation)
      return await _mockOcrExtraction(imagePath);
    } catch (e) {
      print('❌ Error in OCR extraction: $e');
      rethrow;
    }
  }

  /// Call your backend OCR API (DeepSeek OCR)
  /// Uncomment and modify this when you have backend ready
  Future<List<DictionaryEntry>> _callOcrBackend(String imagePath) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/ocr/extract'),
      );

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('image', imagePath),
      );

      // Send request
      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200) {
        // Parse response
        final jsonResponse = json.decode(responseString);
        final words = jsonResponse['words'] as List<dynamic>;

        // Match with dictionary
        List<DictionaryEntry> vocabularyList = [];

        for (var word in words) {
          final wordText = word['text'] as String;
          
          // Search in English dictionary
          final searchResults = await _dictionaryService.searchEnglish(wordText, limit: 1);
          
          if (searchResults.isNotEmpty) {
            vocabularyList.add(searchResults.first);
          }
        }

        return vocabularyList;
      } else {
        throw Exception('OCR API error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error calling OCR backend: $e');
      throw Exception('Failed to process image with OCR');
    }
  }

  /// Mock OCR extraction for testing
  /// This simulates OCR extraction without actual backend
  /// Replace this with _callOcrBackend when you have backend ready
  Future<List<DictionaryEntry>> _mockOcrExtraction(String imagePath) async {
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock extracted words - in real scenario, these come from OCR
    final mockWords = [
      'apple',
      'banana',
      'computer',
      'book',
      'study',
      'learn',
      'teach',
      'write',
      'read',
      'hello',
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
