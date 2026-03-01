import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/language_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {

  bool get _isEnglish => context.watch<LanguageService>().isEnglish;

  String _getLabel(String key) {
    final labels = _isEnglish
        ? {
            'notifications': 'Notifications',
            'all': 'All',
            'unread': 'Unread',
            'offers': 'Offers',
            'system': 'System',
            'today': 'Today',
            'yesterday': 'Yesterday',
          }
        : {
            'notifications': 'Thông báo',
            'all': 'Tất cả',
            'unread': 'Chưa đọc',
            'offers': 'Ưu đãi',
            'system': 'Hệ thống',
            'today': 'Hôm nay',
            'yesterday': 'Hôm qua',
          };
    return labels[key] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
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
                    _getLabel('notifications'),
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Filter tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterTab('all', _getLabel('all'), true),
                    const SizedBox(width: 12),
                    _buildFilterTab('unread', _getLabel('unread'), false),
                    const SizedBox(width: 12),
                    _buildFilterTab('offers', _getLabel('offers'), false),
                    const SizedBox(width: 12),
                    _buildFilterTab('system', _getLabel('system'), false),
                  ],
                ),
              ),
            ),

            // Notifications list
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Today section
                      Text(
                        _getLabel('today'),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9CA3AF),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildNotificationItem(
                        icon: Icons.book,
                        iconBgColor: const Color(0xFFDEECFF),
                        iconColor: const Color(0xFF3B82F6),
                        title: _isEnglish
                            ? 'New Course Available!'
                            : 'Khóa học mới!',
                        description: _isEnglish
                            ? '"Digital Design Thinking" is now live. Enroll early to get a discount.'
                            : '"Thiết kế Kỹ thuật số" đã sẵn sàng. Đăng ký sớm để nhận giảm giá.',
                        time: _isEnglish ? '2 mins ago' : '2 phút trước',
                        isUnread: true,
                      ),
                      const SizedBox(height: 12),
                      _buildNotificationItem(
                        icon: Icons.schedule,
                        iconBgColor: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFFA855F7),
                        title: _isEnglish
                            ? 'Assignment Deadline'
                            : 'Hạn chót bài tập',
                        description: _isEnglish
                            ? 'Your \'Web Development Basics\' project is due in 3 hours.'
                            : 'Dự án \'Lập trình Web Cơ bản\' của bạn sẽ hết hạn trong 3 giờ.',
                        time: _isEnglish ? '3 hours ago' : '3 giờ trước',
                        isUnread: true,
                      ),
                      const SizedBox(height: 32),
                      // Yesterday section
                      Text(
                        _getLabel('yesterday'),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9CA3AF),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildNotificationItem(
                        icon: Icons.emoji_events,
                        iconBgColor: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFF59E0B),
                        title: _isEnglish
                            ? 'Congratulations, Alonzo!'
                            : 'Xin chúc mừng!',
                        description: _isEnglish
                            ? 'You\'ve completed 50% of your weekly learning goal.'
                            : 'Bạn đã hoàn thành 50% mục tiêu học tập hàng tuần.',
                        time: _isEnglish ? '1 day ago' : '1 ngày trước',
                        isUnread: false,
                      ),
                      const SizedBox(height: 12),
                      _buildNotificationItem(
                        icon: Icons.local_offer,
                        iconBgColor: const Color(0xFFDCFCE7),
                        iconColor: const Color(0xFF10B981),
                        title: _isEnglish ? 'Pro Plan Offer' : 'Ưu đãi gói Pro',
                        description: _isEnglish
                            ? 'Get 30% off on all advanced courses for the next 24 hours.'
                            : 'Giảm 30% cho tất cả khóa học nâng cao trong 24 giờ tiếp theo.',
                        time: _isEnglish ? '1 day ago' : '1 ngày trước',
                        isUnread: false,
                      ),
                      const SizedBox(height: 12),
                      _buildNotificationItem(
                        icon: Icons.group,
                        iconBgColor: const Color(0xFFFCE7F3),
                        iconColor: const Color(0xFFEC4899),
                        title: _isEnglish
                            ? 'Community Meetup'
                            : 'Gặp gỡ cộng đồng',
                        description: _isEnglish
                            ? 'Join the live Q&A session with industry experts.'
                            : 'Tham gia phiên hỏi đáp trực tiếp với các chuyên gia.',
                        time: _isEnglish ? '1 day ago' : '1 ngày trước',
                        isUnread: false,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String id, String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        // Filter functionality to be implemented
        // setState(() => _selectedFilter = id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? AppColors.primaryColor.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
            if (id == 'unread' && isActive) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '3',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String description,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconBgColor,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isUnread)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
