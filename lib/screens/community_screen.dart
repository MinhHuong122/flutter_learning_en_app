import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../widgets/custom_bottom_nav.dart';
import '../services/language_service.dart';
import 'home_screen.dart';
import 'process_screen.dart';
import 'chat_ai_screen.dart';
import 'account_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _currentIndex = 3;
  int _selectedCategory = 0;
  final List<String> categories = ['All', 'Discussion', 'Resources', 'Study Groups'];
  final List<Color> categoryColors = [
    AppColors.primaryColor,
    const Color(0xFFFF9800),
    const Color(0xFF9C27B0),
    const Color(0xFF4CAF50),
  ];
  final List<Color> categoryBgColors = [
    const Color(0xFFE0F4FF),
    const Color(0xFFFFF3E0),
    const Color(0xFFF3E5F5),
    const Color(0xFFE8F5E9),
  ];

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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProcessScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEnglish ? 'Community' : 'Cộng đồng',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            _isEnglish ? 'Connect with fellow learners' : 'Kết nối với các học viên khác',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE0F4FF),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primaryColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFFF3F4F6),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: _isEnglish ? 'Search discussions...' : 'Tìm kiếm bài viết...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF9CA3AF),
                        ),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.search,
                          color: const Color(0xFF9CA3AF),
                          size: 20,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Category Chips
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedCategory == index;
                        return Padding(
                          padding: EdgeInsets.only(right: index == categories.length - 1 ? 0 : 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedCategory = index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: isSelected ? categoryColors[index] : categoryBgColors[index],
                              ),
                              child: Text(
                                categories[index],
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : (index == 0
                                          ? AppColors.primaryColor
                                          : (index == 1
                                              ? const Color(0xFFFF9800)
                                              : (index == 2
                                                  ? const Color(0xFF9C27B0)
                                                  : const Color(0xFF4CAF50)))),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Feed
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _buildPostCard(
                    name: 'Alonzo Lee',
                    time: _isEnglish ? '2 hours ago' : '2 giờ trước',
                    content: _isEnglish
                        ? 'Just finished the Digital Design Thinking course! The module on empathy maps was a game changer. Does anyone have extra resources on user personas? 🎨'
                        : 'Vừa hoàn thành khóa Thiết kế Tư duy Kỹ thuật số! Module về empathy maps thay đổi cuộc chơi. Có ai có tài nguyên bổ sung về personas không? 🎨',
                    hasImage: true,
                    hasDownload: true,
                    downloadText: _isEnglish ? 'Download Resource' : 'Tải tài nguyên',
                    likes: 24,
                    comments: 8,
                  ),
                  const SizedBox(height: 16),
                  _buildPostCard(
                    name: 'Sarah Miller',
                    time: _isEnglish ? '5 hours ago' : '5 giờ trước',
                    content: _isEnglish
                        ? 'Looking for a study buddy for the \'Web Development\' track. Anyone interested in working through the React modules together next week? 💻🔥'
                        : 'Tìm bạn học cho track \'Phát triển Web\'. Có ai quan tâm làm việc trên các module React cùng nhau tuần tới không? 💻🔥',
                    hasImage: false,
                    hasDownload: true,
                    downloadText: _isEnglish ? 'Download Syllabus' : 'Tải Chương trình',
                    likes: 12,
                    comments: 15,
                  ),
                  const SizedBox(height: 16),
                  _buildPostCard(
                    name: 'John Developer',
                    time: _isEnglish ? '8 hours ago' : '8 giờ trước',
                    content: _isEnglish
                        ? 'Sharing my notes on advanced Flutter concepts. Check out the CustomPaint and animation techniques I covered in this document! 🚀'
                        : 'Chia sẻ ghi chú của tôi về các khái niệm Flutter nâng cao. Xem các kỹ thuật CustomPaint và animation tôi đã đề cập! 🚀',
                    hasImage: false,
                    hasDownload: true,
                    downloadText: _isEnglish ? 'Download Notes' : 'Tải ghi chú',
                    likes: 35,
                    comments: 12,
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primaryColor,
        elevation: 8,
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildPostCard({
    required String name,
    required String time,
    required String content,
    required bool hasImage,
    required bool hasDownload,
    required String downloadText,
    required int likes,
    required int comments,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primaryColor, AppColors.primaryLight],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    name[0],
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Content
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // Image (optional)
          if (hasImage)
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFE0F4FF),
              ),
              child: Icon(
                Icons.image,
                size: 60,
                color: AppColors.primaryColor.withValues(alpha: 0.3),
              ),
            ),

          if (hasImage) const SizedBox(height: 12),

          // Download button
          if (hasDownload)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFFE0F4FF),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.download,
                      size: 16,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      downloadText,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (hasDownload) const SizedBox(height: 12),

          // Actions
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: const Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.favorite_border,
                    label: '$likes',
                  ),
                ),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: '$comments',
                  ),
                ),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.share_outlined,
                    label: '',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
  }) {
    return InkWell(
      onTap: () {},
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF9CA3AF),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
