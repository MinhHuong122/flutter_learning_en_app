import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/constants.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/survey_screen.dart';
import 'screens/home_screen.dart';
import 'screens/dictionary_search_screen.dart';
import 'services/auth_service.dart';
import 'services/language_service.dart';
import 'services/database_helper.dart';
import 'services/notification_center_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ypckcxhrbyfpsutzhdho.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlwY2tjeGhyYnlmcHN1dHpoZGhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwNzIzMjEsImV4cCI6MjA4NDY0ODMyMX0.AbPrkjoLv5mbBaD6kOdXK34Qttq-39M6Aqrq-fPLwgY',
  );

  // Initialize dictionary database (will import on first run)
  print('📚 Initializing dictionary database...');
  try {
    final db = DatabaseHelper();
    final database = await db.database;
    
    // Verify data was imported
    final result = await database.rawQuery('SELECT COUNT(*) as count FROM headwords');
    final headwordCount = result.isNotEmpty ? (result[0]['count'] as int? ?? 0) : 0;
    print('📊 Database contains $headwordCount headwords');
    
    if (headwordCount == 0) {
      print('⚠️  No headwords found in database - import may have failed');
    } else {
      print('✅ Dictionary database ready with $headwordCount headwords');
    }
  } catch (e) {
    print('⚠️ Dictionary initialization warning: $e');
  }

  // Initialize local notifications and sync in-app notifications
  try {
    final notificationCenter = NotificationCenterService();
    await notificationCenter.initialize();
    await notificationCenter.restoreSchedulesFromSavedSettings();
    await notificationCenter.syncNotifications();
  } catch (e) {
    print('⚠️ Notification initialization warning: $e');
  }

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => LanguageService()),
      ],
      child: MaterialApp(
        title: AppStrings.appTitle,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
        routes: {
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.signup: (context) => const SignupScreen(),
          AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
          AppRoutes.survey: (context) => const SurveyScreen(),
          AppRoutes.home: (context) => const HomeScreen(),
          '/dictionary': (context) => const DictionarySearchScreen(),
        },
      ),
    );
  }
}

