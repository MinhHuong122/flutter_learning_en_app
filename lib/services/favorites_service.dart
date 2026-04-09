import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lesson_model.dart';

class FavoritesService {
  static const String _favLessonsKey = 'favorite_lessons';

  Future<List<Lesson>> getFavoriteLessons() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_favLessonsKey) ?? [];
    return data
        .map((json) => Lesson.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  Future<bool> isFavorite(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_favLessonsKey) ?? [];
    return data.any((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map['id'] == lessonId;
    });
  }

  Future<void> addFavorite(Lesson lesson) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_favLessonsKey) ?? [];
    final alreadyExists = data.any((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map['id'] == lesson.id;
    });
    if (!alreadyExists) {
      data.add(jsonEncode(lesson.toJson()));
      await prefs.setStringList(_favLessonsKey, data);
    }
  }

  Future<void> removeFavorite(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_favLessonsKey) ?? [];
    data.removeWhere((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map['id'] == lessonId;
    });
    await prefs.setStringList(_favLessonsKey, data);
  }

  /// Returns `true` if the lesson is now favourited, `false` if removed.
  Future<bool> toggleFavorite(Lesson lesson) async {
    final fav = await isFavorite(lesson.id);
    if (fav) {
      await removeFavorite(lesson.id);
      return false;
    } else {
      await addFavorite(lesson);
      return true;
    }
  }
}
