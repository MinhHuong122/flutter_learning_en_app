import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

class FileHistoryItem {
  final String id;
  final String fileName;
  final String fileSize;
  final String fileType; // 'pdf', 'doc', 'folder', 'image', etc
  final String action; // 'download' or 'upload'
  final DateTime timestamp;
  final String? sourceScreen; // 'community', 'lesson', etc
  final String? filePath; // Local file path on device

  FileHistoryItem({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    required this.action,
    required this.timestamp,
    this.sourceScreen,
    this.filePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'fileSize': fileSize,
    'fileType': fileType,
    'action': action,
    'timestamp': timestamp.toIso8601String(),
    'sourceScreen': sourceScreen,
    'filePath': filePath,
  };

  factory FileHistoryItem.fromJson(Map<String, dynamic> json) => FileHistoryItem(
    id: json['id'] ?? '',
    fileName: json['fileName'] ?? '',
    fileSize: json['fileSize'] ?? '',
    fileType: json['fileType'] ?? 'doc',
    action: json['action'] ?? 'download',
    timestamp: json['timestamp'] != null 
        ? DateTime.parse(json['timestamp']) 
        : DateTime.now(),
    sourceScreen: json['sourceScreen'],
    filePath: json['filePath'],
  );
}

class FileHistoryService {
  static const String _storageKey = 'file_history';

  /// Add a file to history (called when user downloads or uploads from community)
  Future<void> addFileToHistory({
    required String fileName,
    required String fileSize,
    required String fileType,
    required String action, // 'download' or 'upload'
    String? sourceScreen, // 'community', 'lesson'
    String? filePath, // Local file path on device
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing history
      final historyJson = prefs.getStringList(_storageKey) ?? [];
      
      // Create new file item
      final newItem = FileHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fileName: fileName,
        fileSize: fileSize,
        fileType: fileType,
        action: action,
        timestamp: DateTime.now(),
        sourceScreen: sourceScreen,
        filePath: filePath,
      );
      
      // Add to list (keep only from community)
      if (sourceScreen == 'community') {
        historyJson.insert(0, jsonEncode(newItem.toJson()));
      }
      
      // Keep only last 50 items
      if (historyJson.length > 50) {
        historyJson.removeRange(50, historyJson.length);
      }
      
      // Save
      await prefs.setStringList(_storageKey, historyJson);
    } catch (e) {
      // Silent fail for production
    }
  }

  /// Get all file history from community only (removes invalid entries)
  Future<List<FileHistoryItem>> getFileHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_storageKey) ?? [];
      
      // Filter valid items: community source + has filePath + file exists
      List<FileHistoryItem> validItems = [];
      List<String> validJsonEntries = [];
      
      for (final jsonStr in historyJson) {
        final item = FileHistoryItem.fromJson(jsonDecode(jsonStr));
        
        // Skip if not from community
        if (item.sourceScreen != 'community') continue;
        
        // Skip if no file path
        if (item.filePath == null || item.filePath!.isEmpty) continue;
        
        // Check if file actually exists
        final file = File(item.filePath!);
        if (!await file.exists()) continue;
        
        // This item is valid
        validItems.add(item);
        validJsonEntries.add(jsonStr);
      }
      
      // Update storage to remove invalid entries
      if (validJsonEntries.length != historyJson.length) {
        await prefs.setStringList(_storageKey, validJsonEntries);
      }
      
      return validItems;
    } catch (e) {
      return [];
    }
  }

  /// Get recent file history (limited to N items)
  Future<List<FileHistoryItem>> getRecentFileHistory({int limit = 5}) async {
    try {
      final history = await getFileHistory();
      return history.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear all file history
  Future<void> clearFileHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      // Silent fail
    }
  }

  /// Get file icon based on file type
  static IconData getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
      case 'txt':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      case 'image':
      case 'jpg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'folder':
        return Icons.folder;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Get icon background color based on file type
  static Color getFileIconBgColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return const Color(0xFFFEE2E2); // Light red
      case 'doc':
      case 'docx':
      case 'txt':
        return const Color(0xFFDEF2FF); // Light blue
      case 'xls':
      case 'xlsx':
        return const Color(0xFFDCFCE7); // Light green
      case 'ppt':
      case 'pptx':
        return const Color(0xFFFFE4D6); // Light orange
      case 'image':
      case 'jpg':
      case 'png':
      case 'gif':
        return const Color(0xFFEFF6FF); // Very light blue
      case 'folder':
        return const Color(0xFFFEF3C7); // Light yellow
      default:
        return const Color(0xFFF3F4F6); // Light gray
    }
  }

  /// Get icon color based on file type
  static Color getFileIconColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return const Color(0xFFDC2626); // Red
      case 'doc':
      case 'docx':
      case 'txt':
        return const Color(0xFF0284C7); // Blue
      case 'xls':
      case 'xlsx':
        return const Color(0xFF16A34A); // Green
      case 'ppt':
      case 'pptx':
        return const Color(0xFFEA580C); // Orange
      case 'image':
      case 'jpg':
      case 'png':
      case 'gif':
        return const Color(0xFF3B82F6); // Blue
      case 'folder':
        return const Color(0xFFD97706); // Yellow-orange
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }
}
