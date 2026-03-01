import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../utils/constants.dart';
import '../services/language_service.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  // Language labels
  static const Map<String, Map<String, String>> _labels = {
    'vi': {
      'home': 'Trang chủ',
      'progress': 'Tiến độ',
      'ai': 'Pupu AI',
      'archive': 'Lưu trữ',
      'profile': 'Cá nhân',
    },
    'en': {
      'home': 'Home',
      'progress': 'Progress',
      'ai': 'Pupu AI',
      'archive': 'Archive',
      'profile': 'Profile',
    },
  };

  String _getLabel(String key, BuildContext context) {
    final isEnglish = context.read<LanguageService>().isEnglish;
    final labels = _labels[isEnglish ? 'en' : 'vi']!;
    return labels[key] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    // Watch for language changes
    context.watch<LanguageService>();
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            border: Border(
              top: BorderSide(
                color: const Color(0xFFE2E8F0).withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Home
                  _buildNavItem(
                    icon: Icons.home_outlined,
                    label: _getLabel('home', context),
                    index: 0,
                    isActive: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  // Progress
                  _buildNavItem(
                    icon: Icons.star_border,
                    label: _getLabel('progress', context),
                    index: 1,
                    isActive: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  // Pupu AI
                  _buildNavItem(
                    icon: Icons.mic,
                    label: _getLabel('ai', context),
                    index: 2,
                    isActive: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                  // Archive
                  _buildNavItem(
                    icon: Icons.description_outlined,
                    label: _getLabel('archive', context),
                    index: 3,
                    isActive: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                  // Profile
                  _buildNavItem(
                    icon: Icons.person_outline,
                    label: _getLabel('profile', context),
                    index: 4,
                    isActive: currentIndex == 4,
                    onTap: () => onTap(4),
                  ),
                ],
              ),
              // iOS Home Indicator
              const SizedBox(height: 16),
              Container(
                width: 128,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: isActive
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            )
          : Icon(
              icon,
              color: const Color(0xFFA0AEC0),
              size: 28,
            ),
    );
  }
}
