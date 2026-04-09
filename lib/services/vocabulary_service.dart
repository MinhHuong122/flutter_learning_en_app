import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lesson_model.dart';

// ============================================================================
// MODELS
// ============================================================================

class VocabularyCard {
  final String id;
  final String term; // English term
  final String meaning; // English meaning
  final String? pronunciation;
  final String? wordClass;
  final String? exampleSentence;
  final String? vietnameseTerm; // Vietnamese translation
  final String? vietnameseMeaning; // Vietnamese meaning
  final String language;
  final int masteryLevel; // 0: Not learned, 1: Learning, 2: Learned, 3: Mastered
  final double appearanceWeight;
  final int correctCount;
  final int attemptCount;
  final bool isCommon;

  VocabularyCard({
    required this.id,
    required this.term,
    required this.meaning,
    this.pronunciation,
    this.wordClass,
    this.exampleSentence,
    this.vietnameseTerm,
    this.vietnameseMeaning,
    required this.language,
    this.masteryLevel = 0,
    this.appearanceWeight = 1.0,
    this.correctCount = 0,
    this.attemptCount = 0,
    this.isCommon = false,
  });

  factory VocabularyCard.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing vocabulary: ${json['term']}');
    return VocabularyCard(
      id: json['vocab_id'] ?? json['id'] ?? '',
      term: json['term'] ?? '',
      meaning: json['meaning'] ?? '',
      pronunciation: json['pronunciation'],
      wordClass: json['word_class'],
      exampleSentence: json['example_sentence'],
      vietnameseTerm: json['vietnamese_term'] ?? json['vietnamese_translation'],
      vietnameseMeaning: json['vietnamese_meaning'],
      language: json['language'] ?? 'en',
      masteryLevel: json['mastery_level'] ?? 0,
      appearanceWeight: (json['appearance_weight'] ?? 1.0).toDouble(),
      correctCount: json['correct_count'] ?? 0,
      attemptCount: json['attempt_count'] ?? 0,
      isCommon: json['is_common'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'vocab_id': id,
    'term': term,
    'meaning': meaning,
    'pronunciation': pronunciation,
    'word_class': wordClass,
    'example_sentence': exampleSentence,
    'vietnamese_term': vietnameseTerm,
    'vietnamese_meaning': vietnameseMeaning,
    'language': language,
    'mastery_level': masteryLevel,
    'appearance_weight': appearanceWeight,
    'correct_count': correctCount,
    'attempt_count': attemptCount,
    'is_common': isCommon,
  };

  @override
  String toString() => 'VocabularyCard($term - $meaning)';
}

// ============================================================================
// VOCABULARY SERVICE
// ============================================================================

class VocabularyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get random vocabulary cards for a lesson with weighted probability
  /// Prioritizes words not yet learned (mastery_level = 0)
  Future<List<VocabularyCard>> getRandomVocabulary({
    required String lessonId,
    required String userId,
    int limit = 5,
  }) async {
    try {
      print('📚 Fetching random vocabulary for lesson: $lessonId');

      // Query lesson_vocabulary table directly
      final response = await _supabase
          .from('lesson_vocabulary')
          .select()
          .eq('lesson_id', lessonId)
          .limit(limit);

      print('📊 Random vocab response type: ${response.runtimeType}');
      if (response is List) {
        print('📊 Got ${(response as List).length} random vocabulary items');
      }

      if (response == null || (response is List && response.isEmpty)) {
        print('❌ No vocabulary found for lesson: $lessonId');
        return [];
      }

      final List<dynamic> data = response is List ? response : [response];
      print('✅ Fetched ${data.length} vocabulary items');

      return data
          .map((item) {
            final row = item as Map<String, dynamic>;
            return VocabularyCard(
              id: row['id'] ?? '',
              term: row['term'] ?? '',
              meaning: row['meaning'] ?? '',
              pronunciation: row['pronunciation'],
              wordClass: row['word_class'],
              exampleSentence: row['example_sentence'],
              vietnameseTerm: row['vietnamese_term'],
              vietnameseMeaning: row['vietnamese_meaning'],
              language: 'en',
              isCommon: row['is_common'] ?? false,
            );
          })
          .toList();
    } catch (e) {
      print('❌ Error fetching random vocabulary: $e');
      return [];
    }
  }

  /// Get all vocabulary for a lesson (with English and Vietnamese)
  Future<List<VocabularyCard>> getLessonVocabulary({
    required String lessonId,
    required String userId,
    String language = 'en',
  }) async {
    try {
      print('📖 Fetching all vocabulary for lesson: $lessonId (language: $language)');

      // Query lesson_vocabulary table directly
      final response = await _supabase
          .from('lesson_vocabulary')
          .select()
          .eq('lesson_id', lessonId);

      print('📊 Raw response type: ${response.runtimeType}');
      if (response is List) {
        print('📊 Response has ${(response as List).length} records');
      }

      if (response == null || (response is List && response.isEmpty)) {
        print('❌ No vocabulary found for lesson: $lessonId');
        
        // Debug: try to fetch all records to see what lesson IDs exist
        try {
          final allRecords = await _supabase
              .from('lesson_vocabulary')
              .select('lesson_id')
              .limit(5);
          print('🔍 Sample lesson_ids in DB: $allRecords');
        } catch (e) {
          print('🔍 Error fetching sample: $e');
        }
        
        return [];
      }

      final List<dynamic> data = response is List ? response : [response];
      print('✅ Fetched ${data.length} vocabulary items');

      return data
          .map((item) {
            // Transform the row to match VocabularyCard expected format
            final row = item as Map<String, dynamic>;
            return VocabularyCard(
              id: row['id'] ?? '',
              term: row['term'] ?? '',
              meaning: row['meaning'] ?? '',
              pronunciation: row['pronunciation'],
              wordClass: row['word_class'],
              exampleSentence: row['example_sentence'],
              vietnameseTerm: row['vietnamese_term'],
              vietnameseMeaning: row['vietnamese_meaning'],
              language: language,
              isCommon: row['is_common'] ?? false,
            );
          })
          .toList();
    } catch (e) {
      print('❌ Error fetching lesson vocabulary: $e');
      return [];
    }
  }

  /// Update user mastery of a vocabulary word
  /// Call this when user marks as "đã biết" or after answering a question
  Future<bool> updateWordMastery({
    required String userId,
    required String vocabularyId,
    required bool isCorrect,
  }) async {
    try {
      print('📝 Updating mastery: vocabulary=$vocabularyId, correct=$isCorrect');

      await _supabase.rpc(
        'update_user_word_mastery',
        params: {
          'p_user_id': userId,
          'p_lesson_vocabulary_id': vocabularyId,
          'p_is_correct': isCorrect,
        },
      );

      print('✅ Mastery updated');
      return true;
    } catch (e) {
      print('❌ Error updating mastery: $e');
      return false;
    }
  }

  /// Get user's mastery stats for a lesson
  Future<Map<int, int>> getLessonMasteryStats({
    required String lessonId,
    required String userId,
  }) async {
    try {
      print('📊 Fetching mastery stats for lesson: $lessonId');

      final response = await _supabase
          .from('user_word_mastery')
          .select('mastery_level')
          .eq('user_id', userId)
          .inFilter('lesson_vocabulary_id',
              (await _supabase
                      .from('lesson_vocabulary')
                      .select('id')
                      .eq('lesson_id', lessonId))
                  .map((e) => e['id'])
                  .toList());

      // Aggregate stats
      Map<int, int> stats = {0: 0, 1: 0, 2: 0, 3: 0};
      for (var item in response) {
        final level = item['mastery_level'] as int;
        stats[level] = (stats[level] ?? 0) + 1;
      }

      print('✅ Stats: Not learned=${stats[0]}, Learning=${stats[1]}, '
          'Learned=${stats[2]}, Mastered=${stats[3]}');
      return stats;
    } catch (e) {
      print('❌ Error fetching mastery stats: $e');
      return {};
    }
  }

  /// Mark a word as favorite/saved
  Future<bool> toggleFavoriteWord({
    required String userId,
    required String vocabularyId,
  }) async {
    try {
      print('❤️  Toggling favorite: vocabulary=$vocabularyId');

      // Try to get existing record
      final existing = await _supabase
          .from('user_saved_words')
          .select('id')
          .eq('user_id', userId)
          .match({'term': vocabularyId})
          .maybeSingle();

      if (existing != null) {
        // Delete if exists
        await _supabase
            .from('user_saved_words')
            .delete()
            .eq('id', existing['id']);
        print('✅ Removed from favorites');
      } else {
        // Add if not exists
        await _supabase.from('user_saved_words').insert({
          'user_id': userId,
          'term': vocabularyId,
          'language': 'en',
          'is_favorite': true,
          'mastery_level': 1,
        });
        print('✅ Added to favorites');
      }

      return true;
    } catch (e) {
      print('❌ Error toggling favorite: $e');
      return false;
    }
  }

  /// Import headwords from dictionary to lesson vocabulary
  /// Call this to populate lesson with real dictionary data
  Future<int> importEnglishHeadwordsToLesson({
    required String lessonId,
    int limit = 100,
  }) async {
    try {
      print('📥 Importing English headwords to lesson: $lessonId');

      final response = await _supabase.rpc(
        'import_english_headwords_to_lesson',
        params: {
          'p_lesson_id': lessonId,
          'p_limit': limit,
        },
      );

      final count = response as int? ?? 0;
      print('✅ Imported $count words');
      return count;
    } catch (e) {
      print('❌ Error importing headwords: $e');
      return 0;
    }
  }

  /// Import Vietnamese headwords to lesson vocabulary
  Future<int> importVietnameseHeadwordsToLesson({
    required String lessonId,
    int limit = 100,
  }) async {
    try {
      print('📥 Importing Vietnamese headwords to lesson: $lessonId');

      final response = await _supabase.rpc(
        'import_vietnamese_headwords_to_lesson',
        params: {
          'p_lesson_id': lessonId,
          'p_limit': limit,
        },
      );

      final count = response as int? ?? 0;
      print('✅ Imported $count words');
      return count;
    } catch (e) {
      print('❌ Error importing Vietnamese headwords: $e');
      return 0;
    }
  }

  /// Get vocabulary cards view (English with Vietnamese translation)
  Future<List<Map<String, dynamic>>> getLessonVocabularyCards({
    required String lessonId,
    int limit = 50,
  }) async {
    try {
      print('🎴 Fetching vocabulary cards for lesson: $lessonId');

      final response = await _supabase
          .from('lesson_vocabulary')
          .select('*')
          .eq('lesson_id', lessonId)
          .limit(limit);

      print('✅ Fetched ${response.length} vocabulary cards');
      return response;
    } catch (e) {
      print('❌ Error fetching vocabulary cards: $e');
      return [];
    }
  }
}

// ============================================================================
// USAGE EXAMPLES
// ============================================================================

/*
// Example 1: Get random vocabulary (adaptive learning)
final vocabService = VocabularyService();
final currentUser = Supabase.instance.client.auth.currentUser;

final randomVocab = await vocabService.getRandomVocabulary(
  lessonId: 'lesson-id',
  userId: currentUser!.id,
  limit: 5,
);

// Example 2: Mark word as learned
await vocabService.updateWordMastery(
  userId: currentUser.id,
  vocabularyId: 'vocab-id',
  isCorrect: true, // User answered correctly
);

// Example 3: Get mastery stats
final stats = await vocabService.getLessonMasteryStats(
  lessonId: 'lesson-id',
  userId: currentUser.id,
);

// Example 4: Import dictionary words to lesson
await vocabService.importEnglishHeadwordsToLesson(
  lessonId: 'lesson-id',
  limit: 100,
);

// Example 5: Get vocabulary cards (English + Vietnamese)
final cards = await vocabService.getLessonVocabularyCards(
  lessonId: 'lesson-id',
);
*/
