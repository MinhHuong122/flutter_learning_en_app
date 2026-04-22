import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/language_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_bottom_nav.dart';
import 'archive_screen.dart';
import 'chat_ai_screen.dart';
import 'home_screen.dart';
import 'process_screen.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  int _currentIndex = 4;
  String _searchQuery = '';

  bool get _isEnglish => context.read<LanguageService>().isEnglish;

  final List<Map<String, String>> _featureItems = [
    {
      'titleEn': 'Personalized Home & Learning Path',
      'titleVi': 'Trang chủ cá nhân hóa & lộ trình học',
      'subtitleEn': 'Survey-based recommendations and quick access',
      'subtitleVi': 'Đề cử theo khảo sát và truy cập nhanh',
      'contentEn': 'After onboarding survey, Home prioritizes lessons that match your level, goals, and selected skills. You can quickly open suggested courses, continue recent learning, and view important updates.',
      'contentVi': 'Sau khảo sát ban đầu, Trang chủ ưu tiên các bài học phù hợp với trình độ, mục tiêu và kỹ năng bạn chọn. Bạn có thể mở nhanh khóa học gợi ý, tiếp tục phần đang học và xem cập nhật quan trọng.',
    },
    {
      'titleEn': 'System Lessons & Structured Courses',
      'titleVi': 'Bài học hệ thống & khóa học có cấu trúc',
      'subtitleEn': 'Topic-based curriculum with levels',
      'subtitleVi': 'Giáo trình theo chủ đề và cấp độ',
      'contentEn': 'Learn through organized lessons from beginner to advanced. Each lesson includes vocabulary, context, and practice flow to help you build confidence step by step.',
      'contentVi': 'Học qua các bài được tổ chức từ cơ bản đến nâng cao. Mỗi bài gồm từ vựng, ngữ cảnh và luồng luyện tập để bạn tiến bộ từng bước rõ ràng.',
    },
    {
      'titleEn': 'Quiz Engine (7 Exercise Types)',
      'titleVi': 'Hệ thống Quiz (7 dạng bài tập)',
      'subtitleEn': 'Rich practice and auto-generated questions',
      'subtitleVi': 'Luyện tập đa dạng và tự sinh câu hỏi',
      'contentEn': 'The app supports 7 quiz formats such as multiple choice, fill in the blank, matching, listening, translation, sentence ordering, and conversation-based tasks. If a lesson has no question set yet, the system can generate relevant exercises from lesson vocabulary.',
      'contentVi': 'Ứng dụng hỗ trợ 7 dạng quiz như trắc nghiệm, điền từ, nối cặp, nghe, dịch nghĩa, sắp xếp câu và tình huống hội thoại. Nếu bài học chưa có bộ câu hỏi, hệ thống có thể tự tạo câu phù hợp từ từ vựng của bài.',
    },
    {
      'titleEn': 'My Lessons: OCR, Camera, and File Import',
      'titleVi': 'Bài học của tôi: OCR, camera và nhập file',
      'subtitleEn': 'Turn your own materials into study sets',
      'subtitleVi': 'Biến tài liệu cá nhân thành bộ học',
      'contentEn': 'Create custom lessons using camera scan, OCR extraction, or file import. Edit detected words, save lesson content, and practice directly with flashcards and exercises.',
      'contentVi': 'Tạo bài học cá nhân bằng quét camera, trích xuất OCR hoặc nhập file. Chỉnh sửa từ đã nhận diện, lưu nội dung bài học và luyện ngay bằng flashcard cùng bài tập.',
    },
    {
      'titleEn': 'Flashcard Practice & Smart Review',
      'titleVi': 'Luyện Flashcard & ôn tập thông minh',
      'subtitleEn': 'Swipe learning with review queue',
      'subtitleVi': 'Học vuốt thẻ với hàng đợi ôn tập',
      'contentEn': 'Use flashcard sessions for fast memorization. "Got it" cards move forward while "Review" cards reappear later in the queue so you revisit weaker vocabulary naturally.',
      'contentVi': 'Dùng phiên flashcard để ghi nhớ nhanh. Thẻ "Đã biết" sẽ tiến tiếp, còn thẻ "Ôn lại" sẽ xuất hiện lại ở lượt sau để bạn củng cố từ yếu một cách tự nhiên.',
    },
    {
      'titleEn': 'AI Chat Tutor & Dictionary',
      'titleVi': 'Trợ giảng AI Chat & Từ điển',
      'subtitleEn': 'Ask, explain, and look up instantly',
      'subtitleVi': 'Hỏi đáp, giải thích và tra cứu tức thì',
      'contentEn': 'Use AI Chat to ask grammar, translation, or usage questions. Dictionary search helps you quickly check meanings and examples while learning.',
      'contentVi': 'Dùng AI Chat để hỏi ngữ pháp, dịch nghĩa hoặc cách dùng từ. Từ điển giúp bạn tra cứu nhanh ý nghĩa và ví dụ trong lúc học.',
    },
    {
      'titleEn': 'Community, Favorites, and Archive',
      'titleVi': 'Cộng đồng, Yêu thích và Lưu trữ',
      'subtitleEn': 'Share content and keep useful resources',
      'subtitleVi': 'Chia sẻ nội dung và lưu lại tài nguyên hữu ích',
      'contentEn': 'Join the community feed, create posts, and discover lessons from others. Save important items to Favorites, and manage completed or stored content in Archive for easy review.',
      'contentVi': 'Tham gia bảng tin cộng đồng, tạo bài viết và khám phá bài học từ người khác. Lưu nội dung quan trọng vào Yêu thích, đồng thời quản lý nội dung đã học/lưu trữ trong Kho để ôn tập dễ dàng.',
    },
    {
      'titleEn': 'Progress, Notifications, and Account',
      'titleVi': 'Tiến độ, thông báo và tài khoản',
      'subtitleEn': 'Track growth and control profile settings',
      'subtitleVi': 'Theo dõi phát triển và quản lý hồ sơ',
      'contentEn': 'Monitor lesson progress over time, receive in-app notifications, update profile details, and control app language and security settings from Account.',
      'contentVi': 'Theo dõi tiến độ bài học theo thời gian, nhận thông báo trong ứng dụng, cập nhật hồ sơ cá nhân và quản lý ngôn ngữ/bảo mật tại mục Tài khoản.',
    },
    {
      'titleEn': 'Payment & Upgrade (if enabled)',
      'titleVi': 'Thanh toán & nâng cấp (nếu bật)',
      'subtitleEn': 'Unlock extra features and storage options',
      'subtitleVi': 'Mở khóa tính năng và dung lượng mở rộng',
      'contentEn': 'The app includes payment and upgrade flows (such as VNPAY integration) for plans or storage enhancements depending on your account and deployment configuration.',
      'contentVi': 'Ứng dụng có luồng thanh toán và nâng cấp (như tích hợp VNPAY) cho gói dịch vụ hoặc mở rộng dung lượng tùy theo cấu hình tài khoản và môi trường triển khai.',
    },
  ];

  final List<Map<String, String>> _supportItems = [
    {
      'icon': 'chat',
      'titleEn': 'Live Chat',
      'titleVi': 'Chat truc tuyen',
      'subtitleEn': 'Typical reply 5m',
      'subtitleVi': 'Thuong phan hoi trong 5 phut',
    },
    {
      'icon': 'mail',
      'titleEn': 'Email Support',
      'titleVi': 'Ho tro qua Email',
      'subtitleEn': '24h Response',
      'subtitleVi': 'Phan hoi trong 24 gio',
    },
  ];

  List<Map<String, String>> get _filteredFeatureItems {
    if (_searchQuery.trim().isEmpty) return _featureItems;

    final q = _searchQuery.toLowerCase().trim();
    return _featureItems.where((item) {
      final title = (_isEnglish ? item['titleEn'] : item['titleVi'])?.toLowerCase() ?? '';
      final subtitle = (_isEnglish ? item['subtitleEn'] : item['subtitleVi'])?.toLowerCase() ?? '';
      final content = (_isEnglish ? item['contentEn'] : item['contentVi'])?.toLowerCase() ?? '';
      return title.contains(q) || subtitle.contains(q) || content.contains(q);
    }).toList();
  }

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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ArchiveScreen()),
        );
        break;
      case 4:
        setState(() => _currentIndex = index);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFFF3F4F6),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF4B5563),
                        size: 20,
                      ),
                    ),
                  ),
                  Text(
                    _isEnglish ? 'Help Center' : 'Trung tâm hỗ trợ',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                color: AppColors.primaryColor,
                                size: 44,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    _isEnglish
                                        ? 'Everything you can do in PUPU'
                                        : 'Toan bo tinh nang ban co the dung trong PUPU',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1F2937),
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isEnglish
                                  ? 'Find answers and learn how to master your study journey.'
                                  : 'Tim cau tra loi va kham pha cach tan dung toi da hanh trinh hoc tap cua ban.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF4B5563),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1C3355).withOpacity(0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: _isEnglish ? 'Search for help...' : 'Tim kiem noi dung ho tro...',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF6B7280),
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF6B7280),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          if (_filteredFeatureItems.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _isEnglish
                                    ? 'No matching topics found. Try another keyword.'
                                    : 'Khong tim thay chu de phu hop. Thu tu khoa khac.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          for (int i = 0; i < _filteredFeatureItems.length; i++) ...[
                            _buildExpandableFeatureItem(
                              index: i,
                              item: _filteredFeatureItems[i],
                              onTap: () {
                                _showFeatureDetailPopup(
                                  context,
                                  _filteredFeatureItems[i],
                                  i,
                                );
                              },
                            ),
                            if (i < _filteredFeatureItems.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSupportCard(
                              icon: Icons.chat_bubble_outline_rounded,
                              color: AppColors.primaryColor,
                              title: _isEnglish ? _supportItems[0]['titleEn']! : _supportItems[0]['titleVi']!,
                              subtitle: _isEnglish ? _supportItems[0]['subtitleEn']! : _supportItems[0]['subtitleVi']!,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSupportCard(
                              icon: Icons.alternate_email,
                              color: const Color(0xFF9B26AF),
                              title: _isEnglish ? _supportItems[1]['titleEn']! : _supportItems[1]['titleVi']!,
                              subtitle: _isEnglish ? _supportItems[1]['subtitleEn']! : _supportItems[1]['subtitleVi']!,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 120),
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

  Widget _buildExpandableFeatureItem({
    required int index,
    required Map<String, String> item,
    required VoidCallback onTap,
  }) {
    final icons = [
      Icons.auto_awesome,
      Icons.menu_book,
      Icons.quiz,
      Icons.document_scanner,
      Icons.style,
      Icons.smart_toy,
      Icons.groups,
      Icons.analytics,
      Icons.workspace_premium,
    ];
    final iconBg = [
      const Color(0xFFEFF6FF),
      const Color(0xFFDCFCE7),
      const Color(0xFFFEF3C7),
      const Color(0xFFFEE2E2),
      const Color(0xFFF3E8FF),
      const Color(0xFFE0F2FE),
      const Color(0xFFFFEDD5),
      const Color(0xFFE2E8F0),
      const Color(0xFFFCE7F3),
    ];
    final iconColors = [
      AppColors.primaryColor,
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFFDC2626),
      const Color(0xFF7C3AED),
      const Color(0xFF0284C7),
      const Color(0xFFEA580C),
      const Color(0xFF475569),
      const Color(0xFFDB2777),
    ];

    final safeIndex = index % icons.length;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFFF3F4F6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: iconBg[safeIndex],
                    ),
                    child: Icon(
                      icons[safeIndex],
                      color: iconColors[safeIndex],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEnglish ? item['titleEn']! : item['titleVi']!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isEnglish ? item['subtitleEn']! : item['subtitleVi']!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeatureDetailPopup(
    BuildContext context,
    Map<String, String> item,
    int index,
  ) {
    final icons = [
      Icons.auto_awesome,
      Icons.menu_book,
      Icons.quiz,
      Icons.document_scanner,
      Icons.style,
      Icons.smart_toy,
      Icons.groups,
      Icons.analytics,
      Icons.workspace_premium,
    ];
    final iconBg = [
      const Color(0xFFEFF6FF),
      const Color(0xFFDCFCE7),
      const Color(0xFFFEF3C7),
      const Color(0xFFFEE2E2),
      const Color(0xFFF3E8FF),
      const Color(0xFFE0F2FE),
      const Color(0xFFFFEDD5),
      const Color(0xFFE2E8F0),
      const Color(0xFFFCE7F3),
    ];
    final iconColors = [
      AppColors.primaryColor,
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFFDC2626),
      const Color(0xFF7C3AED),
      const Color(0xFF0284C7),
      const Color(0xFFEA580C),
      const Color(0xFF475569),
      const Color(0xFFDB2777),
    ];
    final safeIndex = index % icons.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: iconBg[safeIndex],
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Icon(
                        icons[safeIndex],
                        color: iconColors[safeIndex],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEnglish ? item['titleEn']! : item['titleVi']!,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isEnglish ? item['subtitleEn']! : item['subtitleVi']!,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: iconBg[safeIndex].withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _isEnglish ? item['contentEn']! : item['contentVi']!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF374151),
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupportCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
