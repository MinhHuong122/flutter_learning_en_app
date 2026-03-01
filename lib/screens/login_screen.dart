import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    // Lắng nghe auth state changes - nếu user đã login sẽ tự điều hướng
    _setupAuthListener();
  }

  void _setupAuthListener() {
    final authService = context.read<AuthService>();
    // Nếu user đã authenticated từ trước, điều hướng sang HomeScreen
    if (authService.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        }
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final isEnglish = Provider.of<LanguageService>(context, listen: false).isEnglish;
    final authService = context.read<AuthService>();
    setState(() => _isLoading = true);

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar(isEnglish ? 'Please fill in all fields' : 'Vui lòng điền tất cả các trường');
      setState(() => _isLoading = false);
      return;
    }

    final success = await authService.loginWithUsernamePassword(username, password);

    setState(() => _isLoading = false);

    if (success && mounted) {
      _showSnackBar(isEnglish ? 'Login successful!' : 'Đăng nhập thành công!');
      
      // Kiểm tra xem user có phải lần đầu tiên không
      await authService.checkIfFirstTimeUser();
      
      if (mounted) {
        if (authService.isFirstTimeUser) {
          // Chuyển đến survey screen nếu lần đầu
          Navigator.of(context).pushReplacementNamed(AppRoutes.survey);
        } else {
          // Chuyển đến home screen nếu không phải lần đầu
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        }
      }
    } else if (mounted) {
      _showSnackBar(isEnglish ? 'Login failed. Please try again.' : 'Đăng nhập thất bại. Vui lòng thử lại.');
    }
  }

  Future<void> _handleGoogleLogin() async {
    final isEnglish = Provider.of<LanguageService>(context, listen: false).isEnglish;
    final authService = context.read<AuthService>();
    setState(() => _isGoogleLoading = true);

    final success = await authService.loginWithGoogle();

    setState(() => _isGoogleLoading = false);

    if (success && mounted) {
      // Kiểm tra xem user có phải lần đầu tiên không
      await authService.checkIfFirstTimeUser();
      
      if (mounted) {
        if (authService.isFirstTimeUser) {
          // Chuyển đến survey screen nếu lần đầu
          Navigator.of(context).pushReplacementNamed(AppRoutes.survey);
        } else {
          // Chuyển đến home screen nếu không phải lần đầu
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        }
      }
    } else if (mounted) {
      _showSnackBar(isEnglish ? 'Login failed. Please try again.' : 'Đăng nhập thất bại. Vui lòng thử lại.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool get _isEnglish => context.watch<LanguageService>().isEnglish;

  String get _loginTitle => _isEnglish ? 'Welcome Back!' : 'Chào mừng trở lại!';
  String get _loginSubtitle => _isEnglish ? 'Login to continue your learning journey' : 'Đăng nhập để tiếp tục hành trình học tập của bạn';
  String get _continueButtonText => _isEnglish ? 'Sign In' : 'Đăng nhập';
  String get _orText => _isEnglish ? 'Or Sign In With' : 'Hoặc đăng nhập bằng';
  String get _signupText => _isEnglish ? "Don't have an account?" : 'Không có tài khoản?';
  String get _signupLinkText => _isEnglish ? 'Sign Up' : 'Đăng ký';
  String get _forgotPasswordText => _isEnglish ? 'Forgot Password?' : 'Quên mật khẩu?';
  String get _usernameHint => _isEnglish ? 'Username' : 'Tên đăng nhập';
  String get _passwordHint => _isEnglish ? 'Password' : 'Mật khẩu';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.backgroundColor,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo/Image Section
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color.fromARGB(255, 49, 112, 249).withValues(alpha: 0.3),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/image/welcome.png',
                              width: 160,
                              height: 160,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Title
                        Text(
                          _loginTitle,
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          _loginSubtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.subtextLight,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        // Username Input
                        _buildInputField(
                          controller: _usernameController,
                          hintText: _usernameHint,
                          icon: Icons.person_outline,
                          keyboardType: TextInputType.text,
                          onChanged: (value) => setState(() {}),
                        ),

                        const SizedBox(height: 16),

                        // Password Input
                        _buildInputField(
                          controller: _passwordController,
                          hintText: _passwordHint,
                          icon: Icons.lock_outline,
                          obscureText: !_isPasswordVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: AppColors.primaryColor,
                            ),
                            onPressed: () {
                              setState(
                                () => _isPasswordVisible = !_isPasswordVisible,
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
                            },
                            child: Text(
                              _forgotPasswordText,
                              style: const TextStyle(
                                color: AppColors.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Sign In Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              disabledBackgroundColor: AppColors.greyLight,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              shadowColor: AppColors.primaryColor.withValues(alpha: 0.3),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _continueButtonText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Divider with "Or Sign In With" text
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: AppColors.greyLight,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                _orText,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.subtextLight,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: AppColors.greyLight,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Google Sign In Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isGoogleLoading ? null : _handleGoogleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(
                                  color: AppColors.greyLight,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/icons/gg.png',
                                  width: 20,
                                  height: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _isEnglish ? 'Google' : 'Google',
                                  style: const TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Sign Up Link
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _signupText,
                                style: TextStyle(
                                  color: AppColors.subtextLight,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushNamed(AppRoutes.signup);
                                },
                                child: Text(
                                  _signupLinkText,
                                  style: const TextStyle(
                                    color: AppColors.primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
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

              // Language Toggle Button - Top Right
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          context.read<LanguageService>().setLanguage(true);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: context.watch<LanguageService>().isEnglish
                                ? AppColors.primaryColor.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'EN',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: context.watch<LanguageService>().isEnglish
                                  ? FontWeight.bold
                                  : FontWeight.w400,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.read<LanguageService>().setLanguage(false);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: !context.watch<LanguageService>().isEnglish
                                ? AppColors.primaryColor.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'VI',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: !context.watch<LanguageService>().isEnglish
                                  ? FontWeight.bold
                                  : FontWeight.w400,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(
          icon,
          color: AppColors.subtextLight,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.greyLight,
            width: 0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primaryColor,
            width: 1,
          ),
        ),
        filled: true,
        fillColor: AppColors.greyLight,
        hintStyle: TextStyle(
          fontSize: 14,
          color: AppColors.subtextLight,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
