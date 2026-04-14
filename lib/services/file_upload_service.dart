import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'cloudinary_service.dart';

class FileUploadService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  static const List<String> allowedImageTypes = ['image/jpeg', 'image/png', 'image/gif'];
  static const List<String> allowedFileTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  ];

  final ImagePicker _imagePicker = ImagePicker();

  // ==================== IMAGE UPLOAD ====================

  /// Chọn ảnh từ camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final photo = await _imagePicker.pickImage(source: ImageSource.camera);
      return photo;
    } catch (e) {
      throw Exception('Lỗi chụp ảnh: $e');
    }
  }

  /// Chọn ảnh từ gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final photo = await _imagePicker.pickImage(source: ImageSource.gallery);
      return photo;
    } catch (e) {
      throw Exception('Lỗi chọn ảnh: $e');
    }
  }

  /// Upload ảnh lên Cloudinary
  Future<String> uploadImage(
    XFile imageFile, {
    required String userId,
    required String folderName, // 'posts', 'profiles', etc.
    void Function(int, int)? onProgress,
  }) async {
    try {
      final file = File(imageFile.path);

      if (!await file.exists()) {
        throw Exception('File không tồn tại');
      }

      final fileSize = await file.length();
      if (fileSize > maxFileSize) {
        throw Exception('File quá lớn (tối đa 50MB)');
      }

      // Upload to Cloudinary
      final imageUrl = await _cloudinaryService.uploadImage(file);
      return imageUrl;
    } catch (e) {
      throw Exception('Lỗi upload ảnh: $e');
    }
  }

  // ==================== FILE UPLOAD ====================

  /// Chọn file từ thiết bị
  Future<File?> pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'ppt', 'pptx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi chọn file: $e');
    }
  }

  /// Upload file lên Supabase Storage
  Future<String> uploadFile(
    File file, {
    required String userId,
    String? customName,
    void Function(int, int)? onProgress,
  }) async {
    try {
      if (!await file.exists()) {
        throw Exception('File không tồn tại');
      }

      final fileSize = await file.length();
      if (fileSize > maxFileSize) {
        throw Exception('File quá lớn (tối đa 50MB)');
      }

      final bytes = await file.readAsBytes();
      final fileName = customName ??
          '${userId}_${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final filePath = 'community/files/$fileName';

      await _supabase.storage
          .from('community_media')
          .uploadBinary(filePath, bytes, fileOptions: FileOptions(cacheControl: '3600'));

      final publicUrl =
          _supabase.storage.from('community_media').getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Lỗi upload file: $e');
    }
  }

  // ==================== FILE DOWNLOAD ====================

  /// Download file từ URL
  Future<File> downloadFile(String fileUrl, String fileName) async {
    try {
      final uri = Uri.parse(fileUrl);
      final response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Không thể tải file (${response.statusCode})');
      }

      // Save to local
      final appDir = Directory.systemTemp;
      final localFile = File('${appDir.path}/$fileName');
      await localFile.writeAsBytes(response.bodyBytes);

      return localFile;
    } catch (e) {
      throw Exception('Lỗi download file: $e');
    }
  }

  // ==================== FILE DELETION ====================

  /// Xóa file khỏi Supabase Storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length < 2) {
        throw Exception('URL không hợp lệ');
      }

      final filePath = pathSegments.sublist(2).join('/');

      await _supabase.storage.from('community_media').remove([filePath]);
    } catch (e) {
      throw Exception('Lỗi xóa file: $e');
    }
  }

  // ==================== UTILITY FUNCTIONS ====================

  /// Validate image
  bool isValidImage(String mimeType) {
    return allowedImageTypes.contains(mimeType.toLowerCase());
  }

  /// Validate file
  bool isValidFile(String mimeType) {
    return allowedFileTypes.contains(mimeType.toLowerCase());
  }

  /// Get MIME type từ file path
  String getMimeType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    final mimeTypes = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.pdf': 'application/pdf',
      '.doc': 'application/msword',
      '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      '.xls': 'application/vnd.ms-excel',
      '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    };
    return mimeTypes[ext] ?? 'application/octet-stream';
  }

  /// Format file size
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Get file name từ URL
  String getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      return pathSegments.last;
    } catch (e) {
      return 'file';
    }
  }

  /// Check if URL is valid image
  bool isImageUrl(String url) {
    try {
      final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();
      return imageExtensions.any((ext) => path.endsWith('.$ext'));
    } catch (e) {
      return false;
    }
  }
}
