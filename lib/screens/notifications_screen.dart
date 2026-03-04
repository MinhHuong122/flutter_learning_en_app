import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/language_service.dart';
import '../services/notification_center_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationCenterService _notificationService =
      NotificationCenterService();
  String _selectedFilter = 'all';
  List<AppNotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

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

  Future<void> _loadNotifications() async {
    await _notificationService.syncNotifications();
    final notifications = await _notificationService.getNotifications();

    if (!mounted) return;
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  List<AppNotificationItem> _getFilteredNotifications() {
    if (_selectedFilter == 'unread') {
      return _notifications.where((n) => !n.isRead).toList();
    }
    if (_selectedFilter == 'offers') {
      return _notifications
          .where((n) => n.type == 'new_lesson' || n.type == 'discount')
          .toList();
    }
    if (_selectedFilter == 'system') {
      return _notifications.where((n) => n.type == 'system').toList();
    }
    return _notifications;
  }

  String _dateSectionLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(compareDate).inDays;

    if (diff == 0) return _getLabel('today');
    if (diff == 1) return _getLabel('yesterday');
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return _isEnglish ? 'just now' : 'vừa xong';
    if (diff.inMinutes < 60) {
      return _isEnglish
          ? '${diff.inMinutes} mins ago'
          : '${diff.inMinutes} phút trước';
    }
    if (diff.inHours < 24) {
      return _isEnglish
          ? '${diff.inHours} hours ago'
          : '${diff.inHours} giờ trước';
    }
    return _isEnglish ? '${diff.inDays} days ago' : '${diff.inDays} ngày trước';
  }

  Map<String, dynamic> _metaByType(String type) {
    switch (type) {
      case 'new_lesson':
        return {
          'icon': Icons.book,
          'bg': const Color(0xFFDEECFF),
          'color': const Color(0xFF3B82F6),
        };
      case 'discount':
        return {
          'icon': Icons.local_offer,
          'bg': const Color(0xFFDCFCE7),
          'color': const Color(0xFF10B981),
        };
      default:
        return {
          'icon': Icons.notifications_active,
          'bg': const Color(0xFFF3E8FF),
          'color': const Color(0xFFA855F7),
        };
    }
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
                    _buildFilterTab('all', _getLabel('all')),
                    const SizedBox(width: 12),
                    _buildFilterTab('unread', _getLabel('unread')),
                    const SizedBox(width: 12),
                    _buildFilterTab('offers', _getLabel('offers')),
                    const SizedBox(width: 12),
                    _buildFilterTab('system', _getLabel('system')),
                  ],
                ),
              ),
            ),

            // Notifications list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildNotificationList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    final filtered = _getFilteredNotifications();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _isEnglish ? 'No notifications' : 'Không có thông báo',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF9CA3AF),
          ),
        ),
      );
    }

    final sections = <String, List<AppNotificationItem>>{};
    for (final item in filtered) {
      final key = _dateSectionLabel(item.createdAt);
      sections.putIfAbsent(key, () => []);
      sections[key]!.add(item);
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            for (final section in sections.entries) ...[
              Text(
                section.key,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9CA3AF),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              ...section.value.map((item) {
                final meta = _metaByType(item.type);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildNotificationItem(
                    icon: meta['icon'] as IconData,
                    iconBgColor: meta['bg'] as Color,
                    iconColor: meta['color'] as Color,
                    title: item.title,
                    description: item.description,
                    time: _timeAgo(item.createdAt),
                    isUnread: !item.isRead,
                    onTap: () async {
                      if (!item.isRead) {
                        await _notificationService.markAsRead(item.id);
                        _loadNotifications();
                      }
                    },
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String id, String label) {
    final isActive = _selectedFilter == id;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = id);
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
            if (id == 'unread' && unreadCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unreadCount',
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
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
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
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
