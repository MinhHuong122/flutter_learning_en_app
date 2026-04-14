import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../widgets/custom_bottom_nav.dart';
import '../services/language_service.dart';
import '../services/word_questions_service.dart';
import '../services/recent_games_service.dart';
import '../models/word_question.dart';
import 'home_screen.dart';
import 'chat_ai_screen.dart';
import 'account_screen.dart';
import 'archive_screen.dart';
import 'word_puzzle_game.dart';
import 'game_screen.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({Key? key}) : super(key: key);

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  late int _currentIndex;
  List<RecentGameModel> _recentGames = [];

  @override
  void initState() {
    super.initState();
    // Always initialize to Progress tab (index 1) for Exercise screen
    _currentIndex = 3;
    _loadRecentGames();
  }

  Future<void> _loadRecentGames() async {
    final games = await RecentGamesService.getRecentGames();
    setState(() => _recentGames = games);
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
        setState(() => _currentIndex = index);
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ChatAiScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ArchiveScreen()),
        );
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
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF9F9FF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEnglish ? 'Exercises' : 'Bài tập',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: AppColors.primaryColor, size: 18),
                const SizedBox(width: 4),
                Text(
                  '1,240',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Games Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      _isEnglish ? 'FEATURED GAMES' : 'TRÒ CHƠI NỔI BẬT',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF9CA3AF),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFF9CA3AF)),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    _isEnglish ? 'View All' : 'Xem tất cả',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Featured Games Carousel
            SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildFeaturedGameCard(
                    title: 'Word Puzzle',
                    category: 'PUZZLE',
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    icon: Icons.games,
                    onTap: () => _openWordPuzzle(),
                  ),
                  const SizedBox(width: 12),
                  _buildFeaturedGameCard(
                    title: 'Memory Matching',
                    category: 'MEMORY',
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
                    ),
                    icon: Icons.memory,
                    onTap: () => _openWebGame(
                      'Memory Matching Game',
                      'https://www.gamestolearnenglish.com/concentration/',
                      'MEMORY',
                      const Color(0xFFEC4899),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildFeaturedGameCard(
                    title: 'Words of Wonders',
                    category: 'WORD',
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                    icon: Icons.language,
                    onTap: () => _openWebGame(
                      'Words of Wonders',
                      'https://www.crazygames.com/vn/game/words-of-wonders',
                      'WORD GAME',
                      const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Recommended For You Header
            Text(
              _isEnglish ? 'RECOMMENDED FOR YOU' : 'GỢI Ý CHO BẠN',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF9CA3AF),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // Recommended Games List
            _buildRecommendedGame(
              title: 'Word Scramble',
              category: 'PUZZLE',
              rating: '4.9',
              color: const Color(0xFF14B8A6),
              icon: Icons.shuffle,
              onTap: () => _openWebGame(
                'Word Scramble',
                'https://games.readersdigest.ca/games/word-scramble',
                'PUZZLE',
                const Color(0xFF14B8A6),
              ),
            ),
            const SizedBox(height: 12),

            _buildRecommendedGame(
              title: 'Word Search - LYG',
              category: 'SEARCH',
              rating: '4.7',
              color: const Color(0xFF8B5CF6),
              icon: Icons.search,
              onTap: () => _openWebGame(
                'Word Search - LYG',
                'https://www.crazygames.com/vn/game/word-search-lyg',
                'SEARCH',
                const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(height: 12),

            _buildRecommendedGame(
              title: 'Crocword',
              category: 'WORD',
              rating: '4.8',
              color: const Color(0xFFDC2626),
              icon: Icons.grid_3x3,
              onTap: () => _openWebGame(
                'Crocword',
                'https://www.crazygames.com/vn/game/crocword',
                'WORD',
                const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 12),

            _buildRecommendedGame(
              title: 'Word Search',
              category: 'PUZZLE',
              rating: '4.6',
              color: const Color(0xFF0EA5E9),
              icon: Icons.find_in_page,
              onTap: () => _openWebGame(
                'Word Search',
                'https://www.crazygames.com/vn/game/word-search',
                'PUZZLE',
                const Color(0xFF0EA5E9),
              ),
            ),
            const SizedBox(height: 12),

            _buildRecommendedGame(
              title: 'Game Học Tiếng Anh',
              category: 'EDUCATION',
              rating: '4.9',
              color: const Color(0xFF10B981),
              icon: Icons.school,
              onTap: () => _openWebGame(
                'Game Học Tiếng Anh',
                'https://gamehoctienganh.vn/',
                'EDUCATION',
                const Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 12),

            _buildRecommendedGame(
              title: 'Easy Games',
              category: 'FUN',
              rating: '4.5',
              color: const Color(0xFFF59E0B),
              icon: Icons.sports_score,
              onTap: () => _openWebGame(
                'Easy Games',
                'https://easygames.vn/games_hoc_tap',
                'FUN',
                const Color(0xFFF59E0B),
              ),
            ),

            // Recently Played Games
            if (_recentGames.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                _isEnglish ? 'RECENTLY PLAYED' : 'CHƠI GẦN ĐÂY',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF9CA3AF),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildRecentGamesSection(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Future<void> _openWordPuzzle() async {
    final questions = await WordQuestionsService.getQuestionsForLevel(1);
    if (mounted && questions.isNotEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WordPuzzleGame(
            levelNumber: 1,
            questions: questions,
          ),
        ),
      );
    }
  }

  void _openWebGame(
    String gameTitle,
    String gameUrl,
    String gameCategory,
    Color accentColor,
  ) async {
    // Save to recent games
    await RecentGamesService.addRecentGame(
      title: gameTitle,
      url: gameUrl,
      category: gameCategory,
      colorHex: '#${accentColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
    );

    // Reload recent games
    await _loadRecentGames();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          gameTitle: gameTitle,
          gameUrl: gameUrl,
          gameCategory: gameCategory,
          accentColor: accentColor,
        ),
      ),
    );
  }

  Widget _buildFeaturedGameCard({
    required String title,
    required String category,
    required LinearGradient gradient,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Overlay gradient
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: Colors.white, size: 36),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.manrope(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
      ),
    );
  }

  Widget _buildRecommendedGame({
    required String title,
    required String category,
    required String rating,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: color.withOpacity(0.15),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.manrope(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFB923C),
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        rating,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Play Button
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                _isEnglish ? 'Play' : 'Chơi',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(width: 4),

            // Chevron
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFD1D5DB),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentGamesSection() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _recentGames.length,
      itemBuilder: (context, index) {
        final game = _recentGames[index];
        final color = _hexToColor(game.colorHex);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildRecommendedGame(
            title: game.title,
            category: game.category,
            rating: _formatPlayedTime(game.playedAt),
            color: color,
            icon: Icons.history,
            onTap: () => _openWebGame(
              game.title,
              game.url,
              game.category,
              color,
            ),
          ),
        );
      },
    );
  }

  Color _hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  String _formatPlayedTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return _isEnglish ? 'Just now' : 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return _isEnglish
          ? '${difference.inMinutes}m ago'
          : '${difference.inMinutes}p';
    } else if (difference.inHours < 24) {
      return _isEnglish
          ? '${difference.inHours}h ago'
          : '${difference.inHours}g';
    } else {
      return _isEnglish
          ? '${difference.inDays}d ago'
          : '${difference.inDays}d';
    }
  }
}