import 'package:flutter/material.dart';

// Colors
class AppColors {
  static const Color primaryColor = Color(0xFF5BC0F8);
  static const Color primaryLight = Color(0xFF7DD1FF);
  static const Color primaryDark = Color(0xFF3BA0D8);
  static const Color secondaryColor = Color(0xFFFF6B6B);
  static const Color backgroundColor = Color(0xFFFAFBFF);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color greyDark = Color(0xFF2D3748);
  static const Color greyLight = Color(0xFFF3F4F6);
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);
  static const Color textLight = Color(0xFF2D3748);
  static const Color subtextLight = Color(0xFF718096);
  static const Color peach = Color(0xFFFFD8CC);
}

// Text Styles
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.greyDark,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.greyLight,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
}

// Routes
class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String survey = '/survey';
  static const String home = '/home';
}

// Strings
class AppStrings {
  // Splash Screen
  static const String appTitle = 'Pupu';


  // Login Screen
  static const String loginTitle = 'Welcome Back';
  static const String loginSubtitle = 'Sign in to continue learning';
  static const String emailHint = 'Email or Username';
  static const String passwordHint = 'Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String loginButton = 'Sign In';
  static const String signupText = "Don't have an account? Sign up";
  static const String orContinueWith = 'Or continue with';
  static const String skipButton = 'Skip';
  static const String googleLogin = 'Sign in with Google';
  static const String supabaseLogin = 'Sign in with Supabase';

  // Signup Screen
  static const String signupTitle = 'Create Account';
  static const String signupSubtitle = 'Join us and start learning';
  static const String nameHint = 'Full Name';
  static const String confirmPasswordHint = 'Confirm Password';
  static const String signupButton = 'Create Account';
  static const String loginText = 'Already have an account? Sign in';
  static const String agreeTerms = 'I agree to Terms & Conditions';
  static const String googleSignup = 'Sign up with Google';
  static const String supabaseSignup = 'Sign up with Supabase';

  // Messages
  static const String loadingMessage = 'Loading...';
  static const String errorMessage = 'Something went wrong';
  static const String successMessage = 'Success!';

  // Survey Screen
  static const String surveyTitle = 'Survey';
  static const String surveyStep1Title = 'What\'s your name?';
  static const String surveyStep1TitleVi = 'Tên của bạn là gì?';
  static const String surveyStep1Subtitle = 'We can call you as';
  static const String surveyStep1SubtitleVi = 'Chúng tôi có thể gọi bạn là';

  static const String surveyStep2Title = 'Why are you learning English?';
  static const String surveyStep2TitleVi = 'Tại sao bạn học tiếng Anh?';
  static const String surveyStep2Subtitle = 'Brain training';
  static const String surveyStep2SubtitleVi = 'Tập luyện trí não';
  static const String surveyStep2Option1 = 'Brain training';
  static const String surveyStep2Option1Vi = 'Tập luyện trí não';
  static const String surveyStep2Option2 = 'Travel';
  static const String surveyStep2Option2Vi = 'Du lịch';
  static const String surveyStep2Option3 = 'For job';
  static const String surveyStep2Option3Vi = 'Để tìm việc';
  static const String surveyStep2Option4 = 'Others';
  static const String surveyStep2Option4Vi = 'Khác';

  static const String surveyStep3Title = 'When\'s your daily activity?';
  static const String surveyStep3TitleVi = 'Bạn học vào lúc nào mỗi ngày?';
  static const String surveyStep3Subtitle = 'We send reminders to help you stay on track';
  static const String surveyStep3SubtitleVi = 'Chúng tôi sẽ gửi nhắc nhở cho bạn';
  static const String surveyStep3Option1 = '5 min / day';
  static const String surveyStep3Option1Vi = '5 phút / ngày';
  static const String surveyStep3Option2 = '10 min / day';
  static const String surveyStep3Option2Vi = '10 phút / ngày';
  static const String surveyStep3Option3 = '20 min / day';
  static const String surveyStep3Option3Vi = '20 phút / ngày';

  static const String surveyStep4Title = 'How much English do you know?';
  static const String surveyStep4TitleVi = 'Bạn biết tiếng Anh ở cấp độ nào?';
  static const String surveyStep4Subtitle = 'This helps us customize your experience';
  static const String surveyStep4SubtitleVi = 'Điều này giúp chúng tôi tùy chỉnh trải nghiệm của bạn';
  static const String surveyStep4Option1 = 'A Help';
  static const String surveyStep4Option1Vi = 'A Cần trợ giúp';
  static const String surveyStep4Option2 = 'A Me';
  static const String surveyStep4Option2Vi = 'A Có chút kinh nghiệm';

  static const String nextButton = 'Next';
  static const String nextButtonVi = 'Tiếp theo';
  static const String finishButton = 'Finish';
  static const String finishButtonVi = 'Hoàn thành';
}
