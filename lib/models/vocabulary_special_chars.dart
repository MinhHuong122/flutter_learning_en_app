// lib/models/vocabulary_special_chars.dart
// Fix for special character recognition in Dart

import 'dart:convert' show utf8;

/// Handles special characters including Vietnamese diacritics and IPA symbols
class VocabularySpecialCharHandler {
  /// Normalize special characters for safe display and comparison
  static String normalizeText(String text) {
    if (text.isEmpty) return text;
    
    // Ensure UTF-8 encoding
    final bytes = utf8.encode(text);
    final decoded = utf8.decode(bytes);
    
    return decoded;
  }

  /// Sanitize for database/JSON storage (escape problematic characters)
  static String sanitizeForStorage(String text) {
    if (text.isEmpty) return text;
    
    // Already UTF-8 safe in Dart strings
    return text
        .replaceAll('\'', '\'\'')  // Escape single quotes for SQL
        .replaceAll('\\', '\\\\');  // Escape backslashes
  }

  /// Unescape from SQL format (reverse of sanitize)
  static String unescapeFromSQL(String text) {
    if (text.isEmpty) return text;
    
    return text
        .replaceAll('\'\'', "'")   // Unescape doubled single quotes
        .replaceAll('\\\\', '\\'); // Unescape doubled backslashes
  }

  /// Check if string contains special characters (Vietnamese, IPA, etc.)
  static bool hasSpecialCharacters(String text) {
    if (text.isEmpty) return false;
    
    // Check for characters outside ASCII range (0-127)
    return text.codeUnits.any((codeUnit) => codeUnit > 127);
  }

  /// Get all unique Unicode characters in text
  static Set<String> getUnicodeCharacters(String text) {
    return text
        .split('')
        .where((char) => char.codeUnitAt(0) > 127)
        .toSet();
  }

  /// Validate UTF-8 encoding
  static bool isValidUTF8(String text) {
    try {
      final bytes = utf8.encode(text);
      utf8.decode(bytes);
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Extension for String to add special character utilities
extension SpecialCharactersExtension on String {
  /// Easy access to normalize text
  String normalizeSpecialChars() {
    return VocabularySpecialCharHandler.normalizeText(this);
  }

  /// Check if this string has special characters
  bool get hasSpecialChars {
    return VocabularySpecialCharHandler.hasSpecialCharacters(this);
  }

  /// Get unique special characters
  Set<String> get specialCharacters {
    return VocabularySpecialCharHandler.getUnicodeCharacters(this);
  }

  /// Truncate safely, respecting UTF-8 character boundaries
  String truncateSafely(int maxBytes) {
    if (isEmpty) return this;
    
    try {
      final bytes = utf8.encode(this);
      if (bytes.length <= maxBytes) return this;
      
      final truncated = utf8.decode(bytes.sublist(0, maxBytes));
      return truncated;
    } catch (e) {
      // Fallback to character-based truncation
      return substring(0, maxBytes.clamp(0, length));
    }
  }

  /// Validate UTF-8 encoding
  bool get isValidUTF8 {
    return VocabularySpecialCharHandler.isValidUTF8(this);
  }
}

/// Vocabulary model with special character support
class VocabularyItem {
  final String id;
  final String lessonId;
  final String term;
  final String meaning;
  final String pronunciation;
  final String wordClass;
  final String exampleSentence;
  final String vietnameseTerm;
  final String vietnameseMeaning;
  final bool isCommon;
  final DateTime createdAt;
  final DateTime updatedAt;

  VocabularyItem({
    required this.id,
    required this.lessonId,
    required this.term,
    required this.meaning,
    required this.pronunciation,
    required this.wordClass,
    required this.exampleSentence,
    required this.vietnameseTerm,
    required this.vietnameseMeaning,
    required this.isCommon,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON with proper UTF-8 handling
  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      id: VocabularySpecialCharHandler.normalizeText(json['id'] as String? ?? ''),
      lessonId: VocabularySpecialCharHandler.normalizeText(json['lesson_id'] as String? ?? ''),
      term: VocabularySpecialCharHandler.normalizeText(json['term'] as String? ?? ''),
      meaning: VocabularySpecialCharHandler.normalizeText(json['meaning'] as String? ?? ''),
      pronunciation: VocabularySpecialCharHandler.normalizeText(json['pronunciation'] as String? ?? ''),
      wordClass: VocabularySpecialCharHandler.normalizeText(json['word_class'] as String? ?? ''),
      exampleSentence: VocabularySpecialCharHandler.normalizeText(json['example_sentence'] as String? ?? ''),
      vietnameseTerm: VocabularySpecialCharHandler.normalizeText(json['vietnamese_term'] as String? ?? ''),
      vietnameseMeaning: VocabularySpecialCharHandler.normalizeText(json['vietnamese_meaning'] as String? ?? ''),
      isCommon: json['is_common'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON with proper UTF-8 encoding
  Map<String, dynamic> toJson() {
    return {
      'id': VocabularySpecialCharHandler.sanitizeForStorage(id),
      'lesson_id': lessonId,
      'term': VocabularySpecialCharHandler.sanitizeForStorage(term),
      'meaning': VocabularySpecialCharHandler.sanitizeForStorage(meaning),
      'pronunciation': VocabularySpecialCharHandler.sanitizeForStorage(pronunciation),
      'word_class': VocabularySpecialCharHandler.sanitizeForStorage(wordClass),
      'example_sentence': VocabularySpecialCharHandler.sanitizeForStorage(exampleSentence),
      'vietnamese_term': VocabularySpecialCharHandler.sanitizeForStorage(vietnameseTerm),
      'vietnamese_meaning': VocabularySpecialCharHandler.sanitizeForStorage(vietnameseMeaning),
      'is_common': isCommon,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Display term with proper character handling
  String get displayTerm {
    return term.normalizeSpecialChars();
  }

  /// Display meaning with proper character handling
  String get displayMeaning {
    return meaning.normalizeSpecialChars();
  }

  /// Display Vietnamese term with proper character handling
  String get displayVietnamese {
    return '$vietnameseTerm - $vietnameseMeaning'.normalizeSpecialChars();
  }

  /// Get pronunciation with safety check
  String get safePronunciation {
    if (!pronunciation.isValidUTF8) {
      return '⚠️ Invalid encoding';
    }
    return pronunciation.normalizeSpecialChars();
  }
}

/// Service for handling vocabulary with special characters
class VocabularyService {
  /// Parse CSV row with special character handling
  static VocabularyItem parseCSVRow(Map<String, dynamic> row) {
    return VocabularyItem.fromJson({
      'id': row['id'] ?? '',
      'lesson_id': row['lesson_id'] ?? '',
      'term': row['term'] ?? '',
      'meaning': row['meaning'] ?? '',
      'pronunciation': row['pronunciation'] ?? '',
      'word_class': row['word_class'] ?? '',
      'example_sentence': row['example_sentence'] ?? '',
      'vietnamese_term': row['vietnamese_term'] ?? '',
      'vietnamese_meaning': row['vietnamese_meaning'] ?? '',
      'is_common': row['is_common'] == 'true',
      'created_at': row['created_at'] ?? DateTime.now().toIso8601String(),
      'updated_at': row['updated_at'] ?? DateTime.now().toIso8601String(),
    });
  }

  /// Search vocabulary with special character support
  static List<VocabularyItem> searchByTerm(
    List<VocabularyItem> vocabulary,
    String query,
  ) {
    final normalizedQuery = query.normalizeSpecialChars().toLowerCase();
    
    return vocabulary
        .where((item) =>
            item.term.normalizeSpecialChars().toLowerCase().contains(normalizedQuery) ||
            item.meaning.normalizeSpecialChars().toLowerCase().contains(normalizedQuery) ||
            item.vietnameseTerm.normalizeSpecialChars().toLowerCase().contains(normalizedQuery))
        .toList();
  }

  /// Sort vocabulary safely with UTF-8 support
  static List<VocabularyItem> sortByTerm(List<VocabularyItem> vocabulary) {
    final sorted = [...vocabulary];
    sorted.sort((a, b) => a.term.toLowerCase().compareTo(b.term.toLowerCase()));
    return sorted;
  }

  /// Validate vocabulary integrity
  static Map<String, dynamic> validateIntegrity(VocabularyItem item) {
    final issues = <String>[];

    if (!VocabularySpecialCharHandler.isValidUTF8(item.term)) {
      issues.add('Term has invalid UTF-8 encoding');
    }
    if (!VocabularySpecialCharHandler.isValidUTF8(item.meaning)) {
      issues.add('Meaning has invalid UTF-8 encoding');
    }
    if (!VocabularySpecialCharHandler.isValidUTF8(item.pronunciation)) {
      issues.add('Pronunciation has invalid UTF-8 encoding');
    }
    if (!VocabularySpecialCharHandler.isValidUTF8(item.vietnameseTerm)) {
      issues.add('Vietnamese term has invalid UTF-8 encoding');
    }

    return {
      'isValid': issues.isEmpty,
      'issues': issues,
      'hasSpecialCharacters': {
        'term': item.term.hasSpecialChars,
        'meaning': item.meaning.hasSpecialChars,
        'pronunciation': item.pronunciation.hasSpecialChars,
        'vietnameseTerm': item.vietnameseTerm.hasSpecialChars,
      },
    };
  }
}
