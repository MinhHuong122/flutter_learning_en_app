import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/language_service.dart';
import '../services/lesson_service.dart';
import '../services/lesson_favorites_service.dart';
import '../services/custom_lesson_favorites_service.dart';
import 'create_lesson_screen.dart';
import 'flashcard_swipe_screen.dart';
import 'flashcard_editor_screen.dart';
import 'dart:developer';


class MyLessonsScreen extends StatefulWidget {
  final String? searchQuery;
  
  const MyLessonsScreen({Key? key, this.searchQuery}) : super(key: key);

  @override
  State<MyLessonsScreen> createState() => _MyLessonsScreenState();
}

class _MyLessonsScreenState extends State<MyLessonsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _customLessons = [];
  final LessonService _lessonService = LessonService();

  final CustomLessonFavoritesService _customLessonFavoritesService = CustomLessonFavoritesService();
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'recent';
  Set<String> _favoriteLessonIds = {};

  bool get _isEnglish => context.read<LanguageService>().isEnglish;

  @override
  void initState() {
    super.initState();
    // Initialize search controller with passed search query from HomeScreen
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      _searchController.text = widget.searchQuery!;
      print('🔍 MyLessonsScreen: Initialized with search query: "${widget.searchQuery}"');
    }
    _loadCustomLessons();
    _loadFavoriteLessons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomLessons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _lessonService.supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception(_isEnglish ? 'User not logged in' : 'Người dùng chưa đăng nhập');
      }

      // Load custom lessons from Supabase
      final lessons = await _lessonService.loadCustomLessons(userId);

      for (final lesson in lessons) {
        final lessonId = lesson['id']?.toString();
        if (lessonId == null || lessonId.isEmpty) continue;

        lesson['progressPercentage'] = await _lessonService.getCustomLessonProgress(userId, lessonId);
      }
      
      setState(() {
        _customLessons = lessons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEnglish
                  ? 'Error loading lessons: $e'
                  : 'Lỗi tải bài học: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToCreateLesson() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateLessonScreen(),
      ),
    );

    // Refresh list if a lesson was created
    if (result == true) {
      _loadCustomLessons();
    }
  }
  Future<void> _loadFavoriteLessons() async {
    try {
      final favoriteLessons = await _customLessonFavoritesService.getUserFavoriteCustomLessons();
      if (mounted) {
        setState(() {
          _favoriteLessonIds = favoriteLessons.map((l) => l['id'] as String).toSet();
        });
      }
    } catch (e) {
      print('❌ Error loading favorite lessons: $e');
    }
  }

  void _deleteLesson(String lessonId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _isEnglish ? 'Delete Lesson' : 'Xóa bài học',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          _isEnglish
              ? 'Are you sure you want to delete this lesson? This action cannot be undone.'
              : 'Bạn có chắc chắn muốn xóa bài học này? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_isEnglish ? 'Cancel' : 'Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Delete lesson from Supabase
              final success = await _lessonService.deleteCustomLesson(lessonId);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isEnglish ? 'Lesson deleted successfully' : 'Xóa bài học thành công',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              _loadCustomLessons();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isEnglish ? 'Failed to delete lesson' : 'Không thể xóa bài học',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              _isEnglish ? 'Delete' : 'Xóa',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareToommunity(Map<String, dynamic> lesson) async {
    try {
      final userId = _lessonService.supabase.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEnglish ? 'Please login first' : 'Vui lòng đăng nhập trước',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get lesson flashcards
      final flashcards = await _lessonService.getFlashcardsForLesson(lesson['id']);

      if (flashcards.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEnglish ? 'No flashcards to share' : 'Không có flashcard để chia sẻ',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Share lesson to community
      final success = await _lessonService.shareCustomLessonToCommunity(
        lessonId: lesson['id'],
        userId: userId,
        title: lesson['name'] ?? 'Untitled',
        description: lesson['description'] ?? '',
        flashcards: flashcards,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEnglish
                    ? '✅ Lesson shared to community! (${flashcards.length} cards)'
                    : '✅ Bài học đã chia sẻ đến cộng đồng! (${flashcards.length} thẻ)',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEnglish ? '❌ Failed to share lesson' : '❌ Không thể chia sẻ bài học',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEnglish ? 'Error: $e' : 'Lỗi: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    _isEnglish ? 'My Lessons' : 'Bài học của tôi',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchController,
                  textAlign: TextAlign.center,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: _isEnglish ? 'Search your lessons...' : 'Tìm kiếm bài học...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF999999),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF0062A3),
                        ),
                      ),
                    )
                  : _customLessons.isEmpty
                      ? _buildEmptyState()
                      : _buildLessonsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }



  Widget _buildFAB() {
    return FloatingActionButton(
        onPressed: _navigateToCreateLesson,
        backgroundColor: AppColors.primaryColor,
      elevation: 8,
      shape: const CircleBorder(),
      child: const Icon(
        Icons.add,
            color: Colors.white,
        size: 32,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor.withOpacity(0.1),
              ),
              child: Icon(
                Icons.menu_book_outlined,
                size: 48,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isEnglish ? 'No Lessons Yet' : 'Chưa có bài học',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isEnglish
                  ? 'Create your first custom lesson\nby tapping the button below'
                  : 'Tạo bài học tùy chỉnh đầu tiên của bạn\nbằng cách nhấn nút bên dưới',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToCreateLesson,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                _isEnglish ? 'Create Lesson' : 'Tạo bài học',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsList() {
    // Filter lessons based on search query
    List<Map<String, dynamic>> filteredLessons = _customLessons;
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filteredLessons = _customLessons.where((lesson) {
        final name = (lesson['name'] as String? ?? '').toLowerCase();
        return name.contains(query);
      }).toList();
    }

    if (filteredLessons.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            _isEnglish ? 'No lessons found' : 'Không tìm thấy bài học',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF999999),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Collection Header with Sort
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isEnglish ? 'Your Collection' : 'Bộ sưu tập của bạn',
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1C1C1C),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() => _sortBy = value);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'recent',
                    child: Text(
                      _isEnglish ? 'Recent' : 'Gần đây',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'name',
                    child: Text(
                      _isEnglish ? 'Name' : 'Tên',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'cards',
                    child: Text(
                      _isEnglish ? 'Cards' : 'Thẻ',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    _isEnglish ? 'Sort: ${_sortBy[0].toUpperCase()}${_sortBy.substring(1)}' 
                               : 'Sắp xếp: ${_sortBy == 'recent' ? 'Gần đây' : _sortBy == 'name' ? 'Tên' : 'Thẻ'}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Grid of lesson cards
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              itemCount: filteredLessons.length,
      itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildLessonCard(filteredLessons[index]),
                );
      },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLessonCard(Map<String, dynamic> lesson) {
    final lessonId = lesson['id'] as String? ?? '';
    final cardCount = lesson['flashcardCount'] ?? 0;
    final createdAt = lesson['createdAt'] ?? 'Recently';
    
    // Icon options
    const iconOptions = [
      Icons.coffee,
      Icons.business_center,
      Icons.flight,
      Icons.school,
      Icons.psychology,
    ];
    
    // Background colors for icons
    const bgColors = [
      Color(0xFFFFDDB9), // Secondary container
      Color(0xFFDFE8FF), // Surface container high
      Color(0xFFF595FF), // Tertiary fixed
      Color(0xFF91C5FF), // Primary fixed
      Color(0xFFCBE4FF), // Light blue
    ];
    
    // Foreground colors
    const fgColors = [
      Color(0xFF754800), // On secondary
      Color(0xFF003F6A), // On primary
      Color(0xFF610071), // On tertiary
      Color(0xFF003D6B), // On primary
      Color(0xFF003D6B), // Dark blue
    ];
    
    // Badge label (High Priority / Recently Added / Popular, etc.)
    final badgeLabels = ['HIGH PRIORITY', 'RECENTLY ADDED', 'POPULAR', 'ESSENTIAL', 'ADVANCED'];
    final badgeLabel = badgeLabels[lessonId.hashCode % badgeLabels.length];
    
    final idx = (lesson['name'] as String).hashCode % iconOptions.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FlashcardSwiperScreen(
                  lessonId: lesson['id'] as String,
                  lessonName: lesson['name'] as String? ?? 'Deck',
                ),
              ),
            ).then((_) {
              if (mounted) {
                _loadCustomLessons();
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Icon & Badge & Menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: bgColors[idx],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        iconOptions[idx],
                        color: fgColors[idx],
                        size: 28,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        badgeLabel,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            // Local state for modal to track favorite status
                            late bool isFavorite;
                            isFavorite = _favoriteLessonIds.contains(lesson['id']);
                            
                            return StatefulBuilder(
                              builder: (context, setModalState) => Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: Icon(
                                        isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: Colors.red,
                                      ),
                                      title: Text(
                                        _isEnglish
                                            ? (isFavorite
                                                ? 'Remove from Favorites'
                                                : 'Add to Favorites')
                                            : (isFavorite
                                                ? 'Xóa khỏi yêu thích'
                                                : 'Thêm vào yêu thích'),
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF1C1C1C),
                                        ),
                                      ),
                                      onTap: () async {
                                        print('💛 Toggle favorite for: ${lesson['id']}');
                                        print('📌 Current status: $isFavorite');
                                        
                                        final result = await _customLessonFavoritesService.toggleFavorite(lesson['id'] as String);
                                        
                                        if (result != null) {
                                          // Update parent state
                                          if (mounted) {
                                            setState(() {
                                              if (result == true) {
                                                _favoriteLessonIds.add(lesson['id'] as String);
                                              } else {
                                                _favoriteLessonIds.remove(lesson['id']);
                        }
                                            });
                                          }
                                          
                                          // Update local modal state
                                          setModalState(() {
                                            isFavorite = result == true;
                                            print('✅ New status: $isFavorite');
                                          });
                                          
                                          // Show snackbar
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  _isEnglish
                                                      ? (isFavorite
                                                          ? '💚 Added to favorites'
                                                          : '💔 Removed from favorites')
                                                      : (isFavorite
                                                          ? '💚 Thêm vào yêu thích'
                                                          : '💔 Xóa khỏi yêu thích'),
                                                ),
                                                backgroundColor: isFavorite ? Colors.green : Colors.orange,
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        } else {
                                          // Error case
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  _isEnglish
                                                      ? '❌ Error updating favorite'
                                                      : '❌ Lỗi cập nhật yêu thích',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                    const Divider(height: 1),
                                    ListTile(
                                      leading: const Icon(Icons.edit, color: AppColors.primaryColor),
                                      title: Text(
                                        _isEnglish ? 'Edit Lesson' : 'Chỉnh sửa bài học',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF1C1C1C),
                                        ),
                                      ),
                                      onTap: () async {
                                        print('📝 Edit button tapped');
                                        Navigator.pop(context);
                                        
                                        // Small delay to ensure dialog closes
                                        await Future.delayed(const Duration(milliseconds: 200));
                                        
                                        // Navigate to flashcard editor screen for editing
                                        if (mounted) {
                                          try {
                                            print('📝 Opening editor for lesson: ${lesson['id']}');
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => FlashcardEditorScreen(
                                                  lessonName: lesson['name'] as String? ?? 'Untitled',
                                                  description: lesson['description'] as String? ?? '',
                                                  extractedWords: [], // Will be loaded from database
                                                  imagePath: '',
                                                  lessonId: lesson['id'] as String,
                                                ),
                                              ),
                                            );
                                            
                                            if (result == true && mounted) {
                                              print('✅ Lesson updated, refreshing list');
                                              _loadCustomLessons();
                                            }
                                          } catch (e) {
                                            print('❌ Error opening editor: $e');
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    _isEnglish
                                                        ? 'Error opening editor: $e'
                                                        : 'Lỗi mở trình chỉnh sửa: $e',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                    ),
                                    const Divider(height: 1),
                                    ListTile(
                                      leading: const Icon(Icons.share, color: AppColors.primaryColor),
                                      title: Text(
                                        _isEnglish ? 'Share to Community' : 'Chia sẻ đến cộng đồng',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF1C1C1C),
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _shareToommunity(lesson);
                                      },
                                    ),
                                    const Divider(height: 1),
                                    ListTile(
                                      leading: const Icon(Icons.delete, color: Colors.red),
                                      title: Text(
                                        _isEnglish ? 'Delete Lesson' : 'Xóa bài học',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.red,
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _deleteLesson(lesson['id']);
                                      },
                              ),
                            ],
                          ),
                        ),
                            );
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.more_vert,
                          color: Color(0xFFBBBBBB),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  lesson['name'] ?? 'Untitled',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C1C1C),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Card Count
                Text(
                  '$cardCount ${_isEnglish ? 'Cards' : 'Thẻ'}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF888888),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // Description
                if ((lesson['description'] ?? '').isNotEmpty)
                  Text(
                    lesson['description'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF888888),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 10),

                // Progress Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEnglish ? 'Progress' : 'Tiến độ',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF777777),
                      ),
                    ),
                    Text(
                      '${(lesson['progressPercentage'] as num?)?.toDouble().toStringAsFixed(0) ?? '0'}%',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ((lesson['progressPercentage'] as num?)?.toDouble() ?? 0.0) / 100,
                    minHeight: 6,
                    backgroundColor: AppColors.primaryColor.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryColor,
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
}

// Temporary model for custom lessons
class CustomLesson {
  final String id;
  final String name;
  final String description;
  final int flashcardCount;
  final String createdAt;

  CustomLesson({
    required this.id,
    required this.name,
    required this.description,
    required this.flashcardCount,
    required this.createdAt,
  });
}
