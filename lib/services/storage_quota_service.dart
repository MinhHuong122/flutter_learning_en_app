import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class StorageQuotaService {
  static const String _quotaKey = 'storage_quota_upgraded';
  static const String _upgradeTimestampKey = 'storage_upgrade_timestamp';
  static const String _storageCacheKey = 'storage_usage_cache';
  static const String _storageCacheTimeKey = 'storage_usage_cache_time';
  static const int _cacheDurationSeconds = 300; // Cache for 5 minutes
  
  // Storage limits in bytes
  static const int baseLimitBytes = 1 * 1024 * 1024 * 1024; // 1GB
  static const int upgradedLimitBytes = 5 * 1024 * 1024 * 1024; // 5GB
  
  // Check if user has upgraded storage
  Future<bool> isUpgraded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_quotaKey) ?? false;
    } catch (e) {
      return false;
    }
  }
  
  // Get current storage limit in bytes
  Future<int> getStorageLimit() async {
    final upgraded = await isUpgraded();
    return upgraded ? upgradedLimitBytes : baseLimitBytes;
  }
  
  // Get current storage usage from Downloads folder (with caching)
  Future<int> getStorageUsage() async {
    try {
      // Check cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedTimeMs = prefs.getInt(_storageCacheTimeKey) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final elapsedSeconds = (nowMs - cachedTimeMs) ~/ 1000;
      
      // If cache is fresh, return cached value
      if (elapsedSeconds < _cacheDurationSeconds) {
        final cachedValue = prefs.getInt(_storageCacheKey) ?? 0;
        if (cachedValue > 0) {
          return cachedValue;
        }
      }
      
      // Calculate actual usage (this can be slow)
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null || !await downloadsDir.exists()) {
        return 0;
      }
      
      int totalSize = 0;
      
      try {
        // Synchronous list with timeout protection
        final files = downloadsDir.listSync(recursive: true, followLinks: false);
            
        for (final entity in files) {
          if (entity is File) {
            try {
              totalSize += await entity.length();
            } catch (e) {
              // Skip files we can't access
            }
          }
        }
      } catch (e) {
        // Return cached value if calculation fails
        final cachedValue = prefs.getInt(_storageCacheKey) ?? 0;
        return cachedValue;
      }
      
      // Cache the result
      try {
        await prefs.setInt(_storageCacheKey, totalSize);
        await prefs.setInt(_storageCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
      } catch (e) {
        // Silent fail - caching is optional
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
  
  // Clear cache to force refresh
  Future<void> clearStorageCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageCacheKey);
      await prefs.remove(_storageCacheTimeKey);
    } catch (e) {
      // Silent fail
    }
  }
  
  // Get usage percentage (0.0 to 1.0)
  Future<double> getStorageUsagePercentage() async {
    final usage = await getStorageUsage();
    final limit = await getStorageLimit();
    
    if (limit == 0) return 0.0;
    final percentage = usage / limit;
    return percentage > 1.0 ? 1.0 : percentage;
  }
  
  // Check if can download file (size in bytes)
  Future<bool> canDownloadFile(int fileSizeBytes) async {
    final usage = await getStorageUsage();
    final limit = await getStorageLimit();
    
    return (usage + fileSizeBytes) <= limit;
  }
  
  // Upgrade storage to 5GB
  Future<void> upgradeStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_quotaKey, true);
      await prefs.setString(_upgradeTimestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      // Silent fail
    }
  }
  
  // Get formatted storage info
  Future<StorageInfo> getStorageInfo() async {
    final usage = await getStorageUsage();
    final limit = await getStorageLimit();
    final percentage = await getStorageUsagePercentage();
    final upgraded = await isUpgraded();
    
    return StorageInfo(
      usageBytes: usage,
      limitBytes: limit,
      percentageUsed: percentage,
      isUpgraded: upgraded,
    );
  }
  
  // Format bytes to MB string
  static String formatBytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(2)} MB';
  }
  
  // Format bytes to GB string
  static String formatBytesGB(int bytes) {
    final gb = bytes / (1024 * 1024 * 1024);
    return '${gb.toStringAsFixed(2)} GB';
  }
}

class StorageInfo {
  final int usageBytes;
  final int limitBytes;
  final double percentageUsed;
  final bool isUpgraded;
  
  StorageInfo({
    required this.usageBytes,
    required this.limitBytes,
    required this.percentageUsed,
    required this.isUpgraded,
  });
  
  String get usageFormatted => StorageQuotaService.formatBytesGB(usageBytes);
  String get limitFormatted => StorageQuotaService.formatBytesGB(limitBytes);
  String get remainingFormatted => StorageQuotaService.formatBytesGB(limitBytes - usageBytes);
  String get percentageText => '${(percentageUsed * 100).toStringAsFixed(0)}%';
}
