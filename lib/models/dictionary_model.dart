/// Dictionary models for simplified schema
/// Uses only DictionaryEntry model instead of complex nested structures

/// Represents a single dictionary entry
class DictionaryEntry {
  final int id;
  final String term;
  final String language; // 'vi' or 'en'
  final String pronunciation; // Only for English
  final String wordClass; // noun, verb, adjective, etc.
  final String meaning;
  final bool isCommon; // Common/basic vocabulary
  final int frequency; // Usage frequency (higher = more common)
  final DateTime createdAt;
  final DateTime? updatedAt;

  DictionaryEntry({
    required this.id,
    required this.term,
    required this.language,
    this.pronunciation = '',
    this.wordClass = 'noun',
    required this.meaning,
    this.isCommon = false,
    this.frequency = 0,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from Supabase JSON response
  factory DictionaryEntry.fromJson(Map<String, dynamic> json, String lang) {
    return DictionaryEntry(
      id: json['id'] as int,
      term: json['term'] as String,
      language: lang,
      pronunciation: json['pronunciation'] as String? ?? '',
      wordClass: json['word_class'] as String? ?? 'noun',
      meaning: json['meaning'] as String,
      isCommon: json['is_common'] as bool? ?? false,
      frequency: json['frequency'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  /// Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'id': id,
      'term': term,
      'language': language,
      'pronunciation': pronunciation,
      'word_class': wordClass,
      'meaning': meaning,
      'is_common': isCommon,
      'frequency': frequency,
    };
  }

  /// Get display name (Vietnamese/English label)
  String get languageName => language.toUpperCase() == 'VI' ? 'Tiếng Việt' : 'English';

  /// Check if is Vietnamese entry
  bool get isVietnamese => language == 'vi';

  /// Check if is English entry
  bool get isEnglish => language == 'en';

  /// Format for display
  String get displayText {
    final result = StringBuffer();
    result.writeln('📖 $term');
    if (pronunciation.isNotEmpty) {
      result.writeln('🔊 /$pronunciation/');
    }
    result.writeln('📝 [$wordClass]');
    result.writeln('ℹ️ $meaning');
    if (isCommon) {
      result.writeln('⭐ Common word');
    }
    return result.toString();
  }

  @override
  String toString() => '''
DictionaryEntry(
  id: $id,
  term: $term,
  language: $language,
  pronunciation: $pronunciation,
  wordClass: $wordClass,
  meaning: $meaning,
  isCommon: $isCommon,
  frequency: $frequency
)''';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DictionaryEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          term == other.term &&
          language == other.language;

  @override
  int get hashCode => Object.hash(id, term, language);
}

/// Search result with metadata
class SearchResult {
  final List<DictionaryEntry> entries;
  final int totalCount;
  final String query;
  final String language; // 'vi', 'en', 'all'
  final DateTime searchedAt;

  SearchResult({
    required this.entries,
    required this.totalCount,
    required this.query,
    this.language = 'all',
    DateTime? searchedAt,
  }) : searchedAt = searchedAt ?? DateTime.now();

  /// Get results by language
  List<DictionaryEntry> getByLanguage(String lang) =>
      entries.where((e) => e.language == lang).toList();

  /// Check if search is empty
  bool get isEmpty => entries.isEmpty;

  /// Get Vietnamese entries only
  List<DictionaryEntry> get vietnameseEntries =>
      getByLanguage('vi');

  /// Get English entries only
  List<DictionaryEntry> get englishEntries =>
      getByLanguage('en');

  @override
  String toString() => 'SearchResult('
      'query: $query, '
      'language: $language, '
      'entries: ${entries.length}, '
      'total: $totalCount)';
}

/// User's saved/favorite word
class SavedWord extends DictionaryEntry {
  final DateTime savedAt;
  final int masteryLevel; // 1-5: beginner to advanced

  SavedWord({
    required int id,
    required String term,
    required String language,
    String? pronunciation,
    String wordClass = 'noun',
    required String meaning,
    bool isCommon = false,
    int frequency = 0,
    DateTime? createdAt,
    required this.savedAt,
    this.masteryLevel = 1,
  }) : super(
    id: id,
    term: term,
    language: language,
    pronunciation: pronunciation ?? '',
    wordClass: wordClass,
    meaning: meaning,
    isCommon: isCommon,
    frequency: frequency,
    createdAt: createdAt,
  );

  /// Create from dictionary entry
  factory SavedWord.fromEntry(
    DictionaryEntry entry, {
    required DateTime savedAt,
    int masteryLevel = 1,
  }) {
    return SavedWord(
      id: entry.id,
      term: entry.term,
      language: entry.language,
      pronunciation: entry.pronunciation,
      wordClass: entry.wordClass,
      meaning: entry.meaning,
      isCommon: entry.isCommon,
      frequency: entry.frequency,
      createdAt: entry.createdAt,
      savedAt: savedAt,
      masteryLevel: masteryLevel,
    );
  }

  /// Get mastery level label
  String get masteryLabel {
    switch (masteryLevel) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Elementary';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Advanced';
      case 5:
        return 'Mastered';
      default:
        return 'Unknown';
    }
  }

  /// Days since saved
  int get daysSinceSaved =>
      DateTime.now().difference(savedAt).inDays;

  @override
  String toString() => 'SavedWord('
      'term: $term, '
      'language: $language, '
      'masteryLevel: $masteryLevel, '
      'savedAt: $savedAt)';
}

/// Dictionary statistics
class DictionaryStats {
  final int vietnameseCount;
  final int englishCount;
  final int commonVietnamese;
  final int commonEnglish;
  final DateTime? lastUpdated;

  DictionaryStats({
    required this.vietnameseCount,
    required this.englishCount,
    this.commonVietnamese = 0,
    this.commonEnglish = 0,
    this.lastUpdated,
  });

  /// Total entries
  int get totalCount => vietnameseCount + englishCount;

  /// Total common words
  int get totalCommon => commonVietnamese + commonEnglish;

  /// Get stats by language
  int getCountByLanguage(String language) =>
      language == 'vi' ? vietnameseCount : englishCount;

  /// Format for display
  String get displayText => '''
📊 Dictionary Statistics
───────────────────────
🇻🇳 Vietnamese: $vietnameseCount entries
   ⭐ Common: $commonVietnamese

🇬🇧 English: $englishCount entries
   ⭐ Common: $commonEnglish

📈 Total: $totalCount entries
      ${lastUpdated != null ? 'Last updated: ${lastUpdated!.toString().split('.')[0]}' : 'Unknown'}
''';

  @override
  String toString() => 'DictionaryStats('
      'vietnamese: $vietnameseCount, '
      'english: $englishCount, '
      'total: $totalCount)';
}

/// Import progress tracking
class ImportProgress {
  final int totalEntries;
  int processedEntries;
  int successfulEntries;
  int failedEntries;
  final DateTime startedAt;
  DateTime? completedAt;

  ImportProgress({
    required this.totalEntries,
    this.processedEntries = 0,
    this.successfulEntries = 0,
    this.failedEntries = 0,
    DateTime? startedAt,
  }) : startedAt = startedAt ?? DateTime.now();

  /// Progress percentage (0-100)
  double get progressPercent =>
      totalEntries > 0 ? (processedEntries / totalEntries * 100) : 0;

  /// Check if import is complete
  bool get isComplete =>
      processedEntries >= totalEntries;

  /// Duration so far
  Duration get elapsedTime =>
      DateTime.now().difference(startedAt);

  /// Estimated time remaining
  Duration? get estimatedTimeRemaining {
    if (progressPercent == 0 || progressPercent == 100) return null;
    final percentPerSecond = progressPercent / elapsedTime.inSeconds;
    final remainingPercent = 100 - progressPercent;
    final secondsRemaining = remainingPercent / percentPerSecond;
    return Duration(seconds: secondsRemaining.toInt());
  }

  /// Mark entry as processed
  void markProcessed({bool success = true}) {
    processedEntries++;
    if (success) {
      successfulEntries++;
    } else {
      failedEntries++;
    }
  }

  /// Mark import as complete
  void complete() {
    completedAt = DateTime.now();
  }

  /// Get status display text
  String get statusText => '''
📥 Import Progress
──────────────────
Progress: $processedEntries / $totalEntries (${progressPercent.toStringAsFixed(1)}%)
✅ Successful: $successfulEntries
❌ Failed: $failedEntries
⏱️ Elapsed: ${elapsedTime.inSeconds}s
${estimatedTimeRemaining != null ? '⏳ Estimated remaining: ${estimatedTimeRemaining!.inSeconds}s' : ''}
''';

  @override
  String toString() => 'ImportProgress('
      'total: $totalEntries, '
      'processed: $processedEntries, '
      'success: $successfulEntries, '
      'failed: $failedEntries)';
}



/// Old Headword model (for SQLite database)
class Headword {
  final int id;
  final String term;
  final String lang; // 'en' or 'vi'
  final String? pronunciation;
  final int isCommon;
  final int frequency;
  final DateTime createdAt;

  Headword({
    required this.id,
    required this.term,
    required this.lang,
    this.pronunciation,
    this.isCommon = 0,
    this.frequency = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'term': term,
      'lang': lang,
      'pronunciation': pronunciation,
      'is_common': isCommon,
      'frequency': frequency,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Headword.fromMap(Map<String, dynamic> map) {
    return Headword(
      id: map['id'] as int,
      term: map['term'] as String,
      lang: map['lang'] as String,
      pronunciation: map['pronunciation'] as String?,
      isCommon: map['is_common'] as int? ?? 0,
      frequency: map['frequency'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Old Sense model (for SQLite database)
class Sense {
  final int id;
  final int headwordId;
  final String? pos; // noun, verb, adj, excl, phrase...
  final String definition;
  final String? domain; // law, medical, slang...

  Sense({
    required this.id,
    required this.headwordId,
    this.pos,
    required this.definition,
    this.domain,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'headword_id': headwordId,
      'pos': pos,
      'definition': definition,
      'domain': domain,
    };
  }

  factory Sense.fromMap(Map<String, dynamic> map) {
    return Sense(
      id: map['id'] as int,
      headwordId: map['headword_id'] as int,
      pos: map['pos'] as String?,
      definition: map['definition'] as String,
      domain: map['domain'] as String?,
    );
  }
}

/// Old Example model (for SQLite database)
class Example {
  final int id;
  final int senseId;
  final String? sentence;
  final String? translation;

  Example({
    required this.id,
    required this.senseId,
    this.sentence,
    this.translation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sense_id': senseId,
      'sentence': sentence,
      'translation': translation,
    };
  }

  factory Example.fromMap(Map<String, dynamic> map) {
    return Example(
      id: map['id'] as int,
      senseId: map['sense_id'] as int,
      sentence: map['sentence'] as String?,
      translation: map['translation'] as String?,
    );
  }
}

/// Old WordEntry model (for SQLite database)
class WordEntry {
  final Headword headword;
  final List<Sense> senses;
  final Map<int, List<Example>> examplesBySense;

  WordEntry({
    required this.headword,
    required this.senses,
    required this.examplesBySense,
  });

  /// Get formatted definition with examples
  String getFormattedDefinition() {
    final lines = <String>[];
    for (final sense in senses) {
      if (sense.pos != null && sense.pos!.isNotEmpty) {
        lines.add('${sense.pos}: ${sense.definition}');
      } else {
        lines.add(sense.definition);
      }
      
      final examples = examplesBySense[sense.id] ?? [];
      for (final example in examples) {
        lines.add('  Example: ${example.sentence}');
        if (example.translation != null && example.translation!.isNotEmpty) {
          lines.add('  Translation: ${example.translation}');
        }
      }
    }
    return lines.join('\n');
  }
}
