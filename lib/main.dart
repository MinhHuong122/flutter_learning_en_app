import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/constants.dart';
import 'utils/route_observer.dart';
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
import 'services/community_service.dart';
import 'services/messaging_service.dart';
import 'providers/lesson_provider.dart';

const bool _warmupDictionaryOnStartup = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ypckcxhrbyfpsutzhdho.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlwY2tjeGhyYnlmcHN1dHpoZGhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwNzIzMjEsImV4cCI6MjA4NDY0ODMyMX0.AbPrkjoLv5mbBaD6kOdXK34Qttq-39M6Aqrq-fPLwgY',
  );

  runApp(const MyApp());

  // Run heavy startup tasks only after the first frame is rendered.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializeAppServices());
  });
}

Future<void> _initializeAppServices() async {
  // Reduce startup delay for faster app launch
  await Future.delayed(const Duration(milliseconds: 100));

  // Initialize notifications quickly with timeout
  await _safeRun(() => _initializeNotificationsWithTimeout());

  // Optional warmup for dictionary DB. Disabled by default to avoid startup jank.
  if (_warmupDictionaryOnStartup) {
    await _safeRun(_initializeDictionaryDatabase);
  }
}

Future<void> _initializeNotificationsWithTimeout() async {
  try {
    final notificationCenter = NotificationCenterService();
    await notificationCenter.initialize();
    
    // Use timeout to prevent hanging
    await notificationCenter.restoreSchedulesFromSavedSettings()
        .timeout(const Duration(seconds: 3), onTimeout: () async {
      debugPrint('Notification restore timeout - skipping');
    });
    
    // Sync notifications in background without waiting
    notificationCenter.syncNotifications().ignore();
  } catch (e) {
    print('⚠️ Notification initialization warning: $e');
  }
}

Future<void> _safeRun(Future<void> Function() task) async {
  try {
    await task();
  } catch (e) {
    debugPrint('⚠️ Startup task warning: $e');
  }
}

Future<void> _initializeDictionaryDatabase() async {
  print('📚 Initializing dictionary database...');
  try {
    final db = DatabaseHelper();
    final database = await db.database;

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
}

Future<void> _initializeNotifications() async {
  try {
    final notificationCenter = NotificationCenterService();
    await notificationCenter.initialize();
    await notificationCenter.restoreSchedulesFromSavedSettings();
    await notificationCenter.syncNotifications();
  } catch (e) {
    print('⚠️ Notification initialization warning: $e');
  }
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
        ChangeNotifierProvider(create: (_) => LessonProvider()),
        Provider(create: (_) => CommunityService()),
        Provider(create: (_) => MessagingService()),
      ],
      child: MaterialApp(
        title: AppStrings.appTitle,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
          useMaterial3: true,
        ),
        navigatorObservers: [appRouteObserver],
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

