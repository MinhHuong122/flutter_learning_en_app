import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../widgets/custom_bottom_nav.dart';
import '../services/language_service.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'process_screen.dart';
import 'chat_ai_screen.dart';
import 'archive_screen.dart';
import 'app_info_screen.dart';
import 'edit_profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  int _currentIndex = 4;
  String _userName = 'User';
  String _userBio = '';
  int _courses = 0;
  int _certificates = 0;
  int _hours = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('profiles')
          .select('display_name, username, bio')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _userName = response['display_name'] ?? response['username'] ?? 'User';
          _userBio = response['bio'] ?? 'No bio yet';
          // Mock data - you can update these from database later
          _courses = 12;
          _certificates = 5;
          _hours = 128;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    _isEnglish ? 'My Profile' : 'Hồ sơ của tôi',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AppInfoScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Expanded scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile header section
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          // Avatar with edit button
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 112,
                                height: 112,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  color: const Color(0xFFEFF6FF),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 56,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const EditProfileScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primaryColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryColor.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Name
                          Text(
                            _userName,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Bio (only show if not empty)
                          if (_userBio.isNotEmpty && _userBio != 'No bio yet')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                                borderRadius: BorderRadius.circular(24),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                _userBio,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF6B7280),
                                  height: 1.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Stats grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            children: [
                              _buildStatCard(
                                title: _isEnglish ? 'Courses' : 'Khóa học',
                                value: _courses.toString(),
                                icon: Icons.library_books,
                                iconBgColor: const Color.fromARGB(255, 208, 224, 246),
                                iconColor: const Color.fromARGB(255, 3, 66, 161),
                                textColor: const Color.fromARGB(255, 3, 66, 161),
                              ),
                              _buildStatCard(
                                title: _isEnglish ? 'Certificates' : 'Chứng chỉ',
                                value: _certificates.toString(),
                                icon: Icons.workspace_premium,
                                iconBgColor: const Color.fromARGB(255, 255, 244, 230),
                                iconColor: const Color(0xFFF97316),
                                textColor: const Color(0xFFF97316),
                              ),
                              _buildStatCard(
                                title: _isEnglish ? 'Hours' : 'Giờ',
                                value: _hours.toString(),
                                icon: Icons.schedule,
                                iconBgColor: const Color(0xFFF3E8FF),
                                iconColor: const Color(0xFFA855F7),
                                textColor: const Color(0xFFA855F7),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),

                    // Menu items
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            Icons.person,
                            _isEnglish ? 'Account Information' : 'Thông tin tài khoản',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              );
                            },
                          ),
                          _buildMenuItem(
                            Icons.language,
                            _isEnglish ? 'Language' : 'Ngôn ngữ',
                            onTap: () => _showLanguageDialog(),
                          ),
                          _buildMenuItem(
                            Icons.notifications,
                            _isEnglish ? 'Notifications' : 'Thông báo',
                            onTap: () => _showNotificationsDialog(),
                          ),
                          _buildMenuItem(
                            Icons.lock,
                            _isEnglish ? 'Change Password' : 'Đổi mật khẩu',
                            onTap: () => _showChangePasswordDialog(),
                          ),
                          _buildMenuItem(
                            Icons.help,
                            _isEnglish ? 'Help Center' : 'Hỗ trợ',
                            onTap: () {},
                          ),
                          const SizedBox(height: 16),
                          // Logout button
                          GestureDetector(
                            onTap: () => _showLogoutDialog(),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                    child: const Icon(
                                      Icons.logout,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      _isEnglish ? 'Logout' : 'Đăng xuất',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 16),
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header Icon
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFEAEA),
                    ),
                    child: const Icon(
                      Icons.logout,
                      size: 48,
                      color: Colors.red,
                    ),
                  ),
                ),

                // Title
                Text(
                  _isEnglish ? 'Logout' : 'Đăng xuất',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  child: Text(
                    _isEnglish
                        ? 'Are you sure you want to logout? You\'ll be taken back to the login screen.'
                        : 'Bạn có chắc chắn muốn đăng xuất? Bạn sẽ được chuyển về màn hình đăng nhập.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Button Group
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(24),
                              child: Center(
                                child: Text(
                                  _isEnglish ? 'Cancel' : 'Hủy',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                await context.read<AuthService>().logout();
                                if (mounted) {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/login',
                                    (route) => false,
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Center(
                                child: Text(
                                  _isEnglish ? 'Logout' : 'Đăng xuất',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: iconBgColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withOpacity(0.15),
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: textColor.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Ensure context is valid before calling onTap
            if (mounted) {
              onTap();
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF3F4F6),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF374151),
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    print('Language dialog called'); // Debug
    final languageService = context.read<LanguageService>();
    final isEnglishNow = languageService.isEnglish;
    String selectedLanguage = isEnglishNow ? 'en' : 'vi';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEnglishNow ? 'Select Language' : 'Chọn ngôn ngữ',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEnglishNow
                          ? 'Choose your preferred language for the interface.'
                          : 'Chọn ngôn ngữ ưa thích của bạn cho giao diện.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),

              // Language options
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  children: [
                    _buildLanguageOption(
                      flag: '🇺🇸',
                      name: 'English',
                      label: isEnglishNow ? 'Default' : '',
                      isSelected: selectedLanguage == 'en',
                      onTap: () => setState(() => selectedLanguage = 'en'),
                    ),
                    const SizedBox(height: 12),
                    _buildLanguageOption(
                      flag: '🇻🇳',
                      name: 'Tiếng Việt',
                      label: !isEnglishNow ? 'Default' : '',
                      isSelected: selectedLanguage == 'vi',
                      onTap: () => setState(() => selectedLanguage = 'vi'),
                    ),
                  ],
                ),
              ),

              // Apply button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: GestureDetector(
                  onTap: () {
                    if (selectedLanguage == 'en' && isEnglishNow == false) {
                      languageService.setEnglish();
                    } else if (selectedLanguage == 'vi' && isEnglishNow == true) {
                      languageService.setVietnamese();
                    }
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        isEnglishNow ? 'Apply' : 'Áp dụng',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String flag,
    required String name,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            // Flag emoji
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF3F4F6),
              ),
              child: Center(
                child: Text(
                  flag,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Language name and label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  if (label.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Radio button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryColor : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                color: isSelected ? AppColors.primaryColor : Colors.white,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsDialog() {
    bool pushNotifications = true;
    bool emailNotifications = false;
    bool courseUpdates = true;
    bool newMessages = true;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  margin: const EdgeInsets.only(bottom: 24),
                ),

                // Title
                Text(
                  _isEnglish ? 'Notification Settings' : 'Cài đặt thông báo',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 28),

                // Push Notifications
                _buildNotificationItem(
                  title: _isEnglish ? 'Push Notifications' : 'Thông báo đẩy',
                  description: _isEnglish ? 'Device alerts' : 'Cảnh báo thiết bị',
                  icon: Icons.notifications,
                  iconBgColor: const Color(0xFFEFF6FF),
                  iconColor: AppColors.primaryColor,
                  value: pushNotifications,
                  onChanged: (value) => setState(() => pushNotifications = value),
                ),
                const SizedBox(height: 16),

                // Email Notifications
                _buildNotificationItem(
                  title: _isEnglish ? 'Email Notifications' : 'Thông báo qua email',
                  description: _isEnglish ? 'Newsletters & Promos' : 'Bản tin & Khuyến mại',
                  icon: Icons.mail_outline,
                  iconBgColor: const Color(0xFFFFF5E6),
                  iconColor: const Color(0xFFF97316),
                  value: emailNotifications,
                  onChanged: (value) => setState(() => emailNotifications = value),
                ),
                const SizedBox(height: 16),

                // Course Updates
                _buildNotificationItem(
                  title: _isEnglish ? 'Course Updates' : 'Cập nhật khóa học',
                  description: _isEnglish ? 'Learning progress' : 'Tiến độ học tập',
                  icon: Icons.menu_book_outlined,
                  iconBgColor: const Color(0xFFF3E8FF),
                  iconColor: const Color(0xFFA855F7),
                  value: courseUpdates,
                  onChanged: (value) => setState(() => courseUpdates = value),
                ),
                const SizedBox(height: 16),

                // New Messages
                _buildNotificationItem(
                  title: _isEnglish ? 'New Messages' : 'Tin nhắn mới',
                  description: _isEnglish ? 'Chat from community' : 'Trò chuyện từ cộng đồng',
                  icon: Icons.chat_bubble_outline,
                  iconBgColor: const Color(0xFFF0FDF4),
                  iconColor: const Color(0xFF22C55E),
                  value: newMessages,
                  onChanged: (value) => setState(() => newMessages = value),
                ),

                const SizedBox(height: 32),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(24),
                            child: Center(
                              child: Text(
                                _isEnglish ? 'Cancel' : 'Hủy',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _isEnglish
                                        ? 'Notifications saved'
                                        : 'Đã lưu thông báo',
                                  ),
                                  backgroundColor: AppColors.primaryColor,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Center(
                              child: Text(
                                _isEnglish ? 'Save' : 'Lưu',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String description,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(16),
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
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Toggle Switch
          SizedBox(
            width: 56,
            height: 32,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primaryColor,
              activeTrackColor: AppColors.primaryColor.withOpacity(0.3),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFE5E7EB),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool showNewPassword = false;
    bool showConfirmPassword = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Icon
                  Padding(
                    padding: const EdgeInsets.only(top: 32, bottom: 16),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF3E8FF),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        size: 48,
                        color: Color(0xFFA855F7),
                      ),
                    ),
                  ),

                  // Title
                  Text(
                    _isEnglish ? 'Change Password' : 'Đổi mật khẩu',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111418),
                    ),
                  ),

                  // Subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                    child: Text(
                      _isEnglish
                          ? 'Create a new strong password for your account security.'
                          : 'Tạo mật khẩu mạnh mới để bảo mật tài khoản của bạn.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF60758A),
                      ),
                    ),
                  ),

                  // Form Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Column(
                      children: [
                        // New Password Field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEnglish ? 'New Password' : 'Mật khẩu mới',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF111418),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: newPasswordController,
                                      obscureText: !showNewPassword,
                                      decoration: InputDecoration(
                                        hintText: _isEnglish
                                            ? 'At least 8 characters'
                                            : 'Tối thiểu 8 ký tự',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: const Color(0xFF111418),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => showNewPassword = !showNewPassword),
                                      child: Icon(
                                        showNewPassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: const Color(0xFF94A3B8),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Confirm Password Field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEnglish ? 'Confirm Password' : 'Xác nhận mật khẩu',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF111418),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: confirmPasswordController,
                                      obscureText: !showConfirmPassword,
                                      decoration: InputDecoration(
                                        hintText: _isEnglish
                                            ? 'Re-enter password'
                                            : 'Nhập lại mật khẩu',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: const Color(0xFF111418),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: GestureDetector(
                                      onTap: () => setState(
                                          () => showConfirmPassword = !showConfirmPassword),
                                      child: Icon(
                                        showConfirmPassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: const Color(0xFF94A3B8),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Button Group
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              borderRadius: BorderRadius.circular(24),
                              color: Colors.white,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(24),
                                child: Center(
                                  child: Text(
                                    _isEnglish ? 'Cancel' : 'Hủy',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF60758A),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: AppColors.primaryColor,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (newPasswordController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _isEnglish
                                              ? 'Please enter a password'
                                              : 'Vui lòng nhập mật khẩu',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  if (newPasswordController.text.length < 8) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _isEnglish
                                              ? 'Password must be at least 8 characters'
                                              : 'Mật khẩu phải có ít nhất 8 ký tự',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  if (newPasswordController.text !=
                                      confirmPasswordController.text) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _isEnglish
                                              ? 'Passwords do not match'
                                              : 'Mật khẩu không khớp',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _isEnglish
                                            ? 'Password changed successfully'
                                            : 'Đã thay đổi mật khẩu thành công',
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: Center(
                                  child: Text(
                                    _isEnglish ? 'Save Changes' : 'Lưu thay đổi',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
