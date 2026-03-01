import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isAuthenticated = false;
  String? _userName;
  String? _userEmail;
  String? _userId;
  String? _errorMessage;
  bool _isFirstTimeUser = false;

  bool get isAuthenticated => _isAuthenticated;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userId => _userId;
  String? get errorMessage => _errorMessage;
  bool get isFirstTimeUser => _isFirstTimeUser;

  /// Stream để lắng nghe thay đổi auth state từ Supabase
  Stream<AuthState> get authStateStream => _supabase.auth.onAuthStateChange;

  /// Constructor - lắng nghe auth state changes tự động
  AuthService() {
    _initAuthStateListener();
  }

  /// Lắng nghe thay đổi auth state từ Supabase
  void _initAuthStateListener() {
    _supabase.auth.onAuthStateChange.listen(
      (data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        print('Auth state changed: ${event.name}');

        if (event == AuthChangeEvent.signedIn && session != null) {
          final user = session.user;
          _isAuthenticated = true;
          _userEmail = user.email;
          _userId = user.id;
          _userName = user.userMetadata?['name'] ?? 
                     user.email?.split('@')[0] ?? 'User';
          print('User signed in: $_userName');
        } else if (event == AuthChangeEvent.signedOut) {
          _isAuthenticated = false;
          _userName = null;
          _userEmail = null;
          _userId = null;
          _errorMessage = null;
          print('User signed out');
        } else if (event == AuthChangeEvent.userUpdated && session != null) {
          final user = session.user;
          _userEmail = user.email;
          _userName = user.userMetadata?['name'] ?? 
                     user.email?.split('@')[0] ?? 'User';
          print('User updated: $_userName');
        }

        notifyListeners();
      },
      onError: (error) {
        print('Auth state stream error: $error');
        _errorMessage = 'Auth error: $error';
        notifyListeners();
      },
    );
  }

  /// Login with email and password
  Future<bool> loginWithEmailPassword(String email, String password) async {
    try {
      _errorMessage = null;
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _isAuthenticated = true;
        _userEmail = response.user!.email;
        _userId = response.user!.id;
        _userName = response.user!.userMetadata?['name'] ?? 
                   response.user!.email?.split('@')[0] ?? 'User';
        notifyListeners();
        return true;
      }
      return false;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      print('Login error: ${e.message}');
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      print('Login error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Signup with email and password
  /// Trigger handle_new_user() sẽ tự động tạo profile entry
  Future<bool> signupWithEmailPassword(
      String username, String email, String password) async {
    try {
      _errorMessage = null;

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'name': username,
        },
      );

      if (response.user != null) {
        _isAuthenticated = true;
        _userEmail = response.user!.email;
        _userId = response.user!.id;
        _userName = username;

        notifyListeners();
        return true;
      }
      return false;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      print('Signup error: ${e.message}');
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      print('Signup error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Login with Google - Using google_sign_in with Supabase
  Future<bool> loginWithGoogle() async {
    try {
      _errorMessage = null;
      print('Starting Google login...');
      
      // 🔑 Logout Google first to force account picker
      final googleSignIn = GoogleSignIn(
        scopes: [
          'email', 
          'profile',
          'openid',
        ],
        serverClientId: '372911173512-r5aadpgmmk7ct23jdodu3cst56pgd0q7.apps.googleusercontent.com',
        forceCodeForRefreshToken: true,
      );
      
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
      
      print('Attempting Google sign-in...');
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        _errorMessage = 'Google sign-in cancelled by user';
        print('Google sign-in cancelled');
        notifyListeners();
        return false;
      }

      print('Google user signed in: ${googleUser.email}');
      
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      
      print('DEBUG: idToken=$idToken, accessToken=$accessToken');
      
      if (idToken == null) {
        _errorMessage = 'Failed to obtain ID Token from Google';
        print('No ID Token found - trying with access token only');
        
        // Try signInWithOAuth as fallback
        try {
          await _supabase.auth.signInWithOAuth(
            OAuthProvider.google,
          );
        } catch (e) {
          print('OAuth fallback failed: $e');
          notifyListeners();
          return false;
        }
      } else {
        print('Signing in to Supabase with Google credentials...');
        await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
      }

      final user = _supabase.auth.currentUser;
      if (user != null) {
        _isAuthenticated = true;
        _userEmail = user.email;
        _userId = user.id;
        _userName = user.userMetadata?['name'] ?? 
                   user.email?.split('@')[0] ?? 'User';
        
        print('Successfully authenticated: $_userName');
        
        // Profile tự động được tạo bởi trigger handle_new_user()
        notifyListeners();
        return true;
      }
      
      _errorMessage = 'Failed to get user information from Supabase';
      return false;
    } catch (e) {
      _errorMessage = 'Google login failed: $e';
      print('Unexpected error in Google login: $e');
      notifyListeners();
      return false;
    }
  }

  /// Signup with Google
  Future<bool> signupWithGoogle() async {
    try {
      _errorMessage = null;
      print('Starting Google Sign-up process...');

      final googleSignIn = GoogleSignIn(
        scopes: [
          'email', 
          'profile',
          'openid',
        ],
        serverClientId: '372911173512-r5aadpgmmk7ct23jdodu3cst56pgd0q7.apps.googleusercontent.com',
        forceCodeForRefreshToken: true,
      );
      
      // 🔑 Logout Google first to force account picker
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
      
      print('Attempting to sign in with Google...');
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        _errorMessage = 'Google sign-in cancelled by user';
        print('Google sign-in cancelled');
        notifyListeners();
        return false;
      }

      print('Google user signed in: ${googleUser.email}');

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      
      print('DEBUG: idToken=$idToken, accessToken=$accessToken');
      
      if (idToken == null) {
        _errorMessage = 'Failed to obtain ID Token from Google';
        print('No ID Token found - trying with access token only');
        
        // Try signInWithOAuth as fallback
        try {
          await _supabase.auth.signInWithOAuth(
            OAuthProvider.google,
          );
        } catch (e) {
          print('OAuth fallback failed: $e');
          notifyListeners();
          return false;
        }
      } else {
        print('Signing in to Supabase with Google credentials...');
        await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
      }

      final user = _supabase.auth.currentUser;
      if (user != null) {
        _isAuthenticated = true;
        _userEmail = user.email;
        _userId = user.id;
        _userName = user.userMetadata?['name'] ?? 
                   user.email?.split('@')[0] ?? 'User';

        print('Successfully signed up: $_userName');

        // Profile tự động được tạo bởi trigger handle_new_user()
        notifyListeners();
        return true;
      }
      
      _errorMessage = 'Failed to get user information from Supabase';
      return false;
    } catch (e) {
      _errorMessage = 'Google signup failed: $e';
      print('Unexpected error in Google signup: $e');
      notifyListeners();
      return false;
    }
  }

  /// Note: _saveUserToDatabase() removed
  /// Profile tự động được tạo bởi trigger function handle_new_user()
  /// khi user mới đăng ký qua auth.users

  /// Logout
  /// ⚠️ Logout từ cả Google + Supabase để xóa session
  Future<void> logout() async {
    try {
      print('Starting logout process...');
      
      // 🔑 Step 1: Logout từ Google để xóa session
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
        print('Google Sign-out completed');
      }
      
      // Try disconnect thêm (clear cache)
      try {
        await googleSignIn.disconnect();
        print('Google disconnect() completed');
      } catch (e) {
        print('Google disconnect note: $e');
      }
      
      // 🔑 Step 2: Logout từ Supabase
      await _supabase.auth.signOut();
      print('Supabase Sign-out completed');
      
      // 🔑 Step 3: Clear local state
      _isAuthenticated = false;
      _userName = null;
      _userEmail = null;
      _userId = null;
      _errorMessage = null;
      
      notifyListeners();
      print('Logout successful');
    } catch (e) {
      _errorMessage = 'Logout error: $e';
      print('Logout error: $e');
      notifyListeners();
    }
  }

  /// Skip authentication (guest mode)
  void skipAuthentication() {
    _isAuthenticated = false;
    _userName = 'Guest';
    _errorMessage = null;
    notifyListeners();
  }

  /// Check if user is already authenticated
  Future<bool> checkAuthStatus() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        _isAuthenticated = true;
        _userEmail = user.email;
        _userId = user.id;
        _userName = user.userMetadata?['name'] ?? 
                   user.email?.split('@')[0] ?? 'User';
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error checking auth status: $e');
      return false;
    }
  }

  /// Reset password - gửi reset link đến email
  Future<void> resetPassword(String email) async {
    try {
      _errorMessage = null;
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.example.app://reset-password', // Adjust based on your redirect URL
      );
      print('Password reset link sent to $email');
    } on AuthException catch (e) {
      _errorMessage = e.message;
      print('Reset password error: ${e.message}');
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      print('Reset password error: $e');
      notifyListeners();
      rethrow;
    }
  }
  /// Kiểm tra xem user đã hoàn thành survey lần đầu hay chưa
  Future<void> checkIfFirstTimeUser() async {
    try {
      if (_userId == null) {
        _isFirstTimeUser = true;
        return;
      }

      // Kiểm tra xem user đã có survey response hay chưa
      // survey_responses.user_id references profiles.id
      final response = await _supabase
          .from('survey_responses')
          .select('id')
          .eq('user_id', _userId!)
          .limit(1);

      // Nếu response trống = user chưa làm survey (lần đầu tiên)
      _isFirstTimeUser = response.isEmpty;
      notifyListeners();

      print('User first time status: $_isFirstTimeUser');
    } catch (e) {
      print('Error checking first time user: $e');
      _isFirstTimeUser = false; // Default to not first time if error
    }
  }

  /// Đánh dấu rằng user đã hoàn thành survey
  Future<void> completeSurvey() async {
    try {
      if (_userId == null) return;

      _isFirstTimeUser = false;
      notifyListeners();
      print('Survey marked as completed');
    } catch (e) {
      print('Error completing survey: $e');
      notifyListeners();
    }
  }

  /// Lưu survey responses của user
  Future<void> saveSurveyResponse({
    required String userName,
    required String learningReason,
    required List<String> selectedSkills,
    required String userBackground,
    required String dailyDuration,
    String? englishLevel,
  }) async {
    try {
      if (_userId == null) {
        throw Exception('User ID is null. User not authenticated.');
      }

      // Verify profile exists before saving survey
      print('DEBUG: Checking if profile exists for user_id: $_userId');
      final profileExists = await _supabase
          .from('profiles')
          .select()
          .eq('id', _userId!)
          .then((data) => data.isNotEmpty);

      if (!profileExists) {
        print('DEBUG: Profile does not exist. Creating profile with username: $userName');
        // Call RPC function with SECURITY DEFINER to bypass RLS
        try {
          await _supabase.rpc('ensure_profile', params: {
            'p_user_id': _userId,
            'p_username': userName,
            'p_display_name': userName,
          });
          print('DEBUG: Profile created successfully via RPC');
        } catch (e) {
          print('DEBUG: RPC error: $e');
          // Fallback to direct insert if RPC fails
          try {
            await _supabase.from('profiles').insert({
              'id': _userId,
              'username': userName,
              'display_name': userName,
            });
            print('DEBUG: Profile created successfully via direct insert');
          } catch (fallbackError) {
            print('DEBUG: Fallback insert error: $fallbackError');
            // Continue anyway - profile might exist or trigger created it
          }
        }
      }

      print('DEBUG: Saving survey response for user_id: $_userId');
      await _supabase.from('survey_responses').insert({
        'user_id': _userId,
        'username': userName,
        'learning_reason': learningReason,
        'daily_duration': dailyDuration,
        'learning_goal': selectedSkills.join(', '),
        'english_level': englishLevel,
        'selected_skills': selectedSkills, // Lưu dưới dạng array
        'starting_point': userBackground,
        'completed_at': DateTime.now().toIso8601String(),
      });

      _isFirstTimeUser = false;
      notifyListeners();
      print('Survey responses saved successfully');
    } catch (e) {
      print('Error saving survey response: $e');
      notifyListeners();
      rethrow;
    }
  }
  /// Login with username and password
  /// Tìm user dựa trên username trong bảng profiles
  /// Sau đó sử dụng email để login
  Future<bool> loginWithUsernamePassword(String username, String password) async {
    try {
      _errorMessage = null;

      // Tìm user dựa trên username trong bảng profiles
      final profileResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      if (profileResponse == null) {
        _errorMessage = 'Username not found';
        print('Username not found: $username');
        notifyListeners();
        return false;
      }

      // Lấy user ID từ profile
      final userId = profileResponse['id'] as String;
      print('User ID found from profile: $userId');

      // ⚠️ Supabase auth yêu cầu email hoặc phone để login
      // Cách 1: Nếu username là email, sử dụng trực tiếp
      if (username.contains('@')) {
        return await loginWithEmailPassword(username, password);
      }
      
      // Cách 2: Nếu không phải email, hiển thị lỗi
      _errorMessage = 'Please use email to login. Username login requires email-based usernames.';
      notifyListeners();
      return false;
      
    } on PostgrestException catch (e) {
      _errorMessage = 'Username not found: ${e.message}';
      print('Database error: ${e.message}');
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      print('Login error: $e');
      notifyListeners();
      return false;
    }
  }
}