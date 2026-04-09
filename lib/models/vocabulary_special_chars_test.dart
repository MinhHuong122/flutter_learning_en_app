// lib/models/vocabulary_special_chars_test.dart
// Test cases for special character handling in vocabulary

import 'package:flutter_test/flutter_test.dart';
import 'vocabulary_special_chars.dart';

void main() {
  group('VocabularySpecialCharHandler', () {
    test('normalizeText handles Vietnamese characters', () {
      final text = 'Một khái niệm liên quan đến health';
      final normalized = VocabularySpecialCharHandler.normalizeText(text);
      expect(normalized, equals('Một khái niệm liên quan đến health'));
    });

    test('normalizeText handles IPA characters', () {
      final text = 'ˌni.oʊˈklæs.ə.sɪz.əm';
      final normalized = VocabularySpecialCharHandler.normalizeText(text);
      expect(normalized, equals('ˌni.oʊˈklæs.ə.sɪz.əm'));
    });

    test('hasSpecialCharacters detects Vietnamese', () {
      expect(
        VocabularySpecialCharHandler.hasSpecialCharacters('mèo'),
        isTrue,
      );
      expect(
        VocabularySpecialCharHandler.hasSpecialCharacters('cat'),
        isFalse,
      );
    });

    test('hasSpecialCharacters detects IPA', () {
      expect(
        VocabularySpecialCharHandler.hasSpecialCharacters('ˈtaɪɡər'),
        isTrue,
      );
      expect(
        VocabularySpecialCharHandler.hasSpecialCharacters('tiger'),
        isFalse,
      );
    });

    test('getUnicodeCharacters extracts all special chars', () {
      final input = 'Một khái niệm';
      final result = VocabularySpecialCharHandler.getUnicodeCharacters(input);
      expect(result.contains('Ộ'), isFalse); // Capital M with circumflex
      expect(result.contains('ộ'), isTrue); // Lowercase o with horn and dot below
      expect(result.isNotEmpty, isTrue);
    });

    test('isValidUTF8 validates encoding', () {
      expect(
        VocabularySpecialCharHandler.isValidUTF8('Valid Vietnamese: mèo'),
        isTrue,
      );
      expect(
        VocabularySpecialCharHandler.isValidUTF8('Valid IPA: ˈtaɪɡər'),
        isTrue,
      );
    });

    test('sanitizeForStorage escapes SQL quotes', () {
      final input = "It's a cat";
      final output = VocabularySpecialCharHandler.sanitizeForStorage(input);
      expect(output, equals("It''s a cat"));
    });

    test('unescapeFromSQL reverses sanitization', () {
      final input = "It''s a cat";
      final output = VocabularySpecialCharHandler.unescapeFromSQL(input);
      expect(output, equals("It's a cat"));
    });
  });

  group('String Extension SpecialCharactersExtension', () {
    test('normalizeSpecialChars works on strings', () {
      final text = 'Một khái niệm liên quan';
      expect(text.normalizeSpecialChars(), equals(text));
    });

    test('hasSpecialChars detects special characters', () {
      expect('mèo'.hasSpecialChars, isTrue);
      expect('cat'.hasSpecialChars, isFalse);
      expect('ˈtaɪɡər'.hasSpecialChars, isTrue);
    });

    test('specialCharacters returns unique set', () {
      final chars = 'Một khái'.specialCharacters;
      expect(chars.isNotEmpty, isTrue);
      expect(chars.length, lessThan(10));
    });

    test('truncateSafely respects UTF-8 boundaries', () {
      final text = 'Một khái niệm';
      final truncated = text.truncateSafely(5);
      expect(
        VocabularySpecialCharHandler.isValidUTF8(truncated),
        isTrue,
      );
    });
  });

  group('VocabularyItem JSON serialization', () {
    test('fromJson handles Vietnamese characters', () {
      final json = {
        'id': '123',
        'lesson_id': 'lesson-1',
        'term': 'mèo',
        'meaning': 'a domestic animal',
        'pronunciation': 'mew',
        'word_class': 'noun',
        'example_sentence': 'The cat sleeps',
        'vietnamese_term': 'mèo',
        'vietnamese_meaning': 'một con vật nuôi',
        'is_common': true,
        'created_at': '2026-03-27T00:00:00Z',
        'updated_at': '2026-03-27T00:00:00Z',
      };

      final item = VocabularyItem.fromJson(json);
      expect(item.term, equals('mèo'));
      expect(item.vietnameseTerm, equals('mèo'));
      expect(item.vietnameseMeaning, equals('một con vật nuôi'));
    });

    test('toJson sanitizes for storage', () {
      final item = VocabularyItem(
        id: '123',
        lessonId: 'lesson-1',
        term: "It's a cat",
        meaning: 'domestic animal',
        pronunciation: '/kæt/',
        wordClass: 'noun',
        exampleSentence: 'Cat meows',
        vietnameseTerm: 'mèo',
        vietnameseMeaning: 'một con vật nuôi',
        isCommon: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = item.toJson();
      expect(json['term'], equals("It''s a cat")); // Escaped for SQL
    });

    test('roundtrip JSON serialization preserves Vietnamese', () {
      final original = VocabularyItem(
        id: '123',
        lessonId: 'lesson-1',
        term: 'từ vựng',
        meaning: 'vocabulary words',
        pronunciation: 'tɨ vɨk tʃuːk',
        wordClass: 'noun',
        exampleSentence: 'Học từ vựng là quan trọng',
        vietnameseTerm: 'từ vựng',
        vietnameseMeaning: 'các từ ngôn ngữ',
        isCommon: true,
        createdAt: DateTime(2026, 3, 27),
        updatedAt: DateTime(2026, 3, 27),
      );

      final json = original.toJson();
      expect(json['term'], contains('từ'));
      expect(json['vietnamese_meaning'], contains('ngôn'));
    });
  });

  group('VocabularyService', () {
    final testVocab = [
      VocabularyItem(
        id: '1',
        lessonId: 'colors',
        term: 'red',
        meaning: 'a color',
        pronunciation: '/red/',
        wordClass: 'noun',
        exampleSentence: 'Red is bright',
        vietnameseTerm: 'đỏ',
        vietnameseMeaning: 'một màu',
        isCommon: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      VocabularyItem(
        id: '2',
        lessonId: 'animals',
        term: 'cat',
        meaning: 'domestic animal',
        pronunciation: '/kæt/',
        wordClass: 'noun',
        exampleSentence: 'Cat meows',
        vietnameseTerm: 'mèo',
        vietnameseMeaning: 'một con vật nuôi',
        isCommon: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    test('searchByTerm finds by English term', () {
      final results = VocabularyService.searchByTerm(testVocab, 'red');
      expect(results.length, equals(1));
      expect(results[0].term, equals('red'));
    });

    test('searchByTerm finds by meaning', () {
      final results = VocabularyService.searchByTerm(testVocab, 'color');
      expect(results.length, equals(1));
      expect(results[0].term, equals('red'));
    });

    test('searchByTerm finds by Vietnamese', () {
      final results = VocabularyService.searchByTerm(testVocab, 'mèo');
      expect(results.length, equals(1));
      expect(results[0].term, equals('cat'));
    });

    test('sortByTerm sorts vocabulary', () {
      final sorted = VocabularyService.sortByTerm(testVocab);
      expect(sorted[0].term, equals('cat'));
      expect(sorted[1].term, equals('red'));
    });

    test('validateIntegrity checks UTF-8', () {
      final item = testVocab[0];
      final result = VocabularyService.validateIntegrity(item);
      expect(result['isValid'], isTrue);
      expect((result['issues'] as List).isEmpty, isTrue);
    });

    test('validateIntegrity detects special characters', () {
      final item = testVocab[1];
      final result = VocabularyService.validateIntegrity(item);
      expect(result['hasSpecialCharacters']['vietnameseTerm'], isTrue);
      expect(result['hasSpecialCharacters']['term'], isFalse);
    });
  });
}
