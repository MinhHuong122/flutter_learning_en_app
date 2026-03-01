import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;
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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final isEnglish = Provider.of<LanguageService>(context, listen: false).isEnglish;
    final authService = context.read<AuthService>();

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar(isEnglish ? 'Please fill in all fields' : 'Vui lòng điền tất cả các trường');
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar(isEnglish ? 'Passwords do not match' : 'Mật khẩu không khớp');
      return;
    }

    if (password.length < 6) {
      _showSnackBar(isEnglish ? 'Password must be at least 6 characters' : 'Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }

    if (!_agreeToTerms) {
      _showSnackBar(isEnglish ? 'Please agree to Terms & Conditions' : 'Vui lòng đồng ý với Điều khoản & Điều kiện');
      return;
    }

    setState(() => _isLoading = true);

    final success = await authService.signupWithEmailPassword(
      username,
      email,
      password,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      _showSnackBar(isEnglish ? 'Signup successful!' : 'Đăng ký thành công!');
      // Quay lại trang login để người dùng đăng nhập
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    } else if (mounted) {
      _showSnackBar(isEnglish ? 'Signup failed. Please try again.' : 'Đăng ký thất bại. Vui lòng thử lại.');
    }
  }

  Future<void> _handleGoogleSignup() async {
    final isEnglish = Provider.of<LanguageService>(context, listen: false).isEnglish;
    final authService = context.read<AuthService>();
    setState(() => _isGoogleLoading = true);

    final success = await authService.signupWithGoogle();

    setState(() => _isGoogleLoading = false);

    if (success && mounted) {
      await authService.checkIfFirstTimeUser();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.survey);
      }
    } else if (mounted) {
      _showSnackBar(isEnglish ? 'Signup failed. Please try again.' : 'Đăng ký thất bại. Vui lòng thử lại.');
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

  String get _createAccountTitle => _isEnglish ? 'Create Account' : 'Tạo Tài Khoản';
  String get _createAccountSubtitle => _isEnglish ? 'Join our community to start learning' : 'Tham gia cộng đồng để bắt đầu học tập';
  String get _signUpButtonText => _isEnglish ? 'Sign Up' : 'Đăng Ký';
  String get _orContinueText => _isEnglish ? 'Or continue with' : 'Hoặc tiếp tục với';
  String get _alreadyHaveAccountText => _isEnglish ? 'Already have an account?' : 'Đã có tài khoản?';
  String get _loginText => _isEnglish ? 'Login' : 'Đăng Nhập';
  String get _agreeTermsText => _isEnglish ? 'I agree to the Terms & Conditions and Privacy Policy' : 'Tôi đồng ý với Điều khoản & Điều kiện và Chính sách Bảo mật';
  String get _usernameHint => _isEnglish ? 'Username' : 'Tên đăng nhập';
  String get _emailHint => _isEnglish ? 'Email Address' : 'Địa chỉ Email';
  String get _passwordHint => _isEnglish ? 'Password' : 'Mật khẩu';
  String get _confirmPasswordHint => _isEnglish ? 'Confirm Password' : 'Xác nhận Mật khẩu';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Back Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Icon(Icons.arrow_back, size: 24),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      _createAccountTitle,
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      _createAccountSubtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.subtextLight,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Username Input
                    _buildInputField(
                      controller: _usernameController,
                      hintText: _usernameHint,
                      icon: Icons.person_outline,
                      keyboardType: TextInputType.text,
                      onChanged: (value) => setState(() {}),
                    ),

                    const SizedBox(height: 12),

                    // Email Input
                    _buildInputField(
                      controller: _emailController,
                      hintText: _emailHint,
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) => setState(() {}),
                    ),

                    const SizedBox(height: 12),

                    // Password Input
                    _buildInputField(
                      controller: _passwordController,
                      hintText: _passwordHint,
                      icon: Icons.lock_outline,
                      obscureText: !_isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: AppColors.primaryColor,
                        ),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),

                    const SizedBox(height: 12),

                    // Confirm Password Input
                    _buildInputField(
                      controller: _confirmPasswordController,
                      hintText: _confirmPasswordHint,
                      icon: Icons.verified_user,
                      obscureText: !_isConfirmPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: AppColors.primaryColor,
                        ),
                        onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),

                    const SizedBox(height: 16),

                    // Terms & Conditions Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _agreeToTerms,
                          onChanged: (value) {
                            setState(() => _agreeToTerms = value ?? false);
                          },
                          activeColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _agreeTermsText,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.subtextLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          disabledBackgroundColor: AppColors.primaryColor.withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: AppColors.primaryColor.withValues(alpha: 0.4),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _signUpButtonText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login Link
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.login),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$_alreadyHaveAccountText ',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.subtextLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(
                              text: _loginText,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Divider with Or Continue With
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
                            _orContinueText,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.subtextLight,
                              fontWeight: FontWeight.w500,
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

                    // Google Button
                    Center(
                      child: GestureDetector(
                        onTap: _isGoogleLoading ? null : _handleGoogleSignup,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white,
                            border: Border.all(
                              color: AppColors.greyLight,
                              width: 1.5,
                            ),
                          ),
                          child: _isGoogleLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                                  ),
                                )
                              : Image.asset(
                                  'assets/icons/gg.png',
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.contain,
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
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
