import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../widgets/custom_bottom_nav.dart';
import '../services/language_service.dart';
import 'home_screen.dart';
import 'chat_ai_screen.dart';
import 'account_screen.dart';
import 'archive_screen.dart';
import 'word_puzzle_game.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({Key? key}) : super(key: key);

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  int _currentIndex = 1;
  String _selectedTheme = 'desert'; // 'desert' or 'forest'
  
  // Sample puzzle words data - In real app, load from Supabase based on lesson
  final Map<String, List<Map<String, dynamic>>> levelWords = {
    'level1': [
      {"word": "PORK", "startRow": 0, "startCol": 5, "direction": "across", "number": 1},
      {"word": "BEEF", "startRow": 1, "startCol": 1, "direction": "across", "number": 2},
      {"word": "WATER", "startRow": 2, "startCol": 0, "direction": "across", "number": 3},
      {"word": "NOODLES", "startRow": 2, "startCol": 4, "direction": "down", "number": 4},
      {"word": "LEMONADE", "startRow": 4, "startCol": 0, "direction": "across", "number": 5},
      {"word": "CHICKEN", "startRow": 6, "startCol": 2, "direction": "across", "number": 6},
    ],
    'level2': [
      {"word": "APPLE", "startRow": 0, "startCol": 2, "direction": "across", "number": 1},
      {"word": "ORANGE", "startRow": 1, "startCol": 0, "direction": "across", "number": 2},
      {"word": "BANANA", "startRow": 2, "startCol": 5, "direction": "across", "number": 3},
      {"word": "GRAPE", "startRow": 2, "startCol": 0, "direction": "down", "number": 4},
      {"word": "MANGO", "startRow": 4, "startCol": 3, "direction": "across", "number": 5},
    ],
    'level3': [
      {"word": "SHIRT", "startRow": 0, "startCol": 2, "direction": "across", "number": 1},
      {"word": "PANTS", "startRow": 1, "startCol": 0, "direction": "across", "number": 2},
      {"word": "SHOES", "startRow": 2, "startCol": 3, "direction": "across", "number": 3},
      {"word": "COAT", "startRow": 2, "startCol": 0, "direction": "down", "number": 4},
      {"word": "HAT", "startRow": 4, "startCol": 5, "direction": "across", "number": 5},
    ],
  };

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
                    _isEnglish ? 'Exercises' : 'Bài tập',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Theme selector tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildThemeTab(
                      label: _isEnglish ? 'Desert Mode' : 'Chế độ sa mạc',
                      theme: 'desert',
                      icon: Icons.wb_sunny,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildThemeTab(
                      label: _isEnglish ? 'Forest Mode' : 'Chế độ rừng',
                      theme: 'forest',
                      icon: Icons.nature,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Main content - Level selection grid
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    itemCount: 3, // 3 levels
                    itemBuilder: (context, index) {
                      return _buildLevelCard(index + 1);
                    },
                  ),
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

  Widget _buildThemeTab({
    required String label,
    required String theme,
    required IconData icon,
  }) {
    final isSelected = _selectedTheme == theme;
    return GestureDetector(
      onTap: () => setState(() => _selectedTheme = theme),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppColors.primaryColor : const Color(0xFFF3F4F6),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(int levelNumber) {
    final isDesert = _selectedTheme == 'desert';
    final primaryColor = isDesert ? const Color(0xFFFDB54E) : const Color(0xFF10B981);
    final bgColor = isDesert ? const Color(0xFFFFF5E6) : const Color(0xFFECFDF5);
    final icon = isDesert ? Icons.wb_sunny : Icons.eco;

    return GestureDetector(
      onTap: () async {
        final words = levelWords['level$levelNumber'] ?? [];
        if (mounted) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WordPuzzleGame(
                levelNumber: levelNumber,
                theme: _selectedTheme,
                words: words,
                            ),
            ),
          );
          if (result == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isEnglish ? '🎉 Level completed!' : '🎉 Hoàn thành màn chơi!',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primaryColor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                color: primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
          ),
          child: Icon(
            icon,
                color: Colors.white,
                size: 28,
          ),
        ),
            const SizedBox(height: 12),
        Text(
              _isEnglish ? 'Level $levelNumber' : 'Cấp độ $levelNumber',
          style: GoogleFonts.poppins(
                fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
              _isEnglish ? 'Play Now' : 'Chơi ngay',
          style: GoogleFonts.poppins(
                fontSize: 12,
                color: primaryColor,
                fontWeight: FontWeight.w600,
          ),
        ),
      ],
        ),
      ),
    );
  }
}
