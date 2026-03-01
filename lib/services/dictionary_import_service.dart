import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Consolidated Dictionary Import Service
/// Supports both old (unified table) and new (split tables) import methods
class DictionaryImportService {
  static final DictionaryImportService _instance =
      DictionaryImportService._internal();

  final _supabase = Supabase.instance.client;

  factory DictionaryImportService() {
    return _instance;
  }

  DictionaryImportService._internal();

  /// Import batch data from JSON file (legacy method)
  /// Use for old unified table approach (dictionary_headwords)
  Future<bool> importFromBatchJson(String jsonAssetPath) async {
    try {
      print('📥 Starting batch import from: $jsonAssetPath');

      final jsonString = await rootBundle.loadString(jsonAssetPath);
      final batches = jsonDecode(jsonString) as List<dynamic>;

      int totalInserted = 0;
      int failedBatches = 0;

      for (final batchData in batches) {
        try {
          final batch = batchData as Map<String, dynamic>;
          final batchNum = batch['batch'] as int;
          final entries = batch['data'] as List<dynamic>;

          print('⏳ Processing batch $batchNum (${entries.length} entries)...');

          // Insert batch
          await _supabase.from('dictionary_headwords').insert(
            List<Map<String, dynamic>>.from(entries),
          );

          totalInserted += entries.length;
          print('✅ Batch $batchNum imported successfully');

          // Delay between batches to avoid rate limiting
          await Future.delayed(Duration(milliseconds: 500));
        } catch (e) {
          failedBatches++;
          print('❌ Batch failed: $e');
          // Continue with next batch
        }
      }

      print('''
🎉 Import Complete!
  ✅ Total inserted: $totalInserted entries
  ❌ Failed batches: $failedBatches
      ''');

      return failedBatches == 0;
    } catch (e) {
      print('❌ Error during import: $e');
      return false;
    }
  }

  /// Import CSV data from generated files (recommended - new method)
  /// Use for new split table approach (vietnamese_headwords, english_headwords)
  Future<bool> importFromCSV({
    required List<Map<String, dynamic>> vietnameseData,
    required List<Map<String, dynamic>> englishData,
  }) async {
    try {
      print('📥 Starting CSV import...\n');

      // Import Vietnamese data
      print(
          '🇻🇳 Importing Vietnamese dictionary (${vietnameseData.length} entries)...');
      await _importBatch(
        'vietnamese_headwords',
        vietnameseData,
      );

      // Import English data
      print(
          '\n🇬🇧 Importing English dictionary (${englishData.length} entries)...');
      await _importBatch(
        'english_headwords',
        englishData,
      );

      print('\n✅ CSV import complete!');
      return true;
    } catch (e) {
      print('❌ Error during CSV import: $e');
      return false;
    }
  }

  /// Internal batch import helper - Splits large datasets into manageable chunks
  Future<void> _importBatch(
    String tableName,
    List<Map<String, dynamic>> data, {
    int batchSize = 100,
  }) async {
    int totalInserted = 0;
    int failedCount = 0;

    // Process in batches
    for (var i = 0; i < data.length; i += batchSize) {
      final end = (i + batchSize < data.length) ? i + batchSize : data.length;
      final batch = data.sublist(i, end);

      try {
        print(
            '  ⏳ Batch ${(i ~/ batchSize) + 1}/${(data.length / batchSize).ceil()} (${batch.length} entries)');

        await _supabase.from(tableName).insert(batch);

        totalInserted += batch.length;
        print('  ✅ Inserted ${batch.length} entries');

        // Delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        failedCount += batch.length;
        print('  ❌ Batch failed: $e');
        // Continue with next batch instead of stopping
      }
    }

    print('\n  📊 Summary:');
    print('     ✅ Inserted: $totalInserted');
    print('     ❌ Failed: $failedCount');
  }

  /// Import single entry (for testing/adding manually)
  Future<bool> importEntry({
    required String term,
    required String language, // 'vi' or 'en'
    String? pronunciation,
    required String wordClass,
    required String meaning,
    bool isCommon = false,
    int frequency = 0,
  }) async {
    try {
      final tableName = language == 'vi'
          ? 'vietnamese_headwords'
          : 'english_headwords';

      final data = {
        'term': term,
        'word_class': wordClass,
        'meaning': meaning,
        'is_common': isCommon,
        'frequency': frequency,
      };

      // Add pronunciation only for English
      if (language == 'en' && pronunciation != null) {
        data['pronunciation'] = pronunciation;
      }

      await _supabase.from(tableName).insert(data);

      print('✅ Entry imported: $term ($language)');
      return true;
    } catch (e) {
      print('❌ Error importing entry: $e');
      return false;
    }
  }

  /// Import multiple entries
  Future<int> importEntries(List<Map<String, dynamic>> entries) async {
    try {
      int successCount = 0;

      for (final entry in entries) {
        final language = entry['language'] as String;
        final success = await importEntry(
          term: entry['term'] as String,
          language: language,
          pronunciation: entry['pronunciation'] as String?,
          wordClass: entry['word_class'] as String? ?? 'noun',
          meaning: entry['meaning'] as String,
          isCommon: entry['is_common'] as bool? ?? false,
          frequency: entry['frequency'] as int? ?? 0,
        );

        if (success) successCount++;
      }

      print('✅ Imported $successCount/${entries.length} entries');
      return successCount;
    } catch (e) {
      print('❌ Error importing entries: $e');
      return 0;
    }
  }

  /// Get import statistics for both languages
  Future<Map<String, int>> getImportStats() async {
    try {
      final viCount = await _supabase
          .from('vietnamese_headwords')
          .select('id')
          .then((results) => results.length);

      final enCount = await _supabase
          .from('english_headwords')
          .select('id')
          .then((results) => results.length);

      return {
        'vietnamese': viCount,
        'english': enCount,
        'total': viCount + enCount,
      };
    } catch (e) {
      print('❌ Error getting stats: $e');
      return {};
    }
  }

  /// Clear all dictionary data (use with caution!)
  Future<bool> clearAllData() async {
    try {
      print('⚠️  Clearing all dictionary data...');

      await _supabase
          .from('vietnamese_headwords')
          .delete()
          .neq('id', -1);

      await _supabase
          .from('english_headwords')
          .delete()
          .neq('id', -1);

      print('✅ All data cleared');
      return true;
    } catch (e) {
      print('❌ Error clearing data: $e');
      return false;
    }
  }

  /// Verify data integrity across both tables
  Future<Map<String, dynamic>> verifyDataIntegrity() async {
    try {
      print('🔍 Verifying data integrity...');

      // Count entries
      final viData = await _supabase
          .from('vietnamese_headwords')
          .select('id')
          .then((results) => results.length);

      final enData = await _supabase
          .from('english_headwords')
          .select('id')
          .then((results) => results.length);

      // Check for any NULL meanings
      final viNulls = await _supabase
          .from('vietnamese_headwords')
          .select('id')
          .filter('meaning', 'is', null)
          .then((results) => results.length);

      final enNulls = await _supabase
          .from('english_headwords')
          .select('id')
          .filter('meaning', 'is', null)
          .then((results) => results.length);

      final report = {
        'vietnamese_entries': viData,
        'english_entries': enData,
        'vietnamese_null_meanings': viNulls,
        'english_null_meanings': enNulls,
        'total_entries': viData + enData,
        'integrity_ok': viNulls == 0 && enNulls == 0,
      };

      print('''
📊 Verification Report:
   🇻🇳 Vietnamese: $viData entries (null meanings: $viNulls)
   🇬🇧 English: $enData entries (null meanings: $enNulls)
   ✅ Integrity: ${report['integrity_ok'] == true ? 'OK' : 'FAILED'}
      ''');

      return report;
    } catch (e) {
      print('❌ Verification error: $e');
      return {'error': e.toString()};
    }
  }

  /// Check for duplicate terms in both tables
  Future<Map<String, dynamic>> checkDuplicates() async {
    try {
      print('🔄 Checking for duplicates...');

      // Check Vietnamese duplicates
      final viDupsResult = await _supabase.rpc(
        'check_vietnamese_duplicates',
      ).catchError((_) => []);

      // Check English duplicates
      final enDupsResult = await _supabase.rpc(
        'check_english_duplicates',
      ).catchError((_) => []);

      final viDuplicates = (viDupsResult as List?)?.length ?? 0;
      final enDuplicates = (enDupsResult as List?)?.length ?? 0;

      print('''
🔍 Duplicate Check:
   🇻🇳 Vietnamese duplicates: $viDuplicates
   🇬🇧 English duplicates: $enDuplicates
      ''');

      return {
        'vietnamese_duplicates': viDuplicates,
        'english_duplicates': enDuplicates,
        'has_duplicates': viDuplicates > 0 || enDuplicates > 0,
      };
    } catch (e) {
      print('❌ Error checking duplicates: $e');
      return {'error': e.toString()};
    }
  }
}
