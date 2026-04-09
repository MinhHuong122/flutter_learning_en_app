import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Consolidated Dictionary Import Service
/// Supports both old (unified table) and new (split tables) import methods
class DictionaryImportService {
  static final DictionaryImportService _instance = DictionaryImportService._internal();

  final _supabase = Supabase.instance.client;

  factory DictionaryImportService() {
    return _instance;
  }

  DictionaryImportService._internal();

  /// Import batch data from JSON file
  /// Use this for initial setup from generated supabase_batch_insert.json
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

          print('� Processing batch $batchNum (${entries.length} entries)...');

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

  /// Import single entry (for testing)
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
      await _supabase.from('dictionary_headwords').insert({
        'term': term,
        'language': language,
        'pronunciation': pronunciation ?? '',
        'word_class': wordClass,
        'meaning': meaning,
        'is_common': isCommon,
        'frequency': frequency,
      });

      print('✅ Entry imported: $term ($language)');
      return true;
    } catch (e) {
      print('❌ Error importing entry: $e');
      return false;
    }
  }

  /// Get import statistics
  Future<Map<String, dynamic>> getImportStats() async {
    try {
      final totalCount = await _supabase
          .from('dictionary_headwords')
          .select('id')
          .then((result) => result.length);
      
      final viCount = await _supabase
          .from('dictionary_headwords')
          .select('id')
          .eq('language', 'vi')
          .then((result) => result.length);

      final enCount = await _supabase
          .from('dictionary_headwords')
          .select('id')
          .eq('language', 'en')
          .then((result) => result.length);
      
      final commonCount = await _supabase
          .from('dictionary_headwords')
          .select('id')
          .eq('is_common', true)
          .then((result) => result.length);

      return {
        'total': totalCount,
        'vietnamese': viCount,
        'english': enCount,
        'common': commonCount,
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

      await _supabase.from('dictionary_headwords').delete().neq('id', -1);

      print('✅ All data cleared');
      return true;
    } catch (e) {
      print('❌ Error clearing data: $e');
      return false;
    }
  }

  /// Verify data integrity
  Future<bool> verifyDataIntegrity() async {
    try {
      print('🔍 Verifying data integrity...');

      // Check for duplicates
      final result = await _supabase.from('dictionary_headwords').select();

      final uniqueTerms = <String>{};
      int duplicates = 0;
      
      for (final entry in result) {
        final key = '${entry['term']}|${entry['language']}';
        if (uniqueTerms.contains(key)) {
          duplicates++;
        } else {
          uniqueTerms.add(key);
        }
      }

      print('''
📊 Verification Report:
  ✅ Total entries: ${result.length}
  ✅ Unique terms: ${uniqueTerms.length}
  ⚠️  Duplicates: $duplicates
      ''');

      return duplicates == 0;
      
    } catch (e) {
      print('❌ Verification error: $e');
      return false;
    }
  }
}
