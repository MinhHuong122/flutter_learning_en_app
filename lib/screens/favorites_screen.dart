import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../widgets/custom_bottom_nav.dart';
import '../services/language_service.dart';
import '../services/lesson_favorites_service.dart';
import '../services/custom_lesson_favorites_service.dart';
import '../services/supabase_dictionary_service.dart';
import '../services/lesson_service.dart';
import '../models/dictionary_model.dart';
import '../models/lesson_model.dart';
import 'home_screen.dart';
import 'process_screen.dart';
import 'chat_ai_screen.dart';
import 'account_screen.dart';
import 'lesson_detail_screen.dart';
import 'flashcard_swipe_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  int _currentIndex = 3;
  List<DictionaryEntry> _favoriteWords = [];
  List<Lesson> _favoriteLessons = [];
  List<DictionaryEntry> _filteredFavoriteWords = [];
  List<Lesson> _filteredFavoriteLessons = [];
  List<Map<String, dynamic>> _customLessons = [];
  bool _isLoadingWords = true;
  bool _isLoadingFavorites = true;
  bool _isLoadingCustom = true;
  final LessonFavoritesService _lessonFavoritesService = LessonFavoritesService();
  final SupabaseDictionaryService _dictionaryService = SupabaseDictionaryService();
  bool _reloadedAfterOpen = false;
  final TextEditingController _searchController = TextEditingController();
  final CustomLessonFavoritesService _customLessonFavoritesService = CustomLessonFavoritesService();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_searchFavorites);
    _reloadAllFavorites();
    _loadCustomLessons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_reloadedAfterOpen) {
      _reloadedAfterOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reloadAllFavorites();
      });
    }
  }

  Future<void> _loadCustomLessons() async {
    if (mounted) setState(() => _isLoadingCustom = true);
    try {
      // Load favorite custom lessons from the new service
      final favoriteLessons = await _customLessonFavoritesService.getUserFavoriteCustomLessons();
      if (mounted) {
        setState(() {
          _customLessons = favoriteLessons;
          _isLoadingCustom = false;
        });
      }
    } catch (e) {
      print('❌ Error loading favorite custom lessons: $e');
      if (mounted) setState(() => _isLoadingCustom = false);
    }
  }

  Future<void> _reloadAllFavorites() async {
    await Future.wait([
      _loadSavedWords(),
      _loadFavorites(),
    ]);
  }

  Future<void> _loadSavedWords() async {
    if (mounted) setState(() => _isLoadingWords = true);
    final words = await _dictionaryService.getUserSavedWords();
    if (mounted) {
      setState(() {
        _favoriteWords = words;
        _filteredFavoriteWords = words;
        _isLoadingWords = false;
      });
    }
  }

  Future<void> _removeSavedWord(DictionaryEntry entry) async {
    await _dictionaryService.unsaveWord(entry.term, entry.language);
    await _loadSavedWords();
  }

  Future<void> _loadFavorites() async {
    if (mounted) setState(() => _isLoadingFavorites = true);
    final lessons = await _lessonFavoritesService.getUserFavoriteLessons();
    if (mounted) {
      setState(() {
        _favoriteLessons = lessons;
        _filteredFavoriteLessons = lessons;
        _isLoadingFavorites = false;
      });
    }
  }

  Future<void> _removeFavorite(String lessonId) async {
    await _lessonFavoritesService.removeFavorite(lessonId);
    await _loadFavorites();
  }

  void _searchFavorites() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFavoriteWords = _favoriteWords;
        _filteredFavoriteLessons = _favoriteLessons;
      } else {
        _filteredFavoriteWords = _favoriteWords.where((entry) {
          return entry.term.toLowerCase().contains(query) ||
              entry.meaning.toLowerCase().contains(query);
        }).toList();

        _filteredFavoriteLessons = _favoriteLessons.where((lesson) {
          return lesson.title.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _openCustomLesson(String lessonId, String lessonName) async {
    try {
      // Navigate to swipe view to practice the lesson
      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlashcardSwiperScreen(
              lessonId: lessonId,
              lessonName: lessonName,
            ),
          ),
        );
        
        // Reload favorites when returning from swipe view
        if (result == true && mounted) {
          _loadCustomLessons();
        }
      }
    } catch (e) {
      print('❌ Error opening custom lesson: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEnglish ? 'Error opening lesson' : 'Lỗi khi mở bài học',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool get _isEnglish => context.read<LanguageService>().isEnglish;

  void _onBottomNavTap(int index) {
    if (index == _currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProcessScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ChatAiScreen()),
        );
        break;
      case 3:
        setState(() => _currentIndex = index);
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AccountScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    _isEnglish ? 'Favorites' : 'Yêu thích',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _isEnglish ? 'Search your favorites...' : 'Tìm kiếm yêu thích...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF9CA3AF),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF9CA3AF),
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _searchFavorites();
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(
                                Icons.close,
                                color: Color(0xFF9CA3AF),
                                size: 18,
                              ),
                            ),
                          )
                        : Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.tune,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Favorite Dictionary Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isEnglish ? 'Favorite Dictionary' : 'Từ vựng yêu thích',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  _isEnglish ? 'View All' : 'Xem tất cả',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),

                    // Horizontal scrolling dictionary cards
                    SizedBox(
                      height: 165,
                      child: _isLoadingWords
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredFavoriteWords.isEmpty
                              ? _buildEmptyDictionaryWords()
                              : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  itemCount: _filteredFavoriteWords.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    return _buildFavoriteDictionaryCard(
                                      _filteredFavoriteWords[index],
                                      index,
                                    );
                                  },
                                ),
                    ),

                    const SizedBox(height: 32),

                    // Favorite Lessons Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isEnglish ? 'Favorite Lessons' : 'Bài học yêu thích',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  _isEnglish ? 'View All' : 'Xem tất cả',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),

                    // Favorite lessons list
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _isLoadingFavorites
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : _filteredFavoriteLessons.isEmpty
                              ? _buildEmptyLessons()
                              : Column(
                                  children: [
                                    ..._filteredFavoriteLessons.asMap().entries.map((e) {
                                      return Column(
                                        children: [
                                          _buildFavoriteLessonCard(e.value, e.key),
                                          if (e.key < _filteredFavoriteLessons.length - 1)
                                            const SizedBox(height: 12),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                    ),

                    const SizedBox(height: 32),

                    // My Created Lessons Section (only show favorited custom lessons)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isEnglish ? 'Created & Favorited' : 'Tạo & Yêu thích',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  _isEnglish ? 'View All' : 'Xem tất cả',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),

                    // Created lessons grid - Only show favorited custom lessons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _isLoadingCustom
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : _customLessons.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      child: Center(
                                        child: Text(
                                          _isEnglish 
                                              ? 'No created lessons favorited yet' 
                                              : 'Chưa có bài học tạo nào được yêu thích',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: const Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ),
                                    )
                                  : GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 0.95,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                                      children: _customLessons.map((lesson) {
                                        final cardCount = lesson['flashcardCount'] ?? 0;
                                        final lessonId = lesson['id'] as String? ?? '';
                                        final lessonName = lesson['name'] as String? ?? 'Untitled';
                                        
                                        const iconOptions = [Icons.note_alt, Icons.psychology, Icons.menu_book, Icons.school];
                                        const bgColors = [
                                          Color(0xFFEEF7FF),
                                          Color(0xFFFFF5E6),
                                          Color(0xFFF0FDF4),
                                          Color(0xFFEFF6FF),
                                        ];
                                        const fgColors = [
                                          AppColors.primaryColor,
                                          Color(0xFFFFB347),
                                          Color(0xFF10B981),
                                          Color(0xFFA855F7),
                                        ];
                                        
                                        final idx = lessonId.hashCode % iconOptions.length;
                                        
                                        return GestureDetector(
                                          onTap: () => _openCustomLesson(lessonId, lessonName),
                                          child: _buildCreatedLessonCard(
                                            title: lessonName,
                                            count: '$cardCount ${_isEnglish ? 'Cards' : 'Thẻ'}',
                                            icon: iconOptions[idx],
                                            backgroundColor: bgColors[idx].withOpacity(0.1),
                                            iconColor: fgColors[idx],
                          ),
                                        );
                                      }).toList(),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildEmptyDictionaryWords() {
    return Center(
      child: Text(
        _isEnglish ? 'No favorite words yet' : 'Chưa có từ yêu thích',
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: const Color(0xFF9CA3AF),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFavoriteDictionaryCard(DictionaryEntry entry, int index) {
    const iconColors = [
      Color(0xFF6366F1),
      Color(0xFFF97316),
      Color(0xFF10B981),
      Color(0xFF3B82F6),
    ];
    const bgColors = [
      Color(0xFFEEF7FF),
      Color(0xFFFFF5E6),
      Color(0xFFF0FDF4),
      Color(0xFFEFF6FF),
    ];
    final iconColor = iconColors[index % iconColors.length];
    final backgroundColor = bgColors[index % bgColors.length];

    return GestureDetector(
      onTap: () => _showWordDetail(entry),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: iconColor.withOpacity(0.3), width: 1),
        ),
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.translate, color: iconColor, size: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  entry.term,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  entry.meaning,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removeSavedWord(entry),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyLessons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Icon(Icons.favorite_border, size: 56, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 12),
          Text(
            _isEnglish ? 'No favorite lessons yet' : 'Chưa có bài học yêu thích',
            style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 6),
          Text(
            _isEnglish
                ? 'Tap the ♥ on any course to save it here'
                : 'Nhấn nút ♥ trong bài học để lưu vào đây',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFD1D5DB)),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteLessonCard(Lesson lesson, int index) {
    const bgColors = [
      Color(0xFFEFF6FF),
      Color(0xFFF3E8FF),
      Color(0xFFFFF7ED),
      Color(0xFFF0FDF4),
    ];
    const progressColors = [
      AppColors.primaryColor,
      Color(0xFFA855F7),
      Color(0xFFF97316),
      Color(0xFF10B981),
    ];
    final bgColor = bgColors[index % bgColors.length];
    final progressColor = progressColors[index % progressColors.length];
    final levelLabel = lesson.level.isEmpty
        ? ''
        : lesson.level[0].toUpperCase() + lesson.level.substring(1);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: lesson)),
        );
        _loadFavorites();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.menu_book_rounded, color: progressColor, size: 36),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        levelLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      if (lesson.durationMinutes != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 12, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 4),
                            Text(
                              '${lesson.durationMinutes} min',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _removeFavorite(lesson.id),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.favorite, color: Colors.red, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatedLessonCard({
    required String title,
    required String count,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
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
                    _removeSavedWord(entry);
                    Navigator.pop(context);
                  },
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.red,
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
