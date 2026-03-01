import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../widgets/custom_bottom_nav.dart';
import '../services/language_service.dart';
import 'home_screen.dart';
import 'process_screen.dart';
import 'chat_ai_screen.dart';
import 'archive_screen.dart';

class AppInfoScreen extends StatefulWidget {
  const AppInfoScreen({Key? key}) : super(key: key);

  @override
  State<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends State<AppInfoScreen> {
  int _currentIndex = 4;
  int? _expandedItemIndex;

  bool get _isEnglish => context.watch<LanguageService>().isEnglish;

  final List<Map<String, String>> _menuItems = [
    {
      'titleEn': 'Our Mission',
      'titleVi': 'Sứ mệnh của chúng tôi',
      'subtitleEn': 'Why we started',
      'subtitleVi': 'Tại sao chúng tôi bắt đầu',
      'contentEn': 'Our mission is to empower learners worldwide with accessible, innovative, and personalized English learning experiences. We believe that everyone deserves the opportunity to master the English language and unlock their potential for personal and professional growth.',
      'contentVi': 'Sứ mệnh của chúng tôi là trao quyền cho những người học trên toàn thế giới với các trải nghiệm học tiếng Anh có thể tiếp cận, sáng tạo và được cá nhân hóa. Chúng tôi tin rằng mọi người đều xứng đáng có cơ hội để nắm vững tiếng Anh và khai thác tiềm năng của họ cho sự phát triển cá nhân và nghề nghiệp.',
    },
    {
      'titleEn': 'Privacy Policy',
      'titleVi': 'Chính sách bảo mật',
      'subtitleEn': 'Your data safety',
      'subtitleVi': 'An toàn dữ liệu của bạn',
      'contentEn': 'We are committed to protecting your privacy. Your personal data is encrypted and stored securely on our servers. We never share your information with third parties without your explicit consent. You have full control over your account data and can request deletion at any time.',
      'contentVi': 'Chúng tôi cam kết bảo vệ quyền riêng tư của bạn. Dữ liệu cá nhân của bạn được mã hóa và lưu trữ an toàn trên máy chủ của chúng tôi. Chúng tôi không bao giờ chia sẻ thông tin của bạn với bên thứ ba mà không có sự đồng ý rõ ràng của bạn. Bạn có toàn quyền kiểm soát dữ liệu tài khoản của mình và có thể yêu cầu xóa bất cứ lúc nào.',
    },
    {
      'titleEn': 'Terms of Service',
      'titleVi': 'Điều khoản dịch vụ',
      'subtitleEn': 'Rules & guidelines',
      'subtitleVi': 'Quy tắc và hướng dẫn',
      'contentEn': 'By using PUPU, you agree to comply with all applicable laws and regulations. You are responsible for maintaining the confidentiality of your account credentials. We reserve the right to suspend or terminate accounts that violate our community guidelines. All content provided is for educational purposes only.',
      'contentVi': 'Bằng cách sử dụng PUPU, bạn đồng ý tuân thủ tất cả các luật và quy định hiện hành. Bạn chịu trách nhiệm duy trì tính bảo mật của thông tin đăng nhập tài khoản của mình. Chúng tôi có quyền tạm ngừng hoặc chấm dứt các tài khoản vi phạm hướng dẫn cộng đồng của chúng tôi. Tất cả nội dung được cung cấp chỉ dành cho mục đích giáo dục.',
    },
    {
      'titleEn': 'Contact Us',
      'titleVi': 'Liên hệ với chúng tôi',
      'subtitleEn': 'Get help 24/7',
      'subtitleVi': 'Nhận trợ giúp 24/7',
      'contentEn': 'Email: support@pupu.app\nPhone: +84 (0) 123-456-789\nAddress: Hung Vuong University, HCM City\nSupport Hours: Monday - Friday, 8:00 AM - 6:00 PM (GMT+7)\nFor urgent issues, contact us anytime via our in-app chat support.',
      'contentVi': 'Email: support@pupu.app\nĐiện thoại: +84 (0) 123-456-789\nĐịa chỉ: Đại học Hùng Vương, Thành phố HCM\nGiờ hỗ trợ: Thứ Hai - Thứ Sáu, 8:00 AM - 6:00 PM (GMT+7)\nĐối với các vấn đề khẩn cấp, hãy liên hệ với chúng tôi bất cứ lúc nào qua hỗ trợ trò chuyện trong ứng dụng.',
    },
  ];

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
            // Header with back button and title
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
                    _isEnglish ? 'App Information' : 'Thông tin ứng dụng',
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

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // App illustration and info section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        children: [
                          // Illustration image
                          Image.asset(
                            'assets/image/info.png',
                            width: 192,
                            height: 192,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 24),

                          // App name and version
                          Text(
                            'PUPU',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Version badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _isEnglish ? 'Version 2.1.0' : 'Phiên bản 2.1.0',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          Text(
                            _isEnglish
                                ? 'Smart English Learning Support Application\nEmpower your English learning journey with intelligent features and comprehensive tools.'
                                : 'Ứng dụng hỗ trợ học tiếng anh thông minh\nNâng cao hành trình học tiếng Anh của bạn với các tính năng thông minh và công cụ toàn diện.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF6B7280),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Designer and school info
                          Text(
                            'Designed by Đỗ Nguyễn Minh Hương',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hung Vuong University • 2026',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Menu items
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          for (int i = 0; i < _menuItems.length; i++) ...[
                            _buildExpandableMenuItem(
                              index: i,
                              item: _menuItems[i],
                              isExpanded: _expandedItemIndex == i,
                              onTap: () {
                                setState(() {
                                  _expandedItemIndex = _expandedItemIndex == i ? null : i;
                                });
                              },
                            ),
                            if (i < _menuItems.length - 1) const SizedBox(height: 12),
                          ],
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

  Widget _buildExpandableMenuItem({
    required int index,
    required Map<String, String> item,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    final icons = [Icons.rocket_launch, Icons.security, Icons.gavel, Icons.headset_mic];
    final bgColors = [
      const Color(0xFFEFF6FF),
      const Color(0xFFFEF3C7),
      const Color(0xFFF3E8FF),
      const Color(0xFFDCFCE7),
    ];
    final iconColors = [
      AppColors.primaryColor,
      const Color(0xFFEA580C),
      const Color(0xFFA855F7),
      const Color(0xFF10B981),
    ];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFF3F4F6),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: bgColors[index],
                    ),
                    child: Icon(
                      icons[index],
                      color: iconColors[index],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEnglish ? item['titleEn']! : item['titleVi']!,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isEnglish ? item['subtitleEn']! : item['subtitleVi']!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.chevron_right,
                      color: const Color(0xFFD1D5DB),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            if (isExpanded)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 1,
                    color: const Color(0xFFF3F4F6),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Text(
                      _isEnglish ? item['contentEn']! : item['contentVi']!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B7280),
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
