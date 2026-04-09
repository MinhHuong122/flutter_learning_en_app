import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lesson_model.dart';

class LessonFavoritesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Lesson>> getUserFavoriteLessons() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final rows = await _supabase
          .from('user_favorite_lessons')
          .select('lesson_id, lessons(*)')
          .eq('user_id', user.id);

      final lessons = <Lesson>[];
      for (final row in rows as List) {
        final lessonJson = row['lessons'];
        if (lessonJson is Map<String, dynamic>) {
          lessons.add(Lesson.fromJson(lessonJson));
        }
      }
      return lessons;
    } catch (e) {
      print('Error fetching favorite lessons: $e');
      return [];
    }
  }

  Future<bool> isFavorite(String lessonId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final result = await _supabase
          .from('user_favorite_lessons')
          .select('id')
          .eq('user_id', user.id)
          .eq('lesson_id', lessonId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      print('Error checking favorite lesson: $e');
      return false;
    }
  }

  Future<bool> addFavorite(String lessonId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase.from('user_favorite_lessons').upsert({
        'user_id': user.id,
        'lesson_id': lessonId,
      });
      return true;
    } catch (e) {
      print('Error adding favorite lesson: $e');
      return false;
    }
  }

  Future<bool> removeFavorite(String lessonId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('user_favorite_lessons')
          .delete()
          .eq('user_id', user.id)
          .eq('lesson_id', lessonId);
      return true;
    } catch (e) {
      print('Error removing favorite lesson: $e');
      return false;
    }
  }

  Future<bool?> toggleFavorite(String lessonId) async {
    final fav = await isFavorite(lessonId);
    if (fav) {
      final ok = await removeFavorite(lessonId);
      return ok ? false : null;
    }

    final ok = await addFavorite(lessonId);
    return ok ? true : null;
  }
}
