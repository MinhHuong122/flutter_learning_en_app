import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dictionary_model.dart';
import '../services/supabase_dictionary_service.dart';
import '../services/language_service.dart';
import '../utils/constants.dart';

class DictionarySearchScreen extends StatefulWidget {
  const DictionarySearchScreen({Key? key}) : super(key: key);

  @override
  State<DictionarySearchScreen> createState() => _DictionarySearchScreenState();
}

class _DictionarySearchScreenState extends State<DictionarySearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SupabaseDictionaryService _supabaseService =
      SupabaseDictionaryService();

  List<DictionaryEntry> _searchResults = [];
  List<Map<String, dynamic>> _searchHistory = [];
  Set<String> _savedWords = {}; // Store as "term|language" for uniqueness

  bool _isLoading = false;
  bool _showHistory = true;
  String _selectedLanguage = 'all'; // 'all', 'en', 'vi'

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _loadSavedWords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isEnglish => context.read<LanguageService>().isEnglish;

  /// Load saved words from Supabase
  Future<void> _loadSavedWords() async {
    try {
      final saved = await _supabaseService.getUserSavedWords();
      setState(() {
        _savedWords = saved.map((e) => '${e.term}|${e.language}').toSet();
      });
      print('✅ Loaded ${_savedWords.length} saved words');
    } catch (e) {
      print('❌ Error loading saved words: $e');
    }
  }

  Future<void> _loadSearchHistory() async {
    try {
      // For now, search history is minimal
      // Could be expanded to store in local SharedPreferences
      setState(() {
        _searchHistory = [];
      });
    } catch (e) {
      print('Error loading history: $e');
    }
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showHistory = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showHistory = false;
    });

    try {
      print('🔍 Searching: "$query" in language: $_selectedLanguage');

      List<DictionaryEntry> results = [];

      // Search based on selected language
      if (_selectedLanguage == 'vi') {
        results = await _supabaseService.searchVietnamese(query, limit: 50);
      } else if (_selectedLanguage == 'en') {
        results = await _supabaseService.searchEnglish(query, limit: 50);
      } else {
        results = await _supabaseService.searchAll(query, limit: 50);
      }

      // Sort by relevance
      results = _sortByRelevance(results, query.toLowerCase());

      print('✅ Found ${results.length} results');

      setState(() {
        _searchResults = results;
      });

      // Reload saved words to update UI
      await _loadSavedWords();
    } catch (e) {
      print('❌ Search error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_isEnglish ? 'Search error: $e' : 'Lỗi tìm kiếm: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Sort results by relevance
  List<DictionaryEntry> _sortByRelevance(
      List<DictionaryEntry> results, String query) {
    // Calculate relevance score for each result
    final List<MapEntry<DictionaryEntry, int>> scoredResults = [];

    for (final entry in results) {
      final termLower = entry.term.toLowerCase();
      int score = 0;

      // Exact match: highest priority
      if (termLower == query) {
        score = 10000;
      }
      // Starts with query (and is single word)
      else if (termLower.startsWith(query) && !termLower.contains(' ')) {
        // Bonus for shorter words starting with query
        score = 5000 + (1000 - termLower.length);
      }
      // Starts with query (multi-word)
      else if (termLower.startsWith(query)) {
        score = 3000;
      }
      // Contains query (single word)
      else if (termLower.contains(query) && !termLower.contains(' ')) {
        score = 500 + (100 - termLower.length);
      }
      // Contains query (multi-word)
      else if (termLower.contains(query)) {
        score = 100;
      }

      scoredResults.add(MapEntry(entry, score));
    }

    // Sort by score (descending), then by term length (ascending)
    scoredResults.sort((a, b) {
      final scoreCompare = b.value.compareTo(a.value);
      if (scoreCompare != 0) return scoreCompare;
      // If scores are equal, shorter terms come first
      return a.key.term.length.compareTo(b.key.term.length);
    });

    print('🔍 Sort scores: ${scoredResults.map((e) => '${e.key.term}=${e.value}').join(', ')}');

    return scoredResults.map((e) => e.key).toList();
  }

  Future<void> _toggleFavorite(DictionaryEntry entry) async {
    try {
      final key = '${entry.term}|${entry.language}';
      final isSaved = _savedWords.contains(key);

      if (isSaved) {
        await _supabaseService.unsaveWord(entry.term, entry.language);
        setState(() => _savedWords.remove(key));
      } else {
        await _supabaseService.saveWord(entry.term, entry.language);
        setState(() => _savedWords.add(key));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSaved
                ? (_isEnglish ? 'Removed from saved' : 'Đã xóa khỏi lưu trữ')
                : (_isEnglish ? 'Saved' : 'Đã lưu'),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('❌ Save error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEnglish ? 'Save error' : 'Lỗi lưu trữ'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _searchFromHistory(String term) {
    _searchController.text = term;
    _search(term);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Search Bar & Filter
            _buildSearchSection(),

            // Results or History
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _showHistory
                      ? _buildHistorySection()
                      : _buildResultsSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF64748B),
                size: 18,
              ),
            ),
          ),
          Text(
            _isEnglish ? 'Dictionary' : 'Từ điển',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: _isEnglish ? 'Search word...' : 'Tìm từ...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: Icon(
                    Icons.search,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _search('');
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.close,
                            color: Color(0xFF9CA3AF),
                            size: 20,
                          ),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Language Filter
          Row(
            children: [
              _buildLanguageChip('All', 'all'),
              const SizedBox(width: 8),
              _buildLanguageChip('English', 'en'),
              const SizedBox(width: 8),
              _buildLanguageChip('Tiếng Việt', 'vi'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageChip(String label, String value) {
    final isSelected = _selectedLanguage == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedLanguage = value);
        if (_searchController.text.isNotEmpty) {
          _search(_searchController.text);
        }
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primaryColor.withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryColor : const Color(0xFF64748B),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primaryColor : const Color(0xFFE5E7EB),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryColor),
          const SizedBox(height: 16),
          Text(
            _isEnglish ? 'Searching...' : 'Đang tìm kiếm...',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: AppColors.primaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _isEnglish ? 'No search history' : 'Chưa có lịch sử tìm kiếm',
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _searchHistory.length,
      separatorBuilder: (context, index) => const SizedBox(height: 0),
      itemBuilder: (context, index) {
        final item = _searchHistory[index];
        final term = item['term'] as String;
        final lang = item['lang'] as String;

        return ListTile(
          leading: Icon(
            Icons.history,
            color: AppColors.primaryColor,
            size: 20,
          ),
          title: Text(
            term,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),
          subtitle: Text(
            lang == 'all' ? 'All' : (lang == 'en' ? 'English' : 'Tiếng Việt'),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Color(0xFFE5E7EB),
          ),
          onTap: () => _searchFromHistory(term),
        );
      },
    );
  }

  Widget _buildResultsSection() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.not_interested,
              size: 64,
              color: AppColors.primaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _isEnglish ? 'No results found' : 'Không tìm thấy kết quả',
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = _searchResults[index];
        return _buildResultCard(entry);
      },
    );
  }

  Widget _buildResultCard(DictionaryEntry entry) {
    final isSaved =
        _savedWords.contains('${entry.term}|${entry.language}');

    return GestureDetector(
      onTap: () => _showWordDetail(entry),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Word & Save Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              entry.term,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (entry.isCommon)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _isEnglish ? 'Common' : 'Phổ biến',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.languageName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleFavorite(entry),
                  child: Icon(
                    isSaved ? Icons.favorite : Icons.favorite_outline,
                    color: isSaved ? Colors.red : const Color(0xFFE5E7EB),
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pronunciation (English only)
            if (entry.isEnglish && entry.pronunciation.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFBFF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '/${entry.pronunciation}/',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryColor,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // Word Class
            if (entry.wordClass.isNotEmpty)
              Container(
                margin: entry.pronunciation.isNotEmpty
                    ? const EdgeInsets.only(top: 8)
                    : EdgeInsets.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFBFF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  entry.wordClass,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryColor,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (entry.wordClass.isNotEmpty) const SizedBox(height: 8),

            // Meaning
            Text(
              entry.meaning,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1F2937),
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),
            Text(
              _isEnglish ? 'Tap to see more' : 'Nhấn để xem thêm',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWordDetail(DictionaryEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildWordDetailSheet(entry),
    );
  }

  Widget _buildWordDetailSheet(DictionaryEntry entry) {
    final isSaved =
        _savedWords.contains('${entry.term}|${entry.language}');

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAFBFF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Word Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.term,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Pronunciation (English only)
                      if (entry.isEnglish && entry.pronunciation.isNotEmpty)
                        Text(
                          '/${entry.pronunciation}/',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: AppColors.primaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _toggleFavorite(entry);
                    Navigator.pop(context);
                  },
                  child: Icon(
                    isSaved ? Icons.favorite : Icons.favorite_outline,
                    color: isSaved ? Colors.red : const Color(0xFFE5E7EB),
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Language & Word Class
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.languageName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.wordClass,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                if (entry.isCommon)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isEnglish ? 'Common' : 'Phổ biến',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Meaning
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEnglish ? 'Meaning' : 'Nghĩa',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    entry.meaning,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Additional Info
            if (entry.frequency > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEnglish ? 'Frequency' : 'Tần suất',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.frequency.toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
