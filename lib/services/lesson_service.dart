import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/lesson_model.dart';

class LessonService {
  static final LessonService _instance = LessonService._internal();
  final supabase = Supabase.instance.client;
  final FlutterTts tts = FlutterTts();
  bool _ttsInitialized = false;
  
  LessonService._internal();

  factory LessonService() {
    return _instance;
  }

  Future<void> _initializeTts() async {
    if (_ttsInitialized) return;
    try {
      await tts.setPitch(1.0);
      await tts.setSpeechRate(0.5);
      await tts.setLanguage('en-US');
      _ttsInitialized = true;
    } catch (e) {
      print('Error initializing TTS: $e');
    }
  }

  // Get all lessons
  Future<List<Lesson>> getAllLessons() async {
    try {
      final response = await supabase
          .from('lessons')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((lesson) => Lesson.fromJson(lesson))
          .toList();
    } catch (e) {
      print('Error fetching lessons: $e');
      return [];
    }
  }

  // Get lesson by ID with its questions and options
  Future<Map<String, dynamic>?> getLessonDetails(String lessonId) async {
    try {
      // Get lesson
      final lessonResponse = await supabase
          .from('lessons')
          .select()
          .eq('id', lessonId)
          .single();

      final lesson = Lesson.fromJson(lessonResponse);

      // Get questions
      final questionsResponse = await supabase
          .from('lesson_questions')
          .select()
          .eq('lesson_id', lessonId)
          .order('question_order', ascending: true);

      final questions = (questionsResponse as List)
          .map((q) => LessonQuestion.fromJson(q))
          .toList();

      // Get options for each question
      final Map<String, List<LessonOption>> optionsByQuestion = {};
      for (var question in questions) {
        final optionsResponse = await supabase
            .from('lesson_options')
            .select()
            .eq('question_id', question.id)
            .order('option_order', ascending: true);

        optionsByQuestion[question.id] = (optionsResponse as List)
            .map((o) => LessonOption.fromJson(o))
            .toList();
      }

      return {
        'lesson': lesson,
        'questions': questions,
        'options': optionsByQuestion,
      };
    } catch (e) {
      print('Error fetching lesson details: $e');
      return null;
    }
  }

  // Get user progress for a lesson
  Future<UserLessonProgress?> getUserProgress(
      String userId, String lessonId) async {
    try {
      final response = await supabase
          .from('user_lesson_progress')
          .select()
          .eq('user_id', userId)
          .eq('lesson_id', lessonId)
          .maybeSingle();

      if (response == null) return null;
      return UserLessonProgress.fromJson(response);
    } catch (e) {
      print('Error fetching user progress: $e');
      return null;
    }
  }

  // Update user progress
  Future<bool> updateUserProgress({
    required String userId,
    required String lessonId,
    required bool completed,
    required int progressPercentage,
    required int correctAnswers,
    required int totalAttempts,
  }) async {
    try {
      final progress = await getUserProgress(userId, lessonId);
      
      if (progress == null) {
        // Insert new progress
        await supabase.from('user_lesson_progress').insert({
          'user_id': userId,
          'lesson_id': lessonId,
          'completed': completed,
          'progress_percentage': progressPercentage,
          'correct_answers': correctAnswers,
          'total_attempts': totalAttempts,
          'last_attempted': DateTime.now().toIso8601String(),
        });
      } else {
        // Update existing progress
        await supabase
            .from('user_lesson_progress')
            .update({
              'completed': completed,
              'progress_percentage': progressPercentage,
              'correct_answers': correctAnswers,
              'total_attempts': totalAttempts + 1,
              'last_attempted': DateTime.now().toIso8601String(),
            })
            .eq('id', progress.id);
      }
      return true;
    } catch (e) {
      print('Error updating user progress: $e');
      return false;
    }
  }

  // Save user answer
  Future<bool> saveUserAnswer({
    required String userId,
    required String questionId,
    String? selectedOptionId,
    bool? isCorrect,
    String? answerText,
  }) async {
    try {
      await supabase.from('user_answers').insert({
        'user_id': userId,
        'question_id': questionId,
        'selected_option_id': selectedOptionId,
        'is_correct': isCorrect,
        'answer_text': answerText,
      });
      return true;
    } catch (e) {
      print('Error saving user answer: $e');
      return false;
    }
  }

  // Text to Speech functionality
  Future<void> speak(String text, {String language = 'en-US'}) async {
    try {
      await _initializeTts();
      await tts.setLanguage(language);
      await tts.speak(text);
    } catch (e) {
      print('Error speaking: $e');
    }
  }

  Future<void> setSpeechRate(double rate) async {
    try {
      await _initializeTts();
      await tts.setSpeechRate(rate);
    } catch (e) {
      print('Error setting speech rate: $e');
    }
  }

  Future<void> setPitch(double pitch) async {
    try {
      await _initializeTts();
      await tts.setPitch(pitch);
    } catch (e) {
      print('Error setting pitch: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _initializeTts();
      await tts.stop();
    } catch (e) {
      print('Error stopping speech: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _initializeTts();
      await tts.pause();
    } catch (e) {
      print('Error pausing speech: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _initializeTts();
      await tts.setVolume(volume);
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  // Get lessons by lesson type
  Future<List<Lesson>> getLessonsByType(String lessonType) async {
    try {
      final response = await supabase
          .from('lessons')
          .select()
          .eq('lesson_type', lessonType)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((lesson) => Lesson.fromJson(lesson))
          .toList();
    } catch (e) {
      print('Error fetching lessons by type: $e');
      return [];
    }
  }

  // Get lessons by level
  Future<List<Lesson>> getLessonsByLevel(String level) async {
    try {
      final response = await supabase
          .from('lessons')
          .select()
          .eq('level', level)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((lesson) => Lesson.fromJson(lesson))
          .toList();
    } catch (e) {
      print('Error fetching lessons by level: $e');
      return [];
    }
  }

  // Get all lessons with user progress
  Future<List<Map<String, dynamic>>> getAllLessonsWithProgress(
      String userId) async {
    try {
      final lessons = await getAllLessons();
      final List<Map<String, dynamic>> result = [];

      for (var lesson in lessons) {
        final progress = await getUserProgress(userId, lesson.id);
        result.add({
          'lesson': lesson,
          'progress': progress,
        });
      }

      return result;
    } catch (e) {
      print('Error fetching lessons with progress: $e');
      return [];
    }
  }

  // ========== HIERARCHICAL LESSON METHODS ==========
  
  // Get all parent lessons (main topics)
  Future<List<Lesson>> getParentLessons() async {
    try {
      final response = await supabase
          .from('lessons')
          .select()
          .filter('parent_lesson_id', 'is', null)
          .order('lesson_order', ascending: true);
      
      return (response as List)
          .map((lesson) => Lesson.fromJson(lesson))
          .toList();
    } catch (e) {
      print('Error fetching parent lessons: $e');
      return [];
    }
  }

  // Get sub-lessons for a specific parent lesson
  Future<List<Lesson>> getSubLessons(String parentLessonId) async {
    try {
      final response = await supabase
          .from('lessons')
          .select()
          .eq('parent_lesson_id', parentLessonId)
          .order('lesson_order', ascending: true);
      
      return (response as List)
          .map((lesson) => Lesson.fromJson(lesson))
          .toList();
    } catch (e) {
      print('Error fetching sub-lessons: $e');
      return [];
    }
  }

  // Get all parent lessons with their sub-lessons
  Future<List<Map<String, dynamic>>> getParentLessonsWithSubLessons() async {
    try {
      final parentLessons = await getParentLessons();
      final List<Map<String, dynamic>> result = [];

      for (var parent in parentLessons) {
        final subLessons = await getSubLessons(parent.id);
        result.add({
          'parent': parent,
          'subLessons': subLessons,
        });
      }

      return result;
    } catch (e) {
      print('Error fetching parent lessons with sub-lessons: $e');
      return [];
    }
  }

  // Get parent lesson of a sub-lesson
  Future<Lesson?> getParentLesson(String subLessonId) async {
    try {
      // First get the sub-lesson to find its parent ID
      final subLessonResponse = await supabase
          .from('lessons')
          .select()
          .eq('id', subLessonId)
          .single();
      
      final subLesson = Lesson.fromJson(subLessonResponse);
      
      if (subLesson.parentLessonId == null) {
        return null; // This is already a parent lesson
      }

      // Get the parent lesson
      final parentResponse = await supabase
          .from('lessons')
          .select()
          .eq('id', subLesson.parentLessonId!)
          .single();

      return Lesson.fromJson(parentResponse);
    } catch (e) {
      print('Error fetching parent lesson: $e');
      return null;
    }
  }

  // Get total duration and questions for a parent lesson (sum of sub-lessons)
  Future<Map<String, int>> getParentLessonStats(String parentLessonId) async {
    try {
      final subLessons = await getSubLessons(parentLessonId);
      
      int totalDuration = 0;
      int totalQuestions = 0;

      for (var lesson in subLessons) {
        totalDuration += lesson.durationMinutes ?? 0;
        totalQuestions += lesson.totalQuestions ?? 0;
      }

      return {
        'totalDuration': totalDuration,
        'totalQuestions': totalQuestions,
        'subLessonsCount': subLessons.length,
      };
    } catch (e) {
      print('Error calculating parent lesson stats: $e');
      return {
        'totalDuration': 0,
        'totalQuestions': 0,
        'subLessonsCount': 0,
      };
    }
  }
}
