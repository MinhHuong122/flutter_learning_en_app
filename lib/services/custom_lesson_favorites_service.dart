import 'package:supabase_flutter/supabase_flutter.dart';

class CustomLessonFavoritesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get user's favorite custom lessons
  Future<List<Map<String, dynamic>>> getUserFavoriteCustomLessons() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        return [];
      }

      // Query with JOIN to get ocr_lessons with vocabulary count
      final rows = await _supabase
          .from('user_favorite_custom_lessons')
          .select('''
            ocr_lesson_id,
            ocr_lessons(
              id,
              title,
              description,
              created_at,
              ocr_vocabulary(id)
            )
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final lessons = <Map<String, dynamic>>[];
      
      for (final row in rows as List) {
        final ocrLessonData = row['ocr_lessons'];
        
        if (ocrLessonData is Map<String, dynamic>) {
          final vocabList = ocrLessonData['ocr_vocabulary'] as List? ?? [];
          
          lessons.add({
            'id': ocrLessonData['id'],
            'name': ocrLessonData['title'] ?? 'Untitled',
            'description': ocrLessonData['description'] ?? '',
            'flashcardCount': vocabList.length,
            'createdAt': ocrLessonData['created_at'] ?? DateTime.now().toIso8601String(),
          });
        }
      }
      
      print('✅ Loaded ${lessons.length} favorite custom lessons');
      return lessons;
    } catch (e) {
      print('❌ Error fetching favorite custom lessons: $e');
      return [];
    }
  }

  // Check if a custom lesson is favorited
  Future<bool> isFavorite(String ocrLessonId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final result = await _supabase
          .from('user_favorite_custom_lessons')
          .select('id')
          .eq('user_id', user.id)
          .eq('ocr_lesson_id', ocrLessonId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      print('❌ Error checking favorite custom lesson: $e');
      return false;
    }
  }

  // Add custom lesson to favorites
  Future<bool> addFavorite(String ocrLessonId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      print('💛 Adding custom lesson to favorites: $ocrLessonId');
      
      await _supabase.from('user_favorite_custom_lessons').upsert({
        'user_id': user.id,
        'ocr_lesson_id': ocrLessonId,
      });
      
      print('✅ Added custom lesson to favorites: $ocrLessonId');
      return true;
    } catch (e) {
      print('❌ Error adding favorite custom lesson: $e');
      return false;
    }
  }

  // Remove custom lesson from favorites
  Future<bool> removeFavorite(String ocrLessonId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      print('💔 Removing custom lesson from favorites: $ocrLessonId');
      
      await _supabase
          .from('user_favorite_custom_lessons')
          .delete()
          .eq('user_id', user.id)
          .eq('ocr_lesson_id', ocrLessonId);
      
      print('✅ Removed custom lesson from favorites: $ocrLessonId');
      return true;
    } catch (e) {
      print('❌ Error removing favorite custom lesson: $e');
      return false;
    }
  }

  // Toggle favorite status for custom lesson
  Future<bool?> toggleFavorite(String ocrLessonId) async {
    try {
      final fav = await isFavorite(ocrLessonId);
      if (fav) {
        final ok = await removeFavorite(ocrLessonId);
        return ok ? false : null;
      }

      final ok = await addFavorite(ocrLessonId);
      return ok ? true : null;
    } catch (e) {
      print('❌ Error toggling favorite custom lesson: $e');
      return null;
    }
  }
}
