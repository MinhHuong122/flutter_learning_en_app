// lib/examples/vocabulary_special_chars_usage.dart
// Examples showing how to use special character handling

import 'package:flutter/material.dart';
import '../models/vocabulary_special_chars.dart';

/// Example 1: Display vocabulary with special characters
class VocabularyDisplayExample extends StatelessWidget {
  final VocabularyItem vocabulary;

  const VocabularyDisplayExample({
    Key? key,
    required this.vocabulary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display term with proper character handling
            _buildField('Term', vocabulary.displayTerm),
            
            // Display meaning with special character support
            _buildField('Meaning', vocabulary.displayMeaning),
            
            // Display pronunciation with validation
            _buildField(
              'Pronunciation (IPA)',
              vocabulary.safePronunciation,
              isHighlighted: vocabulary.pronunciation.hasSpecialChars,
            ),
            
            // Display Vietnamese with proper handling
            _buildField('Vietnamese', vocabulary.displayVietnamese),
            
            // Show encoding status
            if (vocabulary.pronunciation.hasSpecialChars)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Chip(
                  label: Text('⚠️ Contains ${vocabulary.pronunciation.specialCharacters.length} special characters'),
                  backgroundColor: Colors.amber[100],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isHighlighted ? Colors.blue[50] : Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 14,
                color: isHighlighted ? Colors.blue[900] : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Example 2: Search with special character support
class VocabularySearchExample extends StatefulWidget {
  final List<VocabularyItem> vocabulary;

  const VocabularySearchExample({
    Key? key,
    required this.vocabulary,
  }) : super(key: key);

  @override
  _VocabularySearchExampleState createState() =>
      _VocabularySearchExampleState();
}

class _VocabularySearchExampleState extends State<VocabularySearchExample> {
  final _searchController = TextEditingController();
  late List<VocabularyItem> _results;

  @override
  void initState() {
    super.initState();
    _results = widget.vocabulary;
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _results = widget.vocabulary;
      } else {
        _results = VocabularyService.searchByTerm(widget.vocabulary, query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search field with UTF-8 support
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by English, Vietnamese, or pronunciation...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: _search,
        ),
        const SizedBox(height: 16),
        
        // Results with special character support
        Expanded(
          child: _results.isEmpty
              ? const Center(
                  child: Text('No results found'),
                )
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    return ListTile(
                      title: Text(item.displayTerm),
                      subtitle: Text(item.displayVietnamese),
                      trailing: item.pronunciation.hasSpecialChars
                          ? const Tooltip(
                              message: 'Contains IPA characters',
                              child: Icon(Icons.info_outline),
                            )
                          : null,
                      onTap: () {
                        _showDetails(context, item);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showDetails(BuildContext context, VocabularyItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.displayTerm),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailField('Meaning', item.displayMeaning),
              _buildDetailField('Pronunciation', item.safePronunciation),
              _buildDetailField('Example', item.exampleSentence),
              _buildDetailField('Vietnamese', item.vietnameseTerm),
              _buildDetailField('Vietnamese Meaning', item.vietnameseMeaning),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

/// Example 3: Vocabulary validation and character info
class VocabularyValidationExample extends StatelessWidget {
  final VocabularyItem vocabulary;

  const VocabularyValidationExample({
    Key? key,
    required this.vocabulary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final validation = VocabularyService.validateIntegrity(vocabulary);
    final isValid = validation['isValid'] as bool;
    final issues = validation['issues'] as List;
    final specialChars = validation['hasSpecialCharacters'] as Map;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  isValid ? Icons.check_circle : Icons.error,
                  color: isValid ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  isValid ? 'Valid UTF-8 encoding' : 'Encoding issues detected',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isValid ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          
          // Issues if any
          if (issues.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Issues found:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...issues.map(
                    (issue) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(issue as String),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Special character information
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Special Characters:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...(specialChars.entries).map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Icon(
                          entry.value as bool
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 16,
                          color: entry.value as bool ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text('${entry.key}: ${entry.value}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Character breakdown
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unique Special Characters:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...vocabulary.term.specialCharacters.map(
                      (char) => Tooltip(
                        message: 'U+${char.codeUnitAt(0).toRadixString(16).padLeft(4, '0')}',
                        child: Chip(
                          label: Text(char),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Example 4: CSV Import with special character handling
class VocabularyCSVImportExample {
  /// Import CSV and handle special characters
  static List<VocabularyItem> importFromCSV(String csvContent) {
    final lines = csvContent.split('\n');
    final vocabulary = <VocabularyItem>[];

    // Skip header
    for (int i = 1; i < lines.length; i++) {
      if (lines[i].isEmpty) continue;

      final row = _parseCSVLine(lines[i]);
      try {
        final item = VocabularyService.parseCSVRow(row);
        
        // Validate before adding
        final validation = VocabularyService.validateIntegrity(item);
        if (validation['isValid'] as bool) {
          vocabulary.add(item);
        } else {
          print('⚠️ Invalid item at line ${i + 1}');
        }
      } catch (e) {
        print('❌ Error parsing line ${i + 1}: $e');
      }
    }

    return vocabulary;
  }

  /// Simple CSV line parser (for production, use csv package)
  static Map<String, dynamic> _parseCSVLine(String line) {
    final columns = line.split(',');
    return {
      'id': columns.isNotEmpty ? columns[0].trim() : '',
      'lesson_id': columns.length > 1 ? columns[1].trim() : '',
      'term': columns.length > 2 ? columns[2].trim() : '',
      'meaning': columns.length > 3 ? columns[3].trim() : '',
      'pronunciation': columns.length > 4 ? columns[4].trim() : '',
      'word_class': columns.length > 5 ? columns[5].trim() : '',
      'example_sentence': columns.length > 6 ? columns[6].trim() : '',
      'vietnamese_term': columns.length > 7 ? columns[7].trim() : '',
      'vietnamese_meaning': columns.length > 8 ? columns[8].trim() : '',
      'is_common': columns.length > 11 ? columns[11].trim() == 'true' : true,
      'created_at': columns.length > 12 ? columns[12].trim() : DateTime.now().toIso8601String(),
      'updated_at': columns.length > 13 ? columns[13].trim() : DateTime.now().toIso8601String(),
    };
  }
}
