import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../utils/constants.dart';

class FilePreviewScreen extends StatefulWidget {
  final String fileUrl;
  final String fileName;
  final bool isEnglish;

  const FilePreviewScreen({
    Key? key,
    required this.fileUrl,
    required this.fileName,
    required this.isEnglish,
  }) : super(key: key);

  @override
  State<FilePreviewScreen> createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends State<FilePreviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _error = null;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _error = error.description;
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_buildPreviewUrl()));
  }

  Future<void> _downloadFile() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEnglish ? 'Downloading...' : 'Đang tải xuống...'),
          duration: const Duration(seconds: 1),
        )
      );
      
      final dir = Platform.isAndroid 
          ? await getExternalStorageDirectory() 
          : await getApplicationDocumentsDirectory();
      
      if (dir != null) {
        final filePath = '${dir.path}/${widget.fileName}';
        final dio = Dio();
        await dio.download(widget.fileUrl, filePath);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEnglish ? 'Downloaded to $filePath' : 'Đã tải xuống $filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          )
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEnglish ? 'Download failed: $e' : 'Lỗi tải xuống: $e'),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  String _buildPreviewUrl() {
    final lowerName = widget.fileName.toLowerCase();
    final lowerUrl = widget.fileUrl.toLowerCase();
    final isOffice = lowerName.endsWith('.doc') ||
        lowerName.endsWith('.docx') ||
        lowerName.endsWith('.ppt') ||
        lowerName.endsWith('.pptx') ||
        lowerName.endsWith('.xls') ||
        lowerName.endsWith('.xlsx') ||
        lowerUrl.contains('.doc') ||
        lowerUrl.contains('.ppt') ||
        lowerUrl.contains('.xls');

    if (isOffice) {
      return 'https://docs.google.com/gview?embedded=1&url=${Uri.encodeComponent(widget.fileUrl)}';
    }

    return widget.fileUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: AppColors.primaryColor),
            onPressed: () => _downloadFile(),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.isEnglish
                      ? 'Cannot preview this file. Please try downloading it.'
                      : 'Không thể xem trước tệp này. Vui lòng thử tải về.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            )
          else
            WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
