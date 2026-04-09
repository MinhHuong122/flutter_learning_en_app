import 'package:flutter/foundation.dart';
import '../models/lesson_model.dart';
import '../services/lesson_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LessonProvider extends ChangeNotifier {
  final LessonService _lessonService = LessonService();
  
  List<Lesson> _allLessons = [];
  Map<String, double> _progressCache = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Lesson> get allLessons => _allLessons;
  Map<String, double> get progressCache => _progressCache;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all lessons once and cache progress
  Future<void> loadLessonsOnce() async {
    if (_allLessons.isNotEmpty) {
      // Data already loaded, skip
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _error = 'User not authenticated';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Load all parent lessons (system lessons only, not custom lessons)
      _allLessons = await _lessonService.getParentLessons();
      
      // Calculate and cache progress for all lessons
      _progressCache.clear();
      for (var lesson in _allLessons) {
        final progress = await _calculateRealProgress(lesson, userId);
        _progressCache[lesson.id] = progress;
        print('✅ Cached progress for ${lesson.title}: ${progress.toStringAsFixed(1)}%');
      }

      _error = null;
    } catch (e) {
      _error = 'Error loading lessons: $e';
      print('❌ Error in LessonProvider.loadLessonsOnce: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get filtered lessons for display
  List<Lesson> getFilteredLessons(String filter) {
    List<Lesson> filtered = List.from(_allLessons);

    if (filter == 'popular') {
      filtered.sort((a, b) {
        final questionCompare = (b.totalQuestions ?? 0).compareTo(a.totalQuestions ?? 0);
        if (questionCompare != 0) return questionCompare;

        final createdA = a.createdAt;
        final createdB = b.createdAt;
        if (createdA != null && createdB != null) {
          final createdCompare = createdB.compareTo(createdA);
          if (createdCompare != 0) return createdCompare;
        }
        return a.lessonOrder.compareTo(b.lessonOrder);
      });
    } else if (filter == 'newest') {
      filtered.sort((a, b) {
        final createdA = a.createdAt;
        final createdB = b.createdAt;
        if (createdA != null && createdB != null) {
          final createdCompare = createdB.compareTo(createdA);
          if (createdCompare != 0) return createdCompare;
        }
        return a.lessonOrder.compareTo(b.lessonOrder);
      });
    } else if (filter == 'advance') {
      filtered = filtered.where((l) => l.level == 'advanced').toList();
    }

    return filtered;
  }

  // Get lessons filtered by progress status
  List<Lesson> getLessonsByStatus(String status) {
    if (status == 'ongoing') {
      return _allLessons.where((l) {
        final p = _progressCache[l.id] ?? 0.0;
        return p < 100 && p > 0;
      }).toList();
    } else if (status == 'completed') {
      return _allLessons.where((l) => (_progressCache[l.id] ?? 0.0) == 100).toList();
    }
    return _allLessons;
  }

  // Get progress for a lesson
  double getProgress(String lessonId) {
    return _progressCache[lessonId] ?? 0.0;
  }

  // Calculate overall progress statistics
  Map<String, dynamic> getProgressStats() {
    if (_allLessons.isEmpty) {
      return {
        'overallProgress': 0.0,
        'totalLessons': 0,
        'completedLessons': 0,
        'ongoingCount': 0,
      };
    }

    double totalProgress = 0.0;
    int completedCount = 0;
    int ongoingCount = 0;

    for (var lesson in _allLessons) {
      final progress = _progressCache[lesson.id] ?? 0.0;
      totalProgress += progress;
      if (progress == 100) {
        completedCount++;
      } else if (progress > 0) {
        ongoingCount++;
      }
    }

    return {
      'overallProgress': (totalProgress / _allLessons.length),
      'totalLessons': _allLessons.length,
      'completedLessons': completedCount,
      'ongoingCount': ongoingCount,
    };
  }

  // Calculate real progress for a lesson
  Future<double> _calculateRealProgress(Lesson lesson, String userId) async {
    try {
      final subLessons = await _lessonService.getSubLessons(lesson.id);
      if (subLessons.isEmpty) return 0.0;

      int totalProgressPercent = 0;
      for (var subLesson in subLessons) {
        final progress = await _lessonService.getUserProgress(userId, subLesson.id);
        if (progress != null) {
          totalProgressPercent += progress.progressPercentage;
        }
      }

      return (totalProgressPercent / subLessons.length).toDouble();
    } catch (e) {
      print('❌ Error calculating progress: $e');
      return 0.0;
    }
  }

  // Force refresh (if user completes a lesson)
  Future<void> refresh() async {
    _allLessons.clear();
    _progressCache.clear();
    await loadLessonsOnce();
  }
}
