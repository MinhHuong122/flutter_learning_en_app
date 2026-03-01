import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pupu/models/dictionary_model.dart';

class SupabaseDictionaryService {
  static final SupabaseDictionaryService _instance =
      SupabaseDictionaryService._internal();

  final _supabase = Supabase.instance.client;

  factory SupabaseDictionaryService() {
    return _instance;
  }

  SupabaseDictionaryService._internal();

  /// Search Vietnamese dictionary
  Future<List<DictionaryEntry>> searchVietnamese(
    String query, {
    int limit = 50,
  }) async {
    try {
      print('🔍 Searching Vietnamese: "$query"');

      final results = await _supabase
          .from('vietnamese_headwords')
          .select()
          .or('term.ilike.%$query%,meaning.ilike.%$query%')
          .order('is_common', ascending: false)
          .order('frequency', ascending: false)
          .limit(limit);

      print('✅ Found ${results.length} Vietnamese entries');

      return (results as List)
          .map((json) => DictionaryEntry.fromJson(
                json as Map<String, dynamic>,
                'vi',
              ))
          .toList();
    } catch (e) {
      print('❌ Vietnamese search error: $e');
      return [];
    }
  }

  /// Search English dictionary
  Future<List<DictionaryEntry>> searchEnglish(
    String query, {
    int limit = 50,
  }) async {
    try {
      print('🔍 Searching English: "$query"');

      final results = await _supabase
          .from('english_headwords')
          .select()
          .or('term.ilike.%$query%,meaning.ilike.%$query%,pronunciation.ilike.%$query%')
          .order('is_common', ascending: false)
          .order('frequency', ascending: false)
          .limit(limit);

      print('✅ Found ${results.length} English entries');

      return (results as List)
          .map((json) => DictionaryEntry.fromJson(
                json as Map<String, dynamic>,
                'en',
              ))
          .toList();
    } catch (e) {
      print('❌ English search error: $e');
      return [];
    }
  }

  /// Search both languages
  Future<List<DictionaryEntry>> searchAll(
    String query, {
    int limit = 50,
  }) async {
    try {
      print('🔍 Searching all languages: "$query"');

      // Use Supabase RPC function for combined search
      final results = await _supabase.rpc(
        'search_all',
        params: {
          'p_term': query,
          'p_limit': limit,
        },
      );

      final entries = <DictionaryEntry>[];

      for (final item in results as List) {
        final json = item as Map<String, dynamic>;
        final lang = json['language'] as String;
        entries.add(DictionaryEntry.fromJson(json, lang));
      }

      print('✅ Found ${entries.length} total entries');
      return entries;
    } catch (e) {
      print('❌ Combined search error: $e');
      // Fallback: search both separately
      final viResults = await searchVietnamese(query, limit: limit);
      final enResults = await searchEnglish(query, limit: limit);
      return [...viResults, ...enResults].take(limit).toList();
    }
  }

  /// Get single Vietnamese entry by ID
  Future<DictionaryEntry?> getVietnameseEntry(int id) async {
    try {
      final result = await _supabase
          .from('vietnamese_headwords')
          .select()
          .eq('id', id)
          .limit(1)
          .maybeSingle();

      if (result == null) return null;

      return DictionaryEntry.fromJson(result, 'vi');
    } catch (e) {
      print('❌ Error fetching Vietnamese entry: $e');
      return null;
    }
  }

  /// Get single English entry by ID
  Future<DictionaryEntry?> getEnglishEntry(int id) async {
    try {
      final result = await _supabase
          .from('english_headwords')
          .select()
          .eq('id', id)
          .limit(1)
          .maybeSingle();

      if (result == null) return null;

      return DictionaryEntry.fromJson(result, 'en');
    } catch (e) {
      print('❌ Error fetching English entry: $e');
      return null;
    }
  }

  /// Get entry by term and language
  Future<DictionaryEntry?> getEntryByTerm(String term, String language) async {
    try {
      final tableName = language == 'vi'
          ? 'vietnamese_headwords'
          : 'english_headwords';

      final result = await _supabase
          .from(tableName)
          .select()
          .eq('term', term)
          .limit(1)
          .maybeSingle();

      if (result == null) return null;

      return DictionaryEntry.fromJson(result, language);
    } catch (e) {
      print('❌ Error fetching entry: $e');
      return null;
    }
  }

  /// Get common Vietnamese words
  Future<List<DictionaryEntry>> getCommonVietnamese({
    int limit = 100,
  }) async {
    try {
      print('📚 Fetching common Vietnamese words...');

      final results = await _supabase.rpc(
        'get_common_vietnamese',
        params: {'p_limit': limit},
      );

      print('✅ Found ${results.length} common Vietnamese words');

      return (results as List)
          .map((json) => DictionaryEntry.fromJson(
                json as Map<String, dynamic>,
                'vi',
              ))
          .toList();
    } catch (e) {
      print('❌ Error fetching common Vietnamese words: $e');
      // Fallback: query directly
      return await _supabase
          .from('vietnamese_headwords')
          .select()
          .eq('is_common', true)
          .order('frequency', ascending: false)
          .limit(limit)
          .then((results) => (results as List)
              .map((json) => DictionaryEntry.fromJson(
                    json as Map<String, dynamic>,
                    'vi',
                  ))
              .toList());
    }
  }

  /// Get common English words
  Future<List<DictionaryEntry>> getCommonEnglish({
    int limit = 100,
  }) async {
    try {
      print('📚 Fetching common English words...');

      final results = await _supabase.rpc(
        'get_common_english',
        params: {'p_limit': limit},
      );

      print('✅ Found ${results.length} common English words');

      return (results as List)
          .map((json) => DictionaryEntry.fromJson(
                json as Map<String, dynamic>,
                'en',
              ))
          .toList();
    } catch (e) {
      print('❌ Error fetching common English words: $e');
      // Fallback: query directly
      return await _supabase
          .from('english_headwords')
          .select()
          .eq('is_common', true)
          .order('frequency', ascending: false)
          .limit(limit)
          .then((results) => (results as List)
              .map((json) => DictionaryEntry.fromJson(
                    json as Map<String, dynamic>,
                    'en',
                  ))
              .toList());
    }
  }

  /// Get all entries count
  Future<Map<String, int>> getDictionaryStats() async {
    try {
      print('📊 Fetching dictionary statistics...');

      final viCount = await _supabase
          .from('vietnamese_headwords')
          .select('id')
          .count(CountOption.exact)
          .then((result) => result.count);

      final enCount = await _supabase
          .from('english_headwords')
          .select('id')
          .count(CountOption.exact)
          .then((result) => result.count);

      final stats = {
        'vietnamese': viCount,
        'english': enCount,
        'total': viCount + enCount,
      };

      print('✅ Stats: $stats');
      return stats;
    } catch (e) {
      print('❌ Error fetching stats: $e');
      return {};
    }
  }

  /// Add word to user's saved/favorite words
  Future<bool> saveWord(String term, String language) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ User not authenticated');
        return false;
      }

      await _supabase.from('user_saved_words').insert({
        'user_id': user.id,
        'term': term,
        'language': language,
        'is_favorite': true,
        'mastery_level': 1,
      });

      print('✅ Word saved: $term ($language)');
      return true;
    } catch (e) {
      print('⚠️ Error saving word: $e');
      return true; // Might already be saved
    }
  }

  /// Remove word from saved words
  Future<bool> unsaveWord(String term, String language) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('user_saved_words')
          .delete()
          .eq('user_id', user.id)
          .eq('term', term)
          .eq('language', language);

      print('✅ Word unsaved: $term ($language)');
      return true;
    } catch (e) {
      print('❌ Error unsaving word: $e');
      return false;
    }
  }

  /// Get user's saved words
  Future<List<DictionaryEntry>> getUserSavedWords() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ User not authenticated');
        return [];
      }

      // Fetch user's saved words
      final saved = await _supabase
          .from('user_saved_words')
          .select()
          .eq('user_id', user.id)
          .order('saved_at', ascending: false);

      final results = <DictionaryEntry>[];

      for (final item in saved) {
        final term = item['term'] as String;
        final language = item['language'] as String;

        final entry = await getEntryByTerm(term, language);
        if (entry != null) {
          results.add(entry);
        }
      }

      print('✅ Loaded ${results.length} saved words');
      return results;
    } catch (e) {
      print('❌ Error loading saved words: $e');
      return [];
    }
  }

  /// Check if word is saved
  Future<bool> isWordSaved(String term, String language) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final result = await _supabase
          .from('user_saved_words')
          .select()
          .eq('user_id', user.id)
          .eq('term', term)
          .eq('language', language)
          .limit(1)
          .maybeSingle();

      return result != null;
    } catch (e) {
      return false;
    }
  }

  /// Update word learning progress
  Future<bool> updateMasteryLevel(
    String term,
    String language,
    int level,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('user_saved_words')
          .update({'mastery_level': level})
          .eq('user_id', user.id)
          .eq('term', term)
          .eq('language', language);

      print('✅ Updated mastery level for $term: $level');
      return true;
    } catch (e) {
      print('❌ Error updating mastery level: $e');
      return false;
    }
  }
}
