import 'package:flutter/foundation.dart';
import '../models/community_model.dart';
import '../services/community_service.dart';

class CommunityProvider extends ChangeNotifier {
  final CommunityService _communityService;

  CommunityProvider(this._communityService);

  List<CommunityPost> _posts = [];
  List<CommunityPost> get posts => _posts;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int _selectedCategory = 0;
  int get selectedCategory => _selectedCategory;

  /// Load posts with optional filtering
  Future<void> loadPosts({String? category}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _posts = await _communityService.getPosts(category: category);
      _error = null;
    } catch (e) {
      _error = 'Lỗi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search posts
  Future<void> searchPosts(String query) async {
    if (query.isEmpty) {
      await loadPosts();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _posts = await _communityService.searchPosts(query);
      _error = null;
    } catch (e) {
      _error = 'Lỗi tìm kiếm: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set selected category
  void setSelectedCategory(int index) {
    _selectedCategory = index;
    notifyListeners();
  }

  /// Refresh posts
  Future<void> refreshPosts() async {
    final category = _selectedCategory == 0 ? null : null; // TODO: Get category name
    await loadPosts(category: category);
  }

  /// Update post in list (for likes, etc)
  void updatePost(CommunityPost post) {
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index != -1) {
      _posts[index] = post;
      notifyListeners();
    }
  }

  /// Add post to beginning of list
  void addPost(CommunityPost post) {
    _posts.insert(0, post);
    notifyListeners();
  }

  /// Remove post from list
  void removePost(String postId) {
    _posts.removeWhere((p) => p.id == postId);
    notifyListeners();
  }
}
