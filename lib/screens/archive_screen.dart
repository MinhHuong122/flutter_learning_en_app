import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../widgets/custom_bottom_nav.dart';
import '../services/language_service.dart';
import '../services/file_history_service.dart';
import '../services/storage_quota_service.dart';
import '../services/gemini_voice_coach.dart';
import 'home_screen.dart';
import 'process_screen.dart';
import 'chat_ai_screen.dart';
import 'account_screen.dart';
import 'favorites_screen.dart';
import 'my_lessons_screen.dart';
import 'exercise_screen.dart';
import 'community_screen.dart';
import 'storage_upgrade_screen.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({Key? key}) : super(key: key);

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  int _currentIndex = 3;
  List<FileHistoryItem> _recentActivities = [];
  bool _isLoadingActivities = false;
  StorageInfo? _storageInfo;
  bool _isLoadingStorage = true;
  final GeminiVoiceCoach _voiceCoach = GeminiVoiceCoach();

  bool get _isEnglish => context.read<LanguageService>().isEnglish;

  Future<void> _openFile(FileHistoryItem item) async {
    try {
      if (item.filePath == null || item.filePath!.isEmpty) {
        _showMessage(
          _isEnglish ? 'File path not found' : 'Đường dẫn file không tìm thấy',
          isError: true,
        );
        return;
      }

      // Check if file exists
      final file = File(item.filePath!);
      if (!await file.exists()) {
        _showMessage(
          _isEnglish ? 'File no longer exists' : 'File không tồn tại',
          isError: true,
        );
        return;
      }

      // Try to open the file
      final result = await OpenFilex.open(item.filePath!);
      
      if (result.type == ResultType.noAppToOpen) {
        _showMessage(
          _isEnglish 
              ? 'No app available to open this file type' 
              : 'Không có ứng dụng để mở file này',
          isError: true,
        );
      } else if (result.type == ResultType.fileNotFound) {
        _showMessage(
          _isEnglish ? 'File not found' : 'Không tìm thấy file',
          isError: true,
        );
      }
    } catch (e) {
      _showMessage(
        _isEnglish ? 'Error: $e' : 'Lỗi: $e',
        isError: true,
      );
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteFile(FileHistoryItem item, int index) async {
    try {
      if (item.filePath == null || item.filePath!.isEmpty) return;

      final file = File(item.filePath!);
      if (await file.exists()) {
        await file.delete();
      }

      // Reload activities after deletion
      await _loadRecentActivities();
      
      _showMessage(
        _isEnglish ? '✅ File deleted' : '✅ Đã xóa file',
        isError: false,
      );
    } catch (e) {
      _showMessage(
        _isEnglish ? 'Error deleting file: $e' : 'Lỗi xóa file: $e',
        isError: true,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRecentActivities();
    _loadStorageInfoFast(); // Load with cache first, then refresh
  }

  // Load storage info quickly (uses cache), then refresh in background
  Future<void> _loadStorageInfoFast() async {
    try {
      // Show cached/estimated value immediately
      final quotaService = StorageQuotaService();
      final info = await quotaService.getStorageInfo();
      if (mounted) {
        setState(() {
          _storageInfo = info;
          _isLoadingStorage = false;
        });
      }
      
      // Optionally refresh in background after short delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _refreshStorageInfoBackground();
        }
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingStorage = false);
    }
  }
  
  // Refresh storage info in background without blocking UI
  Future<void> _refreshStorageInfoBackground() async {
    try {
      // Clear cache to force fresh calculation
      await StorageQuotaService().clearStorageCache();
      final info = await StorageQuotaService().getStorageInfo();
      if (mounted) {
        setState(() => _storageInfo = info);
      }
    } catch (e) {
      // Silent fail - keep showing previous value
    }
  }

  Future<void> _loadStorageInfo() async {
    try {
      final info = await StorageQuotaService().getStorageInfo();
      if (mounted) {
        setState(() {
          _storageInfo = info;
          _isLoadingStorage = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStorage = false);
    }
  }

  Future<void> _loadRecentActivities() async {
    setState(() => _isLoadingActivities = true);
    try {
      final history = await FileHistoryService().getRecentFileHistory(limit: 10);
      if (mounted) {
        setState(() {
          _recentActivities = history;
          _isLoadingActivities = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingActivities = false);
    }
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ChatAiScreen()),
        );
        break;
      case 3:
        setState(() => _currentIndex = index);
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AccountScreen()),
        );
        break;
    }
  }

  // Show context menu with more options
  void _showFileContextMenu(FileHistoryItem item, int index) {
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
              // Handle
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2.5),
                ),
                margin: const EdgeInsets.only(bottom: 16),
              ),

              // File name
              Text(
                item.fileName,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),

              // Score option
              _buildMenuOption(
                icon: Icons.star,
                title: _isEnglish ? 'Score File' : 'Chấm điểm file',
                subtitle: _isEnglish ? 'AI evaluates the content' : 'AI đánh giá nội dung',
                iconColor: const Color(0xFFFFB800),
                onTap: () {
                  Navigator.pop(context);
                  _scoreFile(item);
                },
              ),
              const SizedBox(height: 12),

              // Summarize option
              _buildMenuOption(
                icon: Icons.summarize,
                title: _isEnglish ? 'Summarize File' : 'Tóm tắt file',
                subtitle: _isEnglish ? 'Get AI summary' : 'Lấy tóm tắt từ AI',
                iconColor: const Color(0xFF0EA5E9),
                onTap: () {
                  Navigator.pop(context);
                  _summarizeFile(item);
                },
              ),
              const SizedBox(height: 12),

              // Delete option
              _buildMenuOption(
                icon: Icons.delete,
                title: _isEnglish ? 'Delete File' : 'Xóa file',
                subtitle: _isEnglish ? 'Remove permanently' : 'Xoá vĩnh viễn',
                iconColor: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(_isEnglish ? 'Delete File?' : 'Xóa file?'),
                      content: Text(_isEnglish 
                          ? 'Are you sure you want to delete this file?'
                          : 'Bạn chắc chắn muốn xóa file này?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(_isEnglish ? 'Cancel' : 'Hủy'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteFile(item, index);
                          },
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: Text(_isEnglish ? 'Delete' : 'Xóa'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Build menu option item
  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withOpacity(0.1),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: const Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }

  // Fallback API call using Vercel when Gemini fails
  Future<String> _callVercelAPI(String userMessage) async {
    try {
      const String vercelApiUrl = 'https://flutter-learning-en-app.vercel.app/api/chat';
      
      print('🔄 Calling Vercel API as fallback...');
      
      final response = await http.post(
        Uri.parse(vercelApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': userMessage,
          'systemPrompt': 'You are PUPU AI, a helpful assistant. Provide concise, clear responses.',
        }),
      ).timeout(const Duration(seconds: 30));

      print('📡 Vercel API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['response'] ?? data['reply'] ?? '';
        print('✅ Vercel API returned: $result');
        return result.isNotEmpty ? result : 'No response from API';
      } else {
        print('❌ Vercel API Error: ${response.statusCode}');
        return 'Vercel API Error (${response.statusCode})';
      }
    } catch (e) {
      print('❌ Vercel API exception: $e');
      return 'Vercel API Error: $e';
    }
  }

  // Direct Gemini API call
  Future<String> _callGeminiDirect(String userMessage) async {
    try {
      const String apiKey = 'AIzaSyB_L3mNuiVhy00-rlC5RF2W7hfLcSBqxbk';
      const String model = 'gemini-2.0-flash-exp';
      
      print('🔄 Calling Gemini API directly...');
      
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';
      
      final body = {
        'contents': [
          {
            'parts': [
              {'text': userMessage}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 1000,
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      print('📡 Gemini Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates.first['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          final text = (parts != null && parts.isNotEmpty)
              ? (parts.first['text']?.toString() ?? '')
              : '';
          print('✅ Gemini returned: $text');
          return text.isNotEmpty ? text : 'No response from Gemini';
        }
      }
      print('❌ Gemini Error: ${response.statusCode} - ${response.body}');
      return 'Gemini Error (${response.statusCode})';
    } catch (e) {
      print('❌ Gemini exception: $e');
      return 'Gemini Error: $e';
    }
  }

  // Read file content
  Future<String> _readFileContent(FileHistoryItem item) async {
    try {
      if (item.filePath == null || item.filePath!.isEmpty) {
        return '';
      }

      final file = File(item.filePath!);
      if (!await file.exists()) {
        return '';
      }

      // Try to read as text
      if (item.fileType == 'pdf' || item.fileName.endsWith('.pdf')) {
        // For PDF, extract text (simplified - just return filename info)
        return 'File: ${item.fileName}\nType: PDF\nSize: ${item.fileSize}';
      }

      // For text files
      if (item.fileName.endsWith('.txt') || 
          item.fileName.endsWith('.doc') || 
          item.fileName.endsWith('.docx')) {
        try {
          final content = await file.readAsString();
          // Limit content to first 3000 characters for API
          return content.substring(0, min(content.length, 3000));
        } catch (e) {
          return 'File: ${item.fileName}\nType: Document\nSize: ${item.fileSize}';
        }
      }

      return 'File: ${item.fileName}\nType: ${item.fileType ?? 'Unknown'}\nSize: ${item.fileSize}';
    } catch (e) {
      print('Error reading file: $e');
      return 'Unable to read file content';
    }
  }

  // Score file using AI
  Future<void> _scoreFile(FileHistoryItem item) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  _isEnglish ? 'Analyzing file...' : 'Đang phân tích file...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Read file content
      final content = await _readFileContent(item);

      // Get AI scoring
      final prompt = _isEnglish
          ? 'Please score and evaluate this file content on a scale of 1-10 based on quality, clarity, and usefulness. Provide a brief assessment:\n\n$content'
          : 'Vui lòng chấm điểm và đánh giá nội dung file này trên thang điểm 1-10 dựa trên chất lượng, rõ ràng và hữu ích. Cung cấp một đánh giá ngắn:\n\n$content';

      // Try multiple APIs in sequence
      var response = await _voiceCoach.generateReply(prompt, isEnglish: _isEnglish);
      
      if (response.contains('Request failed') || response.contains('No response') || response.contains('Error (')) {
        print('⚠️ GeminiVoiceCoach failed, trying direct Gemini API...');
        response = await _callGeminiDirect(prompt);
      }
      
      if (response.contains('Gemini Error') || response.contains('Error (')) {
        print('⚠️ Direct Gemini failed, trying Vercel API...');
        response = await _callVercelAPI(prompt);
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Check for error response
        if (response.contains('Error') || response.isEmpty) {
          _showMessage(
            _isEnglish 
                ? 'API Error: Unable to analyze file. Please try again later.'
                : 'Lỗi API: Không thể phân tích file. Vui lòng thử lại sau.',
            isError: true,
          );
          return;
        }

        // Show result
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              _isEnglish ? 'File Score' : 'Chấm điểm file',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.fileName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    response,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_isEnglish ? 'Close' : 'Đóng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showMessage(
          _isEnglish 
              ? 'Error scoring file: Unable to process. Check your internet connection.'
              : 'Lỗi chấm điểm file: Không thể xử lý. Kiểm tra kết nối internet của bạn.',
          isError: true,
        );
      }
    }
  }

  // Summarize file using AI
  Future<void> _summarizeFile(FileHistoryItem item) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  _isEnglish ? 'Summarizing file...' : 'Đang tóm tắt file...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Read file content
      final content = await _readFileContent(item);

      // Get AI summary
      final prompt = _isEnglish
          ? 'Please provide a concise summary of this file content in 3-5 key points:\n\n$content'
          : 'Vui lòng cung cấp một tóm tắt ngắn gọn về nội dung file này trong 3-5 điểm chính:\n\n$content';

      // Try multiple APIs in sequence
      var response = await _voiceCoach.generateReply(prompt, isEnglish: _isEnglish);
      
      if (response.contains('Request failed') || response.contains('No response') || response.contains('Error (')) {
        print('⚠️ GeminiVoiceCoach failed, trying direct Gemini API...');
        response = await _callGeminiDirect(prompt);
      }
      
      if (response.contains('Gemini Error') || response.contains('Error (')) {
        print('⚠️ Direct Gemini failed, trying Vercel API...');
        response = await _callVercelAPI(prompt);
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Check for error response
        if (response.contains('Error') || response.isEmpty) {
          _showMessage(
            _isEnglish 
                ? 'API Error: Unable to summarize file. Please try again later.'
                : 'Lỗi API: Không thể tóm tắt file. Vui lòng thử lại sau.',
            isError: true,
          );
          return;
        }

        // Show result
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              _isEnglish ? 'File Summary' : 'Tóm tắt file',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.fileName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    response,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_isEnglish ? 'Close' : 'Đóng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showMessage(
          _isEnglish 
              ? 'Error summarizing file: Unable to process. Check your internet connection.'
              : 'Lỗi tóm tắt file: Không thể xử lý. Kiểm tra kết nối internet của bạn.',
          isError: true,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    _isEnglish ? 'Archive' : 'Lưu trữ',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadRecentActivities,
                color: AppColors.primaryColor,
                child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Storage card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryColor,
                              AppColors.primaryLight,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: _isLoadingStorage
                            ? SizedBox(
                                height: 150,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _isEnglish ? 'Storage Usage' : 'Sử dụng dung lượng',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.white70,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _storageInfo?.usageFormatted ?? '0 GB',
                                            style: GoogleFonts.poppins(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_isEnglish ? 'of' : 'trên'} ${_storageInfo?.limitFormatted ?? '1 GB'}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withOpacity(0.2),
                                        ),
                                        child: const Icon(
                                          Icons.cloud,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Progress bar
                                  Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: _storageInfo?.percentageUsed ?? 0.0,
                                          minHeight: 6,
                                          backgroundColor: Colors.white.withOpacity(0.2),
                                          valueColor: const AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${_storageInfo?.percentageText ?? '0%'} ${_isEnglish ? 'used' : 'đã sử dụng'}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          if (!(_storageInfo?.isUpgraded ?? false))
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => const StorageUpgradeScreen(),
                                                  ),
                                                ).then((_) {
                                                  // Reload storage info after returning from upgrade screen
                                                  _loadStorageInfo();
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  _isEnglish ? 'Upgrade' : 'Nâng cấp',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    ),

                    // Quick Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          Text(
                            _isEnglish ? 'Quick Actions' : 'Hành động nhanh',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 1.1,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            children: [
                              _buildActionCard(
                                icon: Icons.add,
                                title: _isEnglish ? 'Create Lesson' : 'Tạo bài học',
                                subtitle: _isEnglish ? 'Start new draft' : 'Bắt đầu nháp mới',
                                iconBgColor: const Color(0xFFEFF6FF),
                                iconColor: const Color(0xFF3B82F6),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const MyLessonsScreen(),
                                      settings: const RouteSettings(name: '/my_lessons'),
                                    ),
                                  );
                                },
                              ),
                              _buildActionCard(
                                icon: Icons.quiz,
                                title: _isEnglish ? 'Exercise' : 'Bài tập',
                                subtitle: _isEnglish ? 'Daily practice' : 'Luyện tập hàng ngày',
                                iconBgColor: const Color(0xFFFFF5E6),
                                iconColor: const Color(0xFFF97316),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ExerciseScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildActionCard(
                                icon: Icons.favorite,
                                title: _isEnglish ? 'Favorites' : 'Yêu thích',
                                subtitle: _isEnglish ? 'Saved items' : 'Mục đã lưu',
                                iconBgColor: const Color(0xFFF3E8FF),
                                iconColor: const Color(0xFFA855F7),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const FavoritesScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildActionCard(
                                icon: Icons.groups,
                                title: _isEnglish ? 'Community' : 'Cộng đồng',
                                subtitle: _isEnglish ? 'Shared docs' : 'Tài liệu chia sẻ',
                                iconBgColor: const Color(0xFFEFFEED),
                                iconColor: const Color(0xFF10B981),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CommunityScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Recent Activities
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isEnglish
                                    ? 'Recent Activities'
                                    : 'Hoạt động gần đây',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  _isEnglish ? 'See All' : 'Xem tất cả',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),

                    // Horizontal scrolling activities
                    _isLoadingActivities
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            child: Center(
                              child: SizedBox(
                                height: 30,
                                width: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        : _recentActivities.isEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                    color: const Color(0xFFF9FAFB),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _isEnglish
                                          ? 'No files from community yet'
                                          : 'Chưa có file từ cộng đồng',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : SizedBox(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  itemCount: _recentActivities.length,
                                  itemBuilder: (context, index) {
                                    final item = _recentActivities[index];
                                    return Padding(
                                      padding: EdgeInsets.only(right: index == _recentActivities.length - 1 ? 0 : 12),
                                      child: GestureDetector(
                                        onTap: () => _openFile(item),
                                        onLongPress: () {
                                          _showFileContextMenu(item, index);
                                        },
                                        child: _buildActivityItem(
                                          icon: FileHistoryService.getFileIcon(item.fileType),
                                          title: item.fileName,
                                          subtitle: item.fileSize,
                                          iconBgColor: FileHistoryService.getFileIconBgColor(item.fileType),
                                          iconColor: FileHistoryService.getFileIconColor(item.fileType),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          color: iconBgColor,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withOpacity(0.2),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(12),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: iconBgColor,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


