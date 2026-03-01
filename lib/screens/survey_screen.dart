import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../services/auth_service.dart';
import 'package:permission_handler/permission_handler.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({Key? key}) : super(key: key);

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  int _currentQuestion = 0;
  bool _notificationPermissionAsked = false;
  
  // Store answers
  String _userName = '';
  String? _selectedLevel;
  String? _selectedReason;
  Set<String> _selectedSkills = {};
  String? _selectedStartingPoint;
  String? _selectedDuration;

  bool get _isEnglish {
    try {
      return Provider.of<LanguageService>(context, listen: false).isEnglish;
    } catch (e) {
      return true; // Default to English if error
    }
  }

  // Question data
  final List<String> _questionTitlesEn = [
    'What\'s your name?',
    'What is your English level?',
    'Why do you want to learn English?',
    'What English skills do you want to develop?',
    'How should you start learning?',
    'How much time can you dedicate to learning?',
  ];

  final List<String> _questionTitlesVi = [
    'Tên bạn là gì?',
    'Trình độ tiếng Anh của bạn hiện tại?',
    'Tại sao bạn muốn học tiếng Anh?',
    'Kỹ năng tiếng Anh nào bạn muốn rèn luyện?',
    'Bạn nên bắt đầu học như thế nào?',
    'Thời gian bạn có thể bỏ ra để học?',
  ];

  List<Map<String, String>> get _reasonOptions => [
    {'id': 'travel', 'en': 'Travel', 'vi': 'Du lịch'},
    {'id': 'work', 'en': 'Work', 'vi': 'Công việc'},
    {'id': 'thinking', 'en': 'Critical Thinking', 'vi': 'Tư duy'},
    {'id': 'other', 'en': 'Other', 'vi': 'Khác'},
  ];

  List<Map<String, String>> get _levelOptions => [
    {'id': 'beginner', 'en': 'Beginner (Just started)', 'vi': 'Mới học'},
    {'id': 'elementary', 'en': 'Elementary (Common words)', 'vi': 'Biết từ thông dụng'},
    {'id': 'intermediate', 'en': 'Intermediate (Basic conversation)', 'vi': 'Giao tiếp cơ bản'},
    {'id': 'upper_intermediate', 'en': 'Upper Intermediate (Many topics)', 'vi': 'Nói về nhiều chủ đề'},
    {'id': 'advanced', 'en': 'Advanced (In-depth topics)', 'vi': 'Đi sâu hầu hết chủ đề'},
  ];

  List<Map<String, String>> get _skillsOptions => [
    {'id': 'speaking', 'en': 'Speaking', 'vi': 'Nói'},
    {'id': 'listening', 'en': 'Listening', 'vi': 'Nghe'},
    {'id': 'reading', 'en': 'Reading', 'vi': 'Đọc'},
    {'id': 'writing', 'en': 'Writing', 'vi': 'Viết'},
  ];

  List<Map<String, String>> get _backgroundOptions => [
    {'id': 'basic_lessons', 'en': 'Start from basic lessons', 'vi': 'Bắt đầu từ học cơ bản (theo từng bài học)'},
    {'id': 'level_test', 'en': 'Take level test', 'vi': 'Học theo trình độ hiện tại (có bài test phân cấp)'},
  ];

  List<Map<String, String>> get _durationOptions => [
    {'id': '5', 'en': '5 minutes', 'vi': '5 phút'},
    {'id': '10', 'en': '10 minutes', 'vi': '10 phút'},
    {'id': '20', 'en': '20 minutes', 'vi': '20 phút'},
    {'id': '30', 'en': '30 minutes', 'vi': '30 phút'},
  ];

  bool get _canContinue {
    switch (_currentQuestion) {
      case 0:
        return _userName.isNotEmpty;
      case 1:
        return _selectedLevel != null;
      case 2:
        return _selectedReason != null;
      case 3:
        return _selectedSkills.isNotEmpty;
      case 4:
        return _selectedStartingPoint != null;
      case 5:
        return _selectedDuration != null;
      default:
        return false;
    }
  }

  void _handleContinue() async {
    print('DEBUG: _currentQuestion = $_currentQuestion, _notificationPermissionAsked = $_notificationPermissionAsked');
    
    if (_currentQuestion < 5) {
      setState(() => _currentQuestion++);
    } else if (!_notificationPermissionAsked) {
      // Ask for notification permission before submitting
      print('DEBUG: Showing notification permission dialog');
      _showNotificationPermissionDialog();
    } else {
      // Save survey responses to database
      print('DEBUG: Submitting survey');
      _submitSurvey();
    }
  }

  void _showNotificationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            _isEnglish ? 'Enable Notifications?' : 'Bật thông báo?',
            style: AppTextStyles.heading2,
          ),
          content: Text(
            _isEnglish
                ? 'Get notified about learning reminders and achievements to stay motivated!'
                : 'Nhận thông báo về lời nhắc học tập và thành tích để duy trì động lực!',
            style: AppTextStyles.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _notificationPermissionAsked = true);
                Navigator.of(context).pop();
                _submitSurvey();
              },
              child: Text(
                _isEnglish ? 'Not Now' : 'Không',
                style: const TextStyle(
                  color: AppColors.subtextLight,
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _requestNotificationPermission();
                _submitSurvey();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
              child: Text(
                _isEnglish ? 'Allow' : 'Cho phép',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      print('Notification permission: ${status.name}');
      setState(() => _notificationPermissionAsked = true);
    } catch (e) {
      print('Error requesting notification permission: $e');
      setState(() => _notificationPermissionAsked = true);
    }
  }

  void _submitSurvey() async {
    final authService = context.read<AuthService>();
    // Get language before async call to avoid Provider context issue
    final isEnglish = _isEnglish;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    print('DEBUG: Starting survey submission');
    print('DEBUG: userName = $_userName');
    print('DEBUG: selectedReason = $_selectedReason');
    print('DEBUG: selectedSkills = $_selectedSkills');
    print('DEBUG: selectedStartingPoint = $_selectedStartingPoint');
    print('DEBUG: selectedDuration = $_selectedDuration');
    print('DEBUG: selectedLevel = $_selectedLevel');
    
    try {
      await authService.saveSurveyResponse(
        userName: _userName,
        learningReason: _selectedReason ?? 'Not specified',
        selectedSkills: _selectedSkills.toList(),
        userBackground: _selectedStartingPoint ?? 'Not specified',
        dailyDuration: _selectedDuration ?? '0',
        englishLevel: _selectedLevel,
      );

      print('DEBUG: Survey saved successfully');
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(isEnglish ? 'Survey submitted!' : 'Khảo sát đã gửi!'),
        ),
      );
      
      if (mounted) {
        print('DEBUG: Navigating to home');
        navigator.pushReplacementNamed(AppRoutes.home);
      }
    } catch (e) {
      print('DEBUG: Error saving survey: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(isEnglish ? 'Error saving survey. Please try again.' : 'Lỗi khi lưu khảo sát. Vui lòng thử lại.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Gradient Header with Mascot
          Container(
            height: MediaQuery.of(context).size.height * 0.32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF5B8BF7),
                  Color(0xFF82C3FF),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Progress indicator
                Positioned(
                  top: 48,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_currentQuestion + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '/6',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Back button - only show if not on first question
                if (_currentQuestion > 0)
                  Positioned(
                    top: 48,
                    left: 16,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _currentQuestion--);
                      },
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

                // Mascot and speech bubble
                Positioned(
                  bottom: 70,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Speech bubble with arrow
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 16, bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Arrow pointer
                                Positioned(
                                  top: 12,
                                  right: -8,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    transform: Matrix4.identity()..rotateZ(0.785), // 45 degrees
                                  ),
                                ),
                                // Text content
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      _isEnglish
                                          ? _getGreetingMessage()
                                          : _getGreetingMessageVi(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Mascot image
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.asset(
                            'assets/image/survey.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Cloud divider at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: CustomPaint(
                    painter: CloudDividerPainter(),
                    size: Size(MediaQuery.of(context).size.width, 60),
                  ),
                ),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: Container(
              color: const Color.fromARGB(255, 234, 242, 255),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    children: [
                      // Question title
                      Text(
                        _isEnglish
                            ? _questionTitlesEn[_currentQuestion]
                            : _questionTitlesVi[_currentQuestion],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),
                      if (_currentQuestion == 0) ...[
                        const SizedBox(height: 12),
                        Text(
                          '...',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),

                      // Question options
                      if (_currentQuestion == 0)
                        _buildNameInputField()
                      else if (_currentQuestion == 1)
                        _buildLevelSlider()
                      else if (_currentQuestion == 2)
                        _buildGridOptionsList(_reasonOptions, _selectedReason, (value) {
                          setState(() => _selectedReason = value);
                        })
                      else if (_currentQuestion == 3)
                        _buildMultiSelectList(_skillsOptions, _selectedSkills, (id, selected) {
                          setState(() {
                            if (selected) {
                              _selectedSkills.add(id);
                            } else {
                              _selectedSkills.remove(id);
                            }
                          });
                        })
                      else if (_currentQuestion == 4)
                        _buildOptionsList(_backgroundOptions, _selectedStartingPoint, (value) {
                          setState(() => _selectedStartingPoint = value);
                        })
                      else if (_currentQuestion == 5)
                        _buildOptionsList(_durationOptions, _selectedDuration, (value) {
                          setState(() => _selectedDuration = value);
                        }),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Continue button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canContinue ? _handleContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  disabledBackgroundColor: AppColors.greyLight,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 3,
                ),
                child: Text(
                  _isEnglish ? 'Continue' : 'Tiếp tục',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreetingMessage() {
    switch (_currentQuestion) {
      case 0:
        return 'Hi there! I\'m Pupu\n What\'s your name?';
      case 1:
        return 'What\'s your level?';
      case 2:
        return 'Love your goal!';
      case 3:
        return 'Pick your skills!';
      case 4:
        return 'Let\'s get started!';
      case 5:
        return 'Almost there!';
      default:
        return 'Let\'s begin!';
    }
  }

  String _getGreetingMessageVi() {
    switch (_currentQuestion) {
      case 0:
        return 'Xin chào! Tôi là Mr. Lingo\nAnd you?';
      case 1:
        return 'Trình độ của bạn?';
      case 2:
        return 'Mục tiêu tuyệt vời!';
      case 3:
        return 'Chọn kỹ năng!';
      case 4:
        return 'Bắt đầu thôi!';
      case 5:
        return 'Sắp xong!';
      default:
        return 'Bắt đầu!';
    }
  }

  Widget _buildNameInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _userName = value),
              decoration: InputDecoration(
                hintText: _isEnglish ? 'Enter your name' : 'Nhập tên của bạn',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          if (_userName.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => _userName = ''),
              child: const Icon(
                Icons.cancel,
                color: Colors.grey,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptionsList(
    List<Map<String, String>> options,
    String? selected,
    Function(String) onSelect,
  ) {
    return Column(
      children: options.map((option) {
        final isSelected = selected == option['id'];
        return GestureDetector(
          onTap: () => onSelect(option['id']!),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? AppColors.primaryColor : AppColors.greyLight,
                width: isSelected ? 2 : 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white, // Always white, no color change
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _isEnglish ? option['en']! : option['vi']!,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primaryColor,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultiSelectList(
    List<Map<String, String>> options,
    Set<String> selected,
    Function(String, bool) onToggle,
  ) {
    return Column(
      children: options.map((option) {
        final isSelected = selected.contains(option['id']);
        return GestureDetector(
          onTap: () => onToggle(option['id']!, !isSelected),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? AppColors.primaryColor : AppColors.greyLight,
                width: isSelected ? 2 : 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white, // Always white, no color change
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _isEnglish ? option['en']! : option['vi']!,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primaryColor : AppColors.greyLight,
                      width: 2,
                    ),
                    color: isSelected ? AppColors.primaryColor : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGridOptionsList(
    List<Map<String, String>> options,
    String? selected,
    Function(String) onSelect,
  ) {
    // Map image paths for each option
    String getImageForOption(String id) {
      switch (id) {
        case 'travel':
          return 'assets/image/travelling.png';
        case 'work':
          return 'assets/image/working.png';
        case 'thinking':
          return 'assets/image/thinking.png';
        case 'other':
          return 'assets/image/orther.png';
        default:
          return 'assets/image/survey.png';
      }
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.95,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = selected == option['id'];
        
        return GestureDetector(
          onTap: () => onSelect(option['id']!),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? AppColors.primaryColor : AppColors.greyLight,
                width: isSelected ? 2 : 1.5,
              ),
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Stack(
              children: [
                // Card content - centered
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Image
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: Image.asset(
                          getImageForOption(option['id']!),
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Label - centered with better spacing
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          _isEnglish ? option['en']! : option['vi']!,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? Colors.black87 : Colors.grey[700],
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Selection indicator - top right
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelSlider() {
    // Map level IDs to numeric values
    final levelMap = {
      'beginner': 0,
      'elementary': 1,
      'intermediate': 2,
      'upper_intermediate': 3,
      'advanced': 4,
    };
    
    final selectedValue = _selectedLevel != null ? levelMap[_selectedLevel] ?? 0 : 0;
    
    return Column(
      children: [
        // Slider
        Slider(
          value: selectedValue.toDouble(),
          min: 0,
          max: 4,
          divisions: 4,
          activeColor: AppColors.primaryColor,
          inactiveColor: Colors.white,
          onChanged: (value) {
            final levels = ['beginner', 'elementary', 'intermediate', 'upper_intermediate', 'advanced'];
            setState(() => _selectedLevel = levels[value.toInt()]);
          },
        ),
        
        // Level labels below slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_isEnglish ? 'Beginner' : 'Mới học', style: const TextStyle(fontSize: 12, color: Colors.black)),
              Text(_isEnglish ? 'Elementary' : 'Thông dụng', style: const TextStyle(fontSize: 12, color: Colors.black)),
              Text(_isEnglish ? 'Intermediate' : 'Cơ bản', style: const TextStyle(fontSize: 12, color: Colors.black)),
              Text(_isEnglish ? 'Upper Int.' : 'Nâng cao', style: const TextStyle(fontSize: 12, color: Colors.black)),
              Text(_isEnglish ? 'Advanced' : 'Chuyên sâu', style: const TextStyle(fontSize: 12, color: Colors.black)),
            ],
          ),
        ),
        
        // Selected level display
        if (_selectedLevel != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 69, 188, 243).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color.fromARGB(255, 69, 200, 247), width: 1.5),
              ),
              child: Text(
                _isEnglish 
                  ? _levelOptions.firstWhere((l) => l['id'] == _selectedLevel)['en']!
                  : _levelOptions.firstWhere((l) => l['id'] == _selectedLevel)['vi']!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
/// Custom painter for cloud divider
class CloudDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = const Color(0xFFEAF2FF)
      ..style = PaintingStyle.fill;

    final path = Path();

    // Start from bottom left
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.5);

    // Create smooth wave pattern matching HTML SVG
    // Using cubic bezier curves for smoother waves
    double baseY = size.height * 0.5;
    double waveAmplitude = size.height * 0.25;
    double waveLength = size.width / 5; // 5 main waves

    // Build smooth continuous wave using cubic bezier
    for (int i = 0; i < 6; i++) {
      double startX = i * waveLength;
      double endX = (i + 1) * waveLength;
      double controlX1 = startX + waveLength * 0.25;
      double controlX2 = startX + waveLength * 0.75;
      
      // Alternate wave direction (up, down, up, down...)
      double controlY = i % 2 == 0 
        ? baseY - waveAmplitude 
        : baseY + waveAmplitude;
      
      path.cubicTo(
        controlX1,
        controlY,
        controlX2,
        controlY,
        endX,
        baseY,
      );
    }

    // Complete the shape
    path.lineTo(size.width, size.height);
    path.close();

    // Draw fill only
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(CloudDividerPainter oldDelegate) => false;
}