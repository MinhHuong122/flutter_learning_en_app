class Lesson {
  final String id;
  final String title;
  final String description;
  final String level; // 'beginner', 'intermediate', 'advanced'
  final String lessonType; // 'multiple_choice', 'listening', 'matching', etc.
  final String? thumbnailUrl;
  final int? durationMinutes;
  final int? totalQuestions;
  final String? parentLessonId; // For hierarchical lessons
  final int lessonOrder; // Order within parent or main list
  final DateTime? createdAt;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.lessonType,
    this.thumbnailUrl,
    this.durationMinutes,
    this.totalQuestions,
    this.parentLessonId,
    this.lessonOrder = 0,
    this.createdAt,
  });

  // Check if this is a parent lesson (has no parent)
  bool get isParent => parentLessonId == null;

  // Check if this is a sub-lesson (has a parent)
  bool get isSubLesson => parentLessonId != null;

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      level: json['level'] as String? ?? 'beginner',
      lessonType: json['lesson_type'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      totalQuestions: json['total_questions'] as int?,
      parentLessonId: json['parent_lesson_id'] as String?,
      lessonOrder: json['lesson_order'] as int? ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'level': level,
    'lesson_type': lessonType,
    'thumbnail_url': thumbnailUrl,
    'duration_minutes': durationMinutes,
    'total_questions': totalQuestions,
    'parent_lesson_id': parentLessonId,
    'lesson_order': lessonOrder,
    'created_at': createdAt?.toIso8601String(),
  };
}

class LessonQuestion {
  final String id;
  final String lessonId;
  final String? questionType; // 'multiple_choice', 'fill_blank', 'matching', etc.
  final String questionText;
  final String? audioUrl;
  final String? imageUrl;
  final int questionOrder;
  final String? explanation;
  final String? correctAnswer; // For fill_blank, translation
  final String? vietnameseText; // For translation exercises
  final String? conversationContext; // For conversation exercises
  final int? points;
  final DateTime? createdAt;

  LessonQuestion({
    required this.id,
    required this.lessonId,
    this.questionType,
    required this.questionText,
    this.audioUrl,
    this.imageUrl,
    required this.questionOrder,
    this.explanation,
    this.correctAnswer,
    this.vietnameseText,
    this.conversationContext,
    this.points,
    this.createdAt,
  });

  factory LessonQuestion.fromJson(Map<String, dynamic> json) {
    return LessonQuestion(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String,
      questionType: json['question_type'] as String?,
      questionText: json['question_text'] as String,
      audioUrl: json['audio_url'] as String?,
      imageUrl: json['image_url'] as String?,
      questionOrder: json['question_order'] as int,
      explanation: json['explanation'] as String?,
      correctAnswer: json['correct_answer'] as String?,
      vietnameseText: json['vietnamese_text'] as String?,
      conversationContext: json['conversation_context'] as String?,
      points: json['points'] as int?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'lesson_id': lessonId,
    'question_type': questionType,
    'question_text': questionText,
    'audio_url': audioUrl,
    'image_url': imageUrl,
    'question_order': questionOrder,
    'explanation': explanation,
    'correct_answer': correctAnswer,
    'vietnamese_text': vietnameseText,
    'conversation_context': conversationContext,
    'points': points,
    'created_at': createdAt?.toIso8601String(),
  };
}

class LessonOption {
  final String id;
  final String questionId;
  final String optionText;
  final String? optionImageUrl;
  final bool isCorrect;
  final int optionOrder;
  final String? explanation;
  final String? matchPairId; // For matching exercises
  final DateTime? createdAt;

  LessonOption({
    required this.id,
    required this.questionId,
    required this.optionText,
    this.optionImageUrl,
    required this.isCorrect,
    required this.optionOrder,
    this.explanation,
    this.matchPairId,
    this.createdAt,
  });

  factory LessonOption.fromJson(Map<String, dynamic> json) {
    return LessonOption(
      id: json['id'] as String,
      questionId: json['question_id'] as String,
      optionText: json['option_text'] as String,
      optionImageUrl: json['option_image_url'] as String?,
      isCorrect: json['is_correct'] as bool? ?? false,
      optionOrder: json['option_order'] as int,
      explanation: json['explanation'] as String?,
      matchPairId: json['match_pair_id'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'question_id': questionId,
    'option_text': optionText,
    'option_image_url': optionImageUrl,
    'is_correct': isCorrect,
    'option_order': optionOrder,
    'explanation': explanation,
    'match_pair_id': matchPairId,
    'created_at': createdAt?.toIso8601String(),
  };
}

class UserLessonProgress {
  final String id;
  final String userId;
  final String lessonId;
  final bool completed;
  final int progressPercentage;
  final int correctAnswers;
  final int totalAttempts;
  final DateTime? lastAttempted;
  final DateTime? createdAt;

  UserLessonProgress({
    required this.id,
    required this.userId,
    required this.lessonId,
    this.completed = false,
    this.progressPercentage = 0,
    this.correctAnswers = 0,
    this.totalAttempts = 0,
    this.lastAttempted,
    this.createdAt,
  });

  factory UserLessonProgress.fromJson(Map<String, dynamic> json) {
    return UserLessonProgress(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      lessonId: json['lesson_id'] as String,
      completed: json['completed'] as bool? ?? false,
      progressPercentage: json['progress_percentage'] as int? ?? 0,
      correctAnswers: json['correct_answers'] as int? ?? 0,
      totalAttempts: json['total_attempts'] as int? ?? 0,
      lastAttempted: json['last_attempted'] != null 
          ? DateTime.parse(json['last_attempted'] as String) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'lesson_id': lessonId,
    'completed': completed,
    'progress_percentage': progressPercentage,
    'correct_answers': correctAnswers,
    'total_attempts': totalAttempts,
    'last_attempted': lastAttempted?.toIso8601String(),
    'created_at': createdAt?.toIso8601String(),
  };
}

class UserAnswer {
  final String id;
  final String userId;
  final String questionId;
  final String? selectedOptionId;
  final bool? isCorrect;
  final String? answerText;
  final DateTime? createdAt;

  UserAnswer({
    required this.id,
    required this.userId,
    required this.questionId,
    this.selectedOptionId,
    this.isCorrect,
    this.answerText,
    this.createdAt,
  });

  factory UserAnswer.fromJson(Map<String, dynamic> json) {
    return UserAnswer(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      questionId: json['question_id'] as String,
      selectedOptionId: json['selected_option_id'] as String?,
      isCorrect: json['is_correct'] as bool?,
      answerText: json['answer_text'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'question_id': questionId,
    'selected_option_id': selectedOptionId,
    'is_correct': isCorrect,
    'answer_text': answerText,
    'created_at': createdAt?.toIso8601String(),
  };
}
