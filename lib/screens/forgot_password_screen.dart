import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleResetPassword() async {
    final isEnglish = Provider.of<LanguageService>(context, listen: false).isEnglish;
    final authService = context.read<AuthService>();
    
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar(isEnglish ? 'Please enter your email' : 'Vui lòng nhập email của bạn');
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar(isEnglish ? 'Please enter a valid email' : 'Vui lòng nhập email hợp lệ');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await authService.resetPassword(email);
      setState(() {
        _isLoading = false;
        _isEmailSent = true;
      });
      _showSnackBar(isEnglish 
          ? 'Password reset link sent to your email!' 
          : 'Liên kết đặt lại mật khẩu đã được gửi đến email của bạn!');
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(isEnglish 
          ? 'Failed to send reset link. Please try again.' 
          : 'Không thể gửi liên kết. Vui lòng thử lại.');
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  bool get _isEnglish => context.watch<LanguageService>().isEnglish;

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

                    // Illustration Container
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color.fromARGB(255, 240, 154, 56).withValues(alpha: 0.4),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/image/forgot_password.png',
                          width: 160,
                          height: 160,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      _isEnglish ? 'Forgot Password?' : 'Quên Mật Khẩu?',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      _isEnglish
                          ? "Don't worry! It happens. Please enter the email address linked with your account."
                          : 'Đừng lo! Điều này có thể xảy ra. Vui lòng nhập địa chỉ email liên kết với tài khoản của bạn.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.subtextLight,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    if (!_isEmailSent)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Email Input
                          _buildInputField(
                            controller: _emailController,
                            hintText: _isEnglish ? 'Email Address' : 'Địa chỉ Email',
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (value) => setState(() {}),
                          ),

                          const SizedBox(height: 32),

                          // Send Code Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading || !_isValidEmail(_emailController.text.trim())
                                  ? null
                                  : _handleResetPassword,
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
                                          _isEnglish ? 'Send Code' : 'Gửi Mã',
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

                          // Remember Password Link
                          GestureDetector(
                            onTap: () => Navigator.of(context).pushNamed(AppRoutes.login),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: _isEnglish ? 'Remember Password? ' : 'Nhớ mật khẩu? ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.subtextLight,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _isEnglish ? 'Sign In' : 'Đăng Nhập',
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
                        ],
                      )
                    else
                      // Success Message
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.successColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.successColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.successColor,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _isEnglish ? 'Code Sent!' : 'Mã Đã Được Gửi!',
                                  style: AppTextStyles.heading3.copyWith(
                                    color: AppColors.successColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _isEnglish
                                      ? 'We\'ve sent a password reset code to ${_emailController.text}. Please check your email and follow the instructions.'
                                      : 'Chúng tôi đã gửi mã đặt lại mật khẩu đến ${_emailController.text}. Vui lòng kiểm tra email của bạn.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.subtextLight,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Back to Login Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              child: Text(
                                _isEnglish ? 'Back to Sign In' : 'Quay Lại Đăng Nhập',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(
          icon,
          color: AppColors.subtextLight,
        ),
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
