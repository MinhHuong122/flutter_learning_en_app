import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/lesson_model.dart';
import '../models/dictionary_model.dart';

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
      final normalizedLessonId = lessonId.trim();

      // Get lesson
      final lessonResponse = await supabase
          .from('lessons')
          .select()
          .eq('id', normalizedLessonId)
          .single();

      final lesson = Lesson.fromJson(lessonResponse);

      // Get questions - explicitly select all columns to ensure question_type is included
      final questionsResponse = await supabase
          .from('lesson_questions')
          .select(
            'id, lesson_id, question_type, question_text, audio_url, image_url, '
            'question_order, explanation, correct_answer, vietnamese_text, '
            'conversation_context, points, created_at'
          )
          .eq('lesson_id', normalizedLessonId)
          .order('question_order', ascending: true);

      final questions = (questionsResponse as List)
          .map((q) => LessonQuestion.fromJson(q))
          .toList();

      print(
        '📘 Lesson details: id=$normalizedLessonId, title=${lesson.title}, '
        'type=${lesson.lessonType}, configured_total=${lesson.totalQuestions}, '
        'loaded_questions=${questions.length}',
      );
      
      // Debug: Show question_type values from database
      for (var i = 0; i < questions.length; i++) {
        final textPreview = questions[i].questionText.length > 50
            ? questions[i].questionText.substring(0, 50) + '...'
            : questions[i].questionText;
        print('   Q${i + 1}: id=${questions[i].id}, type="${questions[i].questionType}" | "$textPreview"');
      }
      
      if (questions.isEmpty) {
        print(
          '⚠️ No rows found in lesson_questions for lesson_id=$normalizedLessonId. '
          'Please verify lesson_questions.lesson_id matches lessons.id exactly and RLS SELECT policy allows read.',
        );
      }

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

  /// Get the most recent activity time for a parent lesson based on its sub-lessons.
  Future<DateTime?> getParentLessonLastActivity(String userId, String parentLessonId) async {
    try {
      final subLessons = await getSubLessons(parentLessonId);
      if (subLessons.isEmpty) return null;

      final lessonIds = subLessons.map((lesson) => lesson.id).toList();
      final response = await supabase
          .from('user_lesson_progress')
          .select('last_attempted')
          .eq('user_id', userId)
          .inFilter('lesson_id', lessonIds)
          .order('last_attempted', ascending: false)
          .limit(1)
          .maybeSingle();

      final lastAttempted = response?['last_attempted'];
      if (lastAttempted == null) return null;
      return DateTime.tryParse(lastAttempted.toString());
    } catch (e) {
      print('❌ Error getting parent lesson last activity: $e');
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
      if (text.isEmpty) {
        print('⚠️ TTS: Empty text provided');
        return;
      }

      print('🔊 TTS: Speaking "$text" (Language: $language)');
      
      await _initializeTts();
      await tts.setLanguage(language);
      
      final result = await tts.speak(text);
      
      if (result == 1) {
        print('✅ TTS: Successfully spoke "$text"');
      } else {
        print('⚠️ TTS: Failed to speak "$text" (result: $result)');
      }
    } catch (e) {
      print('❌ TTS Error speaking "$text": $e');
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

  // ========== CUSTOM LESSON CREATION METHODS ==========

  /// Create a custom lesson with vocabulary words (saves to OCR schema)
  Future<Map<String, dynamic>?> createCustomLesson({
    required String userId,
    required String title,
    required String description,
    required List<Map<String, String>> vocabularyWords,
  }) async {
    try {
      // Step 1: Create the lesson in ocr_lessons table
      final lessonResponse = await supabase
          .from('ocr_lessons')
          .insert({
            'user_id': userId,
            'title': title,
            'description': description,
            'cloudinary_url': null,
            'cloudinary_public_id': null,
          })
          .select()
          .single();

      final lessonId = lessonResponse['id'] as String;
      print('✅ Created OCR lesson: $lessonId');

      // Step 2: Save vocabulary words in ocr_vocabulary table
      // Deduplicate words to prevent unique constraint violation
      final Set<String> seenTerms = {};
      final List<Map<String, dynamic>> vocabInserts = [];
      for (var word in vocabularyWords) {
        final term = (word['term'] ?? '').trim().toLowerCase();
        if (term.isNotEmpty && !seenTerms.contains(term)) {
          seenTerms.add(term);
          vocabInserts.add({
            'lesson_id': lessonId,
            'term': term,
            'meaning': word['meaning'] ?? '',
            'pronunciation': word['pronunciation'] ?? '',
            'word_class': word['wordClass'] ?? 'noun',
            'example': word['example'] ?? '',
            'vietnamese_term': '',
            'vietnamese_meaning': '',
          });
        }
      }

      if (vocabInserts.isNotEmpty) {
        final vocabResponse = await supabase.from('ocr_vocabulary').insert(vocabInserts).select();
        print('✅ Saved ${vocabResponse.length} vocabulary words to ocr_vocabulary');

        // Step 3: Create initial progress records in ocr_word_progress for each word
        final progressInserts = [];
        for (var vocab in vocabResponse) {
          progressInserts.add({
            'user_id': userId,
            'word_id': vocab['id'],
            'times_studied': 0,
            'times_correct': 0,
            'mastered': false,
          });
        }
        
        if (progressInserts.isNotEmpty) {
          await supabase.from('ocr_word_progress').insert(progressInserts);
          print('✅ Created ${progressInserts.length} progress records');
        }
      }

      return {
        'lessonId': lessonId,
        'title': title,
        'vocabularyCount': vocabularyWords.length,
      };
    } catch (e) {
      print('❌ Error creating custom lesson: $e');
      return null;
    }
  }

  /// Load custom lessons for the current user from OCR_LESSONS table
  Future<List<Map<String, dynamic>>> loadCustomLessons(String userId) async {
    try {
      // Get user's custom lessons from ocr_lessons table
      final response = await supabase
          .from('ocr_lessons')
          .select('''
            id, 
            title, 
            description, 
            created_at,
            ocr_vocabulary(id)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> customLessons = [];

      for (var lesson in response as List) {
        final vocabList = lesson['ocr_vocabulary'] as List? ?? [];
        customLessons.add({
          'id': lesson['id'],
          'name': lesson['title'],
          'description': lesson['description'] ?? '',
          'flashcardCount': vocabList.length,
          'createdAt': lesson['created_at'] ?? DateTime.now().toIso8601String(),
        });
      }

      print('✅ Loaded ${customLessons.length} custom lessons from ocr_lessons');
      return customLessons;
    } catch (e) {
      print('❌ Error loading custom lessons: $e');
      return [];
    }
  }

  /// Get all flashcards/vocabulary for a lesson from OCR_VOCABULARY table
  Future<List<Map<String, dynamic>>> getFlashcardsForLesson(String lessonId) async {
    try {
      final response = await supabase
          .from('ocr_vocabulary')
          .select('id, term, meaning, pronunciation, word_class, vietnamese_term, vietnamese_meaning, example')
          .eq('lesson_id', lessonId)
          .order('created_at', ascending: true);

      final List<Map<String, dynamic>> flashcards = [];
      
      for (var item in response as List) {
        flashcards.add({
          'id': item['id'],
          'word': item['term'] ?? 'Unknown',
          'definition': item['meaning'] ?? 'No definition',
          'pronunciation': item['pronunciation'] ?? '',
          'partOfSpeech': item['word_class'] ?? 'noun',
          'example': item['example'] ?? '',
          'vietnameseTerm': item['vietnamese_term'] ?? '',
          'vietnameseMeaning': item['vietnamese_meaning'] ?? '',
        });
      }

      print('✅ Loaded ${flashcards.length} flashcards from ocr_vocabulary for lesson $lessonId');
      return flashcards;
    } catch (e) {
      print('❌ Error loading flashcards: $e');
      return [];
    }
  }

  /// Get the most recent study time for a custom OCR lesson.
  Future<DateTime?> getCustomLessonLastActivity(String userId, String lessonId) async {
    try {
      final cards = await getFlashcardsForLesson(lessonId);
      if (cards.isEmpty) return null;

      final vocabIds = cards.map((card) => card['id'].toString()).where((id) => id.isNotEmpty).toList();
      if (vocabIds.isEmpty) return null;

      final response = await supabase
          .from('ocr_word_progress')
          .select('last_studied')
          .eq('user_id', userId)
          .inFilter('word_id', vocabIds)
          .order('last_studied', ascending: false)
          .limit(1)
          .maybeSingle();

      final lastStudied = response?['last_studied'];
      if (lastStudied == null) return null;
      return DateTime.tryParse(lastStudied.toString());
    } catch (e) {
      print('❌ Error getting custom lesson last activity: $e');
      return null;
    }
  }

  /// Get OCR lesson progress as a percentage based on studied vocabulary cards.
  Future<double> getCustomLessonProgress(String userId, String lessonId) async {
    try {
      final cards = await getFlashcardsForLesson(lessonId);
      final totalCards = cards.length;
      if (totalCards == 0) return 0.0;

      final vocabIds = cards
          .map((card) => card['id'])
          .whereType<String>()
          .toList();

      if (vocabIds.isEmpty) return 0.0;

      final progressRows = await supabase
          .from('ocr_word_progress')
          .select('word_id, times_studied, mastered')
          .eq('user_id', userId)
          .inFilter('word_id', vocabIds);

      int studiedCount = 0;
      for (final row in progressRows as List) {
        final timesStudied = (row['times_studied'] as num?)?.toInt() ?? 0;
        if (timesStudied > 0 || row['mastered'] == true) {
          studiedCount++;
        }
      }

      return (studiedCount / totalCards) * 100;
    } catch (e) {
      print('❌ Error loading OCR lesson progress: $e');
      return 0.0;
    }
  }

  /// Update study progress for a single OCR vocabulary word.
  Future<bool> updateOcrWordProgress({
    required String userId,
    required String wordId,
    required bool gotIt,
  }) async {
    try {

      // Check xem progress row đã tồn tại chưa
      final existing = await supabase
          .from('ocr_word_progress')
          .select('id, times_studied, times_correct')
          .eq('user_id', userId)
          .eq('word_id', wordId)
          .maybeSingle();

      final now = DateTime.now().toIso8601String();

      if (existing == null) {
        await supabase.from('ocr_word_progress').insert({
          'user_id': userId,
          'word_id': wordId,
          'times_studied': 1,
          'times_correct': gotIt ? 1 : 0,
          'last_studied': now,
          'mastered': false,
        });
      } else {
        final currentTimesStudied = (existing['times_studied'] as num?)?.toInt() ?? 0;
        final currentTimesCorrect = (existing['times_correct'] as num?)?.toInt() ?? 0;
        final updatedTimesStudied = currentTimesStudied + 1;
        final updatedTimesCorrect = currentTimesCorrect + (gotIt ? 1 : 0);
        final updatedMastered = updatedTimesCorrect >= 3;

        await supabase
            .from('ocr_word_progress')
            .update({
              'times_studied': updatedTimesStudied,
              'times_correct': updatedTimesCorrect,
              'last_studied': now,
              'mastered': updatedMastered,
            })
            .eq('id', existing['id']);
      }

      return true;
    } catch (e) {
      print('❌ Error updating OCR word progress: $e');
      return false;
    }
  }

  /// Delete a custom lesson and all its vocabulary from OCR tables
  Future<bool> deleteCustomLesson(String lessonId) async {
    try {
      // Step 1: Delete OCR vocabulary words
      // NOTE: ocr_word_progress will be auto-deleted via CASCADE foreign key
      await supabase
          .from('ocr_vocabulary')
          .delete()
          .eq('lesson_id', lessonId);
      print('✅ Deleted OCR vocabulary words (progress auto-deleted via CASCADE)');

      // Step 2: Delete the OCR lesson
      await supabase
          .from('ocr_lessons')
          .delete()
          .eq('id', lessonId);
      print('✅ Deleted custom lesson from ocr_lessons: $lessonId');

      return true;
    } catch (e) {
      print('❌ Error deleting custom lesson: $e');
      return false;
    }
  }

  /// Save new vocabulary words to english_headwords table if they don't exist
  Future<bool> saveNewEnglishWords(List<Map<String, String>> vocabularyWords) async {
    try {
      for (var word in vocabularyWords) {
        final term = (word['term'] ?? '').trim().toLowerCase();
        if (term.isEmpty) continue;

        // Check if word already exists
        final existing = await supabase
            .from('english_headwords')
            .select('id')
            .eq('term', term)
            .maybeSingle();

        // Only insert if doesn't exist
        if (existing == null) {
          // Word doesn't exist, so save it
          await supabase.from('english_headwords').insert({
            'term': term,
            'pronunciation': word['pronunciation'] ?? '',
            'word_class': word['wordClass'] ?? 'noun',
            'meaning': word['meaning'] ?? 'New vocabulary word',
            'is_common': false,
            'frequency': 0,
          });
          print('✅ Saved new English word: $term');
        }
      }
      return true;
    } catch (e) {
      print('⚠️ Error saving new English words: $e');
      return false;
    }
  }

  /// Get lesson vocabulary as DictionaryEntry list for editing
  Future<List<DictionaryEntry>> getLessonVocabulary(String lessonId) async {
    try {
      print('📚 Fetching vocabulary for lesson: $lessonId');
      final response = await supabase
          .from('ocr_vocabulary')
          .select('id, term, meaning, pronunciation, word_class')
          .eq('lesson_id', lessonId)
          .order('created_at', ascending: true);

      print('✅ Got response: ${(response as List).length} items');
      
      final List<DictionaryEntry> vocabulary = [];
      
      for (var item in response as List) {
        try {
          vocabulary.add(
            DictionaryEntry(
              id: int.tryParse(item['id'].toString()) ?? (vocabulary.length + 1),
              term: item['term'] ?? 'Unknown',
              language: 'en',
              pronunciation: item['pronunciation'] ?? '',
              wordClass: item['word_class'] ?? 'noun',
              meaning: item['meaning'] ?? '',
              isCommon: false,
              frequency: 0,
            ),
          );
        } catch (e) {
          print('⚠️ Error parsing vocabulary item: $e, item: $item');
        }
      }

      print('✅ Loaded ${vocabulary.length} vocabulary items for lesson $lessonId');
      return vocabulary;
    } catch (e) {
      print('❌ Error loading lesson vocabulary: $e');
      return [];
    }
  }

  /// Update an existing custom lesson
  Future<Map<String, dynamic>?> updateCustomLesson({
    required String lessonId,
    required String title,
    required String description,
    required List<Map<String, String>> vocabularyWords,
  }) async {
    try {
      // Step 1: Update lesson info
      await supabase
          .from('ocr_lessons')
          .update({
            'title': title,
            'description': description,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', lessonId);
      print('✅ Updated lesson info for $lessonId');

      // Step 2: Delete existing vocabulary
      await supabase
          .from('ocr_vocabulary')
          .delete()
          .eq('lesson_id', lessonId);
      print('✅ Deleted old vocabulary for lesson $lessonId');

      // Step 3: Get user_id from lesson
      final lessonData = await supabase
          .from('ocr_lessons')
          .select('user_id')
          .eq('id', lessonId)
          .single();
      
      final userId = lessonData['user_id'] as String;

      // Step 4: Insert new vocabulary words
      final Set<String> seenTerms = {};
      final List<Map<String, dynamic>> vocabInserts = [];
      
      for (var word in vocabularyWords) {
        final term = (word['term'] ?? '').trim().toLowerCase();
        if (term.isNotEmpty && !seenTerms.contains(term)) {
          seenTerms.add(term);
          vocabInserts.add({
            'lesson_id': lessonId,
            'term': term,
            'meaning': word['meaning'] ?? '',
            'pronunciation': word['pronunciation'] ?? '',
            'word_class': word['wordClass'] ?? 'noun',
            'example': word['example'] ?? '',
            'vietnamese_term': '',
            'vietnamese_meaning': '',
          });
        }
      }

      // Insert new vocabulary
      if (vocabInserts.isNotEmpty) {
        final vocabResponse = await supabase
            .from('ocr_vocabulary')
            .insert(vocabInserts)
            .select();
        print('✅ Saved ${vocabResponse.length} updated vocabulary words');

        // Step 5: Create progress records for new words
        final progressInserts = [];
        for (var vocab in vocabResponse) {
          progressInserts.add({
            'user_id': userId,
            'word_id': vocab['id'],
            'times_studied': 0,
            'times_correct': 0,
            'mastered': false,
          });
        }
        
        if (progressInserts.isNotEmpty) {
          await supabase.from('ocr_word_progress').insert(progressInserts);
          print('✅ Created ${progressInserts.length} progress records');
        }
      }

      return {
        'lessonId': lessonId,
        'title': title,
        'vocabularyCount': vocabularyWords.length,
      };
    } catch (e) {
      print('❌ Error updating custom lesson: $e');
      return null;
    }
  }

  /// Share custom lesson to community
  Future<bool> shareCustomLessonToCommunity({
    required String lessonId,
    required String userId,
    required String title,
    required String description,
    required List<Map<String, dynamic>> flashcards,
  }) async {
    try {
      // Create shared lesson entry
      final sharedLessonData = {
        'original_lesson_id': lessonId,
        'user_id': userId,
        'title': title,
        'description': description,
        'flashcard_count': flashcards.length,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await supabase
          .from('shared_lessons')
          .insert(sharedLessonData)
          .select()
          .single();

      final sharedLessonId = response['id'] as String;
      print('✅ Created shared lesson: $sharedLessonId');

      // Share the flashcards
      final sharedFlashcards = flashcards.map((card) {
        return {
          'shared_lesson_id': sharedLessonId,
          'term': card['word'] ?? card['term'] ?? '',
          'meaning': card['definition'] ?? card['meaning'] ?? '',
          'pronunciation': card['pronunciation'] ?? '',
          'word_class': card['partOfSpeech'] ?? card['word_class'] ?? 'noun',
          'example': card['example'] ?? '',
        };
      }).toList();

      if (sharedFlashcards.isNotEmpty) {
        await supabase
            .from('shared_flashcards')
            .insert(sharedFlashcards);
        print('✅ Shared ${sharedFlashcards.length} flashcards');
      }

      return true;
    } catch (e) {
      print('❌ Error sharing lesson to community: $e');
      return false;
    }
  }

  /// Get shared lessons from community
  Future<List<Map<String, dynamic>>> getSharedLessons() async {
    try {
      final response = await supabase
          .from('shared_lessons')
          .select('id, user_id, title, description, flashcard_count, created_at, ocr_lessons(user_id)')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> sharedLessons = [];
      
      for (var lesson in response as List) {
        sharedLessons.add({
          'id': lesson['id'],
          'userId': lesson['user_id'],
          'title': lesson['title'],
          'description': lesson['description'] ?? '',
          'flashcardCount': lesson['flashcard_count'] ?? 0,
          'createdAt': lesson['created_at'] ?? DateTime.now().toIso8601String(),
        });
      }

      print('✅ Loaded ${sharedLessons.length} shared lessons from community');
      return sharedLessons;
    } catch (e) {
      print('❌ Error loading shared lessons: $e');
      return [];
    }
  }

  /// Save shared lesson to user's custom lessons
  Future<bool> saveSharedLessonToCustom({
    required String sharedLessonId,
    required String userId,
  }) async {
    try {
      // Get shared lesson details
      final sharedLesson = await supabase
          .from('shared_lessons')
          .select('title, description, original_lesson_id')
          .eq('id', sharedLessonId)
          .single();

      // Create new custom lesson for user
      final newLessonData = {
        'user_id': userId,
        'title': '${sharedLesson['title']} (Shared)',
        'description': sharedLesson['description'] ?? '',
        'cloudinary_url': null,
        'cloudinary_public_id': null,
      };

      final lessonResponse = await supabase
          .from('ocr_lessons')
          .insert(newLessonData)
          .select()
          .single();

      final newLessonId = lessonResponse['id'] as String;
      print('✅ Created new custom lesson: $newLessonId');

      // Get shared flashcards
      final sharedFlashcards = await supabase
          .from('shared_flashcards')
          .select('term, meaning, pronunciation, word_class, example')
          .eq('shared_lesson_id', sharedLessonId);

      // Copy flashcards to new lesson
      if ((sharedFlashcards as List).isNotEmpty) {
        final flashcardsToInsert = (sharedFlashcards as List).map((card) {
          return {
            'lesson_id': newLessonId,
            'term': card['term'] ?? '',
            'meaning': card['meaning'] ?? '',
            'pronunciation': card['pronunciation'] ?? '',
            'word_class': card['word_class'] ?? 'noun',
            'example': card['example'] ?? '',
            'vietnamese_term': '',
            'vietnamese_meaning': '',
          };
        }).toList();

        await supabase
            .from('ocr_vocabulary')
            .insert(flashcardsToInsert);
        print('✅ Copied ${flashcardsToInsert.length} flashcards to new lesson');
      }

      return true;
    } catch (e) {
      print('❌ Error saving shared lesson: $e');
      return false;
    }
  }
}

