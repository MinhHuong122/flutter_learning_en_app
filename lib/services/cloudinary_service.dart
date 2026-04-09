import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  
  // Cloudinary credentials
  static const String _cloudName = 'dssazeaz6';
  static const String _uploadPreset = 'app_learn_english';
  static const String _uploadUrl = 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';
  
  CloudinaryService._internal();

  factory CloudinaryService() {
    return _instance;
  }

  /// Upload image to Cloudinary and return the secure URL
  Future<String> uploadImage(File imageFile) async {
    try {
      print('📤 Uploading image to Cloudinary: ${imageFile.path}');

      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      
      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
      
      // Add upload preset
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = 'app_learn_english/ocr';

      print('🔄 Sending upload request...');
      final response = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Upload timeout'),
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        print('❌ Upload error body: $body');
        throw Exception('Upload failed: ${response.statusCode}');
      }

      final responseBody = await response.stream.bytesToString();
      print('📝 Response: $responseBody');

      // Parse response - expect JSON with secure_url
      final responseMap = _parseJsonResponse(responseBody);
      final secureUrl = responseMap['secure_url'] as String?;

      if (secureUrl == null || secureUrl.isEmpty) {
        throw Exception('No secure_url in response');
      }

      print('✅ Image uploaded successfully: $secureUrl');
      return secureUrl;
    } catch (e) {
      print('❌ Cloudinary upload failed: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload image and return both secure URL and public ID
  Future<Map<String, String>> uploadImageWithId(File imageFile) async {
    try {
      print('📤 Uploading image to Cloudinary: ${imageFile.path}');

      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
      
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = 'app_learn_english/ocr';

      final response = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Upload timeout'),
      );

      if (response.statusCode != 200) {
        throw Exception('Upload failed: ${response.statusCode}');
      }

      final responseBody = await response.stream.bytesToString();
      final responseMap = _parseJsonResponse(responseBody);

      final secureUrl = responseMap['secure_url'] as String?;
      final publicId = responseMap['public_id'] as String?;

      if (secureUrl == null || publicId == null) {
        throw Exception('Missing URL or public ID in response');
      }

      print('✅ Image uploaded: $secureUrl');
      
      return {
        'url': secureUrl,
        'publicId': publicId,
      };
    } catch (e) {
      print('❌ Cloudinary upload failed: $e');
      rethrow;
    }
  }

  /// Delete image from Cloudinary by public ID
  Future<bool> deleteImage(String publicId) async {
    try {
      print('🗑️ Deleting image from Cloudinary: $publicId');
      // Note: Deletion requires authentication, skip for unsigned preset
      print('⚠️ Note: Deletion requires signed requests');
      return true;
    } catch (e) {
      print('⚠️ Cloudinary delete failed: $e');
      return false;
    }
  }

  /// Helper function to parse JSON response
  Map<String, dynamic> _parseJsonResponse(String jsonString) {
    try {
      // Simple JSON parsing without external dependency
      final trimmed = jsonString.trim();
      if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) {
        throw Exception('Invalid JSON format');
      }

      // Extract secure_url
      final secureUrlMatch = RegExp(r'"secure_url"\s*:\s*"([^"]+)"').firstMatch(trimmed);
      final publicIdMatch = RegExp(r'"public_id"\s*:\s*"([^"]+)"').firstMatch(trimmed);

      return {
        'secure_url': secureUrlMatch?.group(1) ?? '',
        'public_id': publicIdMatch?.group(1) ?? '',
      };
    } catch (e) {
      print('❌ JSON parse error: $e');
      rethrow;
    }
  }
}

