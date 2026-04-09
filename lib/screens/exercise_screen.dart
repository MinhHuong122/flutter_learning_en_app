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

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({Key? key}) : super(key: key);

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  int _currentIndex = 1;
  int _selectedTheme = 0; // 0: Desert, 1: Forest

  bool get _isEnglish => context.watch<LanguageService>().isEnglish;

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
          MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
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
            // Header with theme tabs
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
                      index: 0,
                      icon: Icons.wb_sunny,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildThemeTab(
                      label: _isEnglish ? 'Forest Mode' : 'Chế độ rừng',
                      index: 1,
                      icon: Icons.nature,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                child: _selectedTheme == 0
                    ? _buildDesertTheme()
                    : _buildForestTheme(),
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
    required int index,
    required IconData icon,
  }) {
    final isSelected = _selectedTheme == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTheme = index),
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

  Widget _buildDesertTheme() {
    return Column(
      children: [
        // Game info card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFDB54E),
                  const Color(0xFFFFE5B4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFDB54E).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEnglish ? 'Level 1' : 'Cấp độ 1',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isEnglish ? 'Desert Adventure' : 'Phiêu lưu sa mạc',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      child: const Icon(
                        Icons.sentiment_satisfied,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Game map container
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: const Color(0xFFFFF5E6),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Game path with levels
                    SizedBox(
                      height: 300,
                      child: CustomPaint(
                        painter: GamePathPainter(isDarkTheme: false),
                        child: Stack(
                          children: [
                            // Level badges
                            Positioned(
                              top: 20,
                              left: 40,
                              child: _buildLevelBadge(1, true),
                            ),
                            Positioned(
                              top: 80,
                              right: 40,
                              child: _buildLevelBadge(2, false),
                            ),
                            Positioned(
                              top: 140,
                              left: 40,
                              child: _buildLevelBadge(3, false),
                            ),
                            Positioned(
                              top: 200,
                              right: 40,
                              child: _buildLevelBadge(4, false),
                            ),
                            Positioned(
                              bottom: 20,
                              left: 50,
                              child: _buildLevelBadge(5, false),
                            ),
                            // Character at bottom
                            Positioned(
                              bottom: 0,
                              left: 20,
                              child: SizedBox(
                                width: 80,
                                child: Icon(
                                  Icons.pets,
                                  size: 60,
                                  color: const Color(0xFFFDB54E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Progress stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          icon: Icons.star,
                          value: '240',
                          label: _isEnglish ? 'Points' : 'Điểm',
                          color: const Color(0xFFFFD700),
                        ),
                        _buildStatItem(
                          icon: Icons.favorite,
                          value: '12',
                          label: _isEnglish ? 'Streak' : 'Chuỗi',
                          color: const Color(0xFFFF6B6B),
                        ),
                        _buildStatItem(
                          icon: Icons.local_fire_department,
                          value: '8/10',
                          label: _isEnglish ? 'Quest' : 'Nhiệm vụ',
                          color: const Color(0xFFFFA500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDB54E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {},
                  child: Text(
                    _isEnglish ? 'Start Exercise' : 'Bắt đầu bài tập',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForestTheme() {
    return Column(
      children: [
        // Game info card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981),
                  const Color(0xFF6EE7B7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEnglish ? 'Level 2' : 'Cấp độ 2',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isEnglish ? 'Forest Quest' : 'Nhiệm vụ rừng',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      child: const Icon(
                        Icons.sentiment_very_satisfied,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Game map container
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: const Color(0xFFECFDF5),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Game path with levels
                    SizedBox(
                      height: 300,
                      child: CustomPaint(
                        painter: GamePathPainter(isDarkTheme: true),
                        child: Stack(
                          children: [
                            // Level badges
                            Positioned(
                              top: 20,
                              left: 40,
                              child: _buildLevelBadge(1, false, isForest: true),
                            ),
                            Positioned(
                              top: 80,
                              right: 40,
                              child: _buildLevelBadge(2, false, isForest: true),
                            ),
                            Positioned(
                              top: 140,
                              left: 40,
                              child: _buildLevelBadge(3, false, isForest: true),
                            ),
                            Positioned(
                              top: 200,
                              right: 40,
                              child: _buildLevelBadge(4, false, isForest: true),
                            ),
                            Positioned(
                              bottom: 20,
                              left: 50,
                              child: _buildLevelBadge(5, false, isForest: true),
                            ),
                            // Character at bottom
                            Positioned(
                              bottom: 0,
                              left: 20,
                              child: SizedBox(
                                width: 80,
                                child: Icon(
                                  Icons.eco,
                                  size: 60,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Progress stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          icon: Icons.star,
                          value: '180',
                          label: _isEnglish ? 'Points' : 'Điểm',
                          color: const Color(0xFFFFD700),
                        ),
                        _buildStatItem(
                          icon: Icons.favorite,
                          value: '8',
                          label: _isEnglish ? 'Streak' : 'Chuỗi',
                          color: const Color(0xFFFF6B6B),
                        ),
                        _buildStatItem(
                          icon: Icons.local_fire_department,
                          value: '5/10',
                          label: _isEnglish ? 'Quest' : 'Nhiệm vụ',
                          color: const Color(0xFFFFA500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {},
                  child: Text(
                    _isEnglish ? 'Start Exercise' : 'Bắt đầu bài tập',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevelBadge(int level, bool isCompleted, {bool isForest = false}) {
    final bgColor = isForest
        ? (isCompleted ? const Color(0xFF10B981) : const Color(0xFFD1DFE8))
        : (isCompleted ? const Color(0xFFFDB54E) : const Color(0xFFD1DFE8));

    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$level',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color:
                    isCompleted ? Colors.white : const Color(0xFF9CA3AF),
              ),
            ),
            if (isCompleted)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 12,
                    color: bgColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
          color: color.withValues(alpha: 0.1),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}

// Custom painter for game path
class GamePathPainter extends CustomPainter {
  final bool isDarkTheme;

  GamePathPainter({required this.isDarkTheme});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDarkTheme ? const Color(0xFFA7F3D0) : const Color(0xFFFFE5CC)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // Draw winding path
    final path = Path();
    path.moveTo(size.width * 0.35, size.height - 40);
    path.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.7,
      size.width * 0.65,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.3,
      size.width * 0.65,
      size.height * 0.1,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(GamePathPainter oldDelegate) => false;
}
