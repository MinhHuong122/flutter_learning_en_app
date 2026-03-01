import 'package:flutter/services.dart';
import '../models/dictionary_model.dart';

class DictionaryParser {
  /// Parse dictionary file (Vi-En.txt or En-Vi.txt)
  /// Format:
  /// @term
  /// * pos (noun, verb, adj, excl, etc.)
  /// - definition
  /// =example+translation
  /// =example+translation
  
  static Future<Map<String, dynamic>> parseFile(
    String assetPath,
    String language, // 'vi' or 'en'
  ) async {
    try {
      print('📖 Parsing $assetPath (language=$language)...');
      
      final content = await rootBundle.loadString(assetPath);
      print('✅ Loaded $assetPath (${content.length} characters)');
      
      final headwords = <String, Headword>{};
      final senses = <Sense>[];
      final examples = <Example>[];
      
      var headwordCounter = 1;
      var senseCounter = 1;
      var exampleCounter = 1;
      
      // Split by @ to get entries
      final entries = content.split(RegExp(r'^@', multiLine: true)).skip(1);
      
      int processedCount = 0;
      
      for (final entry in entries) {
        final lines = entry.trim().split('\n');
        if (lines.isEmpty) continue;
        
        // First line is the term
        final term = lines[0].trim();
        if (term.isEmpty) continue;
        
        processedCount++;
        
        // Create or get headword
        final hwKey = '$term|$language';
        if (!headwords.containsKey(hwKey)) {
          headwords[hwKey] = Headword(
            id: headwordCounter,
            term: term,
            lang: language,
            isCommon: _isCommonWord(term) ? 1 : 0,
          );
          headwordCounter++;
        }
        
        final hwId = headwords[hwKey]!.id;
        Sense? currentSense;
        
        // Sample logging for first 3 words
        if (processedCount <= 3) {
          print('  📝 Entry $processedCount: $term (HW ID: $hwId)');
        }
        
        // Parse rest of entry
        for (var i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          
          if (line.isEmpty) continue;
          
          // POS (part of speech)
          if (line.startsWith('* ')) {
            final pos = line.substring(2).trim();
            final senseObj = Sense(
              id: senseCounter,
              headwordId: hwId,
              pos: pos,
              definition: '',
            );
            senseCounter++;
            senses.add(senseObj);
            currentSense = senseObj;
          }
          
          // Definition
          else if (line.startsWith('- ')) {
            final definition = line.substring(2).trim();
            if (currentSense != null) {
              if (currentSense.definition.isEmpty) {
                currentSense = Sense(
                  id: currentSense.id,
                  headwordId: currentSense.headwordId,
                  pos: currentSense.pos,
                  definition: definition,
                  domain: currentSense.domain,
                );
                // Replace in list
                final idx = senses.indexOf(currentSense);
                if (idx >= 0) {
                  senses[idx] = currentSense;
                }
              } else {
                currentSense = Sense(
                  id: currentSense.id,
                  headwordId: currentSense.headwordId,
                  pos: currentSense.pos,
                  definition: '${currentSense.definition} | $definition',
                  domain: currentSense.domain,
                );
                final idx = senses.indexOf(currentSense);
                if (idx >= 0) {
                  senses[idx] = currentSense;
                }
              }
            }
          }
          
          // Example & Translation
          else if (line.startsWith('=')) {
            final exampleText = line.substring(1).trim();
            
            // Split by + to get example and translation
            final parts = exampleText.split('+');
            if (parts.length >= 2 && currentSense != null) {
              final sentence = parts[0].trim();
              final translation = parts.skip(1).join('+').trim(); // In case + appears in translation
              
              if (sentence.isNotEmpty) {
                final exampleObj = Example(
                  id: exampleCounter,
                  senseId: currentSense.id,
                  sentence: sentence,
                  translation: translation,
                );
                exampleCounter++;
                examples.add(exampleObj);
              }
            }
          }
        }
      }
      
      print('✅ Parsed $processedCount entries from $assetPath');
      print('   - Headwords: ${headwords.length}');
      print('   - Senses: ${senses.length}');
      print('   - Examples: ${examples.length}');
      
      return {
        'headwords': headwords.values.toList(),
        'senses': senses,
        'examples': examples,
      };
    } catch (e) {
      print('❌ Error parsing $assetPath: $e');
      rethrow;
    }
  }

  /// Check if word is common (basic vocabulary)
  static bool _isCommonWord(String term) {
    const commonWords = {
      // English
      'a', 'the', 'is', 'are', 'was', 'were', 'be', 'have', 'has', 'do', 'does',
      'apple', 'book', 'cat', 'dog', 'hello', 'yes', 'no', 'thank', 'please',
      'water', 'food', 'house', 'door', 'window', 'car', 'road', 'see', 'look',
      'good', 'bad', 'big', 'small', 'happy', 'sad', 'red', 'blue', 'green',
      // Vietnamese
      'là', 'và', 'cái', 'của', 'có', 'không', 'được', 'cho', 'với', 'từ',
      'tôi', 'anh', 'cô', 'ông', 'bà', 'em', 'bé', 'mẹ', 'bố', 'chị',
      'nhà', 'cửa', 'bàn', 'ghế', 'chuối', 'táo', 'nước', 'ăn', 'uống',
    };
    
    return commonWords.contains(term.toLowerCase());
  }

  /// Parse both files (Vi-En and En-Vi)
  static Future<Map<String, dynamic>> parseBothFiles() async {
    print('\n🚀 Dictionary Parser Started\n');
    
    try {
      final viEnData = await parseFile('assets/txt/Vi-En.txt', 'vi');
      final enViData = await parseFile('assets/txt/En-Vi.txt', 'en');
      
      // Merge data
      final allHeadwords = <Headword>[
        ...viEnData['headwords'] as List<Headword>,
        ...enViData['headwords'] as List<Headword>,
      ];
      
      final allSenses = <Sense>[
        ...viEnData['senses'] as List<Sense>,
        ...enViData['senses'] as List<Sense>,
      ];
      
      final allExamples = <Example>[
        ...viEnData['examples'] as List<Example>,
        ...enViData['examples'] as List<Example>,
      ];
      
      print('''
📊 PARSING COMPLETE
───────────────────────────────────
Total Headwords: ${allHeadwords.length}
Total Senses:    ${allSenses.length}
Total Examples:  ${allExamples.length}

By Language:
  VI-EN: ${(viEnData['headwords'] as List).length} headwords
  EN-VI: ${(enViData['headwords'] as List).length} headwords
      ''');
      
      return {
        'headwords': allHeadwords,
        'senses': allSenses,
        'examples': allExamples,
      };
    } catch (e) {
      print('❌ Error parsing dictionary files: $e');
      rethrow;
    }
  }

  /// Generate SQL INSERT statements for debugging
  static String generateSQL(
    List<Headword> headwords,
    List<Sense> senses,
    List<Example> examples,
  ) {
    final lines = <String>[];
    
    lines.add('''-- =============================================
-- DICTIONARY DATA
-- Total: ${headwords.length} headwords, ${senses.length} senses, ${examples.length} examples
-- =============================================
''');
    
    lines.add('-- INSERT HEADWORDS');
    for (final hw in headwords) {
      lines.add(
        "INSERT INTO headwords (id, term, lang, is_common) VALUES "
        "('${_escapeSql(hw.id.toString())}', '${_escapeSql(hw.term)}', '${hw.lang}', ${hw.isCommon});",
      );
    }
    
    lines.add('\n-- INSERT SENSES');
    for (final sense in senses) {
      final pos = sense.pos != null ? "'${_escapeSql(sense.pos!)}" : 'NULL';
      lines.add(
        "INSERT INTO senses (id, headword_id, pos, definition) VALUES "
        "(${sense.id}, ${sense.headwordId}, $pos, '${_escapeSql(sense.definition)}');",
      );
    }
    
    lines.add('\n-- INSERT EXAMPLES');
    for (final example in examples) {
      lines.add(
        "INSERT INTO examples (id, sense_id, sentence, translation) VALUES "
        "(${example.id}, ${example.senseId}, '${_escapeSql(example.sentence ?? '')}', '${_escapeSql(example.translation ?? '')}');",
      );
    }
    
    return lines.join('\n');
  }

  static String _escapeSql(String text) {
    return text.replaceAll("'", "''");
  }
}
